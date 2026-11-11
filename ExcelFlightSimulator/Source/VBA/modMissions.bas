Attribute VB_Name = "modMissions"
Option Explicit
Public NavAirport As Long, MissionActive As Boolean, MissionStage As Long
Public MissionTitle As String, MissionStatus As String, MissionLeg As Long
Public MissionAssisted As Boolean, MissionElapsed As Double
Private route(0 To 2) As Long, legs As Long, stopped As Double
Private departed As Boolean, missionWritten As Boolean, missionConfigured As Boolean

Public Function AirportDistance(ByVal airport As Long) As Double
    Dim runway As Long
    runway = PrimaryRunway(airport)
    AirportDistance = Sqr((Plane.east - Runways(runway).East) ^ 2 + (Plane.north - Runways(runway).North) ^ 2)
End Function

Public Sub SetupMission(ByVal scenarioID As Long)
    Dim origin As Long, approach As Boolean, index As Long, along As Double
    MissionActive = False: MissionStage = 0: MissionTitle = "": MissionStatus = ""
    MissionLeg = 0: stopped = 0: departed = False: missionWritten = False
    missionConfigured = False: MissionAssisted = False: MissionElapsed = 0: NavAirport = 0
    If scenarioID < 8 Then Exit Sub
    origin = 0: legs = 1
    Select Case scenarioID
        Case 8: origin = 1: NavAirport = 1
        Case 9: origin = 2: NavAirport = 2
        Case 10: origin = 0: route(0) = 1: MissionTitle = "Capital arrival / KFCI to KRIC"
        Case 11: origin = 1: route(0) = 2: MissionTitle = "Hanover hop / KRIC to KOFP"
        Case 12: origin = 2: route(0) = 0: MissionTitle = "Homeward / KOFP to KFCI"
        Case 13
            route(0) = 1: route(1) = 2: route(2) = 0: legs = 3
            MissionTitle = "Three-airport Richmond tour"
        Case 14: origin = 1: NavAirport = 1: approach = True
        Case 15: origin = 2: NavAirport = 2: approach = True
    End Select
    If Len(MissionTitle) > 0 Then
        MissionActive = True: MissionStage = 1: MissionLeg = 1
        NavAirport = route(0): missionConfigured = True
        MissionStatus = "Depart " & AirportCode(origin) & " and climb"
    End If
    index = PrimaryRunway(origin)
    along = -Runways(index).Length / 2 + 120
    Plane.heading = Runways(index).Heading
    If approach Then along = -Runways(index).Length / 2 - 2500
    RegionPoint index, along, 0, Plane.east, Plane.north
    Plane.altitude = Ground(Plane.east, Plane.north) + 1.2
    Plane.speed = 0: Plane.vertical = 0: Plane.throttle = 0.15
    Plane.grounded = True: Plane.pitch = 0: Plane.bank = 0: Plane.flaps = 0
    If approach Then
        Plane.altitude = TerrainGround(Runways(index).East, Runways(index).North) + 145
        Plane.speed = 34: Plane.vertical = -1.8: Plane.throttle = 0.34
        Plane.pitch = 0.035: Plane.flaps = 2: Plane.grounded = False
    End If
    ShowMap = True
End Sub

Public Sub UpdateMission(ByVal dt As Double)
    Dim i As Long, landedHere As Boolean, distance As Double
    If Not MissionActive Or ReplayActive Or Paused Then Exit Sub
    MissionElapsed = MissionElapsed + dt
    If Demo Then MissionAssisted = True
    If Plane.crashed Then
        MissionStatus = "Mission ended / aircraft damaged": MissionActive = False: MissionStage = 5
        Exit Sub
    End If
    distance = AirportDistance(NavAirport)
    If Not Plane.grounded And Plane.altitude - Ground(Plane.east, Plane.north) > 45 Then departed = True
    If departed Then
        MissionStage = 2: MissionStatus = "Navigate to " & AirportCode(NavAirport)
        If distance < 6000 Then
            MissionStage = 3: MissionStatus = "Land at " & AirportCode(NavAirport) & " and brake to a stop"
        End If
    End If
    For i = 0 To RunwayCount - 1
        If Runways(i).Airport = NavAirport And OnRegionRunway(i, Plane.east, Plane.north) Then landedHere = True
    Next
    If departed And Plane.grounded And landedHere And Plane.speed < 1.5 Then stopped = stopped + dt Else stopped = 0
    If stopped >= 3 Then
        If MissionLeg = legs Then
            MissionStage = 4: MissionStatus = "Mission complete / all landings recorded": MissionActive = False
        Else
            MissionLeg = MissionLeg + 1: NavAirport = route(MissionLeg - 1)
            stopped = 0: departed = False: MissionStage = 1
            MissionStatus = "Leg complete / depart for " & AirportCode(NavAirport)
        End If
    End If
End Sub

Public Sub CycleDestination()
    If MissionActive Or ReplayActive Then Exit Sub
    NavAirport = (NavAirport + 1) Mod 3
End Sub

Public Sub DrawNavigation()
    Dim index As Long, distance As Double, bearing As Double, track As Double, text As String, groundspeed As Double
    If ReplayActive Or (Scenario < 8 And Not ShowMap) Then Exit Sub
    index = PrimaryRunway(NavAirport)
    distance = AirportDistance(NavAirport)
    bearing = Wrap(Atan2(Runways(index).East - Plane.east, Runways(index).North - Plane.north))
    track = Wrap(bearing + 10 * PI / 180) * 180 / PI
    Box Canvas, 16, 65, 730, 47, RGB(13, 31, 38)
    text = AirportCode(NavAirport) & "  " & Format(distance / 1852, "0.0") & " NM  BRG " & Format(track, "000") & " M"
    groundspeed = GroundSpeedKnots() / 1.94384
    If groundspeed > 10 Then text = text & "  " & Format(distance / groundspeed / 60, "0") & " MIN"
    DrawText Canvas, 28, 72, text, 0, RGB(118, 222, 199)
    If missionConfigured Then
        DrawText Canvas, 28, 94, MissionStatus & "  [" & MissionLeg & "/" & legs & "]", 3
    Else
        DrawText Canvas, 28, 94, AirportName(NavAirport) & "  RWY " & Runways(index).Designator & "  / N next destination", 3
    End If
    If Abs(Plane.east) > 38000 Or Abs(Plane.north) > 38000 Then
        DrawText Canvas, 28, 139, IIf(Paused, "REGION LIMIT / R restart or Esc menu", "REGION EDGE / Turn toward the airports"), 0, RGB(255, 194, 91)
    End If
End Sub

Public Sub WriteMissionLog()
    Dim ws As Worksheet, candidate As Worksheet, row As Long, status As String
    If Not missionConfigured Or missionWritten Then Exit Sub
    On Error GoTo failed
    For Each candidate In ThisWorkbook.Worksheets
        If candidate.Name = "Mission log" Then Set ws = candidate: Exit For
    Next
    If ws Is Nothing Then
        Set ws = ThisWorkbook.Worksheets.Add(After:=ThisWorkbook.Worksheets(ThisWorkbook.Worksheets.Count))
        ws.Name = "Mission log"
    End If
    ws.Range("A1:G1").Value = Array("Recorded", "Mission", "Result", "Leg reached", "Elapsed minutes", "Assisted", "Weather")
    ws.Range("A1:G1").Font.Bold = True
    row = ws.Cells(ws.Rows.Count, 1).End(xlUp).row + 1
    status = MissionStatus
    If MissionActive Then status = "Ended before completion"
    ws.Cells(row, 1).Value = Now: ws.Cells(row, 1).NumberFormat = "yyyy-mm-dd hh:mm"
    ws.Cells(row, 2).Value2 = MissionTitle: ws.Cells(row, 3).Value2 = status
    ws.Cells(row, 4).Value2 = MissionLeg: ws.Cells(row, 5).Value2 = Round(MissionElapsed / 60, 1)
    ws.Cells(row, 6).Value2 = MissionAssisted: ws.Cells(row, 7).Value2 = Weather
    ws.Columns("A:G").AutoFit
    missionWritten = True
    Exit Sub
failed:
    ReviewError = "Mission log could not be written: " & Err.Description
End Sub

Public Function MissionSummary() As String
    If missionConfigured Then MissionSummary = MissionTitle & " / " & MissionStatus
End Function
