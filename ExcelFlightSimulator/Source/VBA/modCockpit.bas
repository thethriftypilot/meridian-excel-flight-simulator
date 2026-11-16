Attribute VB_Name = "modCockpit"
Option Explicit
'Original approximate pilot-eye geometry, not a surveyed Piper cockpit.
Private Declare PtrSafe Sub glMatrixMode Lib "opengl32" (ByVal mode As Long)
Private Declare PtrSafe Sub glPushMatrix Lib "opengl32" ()
Private Declare PtrSafe Sub glPopMatrix Lib "opengl32" ()
Private Declare PtrSafe Sub glLoadIdentity Lib "opengl32" ()
Private Declare PtrSafe Sub glFrustum Lib "opengl32" (ByVal l As Double, ByVal r As Double, ByVal b As Double, ByVal t As Double, ByVal n As Double, ByVal f As Double)
Private Declare PtrSafe Sub glEnable Lib "opengl32" (ByVal token As Long)
Private Declare PtrSafe Sub glDisable Lib "opengl32" (ByVal token As Long)
Private Declare PtrSafe Sub glClear Lib "opengl32" (ByVal token As Long)
Private Declare PtrSafe Sub glBindTexture Lib "opengl32" (ByVal token As Long, ByVal id As Long)
Private Declare PtrSafe Sub glColor3f Lib "opengl32" (ByVal r As Single, ByVal g As Single, ByVal b As Single)
Private Declare PtrSafe Sub glBegin Lib "opengl32" (ByVal token As Long)
Private Declare PtrSafe Sub glEnd Lib "opengl32" ()
Private Declare PtrSafe Sub glVertex3f Lib "opengl32" (ByVal x As Single, ByVal y As Single, ByVal z As Single)
Private Declare PtrSafe Sub glTexCoord2f Lib "opengl32" (ByVal u As Single, ByVal v As Single)
Private Declare PtrSafe Sub glTranslated Lib "opengl32" (ByVal x As Double, ByVal y As Double, ByVal z As Double)
Private Declare PtrSafe Sub glRotated Lib "opengl32" (ByVal angle As Double, ByVal x As Double, ByVal y As Double, ByVal z As Double)
Public Sub DrawImmersiveCockpit(ByVal panelTexture As Long, ByVal zoom As Double)
    Dim side As Long, light As Single
    light = 1
    If Weather = 4 Then light = 0.36
    If Weather = 1 Then light = 0.8
    glMatrixMode &H1701: glPushMatrix: glLoadIdentity
    glFrustum -0.666667 / zoom, 0.666667 / zoom, -0.6 / zoom, 0.333333 / zoom, 1, 20
    glMatrixMode &H1700: glPushMatrix: glLoadIdentity
    glClear &H100
    glEnable &HB71: glDisable &HB60: glDisable &HBC0
    'All geometry lies beyond the one-metre near plane. Units are doubled.
    CockpitBox 0, -0.91, -2.08, 1.4, 0.40, 0.015, 0.10 * light
    glEnable &HDE1: glBindTexture &HDE1, panelTexture
    glColor3f 1, 1, 1
    glBegin 7
    glTexCoord2f 0, 390 / 700: glVertex3f -1.03, -0.50, -2
    glTexCoord2f 1, 390 / 700: glVertex3f 1.03, -0.50, -2
    glTexCoord2f 1, 1: glVertex3f 1.03, -1.12, -2
    glTexCoord2f 0, 1: glVertex3f -1.03, -1.12, -2
    glEnd
    glDisable &HDE1
    CockpitBox 0, -0.50, -2.15, 1.38, 0.012, 0.08, 0.075 * light
    For side = -1 To 1 Step 2
        glPushMatrix
        glTranslated side * 1.33, 0.07, -2.05
        glRotated side * 9, 0, 0, 1
        CockpitBox 0, 0, 0, 0.022, 0.69, 0.028, 0.24 * light
        glPopMatrix
        CockpitBox side * 1.25, -0.88, -1.85, 0.10, 0.23, 0.35, 0.15 * light
    Next
    'State-linked control wheel. The panel texture still contains live gauges.
    glPushMatrix
    glTranslated -0.43, -0.93 + Plane.elevator * 0.035, -1.53
    glRotated -Plane.aileron * 35, 0, 0, 1
    CockpitBox 0, 0, -0.10, 0.025, 0.025, 0.12, 0.19 * light
    CockpitBox 0, 0, 0, 0.14, 0.018, 0.026, 0.10 * light
    CockpitBox -0.14, 0.035, 0, 0.022, 0.055, 0.028, 0.13 * light
    CockpitBox 0.14, 0.035, 0, 0.022, 0.055, 0.028, 0.13 * light
    glPopMatrix
    glDisable &HB71
    Call glPopMatrix: glMatrixMode &H1701: glPopMatrix: glMatrixMode &H1700
End Sub
Private Sub CockpitBox(ByVal x As Double, ByVal y As Double, ByVal z As Double, ByVal w As Double, ByVal h As Double, ByVal d As Double, ByVal tone As Single)
    glColor3f tone, tone * 1.02, tone * 1.04
    glBegin 7
    glVertex3f x - w, y - h, z + d: glVertex3f x + w, y - h, z + d
    glVertex3f x + w, y + h, z + d: glVertex3f x - w, y + h, z + d
    glColor3f tone * 1.35, tone * 1.36, tone * 1.37
    glVertex3f x - w, y + h, z - d: glVertex3f x - w, y + h, z + d
    glVertex3f x + w, y + h, z + d: glVertex3f x + w, y + h, z - d
    glColor3f tone * 0.6, tone * 0.62, tone * 0.65
    glVertex3f x - w, y - h, z - d: glVertex3f x - w, y - h, z + d
    glVertex3f x - w, y + h, z + d: glVertex3f x - w, y + h, z - d
    glVertex3f x + w, y - h, z + d: glVertex3f x + w, y - h, z - d
    glVertex3f x + w, y + h, z - d: glVertex3f x + w, y + h, z + d
    glEnd
End Sub
