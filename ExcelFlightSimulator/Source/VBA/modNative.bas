Attribute VB_Name = "modNative"
Option Explicit
' VBA7 / 64-bit Windows. No callbacks, subclassing, or executable dependencies.
Public Type POINTAPI
    x As Long
    y As Long
End Type
Public Type RECT
    Left As Long
    Top As Long
    Right As Long
    Bottom As Long
End Type
Public Type BITMAPINFOHEADER
    biSize As Long
    biWidth As Long
    biHeight As Long
    biPlanes As Integer
    biBitCount As Integer
    biCompression As Long
    biSizeImage As Long
    biXPelsPerMeter As Long
    biYPelsPerMeter As Long
    biClrUsed As Long
    biClrImportant As Long
End Type
Public Declare PtrSafe Function QueryPerformanceCounter Lib "kernel32" (ByRef value As Currency) As Long
Public Declare PtrSafe Function QueryPerformanceFrequency Lib "kernel32" (ByRef value As Currency) As Long
Public Declare PtrSafe Sub Sleep Lib "kernel32" (ByVal milliseconds As Long)
Public Declare PtrSafe Function GetAsyncKeyState Lib "user32" (ByVal key As Long) As Integer
Public Declare PtrSafe Function GetForegroundWindow Lib "user32" () As LongPtr
Public Declare PtrSafe Function FindWindow Lib "user32" Alias "FindWindowA" (ByVal className As String, ByVal caption As String) As LongPtr
Public Declare PtrSafe Function GetDC Lib "user32" (ByVal hwnd As LongPtr) As LongPtr
Public Declare PtrSafe Function ReleaseDC Lib "user32" (ByVal hwnd As LongPtr, ByVal hdc As LongPtr) As Long
Public Declare PtrSafe Function GetClientRect Lib "user32" (ByVal hwnd As LongPtr, ByRef r As RECT) As Long
Public Declare PtrSafe Function CreateCompatibleDC Lib "gdi32" (ByVal hdc As LongPtr) As LongPtr
Public Declare PtrSafe Function CreateCompatibleBitmap Lib "gdi32" (ByVal hdc As LongPtr, ByVal w As Long, ByVal h As Long) As LongPtr
Public Declare PtrSafe Function SelectObject Lib "gdi32" (ByVal hdc As LongPtr, ByVal obj As LongPtr) As LongPtr
Public Declare PtrSafe Function DeleteObject Lib "gdi32" (ByVal obj As LongPtr) As Long
Public Declare PtrSafe Function DeleteDC Lib "gdi32" (ByVal hdc As LongPtr) As Long
Public Declare PtrSafe Function StretchDIBits Lib "gdi32" (ByVal hdc As LongPtr, ByVal x As Long, ByVal y As Long, ByVal w As Long, ByVal h As Long, ByVal sx As Long, ByVal sy As Long, ByVal sw As Long, ByVal sh As Long, ByRef bits As Any, ByRef bmi As BITMAPINFOHEADER, ByVal usage As Long, ByVal rop As Long) As Long
Public Declare PtrSafe Function StretchBlt Lib "gdi32" (ByVal dest As LongPtr, ByVal x As Long, ByVal y As Long, ByVal w As Long, ByVal h As Long, ByVal src As LongPtr, ByVal sx As Long, ByVal sy As Long, ByVal sw As Long, ByVal sh As Long, ByVal rop As Long) As Long
Public Declare PtrSafe Function PlgBlt Lib "gdi32" (ByVal dest As LongPtr, ByRef points As POINTAPI, ByVal src As LongPtr, ByVal sx As Long, ByVal sy As Long, ByVal w As Long, ByVal h As Long, ByVal mask As LongPtr, ByVal mx As Long, ByVal my As Long) As Long
Public Declare PtrSafe Function CreateSolidBrush Lib "gdi32" (ByVal color As Long) As LongPtr
Public Declare PtrSafe Function CreatePen Lib "gdi32" (ByVal style As Long, ByVal width As Long, ByVal color As Long) As LongPtr
Public Declare PtrSafe Function FillRect Lib "user32" (ByVal hdc As LongPtr, ByRef r As RECT, ByVal brush As LongPtr) As Long
Public Declare PtrSafe Function Ellipse Lib "gdi32" (ByVal hdc As LongPtr, ByVal l As Long, ByVal t As Long, ByVal r As Long, ByVal b As Long) As Long
Public Declare PtrSafe Function Polygon Lib "gdi32" (ByVal hdc As LongPtr, ByRef p As POINTAPI, ByVal count As Long) As Long
Public Declare PtrSafe Function MoveToEx Lib "gdi32" (ByVal hdc As LongPtr, ByVal x As Long, ByVal y As Long, ByVal old As LongPtr) As Long
Public Declare PtrSafe Function LineTo Lib "gdi32" (ByVal hdc As LongPtr, ByVal x As Long, ByVal y As Long) As Long
Public Declare PtrSafe Function SetTextColor Lib "gdi32" (ByVal hdc As LongPtr, ByVal color As Long) As Long
Public Declare PtrSafe Function SetBkMode Lib "gdi32" (ByVal hdc As LongPtr, ByVal mode As Long) As Long
Public Declare PtrSafe Function TextOut Lib "gdi32" Alias "TextOutA" (ByVal hdc As LongPtr, ByVal x As Long, ByVal y As Long, ByVal text As String, ByVal count As Long) As Long
Public Declare PtrSafe Function CreateFont Lib "gdi32" Alias "CreateFontA" (ByVal height As Long, ByVal width As Long, ByVal escapement As Long, ByVal orientation As Long, ByVal weight As Long, ByVal italic As Long, ByVal underline As Long, ByVal strikeout As Long, ByVal charset As Long, ByVal outprecision As Long, ByVal clipprecision As Long, ByVal quality As Long, ByVal family As Long, ByVal face As String) As LongPtr
Public Declare PtrSafe Function GetGuiResources Lib "user32" (ByVal process As LongPtr, ByVal flags As Long) As Long
Public Declare PtrSafe Function GetCurrentProcess Lib "kernel32" () As LongPtr
Public Const SRCCOPY As Long = &HCC0020
Public Const PI As Double = 3.14159265358979
Public Function Clock() As Double
    Static frequency As Currency
    Dim ticks As Currency
    If frequency = 0 Then QueryPerformanceFrequency frequency
    QueryPerformanceCounter ticks
    Clock = ticks / frequency
End Function
Public Function Clamp(ByVal v As Double, ByVal lo As Double, ByVal hi As Double) As Double
    If v < lo Then v = lo
    If v > hi Then v = hi
    Clamp = v
End Function
Public Function Wrap(ByVal a As Double) As Double
    Wrap = a - 2 * PI * Int(a / (2 * PI))
End Function
Public Function Atan2(ByVal y As Double, ByVal x As Double) As Double
    If Abs(x) < 0.000001 Then
        Atan2 = Sgn(y) * PI / 2
    Else
        Atan2 = Atn(y / x)
        If x < 0 Then Atan2 = Atan2 + Sgn(y + 0.0000001) * PI
    End If
End Function
