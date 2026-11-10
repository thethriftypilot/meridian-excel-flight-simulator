Attribute VB_Name = "modLandscape"
Option Explicit
Private Declare PtrSafe Function CreateWindowExA Lib "user32" (ByVal ex As Long, ByVal cls As String, ByVal title As String, ByVal style As Long, ByVal x As Long, ByVal y As Long, ByVal w As Long, ByVal h As Long, ByVal parent As LongPtr, ByVal menu As LongPtr, ByVal instance As LongPtr, ByVal param As LongPtr) As LongPtr
Private Declare PtrSafe Function DestroyWindow Lib "user32" (ByVal hwnd As LongPtr) As Long
Private Declare PtrSafe Function SetStretchBltMode Lib "gdi32" (ByVal context As LongPtr, ByVal mode As Long) As Long
Private Declare PtrSafe Function SetBrushOrgEx Lib "gdi32" (ByVal context As LongPtr, ByVal x As Long, ByVal y As Long, ByVal previous As LongPtr) As Long
Private Declare PtrSafe Function ChoosePixelFormat Lib "gdi32" (ByVal dc As LongPtr, ByRef pfd As Any) As Long
Private Declare PtrSafe Function SetPixelFormat Lib "gdi32" (ByVal dc As LongPtr, ByVal fmt As Long, ByRef pfd As Any) As Long
Private Declare PtrSafe Function wglCreateContext Lib "opengl32" (ByVal dc As LongPtr) As LongPtr
Private Declare PtrSafe Function wglDeleteContext Lib "opengl32" (ByVal rc As LongPtr) As Long
Private Declare PtrSafe Function wglMakeCurrent Lib "opengl32" (ByVal dc As LongPtr, ByVal rc As LongPtr) As Long
Private Declare PtrSafe Function wglGetCurrentContext Lib "opengl32" () As LongPtr
Private Declare PtrSafe Function wglGetCurrentDC Lib "opengl32" () As LongPtr
Private Declare PtrSafe Function glGetError Lib "opengl32" () As Long
Private Declare PtrSafe Sub glViewport Lib "opengl32" (ByVal x As Long, ByVal y As Long, ByVal w As Long, ByVal h As Long)
Private Declare PtrSafe Sub glMatrixMode Lib "opengl32" (ByVal mode As Long)
Private Declare PtrSafe Sub glLoadIdentity Lib "opengl32" ()
Private Declare PtrSafe Sub glFrustum Lib "opengl32" (ByVal leftEdge As Double, ByVal rightEdge As Double, ByVal bottom As Double, ByVal top As Double, ByVal nearZ As Double, ByVal farZ As Double)
Private Declare PtrSafe Sub glRotated Lib "opengl32" (ByVal angle As Double, ByVal x As Double, ByVal y As Double, ByVal z As Double)
Private Declare PtrSafe Sub glTranslated Lib "opengl32" (ByVal x As Double, ByVal y As Double, ByVal z As Double)
Private Declare PtrSafe Sub glEnable Lib "opengl32" (ByVal cap As Long)
Private Declare PtrSafe Sub glDisable Lib "opengl32" (ByVal cap As Long)
Private Declare PtrSafe Sub glPushMatrix Lib "opengl32" ()
Private Declare PtrSafe Sub glPopMatrix Lib "opengl32" ()
Private Declare PtrSafe Sub glGetFloatv Lib "opengl32" (ByVal token As Long, ByRef value As Single)
Private Declare PtrSafe Sub glTexParameterf Lib "opengl32" (ByVal target As Long, ByVal key As Long, ByVal value As Single)
Private Declare PtrSafe Sub glClear Lib "opengl32" (ByVal mask As Long)
Private Declare PtrSafe Sub glClearColor Lib "opengl32" (ByVal red As Single, ByVal green As Single, ByVal blue As Single, ByVal alpha As Single)
Private Declare PtrSafe Sub glBegin Lib "opengl32" (ByVal mode As Long)
Private Declare PtrSafe Sub glEnd Lib "opengl32" ()
Private Declare PtrSafe Sub glColor3f Lib "opengl32" (ByVal r As Single, ByVal g As Single, ByVal b As Single)
Private Declare PtrSafe Sub glTexCoord2f Lib "opengl32" (ByVal u As Single, ByVal v As Single)
Private Declare PtrSafe Sub glVertex3f Lib "opengl32" (ByVal x As Single, ByVal y As Single, ByVal z As Single)
Private Declare PtrSafe Sub glBindTexture Lib "opengl32" (ByVal target As Long, ByVal id As Long)
Private Declare PtrSafe Sub glTexParameteri Lib "opengl32" (ByVal target As Long, ByVal key As Long, ByVal value As Long)
Private Declare PtrSafe Sub glTexImage2D Lib "opengl32" (ByVal target As Long, ByVal level As Long, ByVal internalFmt As Long, ByVal width As Long, ByVal height As Long, ByVal border As Long, ByVal fmt As Long, ByVal kind As Long, ByVal data As LongPtr)
Private Declare PtrSafe Sub glInterleavedArrays Lib "opengl32" (ByVal fmt As Long, ByVal stride As Long, ByVal data As LongPtr)
Private Declare PtrSafe Sub glDrawArrays Lib "opengl32" (ByVal mode As Long, ByVal first As Long, ByVal count As Long)
Private Declare PtrSafe Sub glReadPixels Lib "opengl32" (ByVal x As Long, ByVal y As Long, ByVal width As Long, ByVal height As Long, ByVal fmt As Long, ByVal kind As Long, ByVal data As LongPtr)
Private Declare PtrSafe Sub glFogi Lib "opengl32" (ByVal key As Long, ByVal value As Long)
Private Declare PtrSafe Sub glFogf Lib "opengl32" (ByVal key As Long, ByVal value As Single)
Private Declare PtrSafe Sub glFogfv Lib "opengl32" (ByVal key As Long, ByVal data As LongPtr)
Private Declare PtrSafe Sub glDepthFunc Lib "opengl32" (ByVal mode As Long)
Private Declare PtrSafe Sub glAlphaFunc Lib "opengl32" (ByVal mode As Long, ByVal value As Single)
Private Declare PtrSafe Sub glDrawBuffer Lib "opengl32" (ByVal mode As Long)
Private Declare PtrSafe Sub glReadBuffer Lib "opengl32" (ByVal mode As Long)

Private Const Texture2D As Long = &HDE1
Private Const BGRA As Long = &H80E1&
Private Const UnsignedByte As Long = &H1401
Private Const width As Long = 1000
Private Const height As Long = 700
Private renderWidth As Long, renderHeight As Long
Private surface As LongPtr, dc As LongPtr, rc As LongPtr
Private previousDC As LongPtr, previousRC As LongPtr
Private output() As Long, mesh() As Single, grove() As Single
Private counts(0 To 255) As Long, offsets(0 To 255) As Long
Private info As BITMAPINFOHEADER
Private rejected As Boolean
Public LandscapeDrawing As Boolean, LandscapeError As String
Private skyName As String, airframe() As Single, nightAirframe() As Single, aniso As Single

Private Sub LoadFloats(ByVal file As String, ByRef values() As Single)
    Dim channel As Integer, bytes As Long
    bytes = FileLen(file)
    If bytes < 4 Or bytes Mod 4 <> 0 Then Err.Raise 5, , "Invalid landscape geometry"
    ReDim values(0 To bytes \ 4 - 1)
    channel = FreeFile
    Open file For Binary Access Read As #channel
    Get #channel, , values
    Close #channel
End Sub

Private Sub LoadTexture(ByVal id As Long, ByVal w As Long, ByVal h As Long, ByVal ptr As LongPtr, ByVal mip As Boolean)
    glBindTexture Texture2D, id
    glTexParameteri Texture2D, &H2800, &H2601
    glTexParameteri Texture2D, &H2801, &H2601
    If mip Then glTexParameteri Texture2D, &H8191&, 1
    glTexImage2D Texture2D, 0, 4, w, h, 0, BGRA, UnsignedByte, ptr
    If glGetError() <> 0 Then Err.Raise 5, , "OpenGL texture upload failed (" & w & " x " & h & ")"
    If mip Then
        glTexParameteri Texture2D, &H2801, &H2703
        If aniso > 1 Then glTexParameterf Texture2D, &H84FE&, aniso
    End If
End Sub

Private Sub Setup()
    Dim root As String, fmt As Long, pfd(0 To 39) As Byte, channel As Integer, i As Long
    Dim texture() As Long
    previousDC = wglGetCurrentDC(): previousRC = wglGetCurrentContext()
    renderWidth = width: renderHeight = height
    If Quality = 3 Then renderWidth = width * 2: renderHeight = height * 2
    ReDim output(0 To renderWidth * renderHeight - 1)
    surface = CreateWindowExA(0, "STATIC", "Meridian offscreen renderer", &H86000000, 0, 0, renderWidth, renderHeight, 0, 0, 0, 0)
    If surface = 0 Then Err.Raise 5, , "Cannot create OpenGL surface"
    dc = GetDC(surface)
    pfd(0) = 40: pfd(2) = 1: pfd(4) = 37: pfd(9) = 32: pfd(23) = 24
    fmt = ChoosePixelFormat(dc, pfd(0))
    If fmt = 0 Then Err.Raise 5, , "No compatible OpenGL pixel format"
    If SetPixelFormat(dc, fmt, pfd(0)) = 0 Then Err.Raise 5, , "Cannot set OpenGL pixel format"
    rc = wglCreateContext(dc)
    If rc = 0 Then Err.Raise 5, , "Cannot create OpenGL context"
    If wglMakeCurrent(dc, rc) = 0 Then Err.Raise 5, , "Cannot activate OpenGL"
    root = ThisWorkbook.Path & "\Assets\Landscape\"
    LoadFloats root & "mesh.f32", mesh
    LoadFloats root & "groves.f32", grove
    If UBound(mesh) + 1 <> 256& * 2176 * 5 Then Err.Raise 5, , "Invalid terrain grid"
    channel = FreeFile
    Open root & "counts.i32" For Binary Access Read As #channel
    Get #channel, , counts
    Close #channel
    For i = 1 To 255
        offsets(i) = offsets(i - 1) + counts(i - 1)
    Next
    If (offsets(255) + counts(255)) * 5 <> UBound(grove) + 1 Then Err.Raise 5, , "Invalid tree geometry"
    glGetFloatv &H84FF&, aniso
    If glGetError() <> 0 Then aniso = 1
    If aniso > 8 Then aniso = 8
    LoadTexture 1, 4096, 4096, VarPtr(Colors(0)), True
    ReDim texture(0 To 16777215)
    channel = FreeFile
    Open root & "airport.rgba" For Binary Access Read As #channel
    Get #channel, , texture
    Close #channel
    LoadTexture 2, 4096, 4096, VarPtr(texture(0)), True
    ReDim texture(0 To 65535)
    Open root & "trees.rgba" For Binary Access Read As #channel
    Get #channel, , texture
    Close #channel
    LoadTexture 3, 512, 128, VarPtr(texture(0)), True
    ReDim texture(0 To 262143)
    Open root & "asphalt.rgba" For Binary Access Read As #channel
    Get #channel, , texture
    Close #channel
    LoadTexture 5, 512, 512, VarPtr(texture(0)), True
    ReDim texture(0 To 524287)
    Open root & "windshield.rgba" For Binary Access Read As #channel
    Get #channel, , texture
    Close #channel
    LoadTexture 6, 1024, 512, VarPtr(texture(0)), False
    LoadFloats root & "airframe.f32", airframe
    nightAirframe = airframe
    For i = 0 To UBound(nightAirframe) Step 6
        nightAirframe(i) = airframe(i) * 0.22
        nightAirframe(i + 1) = airframe(i + 1) * 0.27
        nightAirframe(i + 2) = airframe(i + 2) * 0.35
    Next
    info.biSize = 40: info.biWidth = renderWidth: info.biHeight = renderHeight: info.biPlanes = 1: info.biBitCount = 32
    glViewport 0, 0, renderWidth, renderHeight
    glDrawBuffer &H405: glReadBuffer &H405
    glDepthFunc &H203
    If glGetError() <> 0 Then Err.Raise 5, , "OpenGL texture or buffer setup failed"
End Sub

Public Sub CloseLandscape()
    LandscapeDrawing = False
    If rc <> 0 Then
        If wglGetCurrentContext() = rc Then wglMakeCurrent previousDC, previousRC
        wglDeleteContext rc: rc = 0
    End If
    If dc <> 0 Then ReleaseDC surface, dc: dc = 0
    If surface <> 0 Then DestroyWindow surface: surface = 0
    Erase output: Erase mesh: Erase grove: Erase airframe: Erase nightAirframe: skyName = "": rejected = False
End Sub

Private Sub Panorama()
    Dim name As String, file As Integer, i As Long, a As Double, e As Double, z As Double
    Dim strip() As Long
    name = Choose(Weather + 1, "day", "dusk", "day", "storm", "night", "storm", "storm")
    If name <> skyName Then
        ReDim strip(0 To 524287)
        file = FreeFile
        Open ThisWorkbook.Path & "\Assets\Graphics\" & name & ".rgb" For Binary Access Read As #file
        Get #file, , strip
        Close #file
        LoadTexture 4, 2048, 256, VarPtr(strip(0)), False
        glTexParameteri Texture2D, &H2803, &H2900
        skyName = name
    End If
    glBindTexture Texture2D, 4
    glColor3f 1, 1, 1
    glBegin 8
    For i = 0 To 96
        a = 2 * PI * i / 96: e = 100 * Sin(a): z = -100 * Cos(a)
        glTexCoord2f i / 96, 0.002: glVertex3f e, -200, z
        glTexCoord2f i / 96, 0.002: glVertex3f e, 0, z
    Next
    glEnd
    glBegin 8
    For i = 0 To 96
        a = 2 * PI * i / 96: e = 100 * Sin(a): z = -100 * Cos(a)
        glTexCoord2f i / 96, 0.002: glVertex3f e, 0, z
        glTexCoord2f i / 96, 0.998: glVertex3f e, 110, z
    Next
    glEnd
    ' Close the sky overhead for steep pitch attitudes.
    glBegin 6
    glTexCoord2f 0.5, 0.998: glVertex3f 0, 145, 0
    For i = 0 To 96
        a = 2 * PI * i / 96
        glTexCoord2f i / 96, 0.998: glVertex3f 100 * Sin(a), 110, -100 * Cos(a)
    Next
    glEnd
End Sub

Public Function StartLandscape(ByVal east As Double, ByVal north As Double, ByVal alt As Double, ByVal yaw As Double, ByVal pitch As Double, ByVal bank As Double) As Boolean
    Dim fog(0 To 3) As Single, i As Long, tx As Long, tz As Long, dx As Double, dz As Double, distance As Double, forward As Double, light As Single
    Dim visible(0 To 255) As Boolean
    If rejected Then Exit Function
    On Error GoTo failed
    If rc <> 0 And renderWidth <> IIf(Quality = 3, width * 2, width) Then CloseLandscape
    previousDC = wglGetCurrentDC(): previousRC = wglGetCurrentContext()
    If rc = 0 Then
        LandscapeError = ""
        Setup
    ElseIf wglMakeCurrent(dc, rc) = 0 Then
        Err.Raise 5, , "Cannot reactivate OpenGL"
    End If
    glClearColor 0.48, 0.58, 0.68, 1
    glClear &H4100
    glMatrixMode &H1701: glLoadIdentity
    glFrustum -500 / 750, 500 / 750, -450 / 750, 250 / 750, 1, 30000
    glMatrixMode &H1700: glLoadIdentity
    glRotated bank * 180 / PI, 0, 0, 1
    glRotated -pitch * 180 / PI, 1, 0, 0
    glRotated yaw * 180 / PI, 0, 1, 0
    glDisable &HB71: glDisable &HB60: glEnable Texture2D
    Panorama
    glTranslated -east, -alt, north
    glEnable &HB71: glEnable &HB60
    fog(0) = 0.68: fog(1) = 0.77: fog(2) = 0.8
    light = 1
    Select Case Weather
        Case 1: fog(0) = 0.91: fog(1) = 0.66: fog(2) = 0.49: light = 0.84
        Case 4: fog(0) = 0.071: fog(1) = 0.11: fog(2) = 0.18: light = 0.19
        Case 3, 5, 6: fog(0) = 0.65: fog(1) = 0.698: fog(2) = 0.71: light = 0.85
    End Select
    glFogi &HB65, &H2601: glFogf &HB63, Visibility * 0.18: glFogf &HB64, Visibility
    glFogfv &HB66, VarPtr(fog(0)): glColor3f light, light, light
    glInterleavedArrays &H2A27, 0, VarPtr(mesh(0))
    For i = 0 To 255
        tx = i Mod 16: tz = i \ 16
        dx = tx * 1280 - 9600 - east: dz = tz * 1280 - 9600 + north
        distance = Sqr(dx * dx + dz * dz): forward = dx * Sin(yaw) - dz * Cos(yaw)
        If distance < Visibility + 1200 And forward > -1200 Then
            If tx >= 6 And tx < 10 And tz >= 6 And tz < 10 Then glBindTexture Texture2D, 2 Else glBindTexture Texture2D, 1
            glDrawArrays 5, i * 2176, 2176
            visible(i) = distance < 3200
        End If
    Next
    glBindTexture Texture2D, 3
    glInterleavedArrays &H2A27, 0, VarPtr(grove(0))
    glEnable &HBC0: glAlphaFunc &H204, 0.34
    For i = 0 To 255
        If visible(i) And counts(i) > 0 Then glDrawArrays 7, offsets(i), counts(i)
    Next
    glDisable &HBC0: glDisable Texture2D
    LandscapeDrawing = True: StartLandscape = True
    Exit Function
failed:
    LandscapeError = Err.Description
    Call CloseLandscape: rejected = True
End Function

Public Sub LandscapeFace(ByRef e() As Double, ByRef n() As Double, ByRef h() As Double, ByVal shade As Long)
    Dim i As Long
    glColor3f (shade And 255) / 255, ((shade \ 256) And 255) / 255, ((shade \ 65536) And 255) / 255
    glBegin 7
    For i = 0 To 3
        glVertex3f e(i), h(i), -n(i)
    Next
    glEnd
End Sub

Private Sub Windshield()
    Dim lit As Single
    lit = 1
    If Weather = 4 Then lit = 0.27
    If Weather = 1 Then lit = 0.83
    glMatrixMode &H1701: glLoadIdentity
    glMatrixMode &H1700: glLoadIdentity
    glDisable &HB71: glDisable &HB60
    glEnable Texture2D: glBindTexture Texture2D, 6
    glEnable &HBC0: glAlphaFunc &H204, 0.5
    glColor3f lit, lit, lit
    glBegin 7
    glTexCoord2f 0, 0: glVertex3f -1, -1 / 7, 0
    glTexCoord2f 1, 0: glVertex3f 1, -1 / 7, 0
    glTexCoord2f 1, 1: glVertex3f 1, 1, 0
    glTexCoord2f 0, 1: glVertex3f -1, 1, 0
    glEnd
    glDisable &HBC0: glDisable Texture2D
End Sub

Public Sub FinishLandscape()
    Dim oldMode As Long
    If CameraMode = 0 Then Windshield
    glReadPixels 0, 0, renderWidth, renderHeight, BGRA, UnsignedByte, VarPtr(output(0))
    If renderWidth > width Then
        oldMode = SetStretchBltMode(Canvas, 4)
        SetBrushOrgEx Canvas, 0, 0, 0
    End If
    StretchDIBits Canvas, 0, 0, width, height, 0, 0, renderWidth, renderHeight, output(0), info, 0, SRCCOPY
    If oldMode <> 0 Then SetStretchBltMode Canvas, oldMode
    wglMakeCurrent previousDC, previousRC
    LandscapeDrawing = False
End Sub


Public Sub DrawDetailedAircraft()
    glPushMatrix
    glTranslated Plane.east, Plane.altitude, -Plane.north
    glRotated -Plane.heading * 180 / PI, 0, 1, 0
    glRotated Plane.pitch * 180 / PI, 1, 0, 0
    glRotated -Plane.bank * 180 / PI, 0, 0, 1
    If Weather = 4 Then
        glInterleavedArrays &H2A24, 0, VarPtr(nightAirframe(0))
    Else
        glInterleavedArrays &H2A24, 0, VarPtr(airframe(0))
    End If
    glDrawArrays 4, 0, (UBound(airframe) + 1) \ 6
    glPopMatrix
End Sub

Public Sub LandscapePavement(ByRef e() As Double, ByRef n() As Double, ByRef h() As Double, ByRef s() As Double, ByRef lateral() As Double)
    Dim i As Long, light As Single
    light = 1
    If Weather = 1 Then light = 0.84
    If Weather = 4 Then light = 0.24
    glColor3f light, light, light
    glEnable Texture2D: glBindTexture Texture2D, 5
    glBegin 7
    For i = 0 To 3
        glTexCoord2f lateral(i) / 30.48 + 0.5, s(i) / 40
        glVertex3f e(i), h(i), -n(i)
    Next
    glEnd
    glDisable Texture2D
End Sub
