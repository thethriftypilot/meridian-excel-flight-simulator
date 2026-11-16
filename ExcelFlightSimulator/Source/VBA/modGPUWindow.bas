Attribute VB_Name = "modGPUWindow"
Option Explicit
Private Type WNDCLASSEXW
    cbSize As Long
    style As Long
    procedure As LongPtr
    classExtra As Long
    windowExtra As Long
    instance As LongPtr
    icon As LongPtr
    cursor As LongPtr
    background As LongPtr
    menuName As LongPtr
    className As LongPtr
    smallIcon As LongPtr
End Type
Private Declare PtrSafe Function GetModuleHandleW Lib "kernel32" (ByVal name As LongPtr) As LongPtr
Private Declare PtrSafe Function GetProcAddress Lib "kernel32" (ByVal module As LongPtr, ByVal name As String) As LongPtr
Private Declare PtrSafe Function GetCurrentProcessId Lib "kernel32" () As Long
Private Declare PtrSafe Function RegisterClassExW Lib "user32" (ByRef definition As WNDCLASSEXW) As Integer
Private Declare PtrSafe Function UnregisterClassW Lib "user32" (ByVal name As LongPtr, ByVal instance As LongPtr) As Long
Private Declare PtrSafe Function CreateWindowExW Lib "user32" (ByVal ex As Long, ByVal cls As LongPtr, ByVal title As LongPtr, ByVal style As Long, ByVal x As Long, ByVal y As Long, ByVal w As Long, ByVal h As Long, ByVal parent As LongPtr, ByVal menu As LongPtr, ByVal instance As LongPtr, ByVal param As LongPtr) As LongPtr
Private Declare PtrSafe Function DestroyWindow Lib "user32" (ByVal hwnd As LongPtr) As Long
Private Declare PtrSafe Function SetWindowPos Lib "user32" (ByVal hwnd As LongPtr, ByVal after As LongPtr, ByVal x As Long, ByVal y As Long, ByVal w As Long, ByVal h As Long, ByVal flags As Long) As Long
Private Declare PtrSafe Function DescribePixelFormat Lib "gdi32" (ByVal dc As LongPtr, ByVal index As Long, ByVal bytes As Long, ByRef data As Any) As Long
Private className As String, registered As Boolean, instance As LongPtr
Public Function CreateGPUWindow(ByVal parent As LongPtr, ByVal width As Long, ByVal height As Long) As LongPtr
    Dim definition As WNDCLASSEXW, user32 As String, style As Long
    If Not registered Then
        className = "MeridianGPU_" & GetCurrentProcessId()
        instance = GetModuleHandleW(0)
        user32 = "user32.dll"
        definition.cbSize = LenB(definition)
        If definition.cbSize <> 80 Then Err.Raise 5, , "GPU window requires x64 WNDCLASSEXW"
        definition.style = &H20
        definition.procedure = GetProcAddress(GetModuleHandleW(StrPtr(user32)), "DefWindowProcW")
        If definition.procedure = 0 Then Err.Raise 5, , "Native window procedure unavailable"
        definition.instance = instance: definition.className = StrPtr(className)
        If RegisterClassExW(definition) = 0 Then Err.Raise 5, , "GPU window class registration failed"
        registered = True
    End If
    style = &H86000000
    If parent <> 0 Then style = &H56000000
    CreateGPUWindow = CreateWindowExW(0, StrPtr(className), 0, style, 0, 0, width, height, parent, 0, instance, 0)
    If CreateGPUWindow = 0 Then
        UnregisterClassW StrPtr(className), instance
        registered = False
        Err.Raise 5, , "GPU window creation failed"
    End If
    If parent <> 0 Then ResizeGPUWindow CreateGPUWindow, 0, 0, width, height
End Function
Public Sub ResizeGPUWindow(ByVal hwnd As LongPtr, ByVal x As Long, ByVal y As Long, ByVal width As Long, ByVal height As Long)
    If SetWindowPos(hwnd, 0, x, y, width, height, &H10) = 0 Then Err.Raise 5, , "GPU window resize failed"
End Sub
Public Sub ReleaseGPUWindow(ByVal hwnd As LongPtr)
    If hwnd <> 0 Then DestroyWindow hwnd
    If registered Then
        If UnregisterClassW(StrPtr(className), instance) <> 0 Then registered = False
    End If
End Sub
Public Sub ValidateGPUFormat(ByVal dc As LongPtr, ByVal format As Long)
    Dim actual(0 To 39) As Byte
    If DescribePixelFormat(dc, format, 40, actual(0)) = 0 Then Err.Raise 5, , "Cannot inspect GPU pixel format"
    If (actual(4) And 37) <> 37 Or actual(8) <> 0 Or actual(23) < 24 Or actual(24) < 8 Then Err.Raise 5, , "GPU pixel format lacks required buffers"
End Sub
