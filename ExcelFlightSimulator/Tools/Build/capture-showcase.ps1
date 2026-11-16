param([string]$Label='extreme-final',[int]$Preset=4,[int]$Width=1000,[switch]$Legacy,[switch]$GPUChecks)
$ErrorActionPreference='Stop'
$root=(Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
if ($Label -notmatch '^[a-zA-Z0-9_-]+$') { throw 'Label must be a simple folder name.' }
if ($Width -lt 640 -or $Width -gt 1920) { throw 'Viewport width must be 640 to 1920.' }
$excel=New-Object -ComObject Excel.Application
$excel.Visible=$true
$book=$null
try {
    $book=$excel.Workbooks.Open((Join-Path $root 'ExcelFlightSimulator.xlsm'))
    if ($GPUChecks) {
        $result=$excel.Run("'ExcelFlightSimulator.xlsm'!RunGPUChecks")
        Write-Output $result
        if ($result -notmatch '^PASS') { throw 'GPU checks failed.' }
    }
    $result=$excel.Run("'ExcelFlightSimulator.xlsm'!CaptureShowcase",$Label,$Preset,(-not $Legacy.IsPresent),($Preset -eq 4),$Width)
    Write-Output $result
    if ($result -notmatch '^PASS') { throw 'Showcase capture failed.' }
} finally {
    if ($null -ne $book) { $book.Close($false) }
    $excel.Quit()
    [void][Runtime.InteropServices.Marshal]::FinalReleaseComObject($excel)
}
