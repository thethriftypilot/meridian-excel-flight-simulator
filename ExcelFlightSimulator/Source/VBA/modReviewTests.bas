Attribute VB_Name = "modReviewTests"
Option Explicit
Private report As String
Private Sub AssertReview(ByVal label As String, ByVal ok As Boolean)
    report = report & IIf(ok, "PASS", "FAIL") & " | Review " & label & vbCrLf
End Sub
Private Sub ContactFixture()
    Demo = False: SetWeather 0: ResetFlight 2: StartRecording
    Plane.east = RunwayEast(-538.2): Plane.north = RunwayNorth(-538.2)
    Plane.altitude = Ground(Plane.east, Plane.north) + 1.21
    Plane.vertical = -0.8: Plane.pitch = 0.05: Plane.speed = 26: Plane.throttle = 0
    StepFlight 1# / 60: UpdateChallenge 1# / 60: RecordFrame
    StepFlight 1# / 60: UpdateChallenge 1# / 60: RecordFrame
End Sub
Public Function RunReviewTests() As String
    Dim i As Long, original As Double, count As Long, best As Double
    report = ""
    AssertReview "perfect rubric", ScoreLanding(0, 300, 0, 0, 0) = 100
    AssertReview "rubric bounded", ScoreLanding(8, -500, 30, 180, 2000) = 0
    AssertReview "softness monotonic", ScoreLanding(0.5, 300, 0, 0, 200) > ScoreLanding(2, 300, 0, 0, 200)
    AssertReview "runway coordinates", Abs(LateralRunway(RunwayEast(120, 7), RunwayNorth(120, 7)) - 7) < 0.000001
    ContactFixture
    AssertReview "contact captured before vertical reset", ContactCount = 1 And ContactSink > 0 And Plane.vertical = 0
    Plane.brake = True
    For i = 1 To 1200
        StepFlight 1# / 60: UpdateChallenge 1# / 60: RecordFrame
        If ChallengeComplete Then Exit For
    Next
    AssertReview "controlled stop completes", ChallengeComplete And ReviewEligible() And LandingScore > 0 And RolloutDistance > 20
    Call FinishRecording: WriteDebrief
    best = ThisWorkbook.Worksheets("Personal bests").Range("C2").Value2
    AssertReview "personal best stored", best = LandingScore And Len(ReviewError) = 0
    Assisted = True
    AssertReview "assisted cannot rank", Not ReviewEligible()
    FinishRecording
    Call ContactFixture: Plane.speed = 0: Plane.grounded = True: UpdateChallenge 2.1
    LandingScore = 1: FinishRecording: WriteDebrief
    AssertReview "lower score preserves personal best", ThisWorkbook.Worksheets("Personal bests").Range("C2").Value2 = best
    Call ContactFixture: Plane.heading = Wrap(RunwayHeading + PI)
    ContactHeading = 180: Plane.speed = 0: Plane.grounded = True: UpdateChallenge 2.1
    AssertReview "opposite runway direction excluded", Not ReviewEligible() And LandingScore = 0
    FinishRecording
    Call ContactFixture: Plane.east = RunwayEast(0, 30): Plane.north = RunwayNorth(0, 30)
    UpdateChallenge 0.1
    Plane.east = RunwayEast(0): Plane.north = RunwayNorth(0): Plane.speed = 0: Plane.grounded = True
    UpdateChallenge 2.1
    AssertReview "excursion stays invalid after return", ChallengeComplete And Not ReviewEligible() And LandingScore = 0
    FinishRecording
    Call ContactFixture: RegisterContact: Plane.speed = 0: Plane.grounded = True: UpdateChallenge 2.1
    AssertReview "bounce excluded", Not ReviewEligible() And LandingScore = 0 And ContactCount = 2
    FinishRecording
    Call ContactFixture: Plane.crashed = True: UpdateChallenge 0.1
    AssertReview "crash excluded", ChallengeComplete And Not ReviewEligible()
    FinishRecording
    ResetFlight 2: StartRecording: FinishRecording
    AssertReview "aborted challenge unscored", Not ChallengeComplete And Not ReviewEligible()
    ResetFlight 1: Plane.heading = 359 * PI / 180: StartRecording
    Plane.elapsed = 1: Plane.heading = PI / 180: Plane.east = Plane.east + 10: RecordFrame
    Plane.elapsed = 2: Plane.east = Plane.east + 10: RecordFrame: FinishRecording
    original = Plane.east: count = SampleCount
    AssertReview "replay available", BeginReplay()
    SeekReplay 0.5
    AssertReview "heading interpolates shortest arc", Abs(AngleDelta(Plane.heading, 0)) < 0.000001
    AssertReview "position interpolation", Abs(Plane.east - (original - 15)) < 0.000001
    Paused = True: AdvanceReplay 0.5
    AssertReview "pause freezes replay", ReplayTime = 0.5
    Call ClearInput: QueueKey 87, True: QueueKey 87, False: original = Plane.throttle: ApplyInput 0.2
    AssertReview "replay ignores flight controls", Plane.throttle = original
    SeekReplay -100: AssertReview "seek clamps start", ReplayTime = 0
    Paused = False: ReplayRate = 2: AdvanceReplay 2
    AssertReview "end pauses without overrunning", ReplayTime = 2 And Paused And SampleCount = count
    EndReplay
    AssertReview "replay restores live state", Not ReplayActive And Plane.elapsed = 2
    ResetFlight 1: StartRecording
    For i = 1 To 18002
        Plane.elapsed = i / 10: RecordFrame
    Next
    AssertReview "recorder bounded", SampleCount = 18001 And RecordingFull
    FinishRecording
    RunReviewTests = report
End Function
