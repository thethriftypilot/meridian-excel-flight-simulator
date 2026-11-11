Attribute VB_Name = "modRegion"
Option Explicit
Public Type RegionRunway
    Airport As Long
    Designator As String
    East As Double
    North As Double
    Heading As Double
    Length As Double
    Width As Double
End Type
Public Runways(0 To 3) As RegionRunway, RunwayCount As Long
Public RegionHeights() As Single, RegionMap() As Long
Private ricHeights() As Single, ofpHeights() As Single
Private regionReady As Boolean

Public Sub LoadRegion()
    Dim file As Integer, root As String, i As Long, a As Long
    If regionReady Then Exit Sub
    root = ThisWorkbook.Path & "\Assets\Region\"
    With Runways(0)
        .Airport = 0: .Designator = "15/33"
        .East = RunwayCenterEast: .North = RunwayCenterNorth
        .Heading = RunwayHeading: .Length = 1676.4: .Width = 30.48
    End With
    file = FreeFile
    On Error GoTo failed
    Open root & "runways.csv" For Input As #file
    RunwayCount = 1
    Do While Not EOF(file)
        If RunwayCount > 3 Then Err.Raise 5, , "Too many regional runways"
        With Runways(RunwayCount)
            Input #file, .Airport, .Designator, .East, .North, .Heading, .Length, .Width
        End With
        RunwayCount = RunwayCount + 1
    Loop
    Close #file
    ReadHeights root & "height.f32", RegionHeights, 1048576
    ReadHeights root & "1-height.f32", ricHeights, 65536
    ReadHeights root & "2-height.f32", ofpHeights, 65536
    ReDim RegionMap(0 To 1048575)
    If FileLen(root & "map.rgb") <> 4194304 Then Err.Raise 5, , "Invalid regional map"
    Open root & "map.rgb" For Binary Access Read As #file
    Get #file, , RegionMap
    Close #file
    regionReady = True
    Exit Sub
failed:
    Close #file
    Err.Raise 5, , "Region assets could not load: " & Err.Description
End Sub

Private Sub ReadHeights(ByVal path As String, ByRef data() As Single, ByVal count As Long)
    Dim file As Integer
    If FileLen(path) <> count * 4 Then Err.Raise 5, , "Invalid regional elevation"
    ReDim data(0 To count - 1)
    file = FreeFile
    Open path For Binary Access Read As #file
    Get #file, , data
    Close #file
End Sub

Public Function PrimaryRunway(ByVal airport As Long) As Long
    Dim i As Long
    For i = 0 To RunwayCount - 1
        If Runways(i).Airport = airport And (airport = 0 Or Runways(i).Designator = "16/34") Then
            PrimaryRunway = i
            Exit Function
        End If
    Next
End Function

Public Function AirportCode(ByVal airport As Long) As String
    AirportCode = Choose(airport + 1, "KFCI", "KRIC", "KOFP")
End Function

Public Function AirportName(ByVal airport As Long) As String
    AirportName = Choose(airport + 1, "Richmond Executive", "Richmond International", "Hanover County")
End Function

Public Function RegionAlong(ByVal index As Long, ByVal east As Double, ByVal north As Double) As Double
    With Runways(index)
        RegionAlong = (east - .East) * Sin(.Heading) + (north - .North) * Cos(.Heading)
    End With
End Function

Public Function RegionSide(ByVal index As Long, ByVal east As Double, ByVal north As Double) As Double
    With Runways(index)
        RegionSide = (east - .East) * Cos(.Heading) - (north - .North) * Sin(.Heading)
    End With
End Function

Public Sub RegionPoint(ByVal index As Long, ByVal along As Double, ByVal side As Double, ByRef east As Double, ByRef north As Double)
    With Runways(index)
        east = .East + along * Sin(.Heading) + side * Cos(.Heading)
        north = .North + along * Cos(.Heading) - side * Sin(.Heading)
    End With
End Sub

Public Function OnRegionRunway(ByVal index As Long, ByVal east As Double, ByVal north As Double) As Boolean
    OnRegionRunway = Abs(RegionAlong(index, east, north)) < Runways(index).Length / 2 And Abs(RegionSide(index, east, north)) < Runways(index).Width / 2
End Function

Public Function OnAnyRunway(ByVal east As Double, ByVal north As Double) As Boolean
    Dim i As Long
    For i = 0 To RunwayCount - 1
        If OnRegionRunway(i, east, north) Then OnAnyRunway = True: Exit Function
    Next
End Function

Private Function Interpolate(ByRef samples() As Single, ByVal size As Long, ByVal x As Double, ByVal y As Double) As Double
    Dim ix As Long, iy As Long, f As Double, g As Double, index As Long
    x = Clamp(x, 0, size - 1.001): y = Clamp(y, 0, size - 1.001)
    ix = Int(x): iy = Int(y): f = x - ix: g = y - iy: index = ix + iy * size
    Interpolate = (samples(index) * (1 - f) + samples(index + 1) * f) * (1 - g) + (samples(index + size) * (1 - f) + samples(index + size + 1) * f) * g
End Function

Public Function RegionElevation(ByVal east As Double, ByVal north As Double) As Double
    Dim airport As Long, index As Long, x As Double, y As Double, blend As Double, detail As Double
    RegionElevation = Interpolate(RegionHeights, 1024, (east + 40960) / 80 - 0.5, (40960 - north) / 80 - 0.5)
    For airport = 1 To 2
        index = PrimaryRunway(airport)
        x = (east - Runways(index).East + 2560) / 20 - 0.5
        y = (Runways(index).North + 2560 - north) / 20 - 0.5
        If x >= 0 And x < 255 And y >= 0 And y < 255 Then
            blend = Clamp(x / 10, 0, 1) * Clamp((255 - x) / 10, 0, 1) * Clamp(y / 10, 0, 1) * Clamp((255 - y) / 10, 0, 1)
            If airport = 1 Then detail = Interpolate(ricHeights, 256, x, y) Else detail = Interpolate(ofpHeights, 256, x, y)
            RegionElevation = RegionElevation * (1 - blend) + detail * blend
            Exit Function
        End If
    Next
End Function

Public Function RegionRunwayHeight(ByVal index As Long, ByVal east As Double, ByVal north As Double) As Double
    Dim centerE As Double, centerN As Double
    RegionPoint index, RegionAlong(index, east, north), 0, centerE, centerN
    RegionRunwayHeight = TerrainGround(centerE, centerN)
End Function
