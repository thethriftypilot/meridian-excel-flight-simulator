Attribute VB_Name = "modAudio"
Option Explicit
Private Type WAVEFORMATEX
    formatTag As Integer
    channels As Integer
    samplesPerSec As Long
    avgBytesPerSec As Long
    blockAlign As Integer
    bitsPerSample As Integer
    extraSize As Integer
End Type
Private Type WAVEHDR
    data As LongPtr
    bufferLength As Long
    bytesRecorded As Long
    user As LongPtr
    flags As Long
    loops As Long
    nextHeader As LongPtr
    reserved As LongPtr
End Type
Private Declare PtrSafe Function waveOutOpen Lib "winmm" (ByRef handle As LongPtr, ByVal device As Long, ByRef fmt As WAVEFORMATEX, ByVal callback As LongPtr, ByVal instance As LongPtr, ByVal flags As Long) As Long
Private Declare PtrSafe Function waveOutPrepareHeader Lib "winmm" (ByVal handle As LongPtr, ByRef header As WAVEHDR, ByVal size As Long) As Long
Private Declare PtrSafe Function waveOutUnprepareHeader Lib "winmm" (ByVal handle As LongPtr, ByRef header As WAVEHDR, ByVal size As Long) As Long
Private Declare PtrSafe Function waveOutWrite Lib "winmm" (ByVal handle As LongPtr, ByRef header As WAVEHDR, ByVal size As Long) As Long
Private Declare PtrSafe Function waveOutReset Lib "winmm" (ByVal handle As LongPtr) As Long
Private Declare PtrSafe Function waveOutClose Lib "winmm" (ByVal handle As LongPtr) As Long
Private output As LongPtr, headers(0 To 3) As WAVEHDR
Private samples(0 To 2204, 0 To 3) As Integer
Private sine(0 To 2047) As Double, phase As Double, warningPhase As Double, noise As Double
Public AudioStatus As String, AudioBuffers As Long
Private Sub AudioCheck(ByVal result As Long, ByVal operation As String)
    If result <> 0 Then Err.Raise vbObjectError + 201, "Audio", operation & ": " & CStr(result)
End Sub
Public Sub StartAudio()
    Dim fmt As WAVEFORMATEX, i As Long
    If output <> 0 Then Exit Sub
    fmt.formatTag = 1: fmt.channels = 1: fmt.samplesPerSec = 22050
    fmt.avgBytesPerSec = 44100: fmt.blockAlign = 2: fmt.bitsPerSample = 16
    For i = 0 To 2047: sine(i) = Sin(i * 2 * PI / 2048): Next
    phase = 0: warningPhase = 0: noise = 17: AudioBuffers = 0
    AudioCheck waveOutOpen(output, -1, fmt, 0, 0, 0), "waveOutOpen"
    For i = 0 To 3
        headers(i).data = VarPtr(samples(0, i)): headers(i).bufferLength = 4410
        headers(i).flags = 0
        AudioCheck waveOutPrepareHeader(output, headers(i), LenB(headers(i))), "prepare"
        FillAudio i
        AudioCheck waveOutWrite(output, headers(i), LenB(headers(i))), "write"
    Next
    AudioStatus = "PCM 22.05 kHz / 4 buffers"
End Sub
Private Sub FillAudio(ByVal slot As Long)
    Dim i As Long, value As Double, freq As Double, amp As Double, n As Double, wind As Double
    freq = Clamp(Plane.rpm, 400, 2800) / 30 * 2048 / 22050
    amp = (0.12 + Plane.throttle * 0.17) * Volume
    wind = Clamp(Plane.speed / 100, 0, 0.8) * 0.13
    If Muted Or Paused Then amp = 0: wind = 0
    For i = 0 To 2204
        phase = phase + freq: If phase >= 2048 Then phase = phase - 2048
        noise = noise * 16807: noise = noise - Int(noise / 2147483647#) * 2147483647#
        n = noise / 1073741823.5 - 1
        value = amp * (sine(Int(phase)) + 0.35 * sine((Int(phase) * 2) And 2047) + 0.18 * sine((Int(phase) * 4) And 2047))
        value = value + n * wind * Volume
        If Plane.grounded Then value = value + n * Clamp(Plane.speed / 70, 0, 0.3) * amp
        warningPhase = warningPhase + 81.734: If warningPhase >= 2048 Then warningPhase = warningPhase - 2048
        If (Plane.stalled Or Plane.speed > 82) And Not Muted And Not Paused Then value = value + 0.12 * Volume * sine(Int(warningPhase))
        samples(i, slot) = CInt(Clamp(value, -0.95, 0.95) * 32767)
    Next
    AudioBuffers = AudioBuffers + 1
End Sub
Public Sub UpdateAudio()
    Dim i As Long
    If output = 0 Then Exit Sub
    For i = 0 To 3
        If (headers(i).flags And 1) <> 0 Then
            FillAudio i
            AudioCheck waveOutWrite(output, headers(i), LenB(headers(i))), "refill"
        End If
    Next
End Sub
Public Sub StopAudio()
    Dim i As Long, result As Long
    If output = 0 Then Exit Sub
    result = waveOutReset(output)
    For i = 0 To 3
        If (headers(i).flags And 2) <> 0 Then result = waveOutUnprepareHeader(output, headers(i), LenB(headers(i)))
    Next
    result = waveOutClose(output)
    If result <> 0 Then AudioStatus = "Audio close error " & result Else AudioStatus = "Stopped"
    output = 0
End Sub
