Attribute VB_Name = "modShowcase"
Option Explicit
'Identical positions and camera state for baseline and candidate captures.
Public Sub ShowcaseState(ByVal scene As Long)
    ResetFlight 1: SetWeather 0: ShowMap = False: Demo = False: Paused = False
    Plane.elapsed = 120: Plane.rpm = 2100
    Select Case scene
        Case 0: ResetFlight 0: Plane.rpm = 700
        Case 1
            ResetFlight 2
            Plane.east = RunwayEast(-1550): Plane.north = RunwayNorth(-1550)
            Plane.altitude = Ground(Plane.east, Plane.north) + 65
        Case 2
            Plane.east = -1600: Plane.north = -1100: Plane.altitude = Ground(-1600, -1100) + 100
            Plane.heading = 0.6: CameraMode = 1
        Case 3: CameraMode = 2: Plane.bank = 0.18
        Case 4: CameraMode = 2: Plane.bank = 0.18: SetWeather 1
        Case 5: ResetFlight 2: SetWeather 4
        Case 6: ResetFlight 14
        Case 7: ResetFlight 6: CameraMode = 2
    End Select
End Sub
Public Function CaptureShowcase(Optional ByVal label As String = "baseline", Optional ByVal preset As Long = 2, Optional ByVal useCache As Boolean = False, Optional ByVal immersive As Boolean = False, Optional ByVal viewportWidth As Long = 1000) As String
    Dim scene As Long, i As Long, f As Integer, started As Double, duration As Double, folder As String
    Dim r As RECT, times(1 To 90) As Double, frameStart As Double, j As Long, swap As Double
    On Error GoTo failed
    folder = ThisWorkbook.Path & "\Tests\" & label
    If Dir(folder, vbDirectory) = "" Then MkDir folder
    Call LoadWorld: Quality = preset: CacheGeometry = useCache: CleanView = immersive
    frmFlight.Show vbModeless: DoEvents
    GetClientRect FindWindow(vbNullString, "Meridian | Excel Flight Simulator"), r
    frmFlight.Width = frmFlight.Width + (viewportWidth - r.Right) * 0.75
    frmFlight.Height = frmFlight.Height + (CLng(viewportWidth * 0.7) - r.Bottom) * 0.75
    DoEvents
    InitRenderer FindWindow(vbNullString, "Meridian | Excel Flight Simulator")
    f = FreeFile: Open folder & "\benchmark.csv" For Output As #f
    Print #f, "scene,preset,width,height,frames,seconds,fps,p95_ms,p99_ms,readback_ms,overlay_ms,present_ms,cached"
    For scene = 0 To 7
        ShowcaseState scene
        For i = 1 To 5: Call RenderFrame: Present: Next
        CompleteGPUWork
        started = Clock()
        For i = 1 To 90
            frameStart = Clock()
            Call RenderFrame: Present: CompleteGPUWork
            times(i) = (Clock() - frameStart) * 1000
        Next
        duration = Clock() - started
        If preset >= 2 And Quality <> preset Then Err.Raise 5, , "Unexpected graphics fallback: " & LandscapeError
        For i = 2 To 90
            swap = times(i): j = i - 1
            Do While j >= 1
                If times(j) <= swap Then Exit Do
                times(j + 1) = times(j): j = j - 1
            Loop
            times(j + 1) = swap
        Next
        Print #f, scene & "," & preset & "," & IIf(preset >= 2, GPUWidth, 480) & "," & IIf(preset >= 2, GPUHeight, 480) & ",90," & Format(duration, "0.000000") & "," & Format(90 / duration, "0.00") & "," & Format(times(86), "0.000") & "," & Format(times(90), "0.000") & "," & Format(GPUReadbackMS, "0.000") & "," & Format(GPUOverlayMS, "0.000") & "," & Format(GPUPresentMS, "0.000") & "," & useCache
        SaveFrame folder & "\scene-" & scene & ".bmp"
        DoEvents
    Next
    Close #f
    Open folder & "\environment.txt" For Output As #f
    Print #f, GPUDescription
    Print #f, "Excel " & Application.Version & " build " & Application.Build & " | " & Application.OperatingSystem
    Print #f, "Framebuffer " & GPUWidth & " x " & GPUHeight & " | direct=" & DirectGPU & " | cached=" & CacheGeometry
    CaptureShowcase = "PASS | Matched showcase captured: " & label
cleanup:
    If f > 0 Then Close #f
    Call CloseRenderer: Unload frmFlight
    Exit Function
failed:
    CaptureShowcase = "FAIL | scene=" & scene & " i=" & i & " " & Err.Number & " " & Err.Description & " GL=" & LandscapeError
    Resume cleanup
End Function


