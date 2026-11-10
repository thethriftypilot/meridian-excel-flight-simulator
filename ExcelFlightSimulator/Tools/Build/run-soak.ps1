param([ValidateRange(10,7200)][double]$Seconds=1200,[switch]$Detailed,[switch]$Supersample)
$ErrorActionPreference='Stop'
$root=(Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$resultPath = if ($Supersample) { "Tests/graphics-2x-soak-result.txt" } elseif ($Detailed) { 'Tests/graphics-soak-result.txt' } else { 'Tests/soak-result.txt' }
Set-Content -LiteralPath (Join-Path $root $resultPath) -Value "RUNNING | Requested $Seconds seconds; completion is not yet verified."
$excel=New-Object -ComObject Excel.Application
$excel.Visible=$true
$book=$null
try {
    $book=$excel.Workbooks.Open((Join-Path $root 'ExcelFlightSimulator.xlsm'))
    $result=$excel.Run("'ExcelFlightSimulator.xlsm'!RunSoak",$Seconds,$Detailed.IsPresent,$Supersample.IsPresent)
    Write-Output $result
    if ($result -notmatch '^PASS') { throw 'Native soak did not pass. See the soak result in Tests.' }
} finally {
    if ($null -ne $book) {$book.Close($false)}
    $excel.Quit()
    [void][Runtime.InteropServices.Marshal]::FinalReleaseComObject($excel)
}
