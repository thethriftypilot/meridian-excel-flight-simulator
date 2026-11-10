Attribute VB_Name = "modInput"
Option Explicit
Private lastKeys(0 To 255) As Boolean
Private queuedKeys(0 To 255) As Boolean, eventHeld(0 To 255) As Boolean
Private pulseUntil(0 To 255) As Double
Public Sub QueueKey(ByVal key As Long, ByVal down As Boolean)
    If key < 0 Or key > 255 Then Exit Sub
    If down And Not eventHeld(key) Then
        queuedKeys(key) = True
        pulseUntil(key) = Clock() + 0.1
    End If
    eventHeld(key) = down
End Sub
Public Function KeyDown(ByVal key As Long) As Boolean
    KeyDown = GetAsyncKeyState(key) < 0 Or Clock() < pulseUntil(key)
End Function
Private Function Pressed(ByVal key As Long) As Boolean
    Pressed = queuedKeys(key)
    queuedKeys(key) = False
End Function
Public Sub ClearInput()
    Erase lastKeys
    Erase queuedKeys: Erase eventHeld
    Erase pulseUntil
End Sub
Public Sub PollInput(ByVal dt As Double)
    Dim e As Double, a As Double, r As Double
    If GetForegroundWindow() <> SimHwnd Then
        Plane.elevator = 0: Plane.aileron = 0: Plane.rudder = 0: Plane.brake = False
        Exit Sub
    End If
    ApplyInput dt
End Sub
Public Sub ApplyInput(ByVal dt As Double)
    Dim e As Double, a As Double, r As Double
    If Pressed(27) Then Running = False
    If Pressed(80) Then Paused = Not Paused
    If Pressed(67) Then CameraMode = (CameraMode + 1) Mod 5
    If Pressed(77) Then ShowMap = Not ShowMap
    If Pressed(86) Then Muted = Not Muted
    If ReplayActive Then
        If Pressed(74) Then SeekReplay ReplayTime - 5
        If Pressed(76) Then SeekReplay ReplayTime + 5
        If Pressed(75) Then
            ReplayRate = ReplayRate * 2
            If ReplayRate > 2 Then ReplayRate = 0.5
        End If
        If Pressed(82) Then SeekReplay 0: Paused = False
        Exit Sub
    End If
    If Pressed(82) Then
        Call FinishRecording: WriteDebrief
        ResetFlight Scenario: Paused = False
        If Running Then StartRecording
    End If
    If Pressed(70) Then Plane.flaps = (Plane.flaps + 1) Mod 4: TriggerSound 3
    If Pressed(84) Then
        Demo = Not Demo
        If Recording Then Assisted = True
    End If
    If Pressed(69) And Not Paused Then
        Plane.engineRunning = Not Plane.engineRunning And Plane.fuel > 0
        If Plane.engineRunning Then TriggerSound 1 Else TriggerSound 3
    End If
    If Demo Or Paused Then Exit Sub
    e = -CInt(KeyDown(40)) + CInt(KeyDown(38))
    a = -CInt(KeyDown(39)) + CInt(KeyDown(37))
    r = -CInt(KeyDown(68)) + CInt(KeyDown(65))
    Plane.elevator = Plane.elevator + (e * Sensitivity - Plane.elevator) * Clamp(dt * 4, 0, 1)
    Plane.aileron = Plane.aileron + (a * Sensitivity - Plane.aileron) * Clamp(dt * 4, 0, 1)
    Plane.rudder = Plane.rudder + (r * Sensitivity - Plane.rudder) * Clamp(dt * 4, 0, 1)
    Plane.throttle = Clamp(Plane.throttle + (-CInt(KeyDown(87)) + CInt(KeyDown(83))) * dt * 0.3, 0, 1)
    Plane.trim = Clamp(Plane.trim + (-CInt(KeyDown(33)) + CInt(KeyDown(34))) * dt * 0.05, -0.15, 0.15)
    Plane.brake = KeyDown(32)
End Sub
