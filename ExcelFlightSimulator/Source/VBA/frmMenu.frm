VERSION 5.00
Begin {C62A69F0-16DC-11CE-9E98-00AA00574A4F} frmMenu 
   Caption         =   "MERIDIAN - The Excel Flight Experiment"
   ClientHeight    =   10410
   ClientLeft      =   120
   ClientTop       =   465
   ClientWidth     =   14955
   OleObjectBlob   =   "frmMenu.frx":0000
   StartUpPosition =   1  'CenterOwner
End
Attribute VB_Name = "frmMenu"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit
Private Sub UserForm_Initialize()
    lblTitle.Font.name = "Segoe UI": lblTitle.Font.size = 36
    lblSub.Font.name = "Segoe UI": lblSub.Font.size = 12
    lblRegion.Font.name = "Segoe UI": lblRegion.Font.size = 13
    lblAbout.Font.name = "Segoe UI": lblAbout.Font.size = 13
    lblScenario.Font.name = "Segoe UI": lblScenario.Font.size = 10
    cboScenario.Font.name = "Segoe UI": cboScenario.Font.size = 12
    lblWeather.Font.name = "Segoe UI": lblWeather.Font.size = 10
    cboWeather.Font.name = "Segoe UI": cboWeather.Font.size = 12
    cboQuality.Font.name = "Segoe UI": cboQuality.Font.size = 11
    lblSettings.Font.name = "Segoe UI": lblSettings.Font.size = 10
    cboVolume.Font.name = "Segoe UI": cboVolume.Font.size = 11
    cboSensitivity.Font.name = "Segoe UI": cboSensitivity.Font.size = 11
    btnStart.Font.name = "Segoe UI": btnStart.Font.size = 17
    btnDemo.Font.name = "Segoe UI": btnDemo.Font.size = 16
    lblHint.Font.name = "Segoe UI": lblHint.Font.size = 10
    btnClose.Font.name = "Segoe UI": btnClose.Font.size = 10

    If Len(Dir(ThisWorkbook.path & "\Assets\Terrain\menu.bmp")) > 0 Then imgTerrain.Picture = LoadPicture(ThisWorkbook.path & "\Assets\Terrain\menu.bmp")
    With cboScenario
        .AddItem "KFCI runway departure"
        .AddItem "Richmond scenic flight"
        .AddItem "Runway 15 approach"
        .AddItem "Sunset flight"
        .AddItem "Low visibility"
        .AddItem "Night flight"
        .AddItem "Apron / taxi"
        .AddItem "Crosswind landing"
        .ListIndex = 1
    End With
    With cboWeather
        .AddItem "Clear / calm"
        .AddItem "Sunset"
        .AddItem "Crosswind / scattered"
        .AddItem "Haze"
        .AddItem "Night"
        .AddItem "Overcast / gusts"
        .AddItem "Rain / reduced visibility"
        .ListIndex = 0
    End With
    cboQuality.AddItem "Performance": cboQuality.AddItem "Balanced": cboQuality.ListIndex = 0
    cboVolume.AddItem "Muted": cboVolume.AddItem "Low": cboVolume.AddItem "Normal": cboVolume.ListIndex = 2
    cboSensitivity.AddItem "Gentle": cboSensitivity.AddItem "Normal": cboSensitivity.AddItem "Direct": cboSensitivity.ListIndex = 1
End Sub
Private Sub UserForm_Activate()
    MenuOpen = True
End Sub
Private Sub ConfigureFlight()
    Scenario = cboScenario.ListIndex
    SetWeather cboWeather.ListIndex
    If Scenario = 3 Then SetWeather 1
    If Scenario = 4 Then SetWeather 3
    If Scenario = 5 Then SetWeather 4
    If Scenario = 7 Then SetWeather 2
    quality = cboQuality.ListIndex
    Volume = cboVolume.ListIndex * 0.325
    Muted = (Volume = 0)
    Sensitivity = 0.5 + cboSensitivity.ListIndex * 0.3
    Call PlayMenuClick
End Sub
Private Sub btnStart_Click()
    ConfigureFlight
    BeginFlight False
End Sub
Private Sub btnDemo_Click()
    ConfigureFlight
    BeginFlight True
End Sub
Private Sub btnClose_Click()
    Unload Me
End Sub
Private Sub UserForm_QueryClose(Cancel As Integer, CloseMode As Integer)
    StopMenuAudio
    MenuOpen = False
End Sub

