Attribute VB_Name = "modDiagnostics"
Option Explicit
Private Type PROCESS_MEMORY_COUNTERS
    cb As Long
    PageFaultCount As Long
    PeakWorkingSetSize As LongPtr
    WorkingSetSize As LongPtr
    QuotaPeakPagedPoolUsage As LongPtr
    QuotaPagedPoolUsage As LongPtr
    QuotaPeakNonPagedPoolUsage As LongPtr
    QuotaNonPagedPoolUsage As LongPtr
    PagefileUsage As LongPtr
    PeakPagefileUsage As LongPtr
End Type
Private Declare PtrSafe Function GetProcessMemoryInfo Lib "psapi" (ByVal process As LongPtr, ByRef counters As PROCESS_MEMORY_COUNTERS, ByVal size As Long) As Long
Public Function WorkingSetMB() As Double
    Dim counters As PROCESS_MEMORY_COUNTERS
    counters.cb = LenB(counters)
    If GetProcessMemoryInfo(GetCurrentProcess(), counters, counters.cb) = 0 Then Err.Raise 5, , "Cannot read process memory"
    WorkingSetMB = counters.WorkingSetSize / 1048576#
End Function
'Native continuous renderer/audio soak, deliberately independent of desktop focus.
'This is a diagnostic harness, not a claim that physical controls were exercised.
Public Function RunSoak(Optional ByVal seconds As Double = 1200, Optional ByVal detailed As Boolean = False, Optional ByVal supersample As Boolean = False) As String
    Dim start As Double, previous As Double, current As Double, accumulator As Double, frameStart As Double
    Dim frames As Long, f As Integer, nextLog As Double, initialGDI As Long, peakGDI As Long, currentGDI As Long
    Dim initialMB As Double, peakMB As Double, memory As Double, errText As String, opened As Boolean
    Dim prefix As String, renderStart As Double, renderMS As Double, fastestBudget As Double
    Dim buckets(0 To 1000) As Long, bucket As Long, cumulative As Long, p95 As Long, worst As Double
    prefix = "soak": fastestBudget = 0.033
    If supersample Then detailed = True
    If detailed Then prefix = "graphics-soak": fastestBudget = 1# / 60
    If supersample Then prefix = "graphics-2x-soak"
    On Error GoTo failed
    errText = "load world": LoadWorld
    errText = "reset flight": ResetFlight 1: SetWeather 0
    Quality = 0: Volume = 0.2: Muted = False: Paused = False: Demo = True
    If detailed Then Quality = 2
    If supersample Then Quality = 3
    StartRecording
    errText = "show form": frmFlight.Show vbModeless: DoEvents
    errText = "renderer init": InitRenderer FindWindow(vbNullString, "Meridian | Excel Flight Simulator")
    errText = "audio init": StartAudio: Running = True
    errText = "first frame": Call RenderFrame: Present
    errText = "memory query": initialGDI = GetGuiResources(GetCurrentProcess(), 0): initialMB = WorkingSetMB()
    peakMB = initialMB: peakGDI = initialGDI
    f = FreeFile: Open ThisWorkbook.Path & "\Tests\" & prefix & ".csv" For Output As #f: opened = True
    Print #f, "wall_seconds,sim_seconds,frames,fps,working_set_mb,gdi_objects,audio_buffers,east,north,altitude,crashed,audio_state"
    start = Clock(): previous = start: nextLog = start
    errText = "soak loop"
    Do While Clock() - start < seconds And Running
        frameStart = Clock(): current = frameStart
        accumulator = accumulator + Clamp(current - previous, 0, 0.2): previous = current
        Do While accumulator >= 1# / 60
            Call DemoControls: StepFlight 1# / 60: accumulator = accumulator - 1# / 60
            RecordFrame
        Loop
        If Plane.crashed Or Paused Or Plane.altitude < 100 Or Plane.altitude > 2000 Then Err.Raise 5, , "Soak flight left stable envelope"
        'Cycle through every preset while using the actual demo controller and five views.
        If detailed Then
            SetWeather (Int((current - start) / 16) Mod 7)
            CameraMode = Int((current - start) / 3) Mod 5
        Else
            SetWeather (Int((current - start) / 45) Mod 7)
        End If
        renderStart = Clock()
        Call UpdateAudio: Call RenderFrame: Present: frames = frames + 1
        renderMS = (Clock() - renderStart) * 1000
        bucket = CLng(Int(Clamp(renderMS, 0, 1000)))
        buckets(bucket) = buckets(bucket) + 1
        If renderMS > worst Then worst = renderMS
        If detailed And Quality < 2 Then Err.Raise 5, , "Detailed renderer fell back: " & LandscapeError
        If current >= nextLog Then
            memory = WorkingSetMB(): currentGDI = GetGuiResources(GetCurrentProcess(), 0)
            If memory > peakMB Then peakMB = memory
            If currentGDI > peakGDI Then peakGDI = currentGDI
            FPS = frames / Clamp(current - start, 0.1, 100000)
            Print #f, Format(current - start, "0.00") & "," & Format(Plane.elapsed, "0.00") & "," & frames & "," & Format(FPS, "0.00") & "," & Format(memory, "0.00") & "," & currentGDI & "," & AudioBuffers & "," & Format(Plane.east, "0.0") & "," & Format(Plane.north, "0.0") & "," & Format(Plane.altitude, "0.0") & "," & Plane.crashed & "," & AudioDebug()
            nextLog = current + 10
        End If
        DoEvents
        If Clock() - frameStart < fastestBudget Then Sleep CLng(Clamp((fastestBudget - (Clock() - frameStart)) * 1000, 0, 33))
    Loop
    If Clock() - start < seconds Then Err.Raise 5, , "Soak interrupted before requested duration"
    If AudioBuffers < seconds * 4 Then Err.Raise 5, , "Audio refill stalled: " & AudioDebug()
    If SampleCount < Clamp(seconds * 8, 1, 18001) Then Err.Raise 5, , "Flight recorder stalled"
    RunSoak = "PASS | Native wall-clock soak | " & Format(Clock() - start, "0.0") & " s; " & frames & " frames; mean " & Format(frames / (Clock() - start), "0.00") & " FPS; peak working set " & Format(peakMB, "0.0") & " MB (initial " & Format(initialMB, "0.0") & "); peak GDI " & peakGDI & " (initial " & initialGDI & "); audio buffers " & AudioBuffers
    RunSoak = RunSoak & "; recorded samples " & SampleCount
    For bucket = 0 To 1000
        cumulative = cumulative + buckets(bucket)
        If cumulative >= frames * 0.95 Then p95 = bucket + 1: Exit For
    Next
    RunSoak = RunSoak & "; render/audio/present P95 below " & p95 & " ms; worst " & Format(worst, "0.0") & " ms"
    SaveFrame ThisWorkbook.Path & "\Tests\" & prefix & "-final.bmp"
cleanup:
    If opened Then Close #f
    Running = False: StopAudio: CloseRenderer: Unload frmFlight
    FinishRecording
    f = FreeFile: Open ThisWorkbook.Path & "\Tests\" & prefix & "-result.txt" For Output As #f
    Print #f, RunSoak: Close #f
    Exit Function
failed:
    RunSoak = "FAIL | Native wall-clock soak | " & Err.Number & " " & Err.Description & " at " & errText
    Resume cleanup
End Function
