Attribute VB_Name = "modRender"
Option Explicit
Public SimHwnd As LongPtr, Canvas As LongPtr
Private windowDC As LongPtr, sceneDC As LongPtr, canvasBitmap As LongPtr, sceneBitmap As LongPtr
Private oldCanvas As LongPtr, oldScene As LongPtr
Private panelDC As LongPtr, panelBitmap As LongPtr, oldPanel As LongPtr
Private buildingPanel As Boolean
Private instrumentDC As LongPtr, instrumentBitmap As LongPtr, oldInstrument As LongPtr
Private fonts(0 To 3) As LongPtr
Private pixels(0 To 230399) As Long, ceiling(0 To 479) As Long
Private bmi As BITMAPINFOHEADER
Private camE As Double, camN As Double, camAlt As Double, camYaw As Double, camPitch As Double, camBank As Double
Private sh As Double, ch As Double, cb As Double, sb As Double
Public TerrainMS As Double, PanelMS As Double, FPS As Double
Public Sub InitRenderer(ByVal hwnd As LongPtr)
    SimHwnd = hwnd: windowDC = GetDC(hwnd)
    If windowDC = 0 Then Err.Raise 5, , "Cannot acquire simulator DC"
    Canvas = CreateCompatibleDC(windowDC): sceneDC = CreateCompatibleDC(windowDC)
    canvasBitmap = CreateCompatibleBitmap(windowDC, 1000, 700)
    sceneBitmap = CreateCompatibleBitmap(windowDC, 480, 480)
    If Canvas = 0 Or sceneDC = 0 Or canvasBitmap = 0 Or sceneBitmap = 0 Then Err.Raise 7, , "GDI allocation failed"
    oldCanvas = SelectObject(Canvas, canvasBitmap): oldScene = SelectObject(sceneDC, sceneBitmap)
    fonts(0) = CreateFont(-15, 0, 0, 0, 400, 0, 0, 0, 1, 0, 0, 5, 0, "Consolas")
    fonts(1) = CreateFont(-22, 0, 0, 0, 600, 0, 0, 0, 1, 0, 0, 5, 0, "Segoe UI")
    fonts(2) = CreateFont(-42, 0, 0, 0, 700, 0, 0, 0, 1, 0, 0, 5, 0, "Segoe UI")
    fonts(3) = CreateFont(-11, 0, 0, 0, 400, 0, 0, 0, 1, 0, 0, 5, 0, "Segoe UI")
    bmi.biSize = 40: bmi.biWidth = 480: bmi.biHeight = -480: bmi.biPlanes = 1: bmi.biBitCount = 32
End Sub
Public Sub CloseRenderer()
    Dim i As Long
    If panelDC <> 0 Then SelectObject panelDC, oldPanel
    If panelBitmap <> 0 Then DeleteObject panelBitmap
    If panelDC <> 0 Then DeleteDC panelDC
    panelDC = 0: panelBitmap = 0
    If instrumentDC <> 0 Then SelectObject instrumentDC, oldInstrument
    If instrumentBitmap <> 0 Then DeleteObject instrumentBitmap
    If instrumentDC <> 0 Then DeleteDC instrumentDC
    instrumentDC = 0: instrumentBitmap = 0
    If Canvas <> 0 Then SelectObject Canvas, oldCanvas
    If sceneDC <> 0 Then SelectObject sceneDC, oldScene
    If canvasBitmap <> 0 Then DeleteObject canvasBitmap
    If sceneBitmap <> 0 Then DeleteObject sceneBitmap
    For i = 0 To 3
        If fonts(i) <> 0 Then DeleteObject fonts(i): fonts(i) = 0
    Next
    If Canvas <> 0 Then DeleteDC Canvas
    If sceneDC <> 0 Then DeleteDC sceneDC
    If windowDC <> 0 Then ReleaseDC SimHwnd, windowDC
    Canvas = 0: sceneDC = 0: canvasBitmap = 0: sceneBitmap = 0: windowDC = 0: SimHwnd = 0
End Sub
Public Sub Box(ByVal dc As LongPtr, ByVal x As Long, ByVal y As Long, ByVal w As Long, ByVal h As Long, ByVal color As Long)
    Dim r As RECT, brush As LongPtr
    r.Left = x: r.Top = y: r.Right = x + w: r.Bottom = y + h
    brush = CreateSolidBrush(color): FillRect dc, r, brush: DeleteObject brush
End Sub
Public Sub DrawText(ByVal dc As LongPtr, ByVal x As Long, ByVal y As Long, ByVal value As String, Optional ByVal size As Long = 0, Optional ByVal color As Long = 15198183)
    Dim old As LongPtr
    old = SelectObject(dc, fonts(size)): SetBkMode dc, 1: SetTextColor dc, color
    TextOut dc, x, y, value, Len(value): SelectObject dc, old
End Sub
Public Sub DrawLine(ByVal dc As LongPtr, ByVal x As Long, ByVal y As Long, ByVal xx As Long, ByVal yy As Long, ByVal color As Long, Optional ByVal width As Long = 1)
    Dim pen As LongPtr, old As LongPtr
    pen = CreatePen(0, width, color): old = SelectObject(dc, pen)
    MoveToEx dc, x, y, 0: LineTo dc, xx, yy
    SelectObject dc, old: DeleteObject pen
End Sub
Public Sub Disk(ByVal dc As LongPtr, ByVal x As Long, ByVal y As Long, ByVal radius As Long, ByVal color As Long)
    Dim brush As LongPtr, old As LongPtr, pen As LongPtr, oldP As LongPtr
    brush = CreateSolidBrush(color): old = SelectObject(dc, brush)
    pen = CreatePen(0, 1, color): oldP = SelectObject(dc, pen)
    Ellipse dc, x - radius, y - radius, x + radius, y + radius
    SelectObject dc, old: SelectObject dc, oldP: DeleteObject brush: DeleteObject pen
End Sub
Private Sub Poly(ByVal dc As LongPtr, ByRef p() As POINTAPI, ByVal n As Long, ByVal color As Long)
    Dim brush As LongPtr, pen As LongPtr, old As LongPtr, oldP As LongPtr
    brush = CreateSolidBrush(color): old = SelectObject(dc, brush)
    pen = CreatePen(0, 1, color): oldP = SelectObject(dc, pen)
    Polygon dc, p(0), n
    SelectObject dc, old: SelectObject dc, oldP: DeleteObject brush: DeleteObject pen
End Sub
Private Sub Camera()
    camE = Plane.east: camN = Plane.north: camAlt = Plane.altitude + 0.6
    camYaw = Plane.heading: camPitch = Plane.pitch: camBank = Plane.bank
    If CameraMode = 2 Then
        camE = camE - Sin(camYaw) * 35: camN = camN - Cos(camYaw) * 35: camAlt = camAlt + 10
        camPitch = camPitch - 0.05: camBank = camBank * 0.55
    ElseIf CameraMode = 3 Then
        camYaw = camYaw + 0.55: camPitch = -0.13: camBank = 0
    End If
    sh = Sin(camYaw): ch = Cos(camYaw): cb = Cos(camBank): sb = Sin(camBank)
End Sub
Public Sub RenderFrame(Optional ByVal menu As Boolean = False)
    Dim t As Double, p(0 To 2) As POINTAPI, i As Long, px As Double, py As Double
    t = Clock(): Camera
    RenderTerrain
    StretchDIBits sceneDC, 0, 0, 480, 480, 0, 0, 480, 480, pixels(0), bmi, 0, SRCCOPY
    Airport
    Box Canvas, 0, 0, 1000, 700, RGB(115, 149, 163)
    For i = 0 To 2
        px = -600: py = -600
        If i = 1 Then px = 600
        If i = 2 Then py = 600
        p(i).x = 500 + px * cb + py * sb
        p(i).y = 250 - px * sb + py * cb
    Next
    PlgBlt Canvas, p(0), sceneDC, 0, 0, 480, 480, 0, 0, 0
    TerrainMS = (Clock() - t) * 1000: t = Clock()
    If CameraMode = 2 Then DrawAircraft
    If menu Then
        Box Canvas, 0, 0, 1000, 94, RGB(12, 24, 31)
        DrawText Canvas, 40, 15, "MERIDIAN", 2, RGB(236, 239, 224)
        DrawText Canvas, 290, 35, "THE EXCEL FLIGHT EXPERIMENT  /  KFCI", 0, RGB(119, 207, 198)
    Else
        DrawPanel
        If ShowMap Then DrawMap
        DrawHUD
        If Paused Then
            Box Canvas, 260, 165, 480, 120, RGB(14, 25, 32)
            DrawText Canvas, 300, 180, "FLIGHT PAUSED", 2
            DrawText Canvas, 300, 239, "P resume  |  R reset  |  Esc menu"
        End If
        If Plane.crashed Then
            Box Canvas, 270, 165, 460, 115, RGB(52, 25, 26)
            DrawText Canvas, 300, 180, "FLIGHT ENDED", 2
            DrawText Canvas, 300, 237, "Ground contact exceeded limits. R reset."
        End If
    End If
    PanelMS = (Clock() - t) * 1000
End Sub
Private Sub RenderTerrain()
    Dim x As Long, y As Long, index As Long, c As Long, py As Long, oldY As Long
    Dim z As Double, dz As Double, ex As Double, ny As Double, dx As Double, dn As Double
    Dim ix As Long, iy As Long, tx As Long, ty As Long, h As Double, horizon As Double, projectionScale As Double
    Dim r As Long, g As Long, b As Long, fog As Double, light As Double, skyR As Long, skyG As Long, skyB As Long
    Dim stride As Long, xx As Long, rowColor As Long, u As Double, shade As Double
    skyR = 174: skyG = 196: skyB = 205
    If Weather = 1 Then skyR = 234: skyG = 169: skyB = 126
    If Weather = 4 Then skyR = 18: skyG = 28: skyB = 46
    If Weather = 3 Or Weather = 5 Then skyR = 166: skyG = 178: skyB = 181
    horizon = 240 + camPitch * 300
    For y = 0 To 479
        u = Clamp((horizon - y) / 270, 0, 1)
        r = skyR * (1 - u * 0.58): g = skyG * (1 - u * 0.35): b = skyB * (1 - u * 0.12)
        rowColor = r * 65536 + g * 256 + b
        index = y * 480
        For x = 0 To 479: pixels(index + x) = rowColor: Next
    Next
    'World-anchored clouds, projected into the same yaw/pitch camera.
    If Weather <> 3 And Weather <> 4 Then Clouds horizon
    For x = 0 To 479: ceiling(x) = 480: Next
    stride = 1: If Quality = 0 Then stride = 2
    z = 8
    'All local DEM samples are below 118 m. Skip rays above the entire terrain.
    If camAlt > 125 And horizon < 479 Then z = Clamp((camAlt - 125) * 300 / (480 - horizon), 8, Visibility)
    Do While z < Visibility
        projectionScale = 300 / z
        ex = camE + sh * z - ch * z * 0.8
        ny = camN + ch * z + sh * z * 0.8
        dx = ch * z / 300: dn = -sh * z / 300
        fog = Clamp(z / Visibility, 0, 1): fog = fog * fog
        For x = 0 To 479 Step stride
            ix = Int((ex + HalfWorld) / 20): iy = Int((HalfWorld - ny) / 20)
            If ix >= 0 And ix < 1024 And iy >= 0 And iy < 1024 Then
                index = ix + iy * 1024: h = Heights(index)
                py = horizon - (h - camAlt) * projectionScale
                oldY = ceiling(x)
                If py < oldY Then
                    tx = Int((ex + HalfWorld) / 5): ty = Int((HalfWorld - ny) / 5)
                    c = Colors(tx + ty * 4096)
                    If z > 1500 Then c = ColorLOD1(ix + iy * 1024)
                    If z > 4500 Then c = ColorLOD2((ix \ 4) + (iy \ 4) * 256)
                    shade = TerrainShade(index)
                    light = shade
                    If Weather = 1 Then light = light * 0.75
                    If Weather = 4 Then light = light * 0.13
                    r = Clamp(((c \ 65536) And 255) * light * (1 - fog) + skyR * fog, 0, 255)
                    g = Clamp(((c \ 256) And 255) * light * (1 - fog) + skyG * fog, 0, 255)
                    b = Clamp((c And 255) * light * (1 - fog) + skyB * fog, 0, 255)
                    c = r * 65536 + g * 256 + b
                    If py < 0 Then py = 0
                    For y = py To oldY - 1
                        pixels(x + y * 480) = c
                        If stride = 2 Then pixels(x + 1 + y * 480) = c
                    Next
                    ceiling(x) = py
                End If
            End If
            ex = ex + dx * stride: ny = ny + dn * stride
        Next
        dz = 5 + z * 0.024
        If Quality = 0 Then dz = dz * 1.5
        z = z + dz
    Loop
End Sub
Private Sub Clouds(ByVal horizon As Double)
    Dim i As Long, x As Long, y As Long, cx As Double, cy As Double, rx As Double, ry As Double
    Dim angle As Double, d As Double, alpha As Double, base As Long, rr As Long, gg As Long, bb As Long
    Dim u As Double, v As Double, density As Double, lobe As Double, tint As Double
    Static mask(0 To 2047) As Single, maskReady As Boolean
    Dim mx As Long, my As Long
    If Not maskReady Then
        For my = 0 To 31
            v = -1 + my * 1.5 / 31
            For mx = 0 To 63
                u = -1 + mx * 2 / 63
                density = 1 - u * u - (v / 0.43) ^ 2
                lobe = 1 - ((u + 0.42) / 0.43) ^ 2 - ((v + 0.27) / 0.53) ^ 2
                If lobe > density Then density = lobe
                lobe = 1 - ((u - 0.05) / 0.42) ^ 2 - ((v + 0.38) / 0.62) ^ 2
                If lobe > density Then density = lobe
                lobe = 1 - ((u - 0.48) / 0.38) ^ 2 - ((v + 0.16) / 0.49) ^ 2
                If lobe > density Then density = lobe
                mask(mx + my * 64) = Clamp(density * 5, 0, 0.94)
            Next
        Next
        maskReady = True
    End If
    For i = 0 To 15
        angle = Wrap(i * 2.399 + 0.2 - camYaw + PI) - PI: d = 3800 + (i Mod 5) * 900
        If Abs(angle) < 1.15 Then
            cx = 240 + Tan(angle) * 300: cy = horizon - (1300 - camAlt) * 300 / d
            rx = 28 + (i Mod 4) * 12: ry = 13 + i Mod 5
            For y = CLng(Clamp(cy - ry, 0, 479)) To CLng(Clamp(cy + ry * 0.5, 0, 479))
                v = (y - cy) / ry
                my = Clamp((v + 1) * 31 / 1.5, 0, 31)
                tint = 1 - Clamp((v + 0.2) * 0.18, 0, 0.14)
                For x = CLng(Clamp(cx - rx, 0, 479)) To CLng(Clamp(cx + rx, 0, 479))
                    mx = Clamp(((x - cx) / rx + 1) * 31.5, 0, 63)
                    alpha = mask(mx + my * 64)
                    If alpha > 0 Then
                        base = pixels(x + y * 480)
                        rr = ((base \ 65536) And 255) * (1 - alpha) + 238 * tint * alpha
                        gg = ((base \ 256) And 255) * (1 - alpha) + IIf(Weather = 1, 193, 239) * tint * alpha
                        bb = (base And 255) * (1 - alpha) + IIf(Weather = 1, 161, 231) * tint * alpha
                        pixels(x + y * 480) = rr * 65536 + gg * 256 + bb
                    End If
                Next
            Next
        End If
    Next
End Sub
'Near-plane clip a runway-aligned rectangle before projecting into the unrolled scene.
Private Sub GroundQuad(ByVal along As Double, ByVal lateral As Double, ByVal length As Double, ByVal width As Double, ByVal color As Long)
    Dim ax(0 To 7) As Double, az(0 To 7) As Double, ah(0 To 7) As Double
    Dim bx(0 To 7) As Double, bz(0 To 7) As Double, bh(0 To 7) As Double
    Dim p(0 To 7) As POINTAPI, i As Long, j As Long, n As Long, u As Double
    Dim s As Double, t As Double, east As Double, north As Double, de As Double, dn As Double
    For i = 0 To 3
        s = along - length / 2: t = lateral - width / 2
        If i = 1 Or i = 2 Then s = along + length / 2
        If i >= 2 Then t = lateral + width / 2
        east = Sin(RunwayHeading) * s + Cos(RunwayHeading) * t
        north = Cos(RunwayHeading) * s - Sin(RunwayHeading) * t
        de = east - camE: dn = north - camN
        ax(i) = de * ch - dn * sh: az(i) = de * sh + dn * ch
        ah(i) = RunwayHeight(east, north) + 0.15 - camAlt
    Next
    For i = 0 To 3
        j = (i + 3) Mod 4
        If (az(i) > 3) <> (az(j) > 3) Then
            u = (3 - az(j)) / (az(i) - az(j))
            bx(n) = ax(j) + u * (ax(i) - ax(j)): bz(n) = 3
            bh(n) = ah(j) + u * (ah(i) - ah(j)): n = n + 1
        End If
        If az(i) > 3 Then bx(n) = ax(i): bz(n) = az(i): bh(n) = ah(i): n = n + 1
    Next
    If n < 3 Then Exit Sub
    For i = 0 To n - 1
        p(i).x = Clamp(240 + bx(i) * 300 / bz(i), -16000, 16000)
        p(i).y = Clamp(240 + camPitch * 300 - bh(i) * 300 / bz(i), -16000, 16000)
    Next
    Poly sceneDC, p, n, color
End Sub
Private Sub Airport()
    Dim s As Double, c As Long
    If Sqr(camE * camE + camN * camN) > Visibility Then Exit Sub
    c = RGB(53, 57, 59): If Weather = 4 Then c = RGB(20, 23, 29)
    For s = -808.265 To 808.265 Step 59.87
        GroundQuad s, 0, 59.87, 30.48, c
        GroundQuad s, -14.5, 59.87, 0.5, RGB(220, 222, 204)
        GroundQuad s, 14.5, 59.87, 0.5, RGB(220, 222, 204)
    Next
    For s = -760 To 760 Step 60
        GroundQuad s, 0, 25, 0.8, RGB(226, 227, 216)
        If Weather = 4 Then
            GroundQuad s, -16, 3, 2, RGB(255, 233, 172)
            GroundQuad s, 16, 3, 2, RGB(255, 233, 172)
        End If
    Next
    For s = -10 To 10 Step 4
        GroundQuad -800, s, 20, 1.5, RGB(225, 225, 211)
        GroundQuad 800, s, 20, 1.5, RGB(225, 225, 211)
    Next
End Sub
Public Sub Present()
    Dim r As RECT
    If SimHwnd = 0 Then Exit Sub
    GetClientRect SimHwnd, r
    StretchBlt windowDC, 0, 0, r.Right, r.Bottom, Canvas, 0, 0, 1000, 700, SRCCOPY
End Sub
Private Sub DrawAircraft()
    Dim p(0 To 7) As POINTAPI, i As Long, xx As Double, yy As Double
    Dim coords As Variant
    coords = Array(-5, -38, 8, -12, 110, 15, 112, 28, 9, 16, 7, 61, -8, 61, -10, 16)
    For i = 0 To 7
        xx = coords(i * 2): yy = coords(i * 2 + 1)
        p(i).x = 500 + xx * Cos(Plane.bank) - yy * Sin(Plane.bank)
        p(i).y = 335 + xx * Sin(Plane.bank) + yy * Cos(Plane.bank)
    Next
    Poly Canvas, p, 8, RGB(228, 229, 219)
    For i = 0 To 7: p(i).x = 1000 - p(i).x: Next
    Poly Canvas, p, 8, RGB(207, 214, 209)
    DrawLine Canvas, 490, 352, 510, 352, RGB(175, 51, 35), 5
    Disk Canvas, 500, 328, 8, RGB(46, 74, 89)
End Sub
Private Sub DrawHUD()
    Box Canvas, 0, 0, 1000, 34, RGB(13, 26, 32)
    DrawText Canvas, 16, 8, "MERIDIAN / KFCI", 0, RGB(106, 211, 197)
    DrawText Canvas, 230, 8, Format(Plane.speed * 1.94384, "0") & " KT   " & Format(Plane.altitude * 3.28084, "0") & " FT   " & Format(Wrap(Plane.heading) * 180 / PI, "000") & " TRUE"
    DrawText Canvas, 690, 8, Format(FPS, "0.0") & " FPS  |  " & IIf(Demo, "DEMONSTRATION", "MANUAL FLIGHT")
    Box Canvas, 414, 34, 172, 24, RGB(15, 28, 34)
    DrawText Canvas, 429, 39, "COMPASS " & Format(Wrap(Plane.heading + 10 * PI / 180) * 180 / PI, "000") & " M", 0, RGB(232, 217, 163)
    If Plane.stalled Then DrawText Canvas, 410, 65, "STALL", 2, RGB(255, 127, 66)
    If Plane.speed > 82 Then DrawText Canvas, 390, 65, "OVERSPEED", 2, RGB(255, 127, 66)
    If CameraMode <> 0 And CameraMode <> 4 Then
        Box Canvas, 0, 654, 1000, 46, RGB(13, 26, 32)
        DrawText Canvas, 24, 670, "W/S POWER   ARROWS FLY   F FLAPS   C CAMERA   M MAP   P PAUSE   ESC MENU"
    End If
End Sub
Private Sub Gauge(ByVal x As Long, ByVal y As Long, ByVal title As String, ByVal value As Double, ByVal maxValue As Double, ByVal units As String)
    Dim i As Long, angle As Double, nx As Long, ny As Long
    If buildingPanel Then
    Disk Canvas, x, y, 69, RGB(12, 18, 21)
    Disk Canvas, x, y, 67, RGB(82, 94, 97)
    Disk Canvas, x, y, 65, RGB(35, 44, 48)
    Disk Canvas, x, y, 62, RGB(5, 12, 17)
    For i = 0 To 10
        angle = (-140 + 28 * i) * PI / 180
        DrawLine Canvas, x + Sin(angle) * 53, y - Cos(angle) * 53, x + Sin(angle) * 60, y - Cos(angle) * 60, RGB(188, 203, 204), 2
        If i Mod 2 = 0 And i > 0 And i < 10 Then DrawText Canvas, x + Sin(angle) * 43 - 10, y - Cos(angle) * 43 - 5, IIf(title = "CLIMB FPM", Format((i - 5) * 400, "0"), Format(maxValue * i / 10, "0")), 3
    Next
    If title = "CLIMB FPM" Then DrawText Canvas, x - 3, y - 49, "0", 3
    DrawText Canvas, x - 39, y - 26, title, 3, RGB(130, 168, 176)
    End If
    If buildingPanel Then Exit Sub
    angle = (-140 + 280 * Clamp(value / maxValue, 0, 1)) * PI / 180
    DrawLine Canvas, x, y, x + Sin(angle) * 48, y - Cos(angle) * 48, RGB(241, 230, 185), 3
    Disk Canvas, x, y, 5, RGB(196, 208, 208)
    Box Canvas, x - 35, y + 27, 70, 19, RGB(23, 35, 40)
    DrawText Canvas, x - 29, y + 28, Format(value, "0") & units, 3
End Sub
Private Sub HorizonGauge(ByVal x As Long, ByVal y As Long)
    Dim row As Long, col As Long, yy As Long, xx As Long, span As Long, p(0 To 3) As POINTAPI
    Disk Canvas, x, y, 69, RGB(50, 57, 61)
    'Short scanlines clipped to circular instrument, horizon responds to pitch and bank.
    Dim h As Double, ycut As Double, leftGround As Long, rightGround As Long
    Static attitude(0 To 15128) As Long
    Dim info As BITMAPINFOHEADER, pitchOffset As Double, bankSin As Double, bankCos As Double
    bankSin = Sin(Plane.bank): bankCos = Cos(Plane.bank): pitchOffset = Plane.pitch * 130
    For row = -61 To 61
        For col = -61 To 61
            If row * row + col * col > 4761 Then
                attitude((row + 61) * 123 + col + 61) = &H1C2226
            ElseIf row * row + col * col > 3721 Then
                attitude((row + 61) * 123 + col + 61) = &H32393D
            ElseIf row * bankCos + col * bankSin > pitchOffset Then
                attitude((row + 61) * 123 + col + 61) = &H865732
            Else
                attitude((row + 61) * 123 + col + 61) = &H33799D
            End If
        Next
    Next
    info.biSize = 40: info.biWidth = 123: info.biHeight = -123: info.biPlanes = 1: info.biBitCount = 32
    StretchDIBits Canvas, x - 61, y - 61, 123, 123, 0, 0, 123, 123, attitude(0), info, 0, SRCCOPY
    DrawLine Canvas, x - 40, y, x - 10, y, RGB(255, 209, 83), 3
    DrawLine Canvas, x + 10, y, x + 40, y, RGB(255, 209, 83), 3
    DrawLine Canvas, x - 10, y, x, y + 7, RGB(255, 209, 83), 3
    DrawLine Canvas, x, y + 7, x + 10, y, RGB(255, 209, 83), 3
    DrawText Canvas, x - 29, y + 39, "ATTITUDE", 3
End Sub
Private Sub DrawPanel()
    Dim saved As LongPtr, i As Long, x As Long, a As Double, hdg As Double, agl As Double
    If CameraMode <> 0 And CameraMode <> 4 Then Exit Sub
    If panelDC = 0 Then
        panelDC = CreateCompatibleDC(Canvas): panelBitmap = CreateCompatibleBitmap(Canvas, 1000, 700)
        If panelDC = 0 Or panelBitmap = 0 Then Err.Raise 7, , "Cockpit allocation failed"
        oldPanel = SelectObject(panelDC, panelBitmap)
        saved = Canvas: Canvas = panelDC: buildingPanel = True
        Box Canvas, 0, 390, 1000, 310, RGB(28, 34, 38)
        For i = 400 To 674 Step 4
            DrawLine Canvas, 0, i, 1000, i, RGB(31, 38, 42)
        Next
        Box Canvas, 0, 390, 1000, 9, RGB(8, 13, 17)
        Gauge 85, 470, "AIRSPEED", 0, 160, "KT"
        Gauge 395, 470, "ALTITUDE", 0, 10000, "FT"
        Gauge 395, 610, "CLIMB FPM", 0, 4000, ""
        Disk Canvas, 240, 610, 69, RGB(50, 57, 61)
        Disk Canvas, 240, 610, 64, RGB(5, 12, 17)
        Disk Canvas, 85, 610, 69, RGB(50, 57, 61)
        Disk Canvas, 85, 610, 64, RGB(5, 12, 17)
        DrawText Canvas, 38, 568, "TURN / SLIP", 3
        DrawText Canvas, 38, 640, "L   2 MIN   R", 3
        Gauge 550, 470, "ENGINE", 0, 3000, "RPM"
        Box Canvas, 637, 412, 341, 245, RGB(7, 17, 21)
        DrawText Canvas, 653, 422, "MERIDIAN / FLIGHT COMPUTER", 0, RGB(98, 206, 187)
        DrawLine Canvas, 650, 448, 965, 448, RGB(55, 80, 83)
        DrawText Canvas, 493, 561, "PA-28-161", 0
        DrawText Canvas, 491, 583, "WARRIOR II", 0
        DrawText Canvas, 489, 625, "EXPERIMENTAL", 3, RGB(214, 178, 104)
        For x = 12 To 987 Step 975
            For i = 408 To 660 Step 252
                Disk Canvas, x, i, 4, RGB(109, 120, 121)
                DrawLine Canvas, x - 2, i - 2, x + 2, i + 2, RGB(20, 26, 30)
            Next
        Next
        DrawText Canvas, 24, 684, "ARROWS FLY  W/S POWER  F FLAPS  C VIEW  M MAP  V MUTE  P PAUSE  ESC MENU", 3, RGB(145, 166, 170)
        buildingPanel = False: Canvas = saved
    End If
    StretchBlt Canvas, 0, 390, 1000, 310, panelDC, 0, 390, 1000, 310, SRCCOPY
    Gauge 85, 470, "AIRSPEED", Plane.speed * Exp(-Plane.altitude / 17000) * 1.94384, 160, "KT"
    HorizonGauge 240, 470
    Gauge 395, 470, "ALTITUDE", Plane.altitude * 3.28084, 10000, "FT"
    'Signed VSI: center zero, clockwise climb, counterclockwise descent.
    a = Clamp(Plane.vertical * 196.85 / 2000, -1, 1) * 140 * PI / 180
    DrawLine Canvas, 395, 610, 395 + Sin(a) * 48, 610 - Cos(a) * 48, RGB(241, 230, 185), 3
    Disk Canvas, 395, 610, 5, RGB(196, 208, 208)
    Box Canvas, 360, 637, 70, 19, RGB(23, 35, 40)
    DrawText Canvas, 366, 638, Format(Plane.vertical * 196.85, "+0;-0;0"), 3
    hdg = Wrap(Plane.heading + 10 * PI / 180)
    For i = 0 To 11
        a = i * PI / 6 - hdg
        DrawLine Canvas, 240 + Sin(a) * 53, 610 - Cos(a) * 53, 240 + Sin(a) * 60, 610 - Cos(a) * 60, RGB(188, 203, 204), 2
        DrawText Canvas, 232 + Sin(a) * 43, 604 - Cos(a) * 43, Choose(i + 1, "N", "3", "6", "E", "12", "15", "S", "21", "24", "W", "30", "33"), 3
    Next
    DrawLine Canvas, 240, 596, 240, 623, RGB(241, 230, 185), 2
    DrawLine Canvas, 221, 610, 259, 610, RGB(241, 230, 185), 2
    DrawText Canvas, 215, 638, Format(hdg * 180 / PI, "000") & " M", 3
    a = Clamp(Plane.turnRate * 180 / PI / 3, -2, 2) * 0.3
    DrawLine Canvas, 85 - Cos(a) * 40, 607 - Sin(a) * 40, 85 + Cos(a) * 40, 607 + Sin(a) * 40, RGB(241, 230, 185), 3
    DrawLine Canvas, 85, 598, 85, 617, RGB(241, 230, 185), 2
    DrawLine Canvas, 54, 628, 116, 628, RGB(156, 181, 184), 2
    Disk Canvas, 85 + Clamp(Plane.slip, -1, 1) * 26, 628, 5, RGB(224, 214, 180)
    Gauge 550, 470, "ENGINE", Plane.rpm, 3000, "RPM"
    agl = (Plane.altitude - Ground(Plane.east, Plane.north)) * 3.28084
    DrawText Canvas, 653, 462, "AGL " & Format(agl, "0") & " FT", 1, RGB(115, 215, 184)
    DrawText Canvas, 653, 498, "FUEL " & Format(Plane.fuel / 3.78541, "0.0") & " GAL   POWER " & Format(Plane.throttle, "0%")
    DrawText Canvas, 653, 526, "FLAP " & Choose(Plane.flaps + 1, "0", "10", "25", "40") & "   TRIM " & Format(Plane.trim, "+0.00;-0.00;0.00")
    DrawText Canvas, 653, 554, "OIL " & Format(Plane.oilTemp, "0") & " C / " & Format(Plane.oilPressure, "0") & " PSI"
    DrawText Canvas, 653, 582, "KFCI " & Format(Sqr(Plane.east ^ 2 + Plane.north ^ 2) / 1852, "0.0") & " NM  /  RWY 15-33"
    DrawText Canvas, 653, 619, IIf(Plane.grounded, "ON GROUND", "AIRBORNE") & "   " & IIf(Plane.brake, "BRAKE", ""), 0, RGB(214, 178, 104)
    If CameraMode = 4 Then
        If instrumentDC = 0 Then
            instrumentDC = CreateCompatibleDC(Canvas): instrumentBitmap = CreateCompatibleBitmap(Canvas, 1000, 310)
            If instrumentDC = 0 Or instrumentBitmap = 0 Then Err.Raise 7, , "Instrument view allocation failed"
            oldInstrument = SelectObject(instrumentDC, instrumentBitmap)
        End If
        StretchBlt instrumentDC, 0, 0, 1000, 310, Canvas, 0, 390, 1000, 310, SRCCOPY
        Box Canvas, 0, 200, 1000, 500, RGB(9, 18, 23)
        StretchBlt Canvas, 0, 200, 1000, 310, instrumentDC, 0, 0, 1000, 310, SRCCOPY
        DrawText Canvas, 30, 536, "FLIGHT DATA / INSTRUMENT VIEW", 0, RGB(106, 211, 197)
        DrawText Canvas, 30, 573, Format(Plane.speed * 1.94384, "0") & " KT", 2
        DrawText Canvas, 320, 573, Format(Plane.altitude * 3.28084, "0") & " FT", 2
        DrawText Canvas, 665, 573, Format(Plane.vertical * 196.85, "+0;-0;0") & " FPM", 2
        DrawText Canvas, 30, 629, "TRUE AIRSPEED", 0
        DrawText Canvas, 320, 629, "ALTITUDE MSL", 0
        DrawText Canvas, 665, 629, "VERTICAL SPEED", 0
        DrawText Canvas, 30, 674, "C CHANGE VIEW    M MAP    P PAUSE    ESC MENU", 0, RGB(145, 166, 170)
    End If
End Sub
Private Sub DrawMap()
    Dim x As Long, y As Long, ix As Long, iy As Long, c As Long, px As Long, py As Long
    Static mapPixels(0 To 1599) As Long
    Dim mapInfo As BITMAPINFOHEADER
    Box Canvas, 795, 48, 195, 195, RGB(9, 20, 26)
    For y = 0 To 39
        For x = 0 To 39
            ix = Clamp((Plane.east + (x * 4 - 80) * 40 + HalfWorld) / 20, 0, 1023)
            iy = Clamp((HalfWorld - Plane.north + (y * 4 - 80) * 40) / 20, 0, 1023)
            mapPixels(x + y * 40) = ColorLOD1(ix + iy * 1024)
        Next
    Next
    mapInfo.biSize = 40: mapInfo.biWidth = 40: mapInfo.biHeight = -40
    mapInfo.biPlanes = 1: mapInfo.biBitCount = 32
    StretchDIBits Canvas, 813, 67, 160, 160, 0, 0, 40, 40, mapPixels(0), mapInfo, 0, SRCCOPY
    px = 893 - Plane.east / 40: py = 147 + Plane.north / 40
    If px > 835 And px < 951 And py > 89 And py < 205 Then
        DrawLine Canvas, px - Sin(RunwayHeading) * 21, py + Cos(RunwayHeading) * 21, px + Sin(RunwayHeading) * 21, py - Cos(RunwayHeading) * 21, RGB(255, 210, 75), 2
    End If
    If px > 813 And px < 973 And py > 67 And py < 227 Then Disk Canvas, px, py, 3, RGB(255, 210, 75)
    DrawLine Canvas, 893, 147, 893 + Sin(Plane.heading) * 18, 147 - Cos(Plane.heading) * 18, RGB(255, 245, 222), 3
    Disk Canvas, 893, 147, 3, RGB(255, 80, 50)
    DrawText Canvas, 810, 228, "N UP    6.4 KM", 3
End Sub
