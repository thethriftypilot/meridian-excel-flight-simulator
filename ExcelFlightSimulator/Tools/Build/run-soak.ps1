param([ValidateRange(10,7200)][double]$Seconds=1200)
$ErrorActionPreference='Stop'
$root=(Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
Set-Content -LiteralPath (Join-Path $root 'Tests/soak-result.txt') -Value "RUNNING | Requested $Seconds seconds; completion is not yet verified."
$excel=New-Object -ComObject Excel.Application
$excel.Visible=$true
$book=$null
try {
    $book=$excel.Workbooks.Open((Join-Path $root 'ExcelFlightSimulator.xlsm'))
    $result=$excel.Run("'ExcelFlightSimulator.xlsm'!RunSoak",$Seconds)
    Write-Output $result
    if ($result -notmatch '^PASS') { throw 'Native soak did not pass. See Tests/soak-result.txt.' }
} finally {
    if ($null -ne $book) {$book.Close($false)}
    $excel.Quit()
    [void][Runtime.InteropServices.Marshal]::FinalReleaseComObject($excel)
}
