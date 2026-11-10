Attribute VB_Name = "modMain"
Option Explicit
Public Running As Boolean, MenuOpen As Boolean
Public PhysicsMS As Double, AudioMS As Double, FrameMS As Double
Public TestFlightSeconds As Double
Private oldStatus As Variant
Public Sub LaunchSimulator()
    On Error GoTo failed
    If Running Or MenuOpen Then Exit Sub
    LoadWorld
    Sensitivity = 0.8: Volume = 0.65: Quality = 0: ShowMap = False
    frmMenu.Show vbModeless
    Exit Sub
failed:
    MsgBox "Simulator could not start: " & Err.Description, vbExclamation, "Meridian"
End Sub
Public Sub StartFlight()
    BeginFlight False
End Sub
Public Sub WatchDemonstration()
    BeginFlight True
End Sub
Public Sub BeginFlight(ByVal automatic As Boolean)
    Dim previous As Double, now As Double, elapsed As Double, accumulator As Double, t As Double
    Dim frameStart As Double, smooth As Double, counter As Long, reportStart As Double
    Dim targetMS As Double, errText As String, qualityTimer As Double, flightStart As Double, logFile As Integer, logOpened As Boolean
    On Error GoTo failed
    If Running Then Exit Sub
    LoadWorld
    If Sensitivity = 0 Then Sensitivity = 0.8: Volume = 0.65: Quality = 0
    Demo = automatic: Paused = False
    If Demo Then Scenario = 1
    ResetFlight Scenario
    StartRecording
    frmMenu.Hide: MenuOpen = False
    frmFlight.StartUpPosition = 0
    frmFlight.Left = Application.Left: frmFlight.Top = Application.Top
    frmFlight.Width = Application.Width
    frmFlight.Height = Application.Height
    frmFlight.Show vbModeless
    DoEvents
    InitRenderer FindWindow(vbNullString, "Meridian | Excel Flight Simulator")
    oldStatus = Application.StatusBar
    Application.StatusBar = "Meridian running. Esc returns to menu. Ctrl+Break is the Excel emergency stop."
    Running = True: Call ClearInput: StartAudio
    previous = Clock(): reportStart = previous
    flightStart = previous
    logFile = FreeFile
    Open ThisWorkbook.Path & "\Tests\last-flight.csv" For Output As #logFile
    logOpened = True
    Print #logFile, "seconds,fps,terrain_ms,panel_ms,physics_ms,audio_ms,quality,east,north,altitude,speed,throttle,pitch,bank,paused,camera"
    Do While Running
        frameStart = Clock(): now = frameStart
        elapsed = Clamp(now - previous, 0, 0.2): previous = now
        PollInput elapsed
        t = Clock()
        If Not Paused And GetForegroundWindow() = SimHwnd Then
            accumulator = accumulator + elapsed
            Do While accumulator >= 1# / 60
                If Demo Then DemoControls
                StepFlight 1# / 60
                UpdateChallenge 1# / 60
                RecordFrame
                If ChallengeComplete Then Paused = True
                accumulator = accumulator - 1# / 60
                If Paused Then accumulator = 0: Exit Do
            Loop
        Else
            accumulator = 0
        End If
        PhysicsMS = (Clock() - t) * 1000
        t = Clock(): Call UpdateAudio: AudioMS = (Clock() - t) * 1000
        Call RenderFrame: Present
        counter = counter + 1
        If now - reportStart >= 1 Then
            FPS = counter / (now - reportStart): reportStart = now: counter = 0
            Print #logFile, Format(now - flightStart, "0.00") & "," & Format(FPS, "0.00") & "," & Format(TerrainMS, "0.00") & "," & Format(PanelMS, "0.00") & "," & Format(PhysicsMS, "0.000") & "," & Format(AudioMS, "0.00") & "," & Quality & "," & Format(Plane.east, "0.0") & "," & Format(Plane.north, "0.0") & "," & Format(Plane.altitude, "0.0") & "," & Format(Plane.speed, "0.00") & "," & Format(Plane.throttle, "0.00") & "," & Format(Plane.pitch, "0.000") & "," & Format(Plane.bank, "0.000") & "," & Paused & "," & CameraMode
            If FPS < 18 And Quality = 1 Then Quality = 0
        End If
        DoEvents
        FrameMS = (Clock() - frameStart) * 1000
        targetMS = 33: If Quality >= 2 Then targetMS = 1000# / 60
        If FrameMS < targetMS Then Sleep CLng(targetMS - FrameMS)
        If TestFlightSeconds > 0 And now - flightStart > TestFlightSeconds Then
            SaveFrame ThisWorkbook.Path & "\Tests\live-flight.bmp"
            Running = False
        End If
    Loop
cleanup:
    Running = False: Call StopAudio: StopMenuAudio: CloseRenderer
    FinishRecording
    WriteDebrief
    If logOpened Then Close #logFile
    TestFlightSeconds = 0
    Unload frmFlight
    If VarType(oldStatus) = vbBoolean Or IsEmpty(oldStatus) Then
        Application.StatusBar = False
    Else
        Application.StatusBar = oldStatus
    End If
    If Len(errText) > 0 Then MsgBox errText, vbExclamation, "Meridian"
    If Len(ReviewError) > 0 Then MsgBox ReviewError, vbExclamation, "Meridian debrief"
    frmMenu.Show vbModeless
    Exit Sub
failed:
    errText = "Flight stopped safely: " & Err.Description
    Resume cleanup
End Sub
Public Sub TimedDemoTest()
    Scenario = 1: SetWeather 0: TestFlightSeconds = 24
    BeginFlight True
End Sub
Public Sub StopSimulator()
    Running = False
End Sub
Public Sub EmergencyCleanup()
    Running = False: Call StopAudio: StopMenuAudio: CloseRenderer
    Unload frmFlight: Unload frmMenu
    Application.StatusBar = False
End Sub
