VERSION 5.00
Begin {C62A69F0-16DC-11CE-9E98-00AA00574A4F} frmFlight 
   Caption         =   "Meridian | Excel Flight Simulator"
   ClientHeight    =   10410
   ClientLeft      =   120
   ClientTop       =   465
   ClientWidth     =   14955
   OleObjectBlob   =   "frmFlight.frx":0000
   StartUpPosition =   1  'CenterOwner
End
Attribute VB_Name = "frmFlight"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit
Private Sub UserForm_KeyDown(ByVal KeyCode As MSForms.ReturnInteger, ByVal Shift As Integer)
    QueueKey CLng(KeyCode), True
End Sub
Private Sub UserForm_KeyUp(ByVal KeyCode As MSForms.ReturnInteger, ByVal Shift As Integer)
    QueueKey CLng(KeyCode), False
End Sub
Private Sub UserForm_QueryClose(Cancel As Integer, CloseMode As Integer)
    If Running Then
        Cancel = True
        Running = False
    End If
End Sub

