Attribute VB_Name = "modRegionTests"
Option Explicit
Private results As String
Private Sub AssertRegion(ByVal name As String, ByVal passed As Boolean)
    results = results & IIf(passed, "PASS", "FAIL") & " | Region " & name & vbCrLf
End Sub

Public Function RunRegionTests() As String
    Dim airport As Long, runway As Long, i As Long, leg As Long, elapsed As Double, startRows As Long
    Dim thresholdE As Double, thresholdN As Double, distance As Double, targetAlt As Double, desiredVS As Double
    Dim cl As Double, pitch As Double, missionChoice As Long
    On Error GoTo failed
    results = ""
    AssertRegion "FAA runway count", RunwayCount = 4
    AssertRegion "Richmond primary length", Abs(Runways(PrimaryRunway(1)).Length - 2744.1144) < 0.01
    AssertRegion "Hanover location", Runways(PrimaryRunway(2)).North > 33000
    For airport = 1 To 2
        runway = PrimaryRunway(airport)
        AssertRegion "Ground at " & AirportCode(airport), Ground(Runways(runway).East, Runways(runway).North) > 0 And Ground(Runways(runway).East, Runways(runway).North) < 150
        ResetFlight 7 + airport
        AssertRegion "Departure " & AirportCode(airport), Plane.grounded And OnRegionRunway(runway, Plane.east, Plane.north)
        ResetFlight 13 + airport: SetWeather 0
        Demo = False: Paused = False
        RegionPoint runway, -Runways(runway).Length / 2, 0, thresholdE, thresholdN
        For i = 1 To 15000
            distance = -Runways(runway).Length / 2 - RegionAlong(runway, Plane.east, Plane.north)
            targetAlt = RegionRunwayHeight(runway, thresholdE, thresholdN) + 1.2 + Clamp(distance, 0, 5000) * 0.0524
            desiredVS = Clamp((targetAlt - Plane.altitude) * 0.35 - 1.4, -3, -0.5)
            If Plane.altitude - Ground(Plane.east, Plane.north) < 7 Then desiredVS = -0.6
            cl = (890 + Plane.fuel * 0.72) * 9.80665 / (0.5 * 1.225 * Exp(-Plane.altitude / 8500) * Plane.speed ^ 2 * 15.8)
            pitch = Atan2(Plane.vertical, Plane.speed) + (cl - 0.25 - Plane.flaps * 0.16) / 4.8 + (desiredVS - Plane.vertical) * 0.025
            Plane.elevator = Clamp((pitch - 0.035) / 0.35, -0.8, 0.8)
            Plane.throttle = Clamp(0.28 + (34 - Plane.speed) * 0.06, 0, 1)
            StepFlight 1# / 60
            If Plane.grounded Or Plane.crashed Then Exit For
        Next
        AssertRegion "Guided arrival " & AirportCode(airport), Not Paused And Plane.grounded And Not Plane.crashed And OnRegionRunway(runway, Plane.east, Plane.north)
        Plane.throttle = 0: Plane.brake = True: Plane.elevator = 0
        For i = 1 To 900: StepFlight 1# / 60: Next
        AssertRegion "Rollout " & AirportCode(airport), Plane.speed < 1 And Not Plane.crashed
        Quality = 2: ResetFlight 13 + airport
        Call RenderFrame: SaveFrame ThisWorkbook.Path & "\Tests\" & AirportCode(airport) & "-v07.bmp"
        AssertRegion "Detailed view " & AirportCode(airport), Quality = 2 And LandscapeError = ""
        Quality = 0: Call RenderFrame
        AssertRegion "Software view " & AirportCode(airport), Quality = 0
    Next
    For missionChoice = 10 To 12
        ResetFlight missionChoice: SetWeather 0: Demo = True: Paused = False
        Plane.grounded = False: Plane.altitude = 600: Plane.speed = 53: Plane.pitch = 0.035
        runway = PrimaryRunway(NavAirport)
        Plane.heading = Wrap(Atan2(Runways(runway).East - Plane.east, Runways(runway).North - Plane.north))
        For i = 1 To 60000
            DemoControls
            Plane.aileron = 0
            StepFlight 1# / 60
            UpdateMission 1# / 60
            If AirportDistance(NavAirport) < 3000 Or Paused Or Plane.crashed Then Exit For
        Next
        AssertRegion "Physics route " & missionChoice, AirportDistance(NavAirport) < 3000 And MissionStage = 3 And Not Paused And Not Plane.crashed
    Next
    Demo = False
    ResetFlight 1: Plane.east = 16000: Plane.north = 17000
    Paused = False: StepFlight 1# / 60
    AssertRegion "Travel beyond original boundary", Not Paused And Not Plane.crashed
    ResetFlight 10: Demo = False: Paused = False
    AssertRegion "Mission configured", MissionActive And NavAirport = 1 And MissionLeg = 1
    Plane.grounded = False: Plane.altitude = 700
    UpdateMission 1
    AssertRegion "Departure recognized", MissionStage = 2
    elapsed = MissionElapsed: Paused = True: UpdateMission 2: Paused = False
    AssertRegion "Pause holds mission clock", MissionElapsed = elapsed
    ReplayActive = True: UpdateMission 2: ReplayActive = False
    AssertRegion "Replay holds mission clock", MissionElapsed = elapsed
    Plane.grounded = True: Plane.speed = 0: UpdateMission 4
    AssertRegion "Wrong airport cannot finish", MissionActive
    runway = PrimaryRunway(1)
    Plane.east = Runways(runway).East: Plane.north = Runways(runway).North
    Plane.altitude = Ground(Plane.east, Plane.north) + 1.2
    UpdateMission 2
    AssertRegion "Stop requires three seconds", MissionActive
    UpdateMission 1.1
    AssertRegion "Point-to-point complete", Not MissionActive And MissionStage = 4
    Call WriteMissionLog
    startRows = ThisWorkbook.Worksheets("Mission log").UsedRange.Rows.Count
    Call WriteMissionLog
    AssertRegion "Mission log idempotent", ThisWorkbook.Worksheets("Mission log").UsedRange.Rows.Count = startRows
    ResetFlight 13
    For leg = 1 To 3
        Plane.grounded = False: Plane.altitude = 700: Plane.speed = 45
        UpdateMission 1
        runway = PrimaryRunway(NavAirport)
        Plane.east = Runways(runway).East: Plane.north = Runways(runway).North
        Plane.altitude = Ground(Plane.east, Plane.north) + 1.2: Plane.grounded = True: Plane.speed = 0
        UpdateMission 3.1
        If leg < 3 Then AssertRegion "Tour advances leg " & leg, MissionActive And MissionLeg = leg + 1 And MissionStage = 1
    Next
    AssertRegion "Tour completes", MissionStage = 4 And Not MissionActive
    ResetFlight 11: Demo = True: UpdateMission 1: Demo = False
    AssertRegion "Assistance marked", MissionAssisted
    Plane.crashed = True: UpdateMission 1
    AssertRegion "Crash ends mission", Not MissionActive And MissionStage = 5
    Quality = 2: ResetFlight 11: ShowMap = True
    Plane.east = Runways(PrimaryRunway(1)).East
    Plane.north = Runways(PrimaryRunway(1)).North
    Plane.altitude = Ground(Plane.east, Plane.north) + 15
    Plane.grounded = False: Plane.speed = 35: CameraMode = 2
    Call RenderFrame: SaveFrame ThisWorkbook.Path & "\Tests\shadow-v07.bmp"
    ResetFlight 11: ShowMap = True
    Call RenderFrame: SaveFrame ThisWorkbook.Path & "\Tests\mission-v07.bmp"
    ResetFlight 1
    RunRegionTests = results
    Exit Function
failed:
    RunRegionTests = results & "FAIL | Region exception | " & Err.Description & vbCrLf
End Function
