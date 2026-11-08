param([switch]$MenuOnly)
$ErrorActionPreference='Stop'
$root=(Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$excel=New-Object -ComObject Excel.Application
$excel.Visible=$true
$book=$excel.Workbooks.Open((Join-Path $root 'ExcelFlightSimulator.xlsm'))
if ($MenuOnly) {
    $excel.Run("'ExcelFlightSimulator.xlsm'!LaunchSimulator")
} else {
    $excel.Run("'ExcelFlightSimulator.xlsm'!TimedDemoTest")
}
# Leave the successfully opened application available to the user.
$excel.UserControl=$true
