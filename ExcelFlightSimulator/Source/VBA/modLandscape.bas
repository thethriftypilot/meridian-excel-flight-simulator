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
Private Declare PtrSafe Sub glLightModelfv Lib "opengl32" (ByVal key As Long, ByVal values As LongPtr)
Private Declare PtrSafe Sub glColorMaterial Lib "opengl32" (ByVal face As Long, ByVal mode As Long)
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

Private Declare PtrSafe Sub glMultMatrixf Lib "opengl32" (ByVal matrix As LongPtr)
Private Declare PtrSafe Sub glBlendFunc Lib "opengl32" (ByVal source As Long, ByVal destination As Long)
Private Declare PtrSafe Sub glColor4f Lib "opengl32" (ByVal red As Single, ByVal green As Single, ByVal blue As Single, ByVal alpha As Single)
Private Declare PtrSafe Sub glStencilFunc Lib "opengl32" (ByVal comparison As Long, ByVal reference As Long, ByVal mask As Long)
Private Declare PtrSafe Sub glStencilOp Lib "opengl32" (ByVal stencilFail As Long, ByVal depthFail As Long, ByVal depthPass As Long)
Private Declare PtrSafe Sub glDepthMask Lib "opengl32" (ByVal enabled As Byte)

Private Declare PtrSafe Function SwapBuffers Lib "gdi32" (ByVal hdc As LongPtr) As Long
Private Declare PtrSafe Function GdiFlush Lib "gdi32" () As Long
Private Declare PtrSafe Sub glTexSubImage2D Lib "opengl32" (ByVal target As Long, ByVal level As Long, ByVal x As Long, ByVal y As Long, ByVal w As Long, ByVal h As Long, ByVal fmt As Long, ByVal kind As Long, ByVal data As LongPtr)
Private Declare PtrSafe Sub glOrtho Lib "opengl32" (ByVal l As Double, ByVal r As Double, ByVal b As Double, ByVal t As Double, ByVal nearZ As Double, ByVal farZ As Double)
Private Declare PtrSafe Sub glFinish Lib "opengl32" ()
Private Declare PtrSafe Sub glNewList Lib "opengl32" (ByVal id As Long, ByVal mode As Long)
Private Declare PtrSafe Sub glEndList Lib "opengl32" ()
Private Declare PtrSafe Sub glCallList Lib "opengl32" (ByVal id As Long)
Public DirectGPU As Boolean, CacheGeometry As Boolean
Public GPUReadbackMS As Double, GPUSubmitMS As Double, GPUPresentMS As Double, GPUOverlayMS As Double
Public GPUWidth As Long, GPUHeight As Long
Private swapped As Boolean, cached As Boolean
Private airportLists(0 To 55) As Boolean

Private Declare PtrSafe Function glGetString Lib "opengl32" (ByVal token As Long) As LongPtr
Private Declare PtrSafe Function lstrlenA Lib "kernel32" (ByVal value As LongPtr) As Long
Private Declare PtrSafe Sub CopyGLString Lib "kernel32" Alias "RtlMoveMemory" (ByRef dest As Any, ByVal source As LongPtr, ByVal count As LongPtr)
Public GPUDescription As String
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
Private regionMesh() As Single, ricMesh() As Single, ofpMesh() As Single
Private ricTrees() As Single, ofpTrees() As Single
Private buildings() As Single, buildingCounts(0 To 255) As Long, buildingOffsets(0 To 255) As Long
Private hasBuildings As Boolean
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
    DirectGPU = (Quality = 4)
    If DirectGPU Then
        surface = CreateGPUWindow(SimHwnd, renderWidth, renderHeight)
    Else
        surface = CreateGPUWindow(0, renderWidth, renderHeight)
    End If
    If surface = 0 Then Err.Raise 5, , "Cannot create OpenGL surface"
    dc = GetDC(surface)
    pfd(0) = 40: pfd(2) = 1: pfd(4) = 37: pfd(9) = 32: pfd(23) = 24: pfd(24) = 8
    fmt = ChoosePixelFormat(dc, pfd(0))
    If fmt = 0 Then Err.Raise 5, , "No compatible OpenGL pixel format"
    If SetPixelFormat(dc, fmt, pfd(0)) = 0 Then Err.Raise 5, , "Cannot set OpenGL pixel format"
    ValidateGPUFormat dc, fmt
    rc = wglCreateContext(dc)
    If rc = 0 Then Err.Raise 5, , "Cannot create OpenGL context"
    If wglMakeCurrent(dc, rc) = 0 Then Err.Raise 5, , "Cannot activate OpenGL"
    GPUDescription = GLString(&H1F00) & " | " & GLString(&H1F01) & " | OpenGL " & GLString(&H1F02)
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
    ReDim texture(0 To FileLen(root & "trees.rgba") \ 4 - 1)
    Open root & "trees.rgba" For Binary Access Read As #channel
    Get #channel, , texture
    Close #channel
    If UBound(texture) = 1048575 Then
        LoadTexture 3, 2048, 512, VarPtr(texture(0)), True
    Else
        LoadTexture 3, 512, 128, VarPtr(texture(0)), True
    End If
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
    hasBuildings = (Dir(root & "buildings.f32") <> "")
    If hasBuildings Then
        LoadFloats root & "buildings.f32", buildings
        If FileLen(root & "buildings-counts.i32") <> 1024 Then Err.Raise 5, , "Invalid building index"
        Open root & "buildings-counts.i32" For Binary Access Read As #channel
        Get #channel, , buildingCounts
        Close #channel
        For i = 0 To 255
            If buildingCounts(i) < 0 Or buildingCounts(i) Mod 3 <> 0 Then Err.Raise 5, , "Invalid building tile"
            If i > 0 Then buildingOffsets(i) = buildingOffsets(i - 1) + buildingCounts(i - 1)
        Next
        If (buildingOffsets(255) + buildingCounts(255)) * 6 <> UBound(buildings) + 1 Then Err.Raise 5, , "Invalid building geometry"
    End If
    nightAirframe = airframe
    For i = 0 To UBound(nightAirframe) Step 6
        nightAirframe(i) = airframe(i) * 0.22
        nightAirframe(i + 1) = airframe(i + 1) * 0.27
        nightAirframe(i + 2) = airframe(i + 2) * 0.35
    Next
    LoadFloats ThisWorkbook.Path & "\Assets\Region\mesh.f32", regionMesh
    LoadFloats ThisWorkbook.Path & "\Assets\Region\1-mesh.f32", ricMesh
    LoadFloats ThisWorkbook.Path & "\Assets\Region\2-mesh.f32", ofpMesh
    LoadFloats ThisWorkbook.Path & "\Assets\Region\1-trees.f32", ricTrees
    LoadFloats ThisWorkbook.Path & "\Assets\Region\2-trees.f32", ofpTrees
    LoadRegionTexture 7, "photo.rgba", 4096
    LoadRegionTexture 8, "1-photo.rgba", 2048
    LoadRegionTexture 9, "2-photo.rgba", 2048
    info.biSize = 40: info.biWidth = renderWidth: info.biHeight = renderHeight: info.biPlanes = 1: info.biBitCount = 32
    glViewport 0, 0, renderWidth, renderHeight
    glDrawBuffer &H405: glReadBuffer &H405
    glDepthFunc &H203
    LoadTexture 10, 1000, 700, 0, False
    GPUWidth = renderWidth: GPUHeight = renderHeight
    If CacheGeometry Then BuildSceneLists
    If glGetError() <> 0 Then Err.Raise 5, , "OpenGL texture or buffer setup failed"
End Sub

Public Sub CloseLandscape()
    LandscapeDrawing = False
    If rc <> 0 Then
        If wglGetCurrentContext() = rc Then wglMakeCurrent previousDC, previousRC
        wglDeleteContext rc: rc = 0
    End If
    If dc <> 0 Then ReleaseDC surface, dc: dc = 0
    If surface <> 0 Then ReleaseGPUWindow surface: surface = 0
    DirectGPU = False: cached = False: swapped = False
    Erase airportLists
    Erase buildings: Erase buildingCounts: Erase buildingOffsets: hasBuildings = False
    Erase regionMesh: Erase ricMesh: Erase ofpMesh: Erase ricTrees: Erase ofpTrees
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
    If rc <> 0 Then
        If DirectGPU <> (Quality = 4) Or cached <> CacheGeometry Then CloseLandscape
        If Not DirectGPU And renderWidth <> IIf(Quality = 3, width * 2, width) Then CloseLandscape
    End If
    previousDC = wglGetCurrentDC(): previousRC = wglGetCurrentContext()
    If rc = 0 Then
        LandscapeError = ""
        Setup
    ElseIf wglMakeCurrent(dc, rc) = 0 Then
        Err.Raise 5, , "Cannot reactivate OpenGL"
    End If
    swapped = False
    If DirectGPU Then FitGPUWindow
    glClearColor 0.48, 0.58, 0.68, 1
    glClear &H4500
    glMatrixMode &H1701: glLoadIdentity
    glFrustum -500 / (750 * ViewZoom), 500 / (750 * ViewZoom), -450 / (750 * ViewZoom), 250 / (750 * ViewZoom), 1, 30000
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
    glBindTexture Texture2D, 7
    glInterleavedArrays &H2A27, 0, VarPtr(regionMesh(0))
    If cached Then glCallList 1 Else glDrawArrays 4, 0, (UBound(regionMesh) + 1) \ 5
    DrawRegionPatch east, north, 1, ricMesh, ricTrees, 8
    DrawRegionPatch east, north, 2, ofpMesh, ofpTrees, 9
    glInterleavedArrays &H2A27, 0, VarPtr(mesh(0))
    For i = 0 To 255
        tx = i Mod 16: tz = i \ 16
        dx = tx * 1280 - 9600 - east: dz = tz * 1280 - 9600 + north
        distance = Sqr(dx * dx + dz * dz): forward = dx * Sin(yaw) - dz * Cos(yaw)
        If distance < Visibility + 1200 And forward > -1200 Then
            If tx >= 6 And tx < 10 And tz >= 6 And tz < 10 Then glBindTexture Texture2D, 2 Else glBindTexture Texture2D, 1
            If cached Then glCallList 100 + i Else glDrawArrays 5, i * 2176, 2176
            visible(i) = distance < 3200
        End If
    Next
    glBindTexture Texture2D, 3
    glInterleavedArrays &H2A27, 0, VarPtr(grove(0))
    glEnable &HBC0: glAlphaFunc &H204, 0.34
    For i = 0 To 255
        If visible(i) And counts(i) > 0 Then
            If cached Then glCallList 400 + i Else glDrawArrays 7, offsets(i), counts(i)
        End If
    Next
    glDisable &HBC0: glDisable Texture2D
    DrawBuildings east, north, yaw, light
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
    Dim oldMode As Long, started As Double
    If CameraMode = 0 And Not (DirectGPU And CleanView) Then Windshield
    LandscapeDrawing = False
    GPUReadbackMS = 0
    If DirectGPU Then Exit Sub
    started = Clock()
    glReadPixels 0, 0, renderWidth, renderHeight, BGRA, UnsignedByte, VarPtr(output(0))
    GPUReadbackMS = (Clock() - started) * 1000
    If glGetError() <> 0 Then Err.Raise 5, , "Graphics driver reported a rendering error"
    If renderWidth > width Then
        oldMode = SetStretchBltMode(Canvas, 4)
        SetBrushOrgEx Canvas, 0, 0, 0
    End If
    StretchDIBits Canvas, 0, 0, width, height, 0, 0, renderWidth, renderHeight, output(0), info, 0, SRCCOPY
    If oldMode <> 0 Then SetStretchBltMode Canvas, oldMode
    wglMakeCurrent previousDC, previousRC
    LandscapeDrawing = False
End Sub


Private Sub AircraftTransform()
    glTranslated Plane.east, Plane.altitude, -Plane.north
    glRotated -Plane.heading * 180 / PI, 0, 1, 0
    glRotated Plane.pitch * 180 / PI, 1, 0, 0
    glRotated -Plane.bank * 180 / PI, 0, 0, 1
End Sub

Public Sub DrawDetailedAircraft()
    glPushMatrix
    AircraftTransform
    If Weather = 4 Then
        glInterleavedArrays &H2A24, 0, VarPtr(nightAirframe(0))
    Else
        glInterleavedArrays &H2A24, 0, VarPtr(airframe(0))
    End If
    glDrawArrays 4, 0, (UBound(airframe) + 1) \ 6
    DrawPropeller
    glPopMatrix
End Sub

Private Sub DrawPropeller()
    Dim i As Long, angle As Double, alpha As Single
    glPushMatrix
    glTranslated 0, 0.12, -3.02
    If Plane.rpm > 400 Then
        glEnable &HBE2: glBlendFunc &H302, &H303
        glDepthMask 0
        glColor4f 0.65, 0.66, 0.62, 0.13
        glBegin 6
        glVertex3f 0, 0, 0
        For i = 0 To 48
            angle = i * 2 * PI / 48
            glVertex3f Cos(angle) * 0.91, Sin(angle) * 0.91, 0
        Next
        glEnd
        glDepthMask 1: glDisable &HBE2
    Else
        glRotated Plane.elapsed * Plane.rpm * 6, 0, 0, 1
        glColor3f 0.13, 0.14, 0.14
        glBegin 7
        glVertex3f -0.07, -0.91, 0: glVertex3f 0.07, -0.91, 0
        glVertex3f 0.07, 0.91, 0: glVertex3f -0.07, 0.91, 0
        glEnd
    End If
    glPopMatrix
End Sub

Public Sub DrawAircraftShadow()
    Dim matrix(0 To 15) As Single, altitude As Double, floor As Double, sx As Double, sz As Double
    If Weather <> 0 And Weather <> 1 And Weather <> 2 Then Exit Sub
    altitude = Plane.altitude - Ground(Plane.east, Plane.north)
    If altitude > 180 Then Exit Sub
    sx = -0.707: sz = -0.707
    If Weather = 1 Then sx = -4: sz = 0
    floor = Ground(Plane.east - sx * altitude, Plane.north + sz * altitude) + 0.46
    matrix(0) = 1: matrix(4) = -sx: matrix(6) = -sz: matrix(10) = 1
    matrix(12) = sx * floor: matrix(13) = floor: matrix(14) = sz * floor: matrix(15) = 1
    glEnable &HBE2: glBlendFunc &H302, &H303: glDepthMask 0
    glColor4f 0.02, 0.04, 0.04, 0.25 * Clamp(1 - altitude / 180, 0, 1)
    glPushMatrix
    glMultMatrixf VarPtr(matrix(0))
    AircraftTransform
    glEnable &HB90
    glStencilFunc &H202, 0, 1
    glStencilOp &H1E00, &H1E00, &H1E02
    glInterleavedArrays &H2A21, 24, VarPtr(airframe(3))
    glDrawArrays 4, 0, (UBound(airframe) + 1) \ 6
    glDisable &HB90
    glPopMatrix
    glDepthMask 1: glDisable &HBE2
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

Private Sub LoadRegionTexture(ByVal textureID As Long, ByVal name As String, ByVal size As Long)
    Dim texture() As Long, file As Integer, path As String
    path = ThisWorkbook.Path & "\Assets\Region\" & name
    If FileLen(path) <> size * size * 4 Then Err.Raise 5, , "Invalid regional texture"
    ReDim texture(0 To size * size - 1)
    file = FreeFile
    Open path For Binary Access Read As #file
    Get #file, , texture
    Close #file
    LoadTexture textureID, size, size, VarPtr(texture(0)), True
End Sub

Private Sub DrawRegionPatch(ByVal east As Double, ByVal north As Double, ByVal airport As Long, ByRef terrain() As Single, ByRef trees() As Single, ByVal textureID As Long)
    Dim distance As Double, index As Long
    index = PrimaryRunway(airport)
    distance = Sqr((east - Runways(index).East) ^ 2 + (north - Runways(index).North) ^ 2)
    If distance > Visibility + 3800 Then Exit Sub
    glBindTexture Texture2D, textureID
    glInterleavedArrays &H2A27, 0, VarPtr(terrain(0))
    If cached Then glCallList 1 + airport Else glDrawArrays 4, 0, (UBound(terrain) + 1) \ 5
    If distance < 6000 Then
        glBindTexture Texture2D, 3
        glInterleavedArrays &H2A27, 0, VarPtr(trees(0))
        glEnable &HBC0: glAlphaFunc &H204, 0.34
        If cached Then glCallList 3 + airport Else glDrawArrays 7, 0, (UBound(trees) + 1) \ 5
        glDisable &HBC0
    End If
End Sub

Private Sub BuildSceneLists()
    Dim i As Long
    glInterleavedArrays &H2A27, 0, VarPtr(regionMesh(0))
    glNewList 1, &H1300
    glDrawArrays 4, 0, (UBound(regionMesh) + 1) \ 5
    glEndList
    glInterleavedArrays &H2A27, 0, VarPtr(mesh(0))
    For i = 0 To 255
        glNewList 100 + i, &H1300
        glDrawArrays 5, i * 2176, 2176
        glEndList
    Next
    glInterleavedArrays &H2A27, 0, VarPtr(grove(0))
    For i = 0 To 255
        glNewList 400 + i, &H1300
        If counts(i) > 0 Then glDrawArrays 7, offsets(i), counts(i)
        glEndList
    Next
    If hasBuildings Then
        glInterleavedArrays &H2A24, 0, VarPtr(buildings(0))
        For i = 0 To 255
            glNewList 700 + i, &H1300
            If buildingCounts(i) > 0 Then glDrawArrays 4, buildingOffsets(i), buildingCounts(i)
            glEndList
        Next
    End If
    CacheArray 2, ricMesh, 4
    CacheArray 3, ofpMesh, 4
    CacheArray 4, ricTrees, 7
    CacheArray 5, ofpTrees, 7
    If glGetError() <> 0 Then Err.Raise 5, , "Static scene caching failed"
    cached = True
End Sub
Private Sub FitGPUWindow()
    Dim r As RECT, factor As Double, w As Long, h As Long
    GetClientRect SimHwnd, r
    factor = r.Right / 1000
    If r.Bottom / 700 < factor Then factor = r.Bottom / 700
    w = CLng(1000 * factor): h = CLng(700 * factor)
    If w < 1 Or h < 1 Then Exit Sub
    If w <> renderWidth Or h <> renderHeight Then
        ResizeGPUWindow surface, (r.Right - w) \ 2, (r.Bottom - h) \ 2, w, h
        renderWidth = w: renderHeight = h
        GPUWidth = w: GPUHeight = h
        glViewport 0, 0, w, h
    End If
End Sub
Private Sub OverlayRect(ByVal x As Double, ByVal y As Double, ByVal w As Double, ByVal h As Double)
    glBegin 7
    glTexCoord2f x / 1000, y / 700: glVertex3f x, y, 0
    glTexCoord2f (x + w) / 1000, y / 700: glVertex3f x + w, y, 0
    glTexCoord2f (x + w) / 1000, (y + h) / 700: glVertex3f x + w, y + h, 0
    glTexCoord2f x / 1000, (y + h) / 700: glVertex3f x, y + h, 0
    glEnd
End Sub
Public Sub CompositeGPU(ByVal menu As Boolean)
    Dim started As Double, i As Long, x As Long, y As Long
    If Not DirectGPU Then Exit Sub
    started = Clock()
    GdiFlush
    glDisable &HB71: glDisable &HB60: glDisable &HBC0
    glMatrixMode &H1701: glLoadIdentity: glOrtho 0, 1000, 700, 0, -1, 1
    glMatrixMode &H1700: glLoadIdentity
    If Weather = 6 Then
        glColor3f 0.65, 0.73, 0.78
        glBegin 1
        For i = 0 To 89
            x = (i * 137 + CLng(Plane.elapsed * WindEast * 8)) Mod 1000
            y = (i * 83 + CLng(Plane.elapsed * 350)) Mod 700
            glVertex3f x, y, 0: glVertex3f x - 5, y + 15, 0
        Next
        glEnd
    End If
    glEnable Texture2D: glBindTexture Texture2D, 10
    glTexSubImage2D Texture2D, 0, 0, 0, 1000, 700, BGRA, UnsignedByte, CanvasBits
    If CameraMode = 0 And CleanView And Not menu Then
        DrawImmersiveCockpit 10, ViewZoom
        glEnable Texture2D: glBindTexture Texture2D, 10
    End If
    glColor3f 1, 1, 1
    If menu Then
        OverlayRect 0, 0, 1000, 94
    Else
        If Not CleanView Or ReplayActive Then OverlayRect 0, 0, 1000, 34
        If Not CleanView Then OverlayRect 414, 34, 172, 24
        If CameraMode = 0 And Not CleanView Then OverlayRect 0, 390, 1000, 310
        If CameraMode = 4 Then OverlayRect 0, 200, 1000, 500
        If Not CleanView And CameraMode <> 0 And CameraMode <> 4 Then OverlayRect 0, 654, 1000, 46
        If ShowMap Then OverlayRect 795, 48, 195, 195
        If Not ReplayActive And (Scenario >= 8 Or ShowMap) Then OverlayRect 16, 65, 730, 47
        If ChallengeActive And Recording And Not ReplayActive Then OverlayRect 12, 88, 730, 45
        If ReplayActive Then OverlayRect 0, 674, 1000, 26
        If Paused Then OverlayRect 260, 165, 480, 120
        If Plane.crashed Then OverlayRect 270, 165, 460, 115
        If Plane.stalled Or Plane.speed > 82 Then OverlayRect 380, 60, 300, 60
        If Not Plane.engineRunning Then OverlayRect 20, 60, 300, 30
        If Abs(Plane.east) > 38000 Or Abs(Plane.north) > 38000 Then OverlayRect 20, 134, 730, 30
    End If
    glDisable Texture2D
    If glGetError() <> 0 Then Err.Raise 5, , "GPU overlay failed"
    GPUOverlayMS = (Clock() - started) * 1000
    wglMakeCurrent previousDC, previousRC
End Sub
Public Sub PresentGPU()
    Dim started As Double
    If Not DirectGPU Then Exit Sub
    started = Clock()
    If SwapBuffers(dc) = 0 Then Err.Raise 5, , "GPU presentation failed"
    GPUPresentMS = (Clock() - started) * 1000
    swapped = True
End Sub
Public Sub CaptureGPU()
    Dim savedDC As LongPtr, savedRC As LongPtr, captureInfo As BITMAPINFOHEADER
    If Not DirectGPU Then Exit Sub
    savedDC = wglGetCurrentDC(): savedRC = wglGetCurrentContext()
    If wglMakeCurrent(dc, rc) = 0 Then Err.Raise 5, , "Cannot activate GPU capture"
    If swapped Then glReadBuffer &H404 Else glReadBuffer &H405
    ReDim output(0 To renderWidth * renderHeight - 1)
    glReadPixels 0, 0, renderWidth, renderHeight, BGRA, UnsignedByte, VarPtr(output(0))
    captureInfo.biSize = 40: captureInfo.biWidth = renderWidth: captureInfo.biHeight = renderHeight
    captureInfo.biPlanes = 1: captureInfo.biBitCount = 32
    StretchDIBits Canvas, 0, 0, 1000, 700, 0, 0, renderWidth, renderHeight, output(0), captureInfo, 0, SRCCOPY
    glReadBuffer &H405
    wglMakeCurrent savedDC, savedRC
End Sub
Public Sub CompleteGPUWork()
    Dim savedDC As LongPtr, savedRC As LongPtr
    If rc = 0 Then Exit Sub
    savedDC = wglGetCurrentDC(): savedRC = wglGetCurrentContext()
    If wglMakeCurrent(dc, rc) = 0 Then Err.Raise 5, , "Cannot synchronize benchmark"
    glFinish
    wglMakeCurrent savedDC, savedRC
End Sub

Private Function GLString(ByVal token As Long) As String
    Dim address As LongPtr, length As Long, bytes() As Byte
    address = glGetString(token)
    If address = 0 Then Exit Function
    length = lstrlenA(address)
    If length < 1 Or length > 16384 Then Exit Function
    ReDim bytes(0 To length - 1)
    CopyGLString bytes(0), address, length
    GLString = StrConv(bytes, vbUnicode)
End Function

Private Sub CacheArray(ByVal list As Long, ByRef data() As Single, ByVal primitive As Long)
    glInterleavedArrays &H2A27, 0, VarPtr(data(0))
    glNewList list, &H1300
    glDrawArrays primitive, 0, (UBound(data) + 1) \ 5
    glEndList
End Sub

Public Sub DrawCachedRegionalAirports()
    Dim mask As Long, runway As Long, key As Long
    For runway = 1 To RunwayCount - 1
        If Sqr((Plane.east - Runways(runway).East) ^ 2 + (Plane.north - Runways(runway).North) ^ 2) < Visibility + 1800 Then mask = mask + 2 ^ (runway - 1)
    Next
    If mask = 0 Then Exit Sub
    key = Weather * 8 + mask
    If Not airportLists(key) Then
        glNewList 1000 + key, &H1300
        DrawRegionalAirports
        glEndList
        If glGetError() <> 0 Then Err.Raise 5, , "Airport geometry cache failed"
        airportLists(key) = True
    End If
    glCallList 1000 + key
End Sub

Private Sub DrawBuildings(ByVal east As Double, ByVal north As Double, ByVal yaw As Double, ByVal light As Single)
    Dim i As Long, dx As Double, dz As Double, ambient(0 To 3) As Single
    If Not hasBuildings Then Exit Sub
    ambient(0) = light: ambient(1) = light: ambient(2) = light: ambient(3) = 1
    glLightModelfv &HB53, VarPtr(ambient(0))
    glColorMaterial &H408, &H1602
    glEnable &HB57: glEnable &HB50
    glInterleavedArrays &H2A24, 0, VarPtr(buildings(0))
    For i = 0 To 255
        dx = (i Mod 16) * 1280 - 9600 - east
        dz = (i \ 16) * 1280 - 9600 + north
        If dx * dx + dz * dz < 4500# * 4500 And dx * Sin(yaw) - dz * Cos(yaw) > -1200 Then
            If buildingCounts(i) > 0 Then
                If cached Then glCallList 700 + i Else glDrawArrays 4, buildingOffsets(i), buildingCounts(i)
            End If
        End If
    Next
    glDisable &HB50: glDisable &HB57
End Sub
