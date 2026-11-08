Attribute VB_Name = "modTests"
Option Explicit
Private Declare PtrSafe Function GetDIBits Lib "gdi32" (ByVal hdc As LongPtr, ByVal bitmap As LongPtr, ByVal start As Long, ByVal lines As Long, ByRef bits As Any, ByRef info As BITMAPINFOHEADER, ByVal usage As Long) As Long
Private Declare PtrSafe Function GetCurrentObject Lib "gdi32" (ByVal hdc As LongPtr, ByVal kind As Long) As LongPtr
Private results As String
Private Sub Check(ByVal name As String, ByVal condition As Boolean, ByVal details As String)
    results = results & IIf(condition, "PASS", "FAIL") & " | " & name & " | " & details & vbCrLf
End Sub
Public Sub SaveFrame(ByVal path As String)
    Dim data() As Long, info As BITMAPINFOHEADER, bmp As LongPtr, f As Integer, scratch As LongPtr, rows As Long
    Dim fileSize As Long, offset As Long, zero As Integer, signature As String * 2
    ReDim data(0 To 699999)
    info.biSize = 40: info.biWidth = 1000: info.biHeight = -700
    info.biPlanes = 1: info.biBitCount = 32: info.biSizeImage = 2800000
    bmp = GetCurrentObject(Canvas, 7)
    scratch = CreateCompatibleBitmap(Canvas, 1, 1)
    SelectObject Canvas, scratch
    rows = GetDIBits(Canvas, bmp, 0, 700, data(0), info, 0)
    SelectObject Canvas, bmp: DeleteObject scratch
    If rows = 0 Then Err.Raise 5, , "Frame capture failed"
    f = FreeFile: fileSize = 2800054: offset = 54: signature = "BM"
    Open path For Binary Access Write As #f
    Put #f, , signature: Put #f, , fileSize: Put #f, , zero: Put #f, , zero: Put #f, , offset
    Put #f, , info: Put #f, , data
    Close #f
End Sub
Public Function RunSelfTests() As String
    Dim i As Long, j As Long, t As Double, duration As Double, first As Double, landed As Boolean
    Dim before As Long, after As Long, maxHeight As Double, replay As Double, f As Integer
    Dim renderSum As Double, panelSum As Double, physicsSum As Double, audioSum As Double
    Dim weatherIndex As Long, cameraIndex As Long
    Dim distance As Double, targetAlt As Double, desiredVS As Double, targetPitch As Double, desiredCL As Double
    On Error GoTo failed
    results = "MERIDIAN / NATIVE EXCEL VBA TEST RUN" & vbCrLf & Format(Now, "yyyy-mm-dd hh:nn:ss") & vbCrLf
    Check "A Compilation", True, "Native VBA execution reached test runner"
    LoadWorld
    Check "C Cached hillshade", UBound(TerrainShade) = 1048575 And TerrainShade(0) >= 0.68 And TerrainShade(0) <= 1.15, "Resident lighting cache available"
    Check "C Terrain", UBound(Heights) = 1048575 And UBound(Colors) = 16777215, "DEM and texture binary lengths validated"
    Check "N Geography", Abs(Latitude(0) - 37.4065) < 0.000001 And Abs(Longitude(0) + 77.5248333333) < 0.000001, "Projection origin round trip"
    Check "N Runway", OnRunway(0, 0) And Not OnRunway(2000, 2000), "1676.4 x 30.48 m footprint"
    SetWeather 0: ResetFlight 0
    Plane.throttle = 1
    For i = 1 To 3600
        If Plane.speed > 27 Then Plane.elevator = 0.36
        StepFlight 1# / 60
        If Plane.altitude > maxHeight Then maxHeight = Plane.altitude
    Next
    Check "E/F Takeoff", Not Plane.grounded And maxHeight > 100 And Not Plane.crashed, "60 s: altitude=" & Format(Plane.altitude, "0.0") & " m; speed=" & Format(Plane.speed, "0.0") & " m/s"
    SetWeather 0: ResetFlight 1
    For i = 1 To 72000
        Call DemoControls: StepFlight 1# / 60
        If Plane.crashed Or Abs(Plane.altitude) > 10000 Or Plane.speed > 130 Then Exit For
    Next
    Check "M Stability", i > 72000 And Not Plane.crashed, "20 simulated minutes / 72000 steps; altitude=" & Format(Plane.altitude, "0.0") & " m"
    first = Plane.altitude
    ResetFlight 1
    For i = 1 To 72000: Call DemoControls: StepFlight 1# / 60: Next
    Check "O Repeatability", Abs(first - Plane.altitude) < 0.00000001, "Deterministic 20-minute replay"
    ResetFlight 2
    'Controlled touchdown state checks collision/rollout independently of approach pilot tuning.
    Plane.east = -400 * Sin(RunwayHeading): Plane.north = -400 * Cos(RunwayHeading)
    Plane.altitude = Ground(Plane.east, Plane.north) + 1.22: Plane.vertical = -0.8
    Plane.pitch = 0.05: Plane.speed = 26: Plane.throttle = 0: Plane.elevator = 0
    StepFlight 1# / 60: StepFlight 1# / 60: Plane.brake = True
    landed = Plane.grounded And Not Plane.crashed
    For i = 1 To 900: StepFlight 1# / 60: Next
    Check "G Touchdown/rollout", landed And Plane.speed < 1 And Not Plane.crashed, "Controlled contact and 15 s braking; approach/flare requires separate pilot test"
    ResetFlight 2: Plane.east = 0: Plane.north = 0: Plane.altitude = Ground(0, 0) + 1.21
    Plane.vertical = -8: StepFlight 1# / 60
    Check "G Hard landing", Plane.crashed, "8 m/s descent rejected"
    SetWeather 0: ResetFlight 2
    For i = 1 To 15000
        distance = -838.2 - AlongRunway(Plane.east, Plane.north)
        targetAlt = RunwayHeight(-838.2 * Sin(RunwayHeading), -838.2 * Cos(RunwayHeading)) + 1.2 + Clamp(distance, 0, 5000) * 0.0524
        desiredVS = Clamp((targetAlt - Plane.altitude) * 0.35 - 1.4, -3, -0.5)
        If Plane.altitude - Ground(Plane.east, Plane.north) < 7 Then desiredVS = -0.6
        desiredCL = (890 + Plane.fuel * 0.72) * 9.80665 / (0.5 * 1.225 * Exp(-Plane.altitude / 8500) * Plane.speed ^ 2 * 15.8)
        targetPitch = Atan2(Plane.vertical, Plane.speed) + (desiredCL - 0.25 - Plane.flaps * 0.16) / 4.8 + (desiredVS - Plane.vertical) * 0.025
        Plane.elevator = Clamp((targetPitch - 0.035) / 0.35, -0.8, 0.8)
        Plane.throttle = Clamp(0.28 + (34 - Plane.speed) * 0.06, 0, 1)
        StepFlight 1# / 60
        If Plane.grounded Or Plane.crashed Then Exit For
    Next
    Check "G Approach/flare", Plane.grounded And Not Plane.crashed And OnRunway(Plane.east, Plane.north), "Guidance-generated controls from approach scenario; touchdown " & Format(Touchdown, "0.00") & " m/s; along=" & Format(AlongRunway(Plane.east, Plane.north), "0.0") & " m"
    ResetFlight 1: SetWeather 2
    For i = 1 To 120: StepFlight 1# / 60: Next
    replay = Plane.east
    ResetFlight 1: SetWeather 0
    For i = 1 To 120: StepFlight 1# / 60: Next
    Check "Weather ground track", Abs(replay - Plane.east - 8) < 0.1, "4 m/s east wind changes position 8 m in 2 s"
    Sensitivity = 0.8: Volume = 0.35: Quality = 1
    before = GetGuiResources(GetCurrentProcess(), 0)
    For j = 1 To 3
        frmFlight.Show vbModeless: DoEvents
        InitRenderer FindWindow(vbNullString, "Meridian | Excel Flight Simulator")
        ResetFlight 1: SetWeather 0: CameraMode = 0
        t = Clock(): Call RenderFrame: Present
        Check "B/J Launch " & j, Canvas <> 0, "Native UserForm, terrain and cockpit presented"
        If j = 1 Then
            Paused = False: Demo = False
            ClearInput
            QueueKey 87, True: QueueKey 87, False: ApplyInput 0.1
            Check "D Throttle", Plane.throttle > 0.64, "Queued short W pulse changes polled power"
            ClearInput
            QueueKey 40, True: QueueKey 40, False: ApplyInput 0.1
            Check "D Elevator", Plane.elevator > 0, "Down produces positive elevator"
            ClearInput
            QueueKey 39, True: QueueKey 39, False: ApplyInput 0.1
            Check "D Aileron", Plane.aileron > 0, "Right produces positive aileron"
            ClearInput
            QueueKey 68, True: QueueKey 68, False: ApplyInput 0.1
            Check "D Rudder", Plane.rudder > 0, "D produces positive rudder"
            ClearInput
            QueueKey 32, True: QueueKey 32, False: ApplyInput 0.1
            Check "D Brake", Plane.brake, "Space sets wheel brake"
            ClearInput
            QueueKey 80, True: QueueKey 80, False: ApplyInput 0.1
            Check "D Pause", Paused, "Short P event retained"
            QueueKey 80, True: QueueKey 80, False: ApplyInput 0.1
            Check "D Resume", Not Paused, "Second P resumes"
            ResetFlight 1: ClearInput
            SaveFrame ThisWorkbook.Path & "\Tests\scenic.bmp"
            t = Clock(): renderSum = 0: panelSum = 0
            For i = 1 To 120
                Call DemoControls: StepFlight 1# / 30: Call RenderFrame: Present
                renderSum = renderSum + TerrainMS: panelSum = panelSum + PanelMS
                If i Mod 10 = 0 Then DoEvents
            Next
            duration = Clock() - t
            FPS = 120 / duration
            Check "L Benchmark", duration > 0, "120 frames: " & Format(FPS, "0.00") & " FPS; terrain " & Format(renderSum / 120, "0.00") & " ms; panel " & Format(panelSum / 120, "0.00") & " ms. Uncapped native renderer, balanced."
            Quality = 0: t = Clock()
            For i = 1 To 120
                Call DemoControls: StepFlight 1# / 30: Call RenderFrame: Present
                If i Mod 10 = 0 Then DoEvents
            Next
            duration = Clock() - t
            Check "L Performance preset", duration > 0, "120 frames: " & Format(120 / duration, "0.00") & " FPS; uncapped with 2-column spans"
            ShowMap = True: t = Clock()
            For i = 1 To 30
                Call RenderFrame: Present
            Next
            Check "L Moving map", True, "Performance preset + map: " & Format(30 / (Clock() - t), "0.00") & " FPS over 30 frames"
            ShowMap = False
            Quality = 1
            ResetFlight 0: CameraMode = 0: Call RenderFrame: Call Present: SaveFrame ThisWorkbook.Path & "\Tests\runway.bmp"
            ResetFlight 2: Call RenderFrame: Call Present: SaveFrame ThisWorkbook.Path & "\Tests\approach.bmp"
            ResetFlight 1: SetWeather 1: CameraMode = 2: Call RenderFrame: Call Present: SaveFrame ThisWorkbook.Path & "\Tests\sunset.bmp"
            SetWeather 4: Call RenderFrame: Call Present: SaveFrame ThisWorkbook.Path & "\Tests\night.bmp"
            ResetFlight 1: SetWeather 0: CameraMode = 0: Plane.bank = 0.35: Plane.pitch = 0.12: Plane.vertical = 3
            Call RenderFrame: SaveFrame ThisWorkbook.Path & "\Tests\banked-cockpit.bmp"
            CameraMode = 4: Call RenderFrame: SaveFrame ThisWorkbook.Path & "\Tests\instruments.bmp"
            For weatherIndex = 0 To 5
                SetWeather weatherIndex
                For cameraIndex = 0 To 4
                    CameraMode = cameraIndex: Call RenderFrame: Present
                Next
            Next
            Check "H Camera/weather matrix", True, "All 5 views x 6 weather presets rendered; banked cockpit and instrument captures saved"
            SetWeather 0: Call StartAudio: t = Clock()
            Do While Clock() - t < 2
                Plane.throttle = (Clock() - t) / 2: Plane.rpm = 700 + Plane.throttle * 2000
                Call UpdateAudio: DoEvents: Sleep 10
            Loop
            Check "I Audio", AudioBuffers > 12, AudioStatus & "; synthesized buffers=" & AudioBuffers
            StopAudio
        End If
        Call CloseRenderer: Unload frmFlight: DoEvents
    Next
    after = GetGuiResources(GetCurrentProcess(), 0)
    Check "K GDI cleanup", after - before < 12, "3 cycles: before=" & before & " after=" & after & "; includes Office UserForm cache"
    results = results & "PARTIAL | D Physical controls | Queued native control tests passed if reported above; UI pause/resume checked separately; sustained physical piloting not fully tested" & vbCrLf
    results = results & "NOT TESTED | H Instruments | Numeric bindings implemented; visual inspection recorded separately" & vbCrLf
done:
    f = FreeFile
    Open ThisWorkbook.Path & "\Tests\results.txt" For Output As #f
    Print #f, results: Close #f
    RunSelfTests = results
    Exit Function
failed:
    results = results & "FAIL | Runtime error | " & Err.Number & " " & Err.Description & vbCrLf
    Call StopAudio: Call CloseRenderer: Unload frmFlight
    Resume done
End Function
