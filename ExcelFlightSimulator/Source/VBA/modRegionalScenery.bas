Attribute VB_Name = "modRegionalScenery"
Option Explicit
Public Sub DrawRegionalAirports()
    Dim runway As Long, along As Double, side As Double, distance As Double, finish As Double
    Dim color As Long, endSign As Long, number As String, section As Double
    color = RGB(222, 222, 208)
    If Weather = 4 Then color = RGB(66, 69, 72)
    For runway = 1 To RunwayCount - 1
        With Runways(runway)
            distance = Sqr((Plane.east - .East) ^ 2 + (Plane.north - .North) ^ 2)
            If distance < Visibility + 1800 Then
                finish = .Length / 2
                For along = -finish To finish - 0.01 Step 60
                    section = Clamp(finish - along, 0, 60)
                    RegionalQuad runway, along + section / 2, 0, section, .Width, RGB(62, 65, 66), True
                    RegionalQuad runway, along + section / 2, -.Width / 2 + 0.8, section, 0.5, color
                    RegionalQuad runway, along + section / 2, .Width / 2 - 0.8, section, 0.5, color
                    If along > -finish + 160 And along < finish - 160 Then RegionalQuad runway, along, 0, 24, 0.8, color
                    If Weather = 4 Then
                        RegionalQuad runway, along, -.Width / 2 - 2, 2.5, 2.5, RGB(255, 232, 173)
                        RegionalQuad runway, along, .Width / 2 + 2, 2.5, 2.5, RGB(255, 232, 173)
                    End If
                Next
                For endSign = -1 To 1 Step 2
                    For side = -12 To 12 Step 4
                        RegionalQuad runway, endSign * (finish - 18), side, 24, 1.7, color
                    Next
                    If endSign = -1 Then number = Left$(.Designator, 2) Else number = Right$(.Designator, 2)
                    RegionNumber runway, endSign * (finish - 70), -endSign, number, color
                Next
            End If
        End With
    Next
End Sub

Private Sub RegionalQuad(ByVal runway As Long, ByVal along As Double, ByVal side As Double, ByVal length As Double, ByVal width As Double, ByVal shade As Long, Optional ByVal pavement As Boolean = False)
    Dim e(0 To 3) As Double, n(0 To 3) As Double, h(0 To 3) As Double
    Dim alongUV(0 To 3) As Double, sideUV(0 To 3) As Double, i As Long, lift As Double
    lift = 0.42: If pavement Then lift = 0.30
    For i = 0 To 3
        alongUV(i) = along - length / 2: sideUV(i) = side - width / 2
        If i = 1 Or i = 2 Then alongUV(i) = along + length / 2
        If i >= 2 Then sideUV(i) = side + width / 2
        RegionPoint runway, alongUV(i), sideUV(i), e(i), n(i)
        h(i) = RegionRunwayHeight(runway, e(i), n(i)) + lift
    Next
    If LandscapeDrawing And pavement Then
        LandscapePavement e, n, h, alongUV, sideUV
    Else
        WorldFace e, n, h, shade
    End If
End Sub

Private Sub RegionNumber(ByVal runway As Long, ByVal along As Double, ByVal direction As Long, ByVal number As String, ByVal shade As Long)
    Dim pattern As String, digit As Long, row As Long, col As Long
    For digit = 0 To 1
        Select Case Mid$(number, digit + 1, 1)
            Case "0": pattern = "111101101101111"
            Case "1": pattern = "010110010010111"
            Case "2": pattern = "111001111100111"
            Case "3": pattern = "111001111001111"
            Case "4": pattern = "101101111001001"
            Case "6": pattern = "111100111101111"
        End Select
        For row = 0 To 4
            For col = 0 To 2
                If Mid$(pattern, row * 3 + col + 1, 1) = "1" Then
                    RegionalQuad runway, along + direction * (2 - row) * 3, direction * (-5 + digit * 6 + col * 1.5), 3, 1.5, shade
                End If
            Next
        Next
    Next
End Sub
