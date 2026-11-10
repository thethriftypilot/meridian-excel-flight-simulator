Attribute VB_Name = "modScenery"
Option Explicit
'Generalized airport structures: locations follow the imagery's northeast apron.
'These are intentionally not surveyed building footprints or obstacle data.
Public Sub DrawAirportObjects()
    Dim i As Long, s As Double, lateral As Double
    If Sqr(Plane.east ^ 2 + Plane.north ^ 2) > Clamp(Visibility, 0, 4500) Then Exit Sub
    For i = 0 To 5
        s = -180 + i * 70: lateral = -235
        Hangar s, lateral, 44, 30, 8
    Next
    Hangar 280, -180, 55, 36, 10
End Sub
Private Sub Hangar(ByVal along As Double, ByVal lateral As Double, ByVal length As Double, ByVal width As Double, ByVal height As Double)
    Dim e(0 To 7) As Double, n(0 To 7) As Double, h(0 To 7) As Double
    Dim fe(0 To 3) As Double, fn(0 To 3) As Double, fh(0 To 3) As Double
    Dim i As Long, j As Long, k As Long, s As Double, t As Double, floor As Double, light As Double
    Dim ids As Variant, faces As Variant, color As Long
    floor = TerrainGround(RunwayEast(along, lateral), RunwayNorth(along, lateral))
    For i = 0 To 3
        s = along - length / 2: t = lateral - width / 2
        If i = 1 Or i = 2 Then s = along + length / 2
        If i >= 2 Then t = lateral + width / 2
        e(i) = RunwayEast(s, t): n(i) = RunwayNorth(s, t): h(i) = floor
        e(i + 4) = e(i): n(i + 4) = n(i): h(i + 4) = floor + height
    Next
    faces = Array(Array(0, 1, 5, 4), Array(1, 2, 6, 5), Array(2, 3, 7, 6), Array(3, 0, 4, 7), Array(4, 5, 6, 7))
    light = 1
    If Weather = 1 Then light = 0.78
    If Weather = 4 Then light = 0.2
    For j = 0 To 4
        ids = faces(j)
        For k = 0 To 3
            i = ids(k): fe(k) = e(i): fn(k) = n(i): fh(k) = h(i)
        Next
        color = RGB((110 + j * 13) * light, (119 + j * 12) * light, (123 + j * 11) * light)
        WorldFace fe, fn, fh, color
    Next
    If LandscapeDrawing Then
        Dim sign As Long, side As Long, peak As Double
        peak = height + width * 0.12
        For sign = -1 To 1 Step 2
            For i = 0 To 3
                s = along - length / 2 - 0.6
                If i = 1 Or i = 2 Then s = along + length / 2 + 0.6
                t = lateral: fh(i) = floor + peak
                If i < 2 Then t = lateral + sign * (width / 2 + 0.7): fh(i) = floor + height
                fe(i) = RunwayEast(s, t): fn(i) = RunwayNorth(s, t)
            Next
            color = RGB((168 + 17 * sign) * light, (164 + 17 * sign) * light, (147 + 17 * sign) * light)
            WorldFace fe, fn, fh, color
            s = along + sign * length / 2
            For i = 0 To 3
                t = lateral: fh(i) = floor + peak
                If i < 2 Then t = lateral + (2 * i - 1) * width / 2: fh(i) = floor + height
                fe(i) = RunwayEast(s, t): fn(i) = RunwayNorth(s, t)
            Next
            WorldFace fe, fn, fh, color
        Next
    End If
    'Inset dark hangar door on the runway-facing wall.
    For i = 0 To 3
        s = along - length * 0.38
        If i = 1 Or i = 2 Then s = along + length * 0.38
        fe(i) = RunwayEast(s, lateral + width / 2 + 0.05)
        fn(i) = RunwayNorth(s, lateral + width / 2 + 0.05)
        fh(i) = floor + 0.15
        If i >= 2 Then fh(i) = floor + height * 0.74
    Next
    WorldFace fe, fn, fh, RGB(42 * light, 55 * light, 60 * light)
End Sub
Public Function HitsAirportBuilding(ByVal east As Double, ByVal north As Double, ByVal altitude As Double) As Boolean
    Dim s As Double, t As Double, i As Long, along As Double
    s = AlongRunway(east, north)
    t = (east - RunwayCenterEast) * Cos(RunwayHeading) - (north - RunwayCenterNorth) * Sin(RunwayHeading)
    For i = 0 To 6
        along = -180 + i * 70
        If i < 6 Then
            If Abs(s - along) < 24 And Abs(t + 235) < 17 Then
                HitsAirportBuilding = altitude < TerrainGround(RunwayEast(along, -235), RunwayNorth(along, -235)) + 9.2
                Exit Function
            End If
        ElseIf Abs(s - 280) < 29.5 And Abs(t + 180) < 20 Then
            HitsAirportBuilding = altitude < TerrainGround(RunwayEast(280, -180), RunwayNorth(280, -180)) + 11.2
        End If
    Next
End Function
