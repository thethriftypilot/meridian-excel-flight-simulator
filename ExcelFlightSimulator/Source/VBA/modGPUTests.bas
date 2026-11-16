Attribute VB_Name = "modGPUTests"
Option Explicit
Public Function RunGPUChecks() As String
    Dim cycle As Long, weatherIndex As Long, cameraIndex As Long, before As Long, after As Long
    Dim report As String, f As Integer, resources As String
    On Error GoTo failed
    LoadWorld
    before = GetGuiResources(GetCurrentProcess(), 0)
    For cycle = 1 To 3
        Quality = 4: CacheGeometry = True: CleanView = True: ViewZoom = 1
        frmFlight.Show vbModeless: DoEvents
        InitRenderer FindWindow(vbNullString, "Meridian | Excel Flight Simulator")
        ResetFlight 1
        For weatherIndex = 0 To 6
            SetWeather weatherIndex
            For cameraIndex = 0 To 4
                CameraMode = cameraIndex
                Call RenderFrame: Present: CompleteGPUWork
                If Not DirectGPU Then Err.Raise 5, , "Direct presentation fell back: " & LandscapeError
                If GPUReadbackMS <> 0 Then Err.Raise 5, , "Direct flight performed readback"
            Next
        Next
        frmFlight.Width = frmFlight.Width + 80
        frmFlight.Height = frmFlight.Height + 45
        DoEvents
        Call RenderFrame: Present: CompleteGPUWork
        If GPUWidth < 1 Or GPUHeight < 1 Then Err.Raise 5, , "Invalid resized framebuffer"
        Paused = True: Call RenderFrame: Present: Paused = False
        SaveFrame ThisWorkbook.Path & "\Tests\gpu-cycle-" & cycle & ".bmp"
        Call CloseRenderer: CloseRenderer
        Unload frmFlight
        DoEvents
        after = GetGuiResources(GetCurrentProcess(), 0)
        resources = resources & " cycle " & cycle & "=" & after
        If cycle = 1 Then before = after
    Next
    after = GetGuiResources(GetCurrentProcess(), 0)
    If after > before + 12 Then Err.Raise 5, , "GDI resources grew across GPU cycles: " & resources
    report = "PASS | Direct GPU | 3 launches, 105 camera/weather frames, resize, pause, capture and double cleanup; GDI " & before & " -> " & after & resources
cleanup:
    Call CloseRenderer: Unload frmFlight
    f = FreeFile: Open ThisWorkbook.Path & "\Tests\gpu-checks.txt" For Output As #f
    Print #f, report: Close #f
    RunGPUChecks = report
    Exit Function
failed:
    report = "FAIL | Direct GPU | " & Err.Number & " " & Err.Description
    Resume cleanup
End Function
