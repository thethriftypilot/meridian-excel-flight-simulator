Attribute VB_Name = "modAircraftVisual"
Option Explicit
'Low-poly original PA-28-inspired model. Local axes: right, up, forward, metres.
Public Sub DrawChaseAircraft()
    AircraftFace Array(-0.55, 0, -3.3, 0.55, 0, -3.3, 0.65, 0, 1.9, -0.65, 0, 1.9), RGB(202, 211, 211)
    AircraftFace Array(-0.55, 0, -3.3, -0.3, 0.7, -3.3, -0.6, 1, 1.1, -0.65, 0, 1.9), RGB(211, 216, 207)
    AircraftFace Array(0.55, 0, -3.3, 0.3, 0.7, -3.3, 0.6, 1, 1.1, 0.65, 0, 1.9), RGB(230, 233, 219)
    AircraftFace Array(-0.3, 0.7, -3.3, 0.3, 0.7, -3.3, 0.6, 1, 1.1, -0.6, 1, 1.1), RGB(223, 228, 217)
    AircraftFace Array(-0.6, 1, 1.1, 0.6, 1, 1.1, 0.45, 0.5, 2.7, -0.45, 0.5, 2.7), RGB(234, 234, 221)
    AircraftFace Array(-0.5, 1.01, -0.3, 0.5, 1.01, -0.3, 0.6, 1.01, 1.1, -0.6, 1.01, 1.1), RGB(40, 71, 86)
    AircraftFace Array(-5.35, 0.05, -0.55, -0.55, -0.2, -0.7, -0.55, -0.2, 1.05, -5.35, 0.05, 0.8), RGB(224, 227, 215)
    AircraftFace Array(0.55, -0.2, -0.7, 5.35, 0.05, -0.55, 5.35, 0.05, 0.8, 0.55, -0.2, 1.05), RGB(240, 239, 224)
    AircraftFace Array(-5.35, 0.06, -0.55, -4.8, 0.03, -0.55, -4.8, 0.03, 0.8, -5.35, 0.06, 0.8), RGB(158, 39, 31)
    AircraftFace Array(4.8, 0.03, -0.55, 5.35, 0.06, -0.55, 5.35, 0.06, 0.8, 4.8, 0.03, 0.8), RGB(158, 39, 31)
    AircraftFace Array(-1.8, 0.35, -3.6, 1.8, 0.35, -3.6, 1.8, 0.35, -2.75, -1.8, 0.35, -2.75), RGB(231, 231, 216)
    AircraftFace Array(0, 0.5, -3.5, 0, 2.15, -3.5, 0, 1.7, -2.85, 0, 0.5, -2.1), RGB(159, 41, 32)
    'Fixed landing gear, represented as dark wheel/strut quads.
    AircraftFace Array(-1.1, -0.2, 0, -1.1, -1, 0, -1.1, -1, 0.5, -1.1, -0.2, 0.5), RGB(30, 35, 37)
    AircraftFace Array(1.1, -0.2, 0, 1.1, -1, 0, 1.1, -1, 0.5, 1.1, -0.2, 0.5), RGB(30, 35, 37)
End Sub
Private Sub AircraftFace(ByVal coordinates As Variant, ByVal color As Long)
    Dim e(0 To 3) As Double, n(0 To 3) As Double, h(0 To 3) As Double
    Dim i As Long, right As Double, up As Double, forward As Double, rolledRight As Double, rolledUp As Double, pitchedForward As Double
    For i = 0 To 3
        right = coordinates(i * 3): up = coordinates(i * 3 + 1): forward = coordinates(i * 3 + 2)
        rolledRight = right * Cos(Plane.bank) + up * Sin(Plane.bank)
        rolledUp = up * Cos(Plane.bank) - right * Sin(Plane.bank)
        pitchedForward = forward * Cos(Plane.pitch) - rolledUp * Sin(Plane.pitch)
        h(i) = Plane.altitude + forward * Sin(Plane.pitch) + rolledUp * Cos(Plane.pitch)
        e(i) = Plane.east + rolledRight * Cos(Plane.heading) + pitchedForward * Sin(Plane.heading)
        n(i) = Plane.north - rolledRight * Sin(Plane.heading) + pitchedForward * Cos(Plane.heading)
    Next
    If Weather = 4 Then color = RGB((color And 255) * 0.35, ((color \ 256) And 255) * 0.35, ((color \ 65536) And 255) * 0.35)
    WorldFace e, n, h, color
End Sub
