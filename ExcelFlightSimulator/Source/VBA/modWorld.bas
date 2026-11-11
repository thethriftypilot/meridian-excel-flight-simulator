Attribute VB_Name = "modWorld"
Option Explicit
Public Heights() As Single, Colors() As Long
Public TerrainShade() As Single, SunsetShade() As Single
Public ColorLOD1() As Long, ColorLOD2() As Long
Public Const TerrainSize As Long = 1024
Public Const TextureSize As Long = 4096
Public Const HalfWorld As Double = 10240
Public Const RunwayHeading As Double = 2.46477472723659
Public Const RunwayCenterEast As Double = -0.16796501
Public Const RunwayCenterNorth As Double = -6.36860172
Public WorldReady As Boolean
Public Sub LoadWorld()
    Dim f As Integer, root As String, ix As Long, iy As Long, index As Long
    If WorldReady Then Exit Sub
    root = ThisWorkbook.Path & "\Assets\Terrain\"
    If FileLen(root & "height.bin") <> 4194304 Then Err.Raise 5, , "Invalid elevation package"
    If FileLen(root & "color.bin") <> 67108864 Then Err.Raise 5, , "Invalid imagery package"
    ReDim Heights(0 To 1048575): ReDim Colors(0 To 16777215)
    f = FreeFile
    Open root & "height.bin" For Binary Access Read As #f
    Get #f, , Heights
    Close #f
    f = FreeFile
    Open root & "color.bin" For Binary Access Read As #f
    Get #f, , Colors
    Close #f
    ReDim ColorLOD1(0 To 1048575): ReDim ColorLOD2(0 To 65535)
    f = FreeFile
    Open root & "color-lod1.bin" For Binary Access Read As #f
    Get #f, , ColorLOD1: Close #f
    f = FreeFile
    Open root & "color-lod2.bin" For Binary Access Read As #f
    Get #f, , ColorLOD2: Close #f
    ReDim TerrainShade(0 To 1048575): ReDim SunsetShade(0 To 1048575)
    For iy = 0 To 1023
        For ix = 0 To 1023
            index = ix + iy * 1024: TerrainShade(index) = 1: SunsetShade(index) = 0.9
            If ix < 1023 And iy < 1023 Then TerrainShade(index) = Clamp(0.94 + (Heights(index + 1) - Heights(index)) * 0.018 + (Heights(index + 1024) - Heights(index)) * 0.012, 0.68, 1.15)
            If ix < 1023 Then SunsetShade(index) = Clamp(0.86 + (Heights(index + 1) - Heights(index)) * 0.035, 0.45, 1.25)
        Next
    Next
    LoadRegion
    WorldReady = True
End Sub
Public Function TerrainGround(ByVal east As Double, ByVal north As Double) As Double
    Dim fx As Double, fy As Double, ix As Long, iy As Long, i As Long, a As Double, b As Double
    If Abs(east) > HalfWorld Or Abs(north) > HalfWorld Then
        TerrainGround = RegionElevation(east, north)
        Exit Function
    End If
    fx = Clamp((east + HalfWorld) / 20 - 0.5, 0, 1022.999)
    fy = Clamp((HalfWorld - north) / 20 - 0.5, 0, 1022.999)
    ix = Int(fx): iy = Int(fy): fx = fx - ix: fy = fy - iy: i = ix + iy * 1024
    a = Heights(i) * (1 - fx) + Heights(i + 1) * fx
    b = Heights(i + 1024) * (1 - fx) + Heights(i + 1025) * fx
    TerrainGround = a * (1 - fy) + b * fy
End Function
Public Function Ground(ByVal east As Double, ByVal north As Double) As Double
    Dim runway As Long
    Ground = TerrainGround(east, north)
    For runway = 1 To RunwayCount - 1
        If OnRegionRunway(runway, east, north) Then
            Ground = RegionRunwayHeight(runway, east, north)
            Exit Function
        End If
    Next
    If OnRunway(east, north) Then Ground = RunwayHeight(east, north)
End Function
Public Function AlongRunway(ByVal east As Double, ByVal north As Double) As Double
    AlongRunway = (east - RunwayCenterEast) * Sin(RunwayHeading) + (north - RunwayCenterNorth) * Cos(RunwayHeading)
End Function
Public Function OnRunway(ByVal east As Double, ByVal north As Double) As Boolean
    OnRunway = Abs(AlongRunway(east, north)) < 838.2 And Abs((east - RunwayCenterEast) * Cos(RunwayHeading) - (north - RunwayCenterNorth) * Sin(RunwayHeading)) < 15.24
End Function
Public Function RunwayHeight(ByVal east As Double, ByVal north As Double) As Double
    Dim s As Double
    s = AlongRunway(east, north)
    RunwayHeight = TerrainGround(RunwayEast(s), RunwayNorth(s))
End Function
Public Function Latitude(ByVal north As Double) As Double
    Dim origin As Double, projectionScale As Double
    projectionScale = Cos(37.4065 * PI / 180)
    origin = Log(Tan(PI / 4 + 37.4065 * PI / 360)) * 6378137
    Latitude = (2 * Atn(Exp((origin + north / projectionScale) / 6378137)) - PI / 2) * 180 / PI
End Function
Public Function Longitude(ByVal east As Double) As Double
    Longitude = -77.5248333333 + east / (6378137 * Cos(37.4065 * PI / 180)) * 180 / PI
End Function

Public Function RunwayEast(ByVal along As Double, Optional ByVal lateral As Double = 0) As Double
    RunwayEast = RunwayCenterEast + Sin(RunwayHeading) * along + Cos(RunwayHeading) * lateral
End Function
Public Function RunwayNorth(ByVal along As Double, Optional ByVal lateral As Double = 0) As Double
    RunwayNorth = RunwayCenterNorth + Cos(RunwayHeading) * along - Sin(RunwayHeading) * lateral
End Function
