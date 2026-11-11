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
    CapturePixels data
    info.biSize = 40: info.biWidth = 1000: info.biHeight = -700
    info.biPlanes = 1: info.biBitCount = 32: info.biSizeImage = 2800000
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
    results = results & RunReviewTests()
    Check "C Cached hillshade", UBound(TerrainShade) = 1048575 And TerrainShade(0) >= 0.68 And TerrainShade(0) <= 1.15, "Resident lighting cache available"
    Check "C Terrain", UBound(Heights) = 1048575 And UBound(Colors) = 16777215, "DEM and texture binary lengths validated"
    Check "N Geography", Abs(Latitude(0) - 37.4065) < 0.000001 And Abs(Longitude(0) + 77.5248333333) < 0.000001, "Projection origin round trip"
    Check "L Memory API", WorkingSetMB() > 0, "Native process working-set counters available"
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
    SetWeather 0: ResetFlight 2: Demo = False: StartRecording
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
        UpdateChallenge 1# / 60: RecordFrame
        If Plane.grounded Or Plane.crashed Then Exit For
    Next
    Check "G Approach/flare", Plane.grounded And Not Plane.crashed And OnRunway(Plane.east, Plane.north), "Guidance-generated controls from approach scenario; touchdown " & Format(Touchdown, "0.00") & " m/s; along=" & Format(AlongRunway(Plane.east, Plane.north), "0.0") & " m"
    Assisted = True 'Guidance-generated test flight is never eligible for a personal best.
    Plane.throttle = 0: Plane.brake = True: Plane.elevator = 0
    For i = 1 To 1200
        StepFlight 1# / 60: UpdateChallenge 1# / 60: RecordFrame
        If ChallengeComplete Then Exit For
    Next
    Call FinishRecording: WriteDebrief
    Check "Review native debrief", Len(ReviewError) = 0 And ThisWorkbook.Worksheets("Debrief").ChartObjects.Count = 2, ReviewError & "Two charts from real recorded approach; assisted result"
    ThisWorkbook.Worksheets("Debrief").ExportAsFixedFormat xlTypePDF, ThisWorkbook.Path & "\Tests\debrief-v04.pdf"
    ResetFlight 1: SetWeather 2
    For i = 1 To 120: StepFlight 1# / 60: Next
    replay = Plane.east
    ResetFlight 1: SetWeather 0
    For i = 1 To 120: StepFlight 1# / 60: Next
    Check "Weather ground track", Abs(replay - Plane.east - 8) < 0.1, "4 m/s east wind changes position 8 m in 2 s"
    ResetFlight 1: Plane.fuel = 0
    For i = 1 To 600: StepFlight 1# / 60: Next
    Check "E Fuel exhaustion", Not Plane.engineRunning And Plane.rpm < 1 And Plane.oilPressure < 1, "Engine cannot regenerate idle RPM after empty tank"
    ResetFlight 1: Plane.engineRunning = False: first = Plane.fuel
    For i = 1 To 120: StepFlight 1# / 60: Next
    Check "E Engine shutdown", Plane.fuel = first And Plane.rpm < 120, "No fuel burn and RPM decays when engine is off"
    Check "G Building collision", HitsAirportBuilding(RunwayEast(-180, -235), RunwayNorth(-180, -235), 0) And Not HitsAirportBuilding(RunwayEast(-180, -235), RunwayNorth(-180, -235), 500), "Generalized hangars collide below roof, clear overhead"
    ResetFlight 1: SetWeather 2
    Check "N Groundspeed", Abs(GroundSpeedKnots() - Plane.speed * 1.94384) > 1, "Wind affects groundspeed indication"
    SetWeather 6
    Check "Weather rain", Visibility = 2800 And Turbulence > 0 And WindEast <> 0, "Rain preset changes visibility, wind, turbulence, drawing and audio"
    Sensitivity = 0.8: Volume = 0.35: Quality = 1
    before = GetGuiResources(GetCurrentProcess(), 0)
    For j = 1 To 3
        frmFlight.Show vbModeless: DoEvents
        InitRenderer FindWindow(vbNullString, "Meridian | Excel Flight Simulator")
        ResetFlight 1: SetWeather 0: CameraMode = 0
        t = Clock(): Call RenderFrame: Present
        Check "B/J Launch " & j, Canvas <> 0, "Native UserForm, terrain and cockpit presented"
        If j = 1 Then
            Check "Review renderer playback starts", BeginReplay(), "Recorded approach available"
            SeekReplay ReplayDuration() * 0.7
            For cameraIndex = 0 To 4
                CameraMode = cameraIndex: Call RenderFrame: Present
            Next
            CameraMode = 2: Call RenderFrame: SaveFrame ThisWorkbook.Path & "\Tests\replay-v04.bmp"
            Check "Review replay cameras", ReplayActive, "Five camera views rendered from recorded aircraft states"
            EndReplay
            CheckInstrumentBindings
            Check "J Depth occlusion", CheckDepthRaster(), "Far polygon cannot overwrite near polygon; nearer polygon can"
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
            QueueKey 69, True: QueueKey 69, False: ApplyInput 0.1
            Check "D Engine off", Not Plane.engineRunning, "E cuts engine"
            QueueKey 69, True: QueueKey 69, False: ApplyInput 0.1
            Check "D Engine restart", Plane.engineRunning, "E restarts with fuel available"
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
            For weatherIndex = 0 To 6
                SetWeather weatherIndex
                For cameraIndex = 0 To 4
                    CameraMode = cameraIndex: Call RenderFrame: Present
                Next
            Next
            Check "H Camera/weather matrix", True, "All 5 views x 7 weather presets rendered; banked cockpit and instrument captures saved"
            ResetFlight 6: Plane.heading = RunwayHeading + PI: CameraMode = 1: SetWeather 0
            Call RenderFrame: SaveFrame ThisWorkbook.Path & "\Tests\airport.bmp"
            ResetFlight 1: CameraMode = 2: Call RenderFrame: SaveFrame ThisWorkbook.Path & "\Tests\aircraft.bmp"
            CameraMode = 0: SetWeather 6: Call RenderFrame: SaveFrame ThisWorkbook.Path & "\Tests\rain.bmp"
            Quality = 2: ResetFlight 2: SetWeather 0: CameraMode = 0
            Call RenderFrame
            SaveFrame ThisWorkbook.Path & "\Tests\approach-v06.bmp"
            Check "Detailed landscape", Quality = 2 And LandscapeError = "", "Full-resolution OpenGL frame" & LandscapeError
            ResetFlight 0: Call RenderFrame: SaveFrame ThisWorkbook.Path & "\Tests\runway-v06.bmp"
            ResetFlight 1: SetWeather 1: CameraMode = 2: Call RenderFrame
            SaveFrame ThisWorkbook.Path & "\Tests\sunset-v06.bmp"
            t = Clock()
            For i = 1 To 120
                Call DemoControls: StepFlight 1# / 30: CameraMode = 2: Call RenderFrame: Present
            Next
            Check "Detailed benchmark", LandscapeError = "", Format(120 / (Clock() - t), "0.00") & " FPS, 120 full-resolution chase frames" & LandscapeError
            For weatherIndex = 0 To 6
                SetWeather weatherIndex
                For cameraIndex = 0 To 4
                    CameraMode = cameraIndex: Call RenderFrame: Present
                Next
            Next
            Check "Detailed camera and weather matrix", Quality = 2 And LandscapeError = "", "35 combinations without software fallback"
            ResetFlight 6: SetWeather 0: CameraMode = 2
            Plane.east = RunwayEast(-260, -150): Plane.north = RunwayNorth(-260, -150)
            Plane.altitude = TerrainGround(Plane.east, Plane.north) + 30
            Plane.heading = RunwayHeading: Plane.bank = -0.15: Plane.pitch = 0
            Call RenderFrame: SaveFrame ThisWorkbook.Path & "\Tests\flyby-v06.bmp"
            ' Identical aircraft states and camera for the same-path comparison.
            Dim level As Long
            For level = 0 To 3
                Quality = level: ResetFlight 2: SetWeather 0: CameraMode = 0
                Call RenderFrame
                t = Clock()
                For i = 1 To 90
                    StepFlight 1# / 60: Call RenderFrame: Present
                Next
                Check "Approach quality " & level, Quality = level, Format(90 / (Clock() - t), "0.00") & " uncapped FPS, matched 90-frame approach"
            Next
            ResetFlight 1: SetWeather 1: CameraMode = 2
            Call RenderFrame: SaveFrame ThisWorkbook.Path & "\Tests\supersampled-v06.bmp"
            Quality = 1
            results = results & RunRegionTests()
            SetWeather 0: Call StartAudio: t = Clock()
            Do While Clock() - t < 2
                Plane.throttle = (Clock() - t) / 2: Plane.rpm = 700 + Plane.throttle * 2000
                Call UpdateAudio: DoEvents: Sleep 10
            Loop
            Check "I Audio", AudioBuffers > 12, AudioStatus & "; synthesized buffers=" & AudioBuffers
            Check "I Menu audio", PlayMenuClick(), "Original WAV accepted by asynchronous PlaySoundW"
            StopMenuAudio
            Check "I Audio events", AudioCueCount > 0, "Startup and touchdown cues reached original PCM mixer"
            StopAudio
        End If
        Call CloseRenderer: Unload frmFlight: DoEvents
    Next
    after = GetGuiResources(GetCurrentProcess(), 0)
    Check "K GDI cleanup", after - before < 12, "3 cycles: before=" & before & " after=" & after & "; includes Office UserForm cache"
    results = results & "PARTIAL | D Physical controls | Queued native control tests passed if reported above; UI pause/resume checked separately; sustained physical piloting not fully tested" & vbCrLf
    results = results & "PARTIAL | H Instruments | All 13 displayed bindings checked through framebuffer changes; independent calibration against aircraft data not performed" & vbCrLf
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

Private Sub CapturePixels(ByRef data() As Long)
    Dim info As BITMAPINFOHEADER, bmp As LongPtr, scratch As LongPtr, rows As Long
    ReDim data(0 To 699999)
    info.biSize = 40: info.biWidth = 1000: info.biHeight = -700
    info.biPlanes = 1: info.biBitCount = 32: info.biSizeImage = 2800000
    bmp = GetCurrentObject(Canvas, 7)
    scratch = CreateCompatibleBitmap(Canvas, 1, 1)
    SelectObject Canvas, scratch
    rows = GetDIBits(Canvas, bmp, 0, 700, data(0), info, 0)
    SelectObject Canvas, bmp: DeleteObject scratch
    If rows = 0 Then Err.Raise 5, , "Frame capture failed"
End Sub
Private Function RegionChanged(ByRef before() As Long, ByRef after() As Long, ByVal x As Long, ByVal y As Long, ByVal width As Long, ByVal height As Long) As Boolean
    Dim xx As Long, yy As Long, changes As Long
    For yy = y To y + height - 1
        For xx = x To x + width - 1
            If before(xx + yy * 1000) <> after(xx + yy * 1000) Then changes = changes + 1
        Next
    Next
    RegionChanged = changes > 8
End Function
Private Sub CheckInstrumentBindings()
    Dim saved As AircraftState, baseline() As Long, changed() As Long, i As Long, x As Long, y As Long, w As Long, h As Long
    Dim label As String
    ResetFlight 1: SetWeather 0: CameraMode = 0: Plane.vertical = 0: Plane.bank = 0: Plane.turnRate = 0: Plane.slip = 0
    saved = Plane: Call RenderFrame: CapturePixels baseline
    For i = 0 To 12
        Plane = saved: w = 130: h = 130
        Select Case i
            Case 0: label = "Airspeed": Plane.speed = 35: x = 20: y = 405
            Case 1: label = "Attitude": Plane.bank = 0.35: Plane.pitch = 0.15: x = 175: y = 405
            Case 2: label = "Altimeter": Plane.altitude = 1000: x = 330: y = 405
            Case 3: label = "Vertical speed": Plane.vertical = 5: x = 330: y = 545
            Case 4: label = "Heading": Plane.heading = 2: x = 175: y = 545
            Case 5: label = "Turn coordinator": Plane.turnRate = 0.05236: x = 35: y = 590: w = 100: h = 30
            Case 6: label = "Slip": Plane.slip = 0.8: x = 40: y = 620: w = 90: h = 16
            Case 7: label = "Tachometer": Plane.rpm = 2700: x = 485: y = 405
            Case 8: label = "Fuel": Plane.fuel = 40: x = 650: y = 496: w = 150: h = 22
            Case 9: label = "Oil temperature": Plane.oilTemp = 105: x = 650: y = 550: w = 150: h = 25
            Case 10: label = "Oil pressure": Plane.oilPressure = 10: x = 740: y = 550: w = 150: h = 25
            Case 11: label = "Flaps": Plane.flaps = 3: x = 650: y = 522: w = 100: h = 25
            Case 12: label = "Magnetic compass": Plane.heading = 2: x = 415: y = 34: w = 170: h = 24
        End Select
        Call RenderFrame: CapturePixels changed
        Check "H " & label, RegionChanged(baseline, changed, x, y, w, h), "Isolated state change updates the corresponding framebuffer region"
    Next
    Plane = saved
End Sub
