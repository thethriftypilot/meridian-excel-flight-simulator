Attribute VB_Name = "modReview"
Option Explicit
'Bounded, in-memory 10 Hz flight recorder. Physics events are captured at 60 Hz.
Private Const MaxSamples As Long = 18001
Private frames(0 To MaxSamples - 1) As AircraftState
Public SampleCount As Long, Recording As Boolean, ReplayActive As Boolean
Public ReplayTime As Double, ReplayRate As Double, RecordingFull As Boolean
Public ChallengeActive As Boolean, ChallengeComplete As Boolean, Assisted As Boolean
Public ContactCount As Long, LandingScore As Long
Public ContactSink As Double, ContactAlong As Double, ContactLateral As Double
Public ContactHeading As Double, ContactSpeed As Double, RolloutDistance As Double
Public ReviewStatus As String, ReviewError As String
Private recordedWeather As Long, recordedScenario As Long, stopTime As Double
Private contactEast As Double, contactNorth As Double, previousEast As Double, previousNorth As Double
Private excursion As Boolean, failedFlight As Boolean, lastSample As Double, reviewWritten As Boolean
Private savedPlane As AircraftState, savedWeather As Long, savedCamera As Long, savedDemo As Boolean
Private savedPause As Boolean, savedMap As Boolean

Public Function LateralRunway(ByVal east As Double, ByVal north As Double) As Double
    LateralRunway = (east - RunwayCenterEast) * Cos(RunwayHeading) - (north - RunwayCenterNorth) * Sin(RunwayHeading)
End Function
Public Function AngleDelta(ByVal a As Double, ByVal b As Double) As Double
    AngleDelta = Wrap(a - b + PI) - PI
End Function
Public Sub StartRecording()
    SampleCount = 0: RecordingFull = False: ContactCount = 0: LandingScore = 0
    ContactSink = 0: ContactAlong = 0: ContactLateral = 0: ContactHeading = 0: ContactSpeed = 0
    RolloutDistance = 0: stopTime = 0: excursion = False: failedFlight = False
    ChallengeActive = (Scenario = 2 Or Scenario = 7)
    ChallengeComplete = False: Assisted = Demo: reviewWritten = False: ReviewError = ""
    recordedWeather = Weather: recordedScenario = Scenario
    ReviewStatus = "Flight ended before a completed landing"
    Recording = True: lastSample = -1
    RecordFrame True
End Sub
Public Sub RecordFrame(Optional ByVal force As Boolean = False)
    If Not Recording Or ReplayActive Then Exit Sub
    If Demo Then Assisted = True
    If Plane.elapsed <= lastSample Then Exit Sub
    If Not force And Plane.elapsed - lastSample < 0.099999 Then Exit Sub
    If SampleCount >= MaxSamples Then
        RecordingFull = True
        Exit Sub
    End If
    frames(SampleCount) = Plane: SampleCount = SampleCount + 1: lastSample = Plane.elapsed
End Sub
Public Sub RegisterContact()
    If Not Recording Or ReplayActive Or ChallengeComplete Then Exit Sub
    ContactCount = ContactCount + 1
    If ContactCount = 1 Then
        ContactSink = Abs(Plane.vertical): ContactAlong = AlongRunway(Plane.east, Plane.north) + 838.2
        ContactLateral = Abs(LateralRunway(Plane.east, Plane.north))
        ContactHeading = Abs(AngleDelta(Plane.heading, RunwayHeading)) * 180 / PI
        ContactSpeed = Plane.speed * 1.94384
        contactEast = Plane.east: contactNorth = Plane.north
        previousEast = Plane.east: previousNorth = Plane.north
    End If
End Sub
Public Sub UpdateChallenge(ByVal dt As Double)
    If Not Recording Or ReplayActive Or ChallengeComplete Then Exit Sub
    If Demo Then Assisted = True
    If Plane.crashed Then failedFlight = True
    If ContactCount > 0 Then
        RolloutDistance = RolloutDistance + Sqr((Plane.east - previousEast) ^ 2 + (Plane.north - previousNorth) ^ 2)
        previousEast = Plane.east: previousNorth = Plane.north
        If Not OnRunway(Plane.east, Plane.north) Then excursion = True
        If Plane.grounded And Plane.speed < 1 Then stopTime = stopTime + dt Else stopTime = 0
    End If
    If Not ChallengeActive Then Exit Sub
    If Plane.crashed Then
        ChallengeComplete = True: ReviewStatus = "Unsuccessful: impact exceeded simulator limits"
    ElseIf stopTime >= 2 Then
        ChallengeComplete = True
        If excursion Then
            ReviewStatus = "Unsuccessful: runway excursion"
        ElseIf ContactCount > 1 Then
            ReviewStatus = "Unsuccessful: bounced landing"
        ElseIf ContactHeading >= 45 Then
            ReviewStatus = "Unsuccessful: wrong landing direction"
        Else
            LandingScore = ScoreLanding(ContactSink, ContactAlong, ContactLateral, ContactHeading, RolloutDistance)
            ReviewStatus = "Completed landing"
        End If
    End If
End Sub
Public Function ScoreLanding(ByVal sink As Double, ByVal along As Double, ByVal lateral As Double, ByVal heading As Double, ByVal rollout As Double) As Long
    'Entertainment rubric: 30 smoothness + 25 target + 20 centerline + 15 heading + 10 stop.
    ScoreLanding = CLng(30 * Clamp(1 - sink / 3.2, 0, 1) + 25 * Clamp(1 - Abs(along - 300) / 450, 0, 1) + 20 * Clamp(1 - Abs(lateral) / 15.24, 0, 1) + 15 * Clamp(1 - Abs(heading) / 30, 0, 1) + 10 * Clamp(1 - rollout / 1200, 0, 1))
End Function
Public Function ReviewEligible() As Boolean
    ReviewEligible = ChallengeActive And ChallengeComplete And Not Assisted And Not excursion And Not failedFlight And ContactCount = 1 And ContactHeading < 45
End Function
Public Sub FinishRecording()
    If Not Recording Then Exit Sub
    RecordFrame True: Recording = False
    If Not ChallengeActive Then ReviewStatus = "Free flight / unscored"
    If Assisted Then ReviewStatus = ReviewStatus & " (assisted / no personal best)"
End Sub
Public Function ReplayDuration() As Double
    If SampleCount > 0 Then ReplayDuration = frames(SampleCount - 1).elapsed
End Function
Public Function BeginReplay() As Boolean
    If Recording Or SampleCount < 2 Or ReplayActive Then Exit Function
    savedPlane = Plane: savedWeather = Weather: savedCamera = CameraMode
    savedDemo = Demo: savedPause = Paused: savedMap = ShowMap
    ReplayActive = True: ReplayTime = 0: ReplayRate = 1: Demo = False: Paused = False
    SetWeather recordedWeather: CameraMode = 2
    SeekReplay 0
    BeginReplay = True
End Function
Public Sub SeekReplay(ByVal seconds As Double)
    Dim lo As Long, hi As Long, mid As Long, f As Double, a As AircraftState, b As AircraftState
    If Not ReplayActive Or SampleCount < 2 Then Exit Sub
    ReplayTime = Clamp(seconds, 0, ReplayDuration())
    lo = 0: hi = SampleCount - 1
    Do While hi - lo > 1
        mid = (lo + hi) \ 2
        If frames(mid).elapsed <= ReplayTime Then lo = mid Else hi = mid
    Loop
    a = frames(lo): b = frames(hi)
    f = Clamp((ReplayTime - a.elapsed) / (b.elapsed - a.elapsed), 0, 1)
    Plane = a
    If f >= 1 Then Plane = b
    Plane.east = a.east + (b.east - a.east) * f: Plane.north = a.north + (b.north - a.north) * f
    Plane.altitude = a.altitude + (b.altitude - a.altitude) * f
    Plane.heading = Wrap(a.heading + AngleDelta(b.heading, a.heading) * f)
    Plane.pitch = a.pitch + (b.pitch - a.pitch) * f: Plane.bank = a.bank + (b.bank - a.bank) * f
    Plane.speed = a.speed + (b.speed - a.speed) * f: Plane.vertical = a.vertical + (b.vertical - a.vertical) * f
    Plane.rpm = a.rpm + (b.rpm - a.rpm) * f: Plane.elapsed = ReplayTime
End Sub
Public Sub AdvanceReplay(ByVal dt As Double)
    If Not ReplayActive Or Paused Then Exit Sub
    SeekReplay ReplayTime + dt * ReplayRate
    If ReplayTime >= ReplayDuration() Then Paused = True
End Sub
Public Sub EndReplay()
    If Not ReplayActive Then Exit Sub
    Plane = savedPlane: SetWeather savedWeather: CameraMode = savedCamera
    Demo = savedDemo: Paused = savedPause: ShowMap = savedMap: ReplayActive = False
End Sub
Public Sub WatchReplay()
    Dim last As Double, now As Double, started As Double, oldStatus As Variant, message As String
    If Running Then Exit Sub
    If Not BeginReplay() Then
        MsgBox "Fly first. Replay keeps the latest flight in this Excel session.", vbInformation, "Meridian replay"
        Exit Sub
    End If
    On Error GoTo failed
    oldStatus = Application.StatusBar
    frmMenu.Hide: MenuOpen = False
    frmFlight.StartUpPosition = 0: frmFlight.Left = Application.Left: frmFlight.Top = Application.Top
    frmFlight.Width = Application.Width: frmFlight.Height = Application.Height
    frmFlight.Show vbModeless: DoEvents
    InitRenderer FindWindow(vbNullString, "Meridian | Excel Flight Simulator")
    Running = True: ClearInput
    Application.StatusBar = "Replay: P pause, J/L seek 5 seconds, K speed, R restart, C camera, Esc menu."
    last = Clock()
    Do While Running
        started = Clock(): now = started
        PollInput Clamp(now - last, 0, 0.2)
        If GetForegroundWindow() = SimHwnd Then AdvanceReplay Clamp(now - last, 0, 0.2)
        last = now
        Call RenderFrame: Present: DoEvents
        If Clock() - started < 0.033 Then Sleep CLng((0.033 - (Clock() - started)) * 1000)
    Loop
cleanup:
    Running = False: CloseRenderer: Unload frmFlight: EndReplay
    Application.StatusBar = oldStatus
    If Len(message) > 0 Then MsgBox message, vbExclamation, "Meridian replay"
    frmMenu.Show vbModeless
    Exit Sub
failed:
    message = "Replay stopped safely: " & Err.Description
    Resume cleanup
End Sub
Public Sub DrawReviewHUD()
    If ReplayActive Then
        Box Canvas, 0, 0, 1000, 31, RGB(23, 47, 60)
        DrawText Canvas, 16, 8, "REPLAY " & Format(ReplayTime, "0.0") & " / " & Format(ReplayDuration(), "0.0") & " SEC  " & Format(ReplayRate, "0.0") & "x  C CAMERA  J/L SEEK  K SPEED  P PAUSE  ESC MENU"
        Box Canvas, 0, 674, 1000, 26, RGB(12, 28, 36)
        DrawText Canvas, 24, 682, "REPLAY / J L SEEK  K SPEED  P PLAY/PAUSE  R RESTART  C CAMERA  M MAP  ESC MENU", 3
    ElseIf ChallengeActive And Recording Then
        Box Canvas, 12, 88, 730, 45, RGB(12, 28, 36)
        If ChallengeComplete Then
            DrawText Canvas, 22, 95, ReviewStatus & " | " & LandingScore & "/100"
            DrawText Canvas, 22, 115, "Esc menu / VIEW DEBRIEF for analysis and replay", 3
        ElseIf ContactCount > 0 Then
            DrawText Canvas, 22, 95, "LANDING CHALLENGE | Brake to a stop on the runway"
            DrawText Canvas, 22, 115, "Sink " & Format(ContactSink * 196.85, "0") & " FPM / offset " & Format(ContactLateral, "0.0") & " m / rollout " & Format(RolloutDistance, "0") & " m", 3
        Else
            DrawText Canvas, 22, 95, "RWY 15 CHALLENGE | Aim 300 m beyond threshold, land, then stop"
            DrawText Canvas, 22, 115, "Entertainment score only / W S power / arrows fly / A D rudder / Space brakes", 3
        End If
    End If
End Sub

Private Function ReviewSheet(ByVal title As String) As Worksheet
    Dim ws As Worksheet
    For Each ws In ThisWorkbook.Worksheets
        If ws.Name = title Then Set ReviewSheet = ws: Exit Function
    Next
    Set ws = ThisWorkbook.Worksheets.Add(After:=ThisWorkbook.Worksheets(ThisWorkbook.Worksheets.Count))
    ws.Name = title: Set ReviewSheet = ws
End Function
Public Sub WriteDebrief()
    Dim ws As Worksheet, data As Worksheet, best As Worksheet, rows() As Variant
    Dim i As Long, chart As ChartObject, s As Series, keyRow As Long, n As Long, button As Shape
    If SampleCount < 2 Or reviewWritten Then Exit Sub
    On Error GoTo failed
    Set ws = ReviewSheet("Debrief"): Set data = ReviewSheet("Flight data"): Set best = ReviewSheet("Personal bests")
    ws.Cells.Clear: data.Cells.Clear
    Do While ws.ChartObjects.Count > 0: ws.ChartObjects(1).Delete: Loop
    Do While ws.Shapes.Count > 0: ws.Shapes(1).Delete: Loop
    ws.Range("A1:N48").Interior.Color = RGB(244, 247, 249)
    ws.Range("A1:N48").Font.Name = "Segoe UI": ws.Range("A1:N48").Font.Color = RGB(23, 44, 61)
    ws.Columns("A:N").ColumnWidth = 12: ws.Rows("1:48").RowHeight = 22
    ws.Range("B2:M3").Merge: ws.Range("B2").Value2 = "MERIDIAN / FLIGHT DEBRIEF"
    ws.Range("B2").Font.Size = 26
    ws.Range("B5:M5").Merge: ws.Range("B5").Value2 = ReviewStatus: ws.Range("B5").Font.Bold = True
    ws.Range("B7:D7").Merge: ws.Range("B7").Value2 = "GAME SCORE"
    ws.Range("F7:H7").Merge: ws.Range("F7").Value2 = "RECORDED SECONDS"
    ws.Range("J7:M7").Merge: ws.Range("J7").Value2 = "CONTACTS"
    ws.Range("B8:D9").Merge: ws.Range("F8:H9").Merge: ws.Range("J8:M9").Merge
    ws.Range("B8").Value2 = IIf(ChallengeComplete, CStr(LandingScore) & " / 100", "Unscored")
    ws.Range("F8").Value2 = Round(ReplayDuration(), 1): ws.Range("J8").Value2 = ContactCount
    ws.Range("B8:M9").Font.Size = 26
    ws.Range("B11:E11").Merge: ws.Range("B11").Value2 = "Touchdown descent (ft/min)"
    ws.Range("B12:E12").Merge: ws.Range("B12").Value2 = "Beyond RWY 15 threshold (m)"
    ws.Range("B13:E13").Merge: ws.Range("B13").Value2 = "Centerline offset (m)"
    ws.Range("H11:K11").Merge: ws.Range("H11").Value2 = "Heading error (degrees)"
    ws.Range("H12:K12").Merge: ws.Range("H12").Value2 = "Touchdown airspeed (knots)"
    ws.Range("H13:K13").Merge: ws.Range("H13").Value2 = "Distance after first contact (m)"
    If ContactCount > 0 Then
        ws.Range("F11").Value2 = ContactSink * 196.85: ws.Range("F12").Value2 = ContactAlong
        ws.Range("F13").Value2 = ContactLateral: ws.Range("L11").Value2 = ContactHeading
        ws.Range("L12").Value2 = ContactSpeed: ws.Range("L13").Value2 = RolloutDistance
    Else
        ws.Range("F11:F13").Value2 = "n.a.": ws.Range("L11:L13").Value2 = "n.a."
    End If
    ws.Range("F11:F13,L11:L13").NumberFormat = "0.0"
    ws.Range("B15:M16").Merge: ws.Range("B15").WrapText = True
    ws.Range("B15").Value2 = "Game rubric: smoothness 30, target zone 25, centerline 20, heading 15, stop 10. Not a flight-training assessment. See Documentation/CHALLENGES.md."
    ws.Range("B18:M19").Merge: ws.Range("B18").WrapText = True
    ws.Range("B18").Value2 = "Replay: C camera, P pause, J/L seek 5 seconds, K speed, R restart. Replay is silent and available until the next flight or workbook close. Save the workbook to retain this debrief and personal bests."
    If RecordingFull Then ws.Range("B20").Value2 = "Recorder reached its 30-minute limit; replay and charts show the recorded portion."
    ReDim rows(1 To SampleCount + 1, 1 To 7)
    rows(1, 1) = "Time (s)": rows(1, 2) = "East (m)": rows(1, 3) = "North (m)"
    rows(1, 4) = "Altitude (ft MSL)": rows(1, 5) = "Airspeed (kt)": rows(1, 6) = "Vertical (ft/min)": rows(1, 7) = "Grounded"
    For i = 0 To SampleCount - 1
        rows(i + 2, 1) = frames(i).elapsed: rows(i + 2, 2) = frames(i).east: rows(i + 2, 3) = frames(i).north
        rows(i + 2, 4) = frames(i).altitude * 3.28084: rows(i + 2, 5) = frames(i).speed * 1.94384
        rows(i + 2, 6) = frames(i).vertical * 196.85: rows(i + 2, 7) = frames(i).grounded
    Next
    n = SampleCount + 1: data.Range("A1").Resize(n, 7).Value2 = rows
    data.Range("A1:G1").Font.Bold = True: data.Range("A2:F" & n).NumberFormat = "0.0": data.Columns("A:G").AutoFit
    Set chart = ws.ChartObjects.Add(ws.Range("B23").Left, ws.Range("B23").Top, ws.Range("H23").Left - ws.Range("B23").Left - 12, 270)
    With chart.Chart
        .ChartType = xlXYScatterLinesNoMarkers: .HasLegend = False: .HasTitle = True: .ChartTitle.Text = "Flight path (local metres)"
        Set s = .SeriesCollection.NewSeries: s.XValues = data.Range("B2:B" & n): s.Values = data.Range("C2:C" & n)
        .Axes(xlCategory).HasTitle = True: .Axes(xlCategory).AxisTitle.Text = "East (m)"
        .Axes(xlValue).HasTitle = True: .Axes(xlValue).AxisTitle.Text = "North (m)"
        .Axes(xlValue).Crosses = xlAxisCrossesMinimum
    End With
    Set chart = ws.ChartObjects.Add(ws.Range("H23").Left, ws.Range("H23").Top, ws.Range("N23").Left - ws.Range("H23").Left, 270)
    With chart.Chart
        .ChartType = xlXYScatterLinesNoMarkers: .HasLegend = False: .HasTitle = True: .ChartTitle.Text = "Altitude profile"
        Set s = .SeriesCollection.NewSeries: s.XValues = data.Range("A2:A" & n): s.Values = data.Range("D2:D" & n)
        .Axes(xlCategory).HasTitle = True: .Axes(xlCategory).AxisTitle.Text = "Elapsed seconds"
        .Axes(xlValue).HasTitle = True: .Axes(xlValue).AxisTitle.Text = "Feet MSL"
    End With
    best.Range("A1:E1").Value = Array("Scenario", "Weather preset", "Best game score", "Completed", "Rule version")
    best.Range("A1:E1").Font.Bold = True
    If ReviewEligible() Then
        keyRow = 2
        Do While Len(best.Cells(keyRow, 1).Value2) > 0
            If best.Cells(keyRow, 1).Value2 = recordedScenario And best.Cells(keyRow, 2).Value2 = recordedWeather Then Exit Do
            keyRow = keyRow + 1
        Loop
        If Len(best.Cells(keyRow, 3).Value2) = 0 Or LandingScore > Val(best.Cells(keyRow, 3).Value2) Then
            best.Cells(keyRow, 1).Value2 = recordedScenario: best.Cells(keyRow, 2).Value2 = recordedWeather
            best.Cells(keyRow, 3).Value2 = LandingScore: best.Cells(keyRow, 4).Value = Now
            best.Cells(keyRow, 4).NumberFormat = "yyyy-mm-dd hh:mm": best.Cells(keyRow, 5).Value2 = "0.4"
        End If
        ws.Range("B21").Value2 = "Personal best for this scenario/weather: " & best.Cells(keyRow, 3).Value2 & " / 100"
    End If
    best.Columns("A:E").AutoFit
    Set button = ws.Shapes.AddShape(5, ws.Range("B38").Left, ws.Range("B38").Top, 220, 38)
    button.TextFrame2.TextRange.Text = "REPLAY LAST FLIGHT": button.OnAction = "WatchReplay"
    Set button = ws.Shapes.AddShape(5, ws.Range("F38").Left, ws.Range("F38").Top, 220, 38)
    button.TextFrame2.TextRange.Text = "OPEN FLIGHT MENU": button.OnAction = "LaunchSimulator"
    ConfigureDebriefPrint ws
    reviewWritten = True
    Exit Sub
failed:
    ReviewError = "Debrief could not be written: " & Err.Description
End Sub
Private Sub ConfigureDebriefPrint(ByVal ws As Worksheet)
    'Printer capabilities vary. Optional print setup must never prevent the sheet report.
    On Error Resume Next
    ws.PageSetup.PrintArea = "$A$1:$N$41": ws.PageSetup.Orientation = xlLandscape
    ws.PageSetup.PaperSize = xlPaperLetter
    ws.PageSetup.LeftMargin = 18: ws.PageSetup.RightMargin = 18
    ws.PageSetup.TopMargin = 18: ws.PageSetup.BottomMargin = 18
    ws.PageSetup.CenterHorizontally = True
    ws.PageSetup.Zoom = False: ws.PageSetup.FitToPagesWide = 1: ws.PageSetup.FitToPagesTall = 1
End Sub
Public Sub ShowDebrief()
    If Running Then Exit Sub
    If SampleCount >= 2 Then WriteDebrief
    If Len(ReviewError) > 0 Then MsgBox ReviewError, vbExclamation, "Meridian": Exit Sub
    Dim ws As Worksheet
    For Each ws In ThisWorkbook.Worksheets
        If ws.Name = "Debrief" Then
            frmMenu.Hide: MenuOpen = False: ws.Activate: ws.Range("A1").Select
            Exit Sub
        End If
    Next
    MsgBox "Fly first, then return here for your debrief.", vbInformation, "Meridian"
End Sub
