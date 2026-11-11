Attribute VB_Name = "modFlight"
Option Explicit
Public Type AircraftState
    east As Double
    north As Double
    altitude As Double
    speed As Double
    vertical As Double
    heading As Double
    pitch As Double
    bank As Double
    throttle As Double
    elevator As Double
    aileron As Double
    rudder As Double
    trim As Double
    rpm As Double
    fuel As Double
    flaps As Long
    alpha As Double
    elapsed As Double
    oilTemp As Double
    oilPressure As Double
    turnRate As Double
    slip As Double
    engineRunning As Boolean
    grounded As Boolean
    crashed As Boolean
    stalled As Boolean
    brake As Boolean
End Type
Public Plane As AircraftState
Public WindEast As Double, WindNorth As Double, Turbulence As Double, Visibility As Double
Public Weather As Long, Scenario As Long, CameraMode As Long
Public Demo As Boolean, Paused As Boolean, ShowMap As Boolean, Muted As Boolean
Public Sensitivity As Double, Volume As Double, Touchdown As Double, Quality As Long
Public Sub SetWeather(ByVal preset As Long)
    Weather = preset: Visibility = 11000: WindEast = 0: WindNorth = 0: Turbulence = 0
    If preset = 1 Then Visibility = 8000
    If preset = 2 Then WindEast = 4: WindNorth = 1: Turbulence = 0.3
    If preset = 3 Then Visibility = 2200: Turbulence = 0.15
    If preset = 4 Then Visibility = 7000
    If preset = 5 Then Visibility = 4000: WindEast = 2: Turbulence = 0.4
    If preset = 6 Then Visibility = 2800: WindEast = 3: WindNorth = -2: Turbulence = 0.5
End Sub
Public Sub ResetFlight(ByVal which As Long)
    Dim blank As AircraftState
    Plane = blank: Plane.engineRunning = True: Scenario = which: Touchdown = 0
    Plane.heading = RunwayHeading: Plane.fuel = 136: Plane.rpm = 700
    Plane.east = RunwayEast(-720): Plane.north = RunwayNorth(-720)
    Plane.altitude = Ground(Plane.east, Plane.north) + 1.2: Plane.grounded = True
    Plane.throttle = 0.15: Plane.trim = 0: CameraMode = 0
    Plane.oilTemp = 65
    If which = 1 Or which = 3 Or which = 4 Or which = 5 Then
        Plane.east = -2200: Plane.north = -1800: Plane.altitude = 520
        Plane.speed = 53: Plane.throttle = 0.64: Plane.pitch = 0.035: Plane.grounded = False
        Plane.heading = 0.6
    ElseIf which = 2 Or which = 7 Then
        Plane.east = RunwayEast(-3300): Plane.north = RunwayNorth(-3300)
        Plane.altitude = 215: Plane.speed = 34: Plane.vertical = -1.8
        Plane.throttle = 0.34: Plane.flaps = 2: Plane.pitch = 0.035: Plane.grounded = False
    ElseIf which = 6 Then
        Plane.east = RunwayEast(0, -155): Plane.north = RunwayNorth(0, -155): Plane.altitude = Ground(Plane.east, Plane.north) + 1.2
    End If
    SetupMission which
    Plane.rpm = 700 + Plane.throttle * 2000
    Plane.oilPressure = 25 + Plane.rpm * 0.019
End Sub
Public Sub StepFlight(ByVal dt As Double)
    Dim density As Double, q As Double, cl As Double, cd As Double, lift As Double, drag As Double
    Dim thrust As Double, gamma As Double, mass As Double, floor As Double, accel As Double
    Dim targetPitch As Double, yawRate As Double, wasGrounded As Boolean
    If Plane.crashed Then Exit Sub
    Plane.elapsed = Plane.elapsed + dt
    wasGrounded = Plane.grounded
    If Plane.fuel <= 0 Then Plane.engineRunning = False
    If Plane.engineRunning Then
        Plane.rpm = Plane.rpm + (700 + Plane.throttle * 2000 - Plane.rpm) * dt * 2
    Else
        Plane.rpm = Plane.rpm * Exp(-dt * 1.5)
    End If
    Plane.oilTemp = Plane.oilTemp + (65 + Plane.throttle * 45 - Plane.speed * 0.12 - Plane.oilTemp) * dt / 90
    Plane.oilPressure = Clamp((25 + Plane.rpm * 0.019 - (Plane.oilTemp - 90) * 0.08) * Clamp(Plane.rpm / 700, 0, 1), 0, 100)
    If Plane.engineRunning Then Plane.fuel = Clamp(Plane.fuel - (0.001 + 0.008 * Plane.throttle) * dt, 0, 136)
    mass = 890 + Plane.fuel * 0.72
    gamma = Atan2(Plane.vertical, Plane.speed)
    Plane.alpha = Plane.pitch - gamma
    density = 1.225 * Exp(-Plane.altitude / 8500)
    q = 0.5 * density * (Plane.speed ^ 2 + Plane.vertical ^ 2)
    cl = 0.25 + 4.8 * Plane.alpha + Plane.flaps * 0.16
    Plane.stalled = Abs(Plane.alpha) > 0.28 And Plane.speed > 12 And Not Plane.grounded
    If Abs(Plane.alpha) > 0.28 Then cl = Sgn(cl) * (1.55 + Plane.flaps * 0.16) * Exp(-(Abs(Plane.alpha) - 0.28) * 3)
    cl = Clamp(cl, -1.4, 1.8)
    cd = 0.032 + 0.058 * cl * cl + Plane.flaps * 0.016
    If Plane.stalled Then cd = cd + 0.18
    lift = q * 15.8 * cl: drag = q * 15.8 * cd
    thrust = Plane.throttle * 119312 * 0.72 / Clamp(Plane.speed, 26, 150)
    If Not Plane.engineRunning Then thrust = 0
    targetPitch = 0.035 + Plane.elevator * 0.35 + Plane.trim
    If Plane.grounded Then targetPitch = Clamp(Plane.elevator * 0.32 + Plane.trim, -0.02, 0.22) * Clamp(Plane.speed / 26, 0, 1)
    Plane.pitch = Plane.pitch + Clamp(targetPitch - Plane.pitch, -0.4, 0.4) * dt * 1.8
    Plane.bank = Clamp(Plane.bank + (Plane.aileron * 0.8 - Plane.bank * 0.08) * dt, -1.25, 1.25)
    If Plane.grounded Then Plane.bank = 0
    yawRate = lift * Sin(Plane.bank) / (mass * Clamp(Plane.speed, 12, 200)) + Plane.rudder * 0.1
    If Plane.grounded Then yawRate = Plane.rudder * Clamp(Plane.speed / 15, 0, 1) * 0.45
    Plane.heading = Wrap(Plane.heading + yawRate * dt)
    Plane.turnRate = yawRate
    Plane.slip = Clamp((yawRate * Plane.speed - lift * Sin(Plane.bank) / mass) / 9.80665, -1, 1)
    accel = (thrust * Cos(Plane.alpha) - drag - lift * Sin(gamma)) / mass
    If Plane.grounded Then
        accel = (thrust - drag) / mass - 0.25
        If Plane.brake Then accel = accel - 4.8
    End If
    Plane.speed = Clamp(Plane.speed + accel * dt, 0, 140)
    Plane.vertical = Plane.vertical + ((lift * Cos(Plane.bank) * Cos(gamma) + thrust * Sin(Plane.pitch) - drag * Sin(gamma)) / mass - 9.80665) * dt
    If Plane.grounded And Plane.vertical < 0 Then Plane.vertical = 0
    If Plane.grounded And Plane.vertical > 0.2 Then Plane.grounded = False
    If Not Plane.grounded Then Plane.vertical = Plane.vertical + Turbulence * Sin(Plane.elapsed * 3.7) * dt
    Plane.east = Plane.east + (Plane.speed * Sin(Plane.heading) + IIf(Plane.grounded, 0, WindEast)) * dt
    Plane.north = Plane.north + (Plane.speed * Cos(Plane.heading) + IIf(Plane.grounded, 0, WindNorth)) * dt
    Plane.altitude = Plane.altitude + Plane.vertical * dt
    floor = Ground(Plane.east, Plane.north) + 1.2
    If Plane.altitude <= floor Then
        If Not wasGrounded Then
            RegisterContact
            Touchdown = Abs(Plane.vertical)
            TriggerSound 2, Clamp(Touchdown / 3.2, 0.15, 1)
            If Plane.vertical < -3.2 Or Abs(Plane.bank) > 0.2 Or Plane.pitch < -0.09 Or Plane.pitch > 0.28 Then Plane.crashed = True
            If Not OnAnyRunway(Plane.east, Plane.north) And Plane.speed > 16 Then Plane.crashed = True
        End If
        Plane.altitude = floor: Plane.vertical = 0: Plane.grounded = True
    End If
    If HitsAirportBuilding(Plane.east, Plane.north, Plane.altitude) Then Plane.crashed = True
    If Abs(Plane.east) > 40000 Or Abs(Plane.north) > 40000 Then Paused = True
End Sub
Public Sub DemoControls()
    Dim desiredBank As Double, altitudeError As Double
    desiredBank = 0.23 + 0.06 * Sin(Plane.elapsed * 0.025)
    If Abs(Plane.east) > 7000 Or Abs(Plane.north) > 7000 Then desiredBank = 0.45
    Plane.aileron = Clamp((desiredBank - Plane.bank) * 2, -0.7, 0.7)
    altitudeError = 520 - Plane.altitude
    Plane.elevator = Clamp(altitudeError * 0.002 - Plane.vertical * 0.06, -0.5, 0.5)
    Plane.throttle = Clamp(0.64 + (53 - Plane.speed) * 0.025, 0.3, 1)
    Plane.rudder = 0
    CameraMode = (Int(Plane.elapsed / 18) Mod 5)
End Sub

Public Function GroundSpeedKnots() As Double
    Dim e As Double, n As Double
    e = Plane.speed * Sin(Plane.heading): n = Plane.speed * Cos(Plane.heading)
    If Not Plane.grounded Then e = e + WindEast: n = n + WindNorth
    GroundSpeedKnots = Sqr(e * e + n * n) * 1.94384
End Function
