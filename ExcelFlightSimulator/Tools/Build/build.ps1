param([switch]$Test)
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$excel = New-Object -ComObject Excel.Application
$excel.Visible = $true
$excel.DisplayAlerts = $false
$book = $null
try {
    $book = $excel.Workbooks.Add()
    try {
        $project = $book.GetType().InvokeMember('VBProject',[Reflection.BindingFlags]::GetProperty,$null,$book,$null)
        if ($null -eq $project) { throw 'VBA project unavailable' }
        $count = $project.VBComponents.Count
    } catch {
        throw 'Excel blocks VBA project access. Enable Trust access to the VBA project object model temporarily to build, then restore your setting. No security setting was changed by this script.'
    }
    foreach ($file in Get-ChildItem -LiteralPath (Join-Path $root 'Source/VBA') -Filter '*.bas') {
        [void]$project.VBComponents.Import($file.FullName)
    }
    $flight = $project.VBComponents.Add(3)
    $flight.Name = 'frmFlight'
    $flight.Properties.Item('Caption').Value = 'Meridian | Excel Flight Simulator'
    $flight.Properties.Item('Width').Value = 760
    $flight.Properties.Item('Height').Value = 550
    $flight.Properties.Item('BackColor').Value = 2036492
    $flight.CodeModule.AddFromString([IO.File]::ReadAllText((Join-Path $root 'Source/VBA/frmFlight.code')))
    $menu = $project.VBComponents.Add(3)
    $menu.Name = 'frmMenu'
    $menu.Properties.Item('Caption').Value = 'MERIDIAN - The Excel Flight Experiment'
    $menu.Properties.Item('Width').Value = 760
    $menu.Properties.Item('Height').Value = 610
    $menu.Properties.Item('BackColor').Value = 2036492
    $script:fontCode = ''
    function Add-Control($kind,$name,$caption,$x,$y,$w,$h,$size=12,$fore=15198183,$back=2036492) {
        $c = $menu.Designer.Controls.Add("Forms.$kind.1",$name,$true)
        $c.Left=$x; $c.Top=$y; $c.Width=$w; $c.Height=$h
        $script:fontCode += "    $name.Font.Name = `"Segoe UI`": $name.Font.Size = $size`r`n"
        $c.ForeColor=$fore; $c.BackColor=$back
        if ($kind -ne 'ComboBox') { $c.Caption=$caption }
        return $c
    }
    [void](Add-Control 'Label' 'lblTitle' 'MERIDIAN' 28 18 420 52 36)
    [void](Add-Control 'Label' 'lblSub' 'THE EXCEL FLIGHT EXPERIMENT' 30 77 500 24 12 12963447)
    [void](Add-Control 'Label' 'lblRegion' 'VIRGINIA / KFCI    |    PIPER PA-28-161 WARRIOR II' 30 108 650 25 13)
    [void](Add-Control 'Label' 'lblAbout' "Real USGS elevation. Aerial imagery. Every flight computed in VBA.`r`nExplore 420 square kilometres around Richmond Executive." 30 147 680 50 13)
    $img=$menu.Designer.Controls.Add('Forms.Image.1','imgTerrain',$true)
    $img.Left=480; $img.Top=212; $img.Width=230; $img.Height=180; $img.PictureSizeMode=3
    # Picture embedded in form by Excel during build; runtime needs no image decoder.
    $preview=Join-Path $root 'Assets/Terrain/menu.bmp'
    if (Test-Path -LiteralPath $preview) {
        # Native LoadPicture is assigned by a build-only VBA macro after import.
    }
    [void](Add-Control 'Label' 'lblScenario' 'FLIGHT' 30 210 100 20 10 12963447)
    [void](Add-Control 'ComboBox' 'cboScenario' '' 30 234 420 26 12 2036492 15198183)
    [void](Add-Control 'Label' 'lblWeather' 'WEATHER' 30 270 100 20 10 12963447)
    [void](Add-Control 'ComboBox' 'cboWeather' '' 30 294 255 26 12 2036492 15198183)
    [void](Add-Control 'ComboBox' 'cboQuality' '' 300 294 150 26 11 2036492 15198183)
    [void](Add-Control 'Label' 'lblSettings' 'SOUND                         CONTROL RESPONSE' 30 332 420 20 10 12963447)
    [void](Add-Control 'ComboBox' 'cboVolume' '' 30 354 175 25 11 2036492 15198183)
    [void](Add-Control 'ComboBox' 'cboSensitivity' '' 225 354 225 25 11 2036492 15198183)
    [void](Add-Control 'CommandButton' 'btnStart' 'START FLIGHT' 30 414 310 48 17 2036492 12963447)
    [void](Add-Control 'CommandButton' 'btnDemo' 'WATCH DEMONSTRATION' 360 414 350 48 16 15198183 4274474)
    [void](Add-Control 'CommandButton' 'btnReplay' 'REPLAY LAST FLIGHT' 30 474 310 38 13 15198183 4274474)
    [void](Add-Control 'CommandButton' 'btnDebrief' 'VIEW DEBRIEF' 360 474 350 38 13 15198183 4274474)
    [void](Add-Control 'Label' 'lblHint' 'v0.4 / Arrow keys fly / W S power / P pause / Esc menu. Experimental simulation.' 30 535 690 22 10 11908508)
    [void](Add-Control 'CommandButton' 'btnClose' 'EXIT' 660 18 60 26 10 15198183 4274474)
    $menuCode=[IO.File]::ReadAllText((Join-Path $root 'Source/VBA/frmMenu.code'))
    $menuCode=$menuCode.Replace('Private Sub UserForm_Initialize()',"Private Sub UserForm_Initialize()`r`n$script:fontCode")
    $menu.CodeModule.AddFromString($menuCode)
    $sheet=$book.Worksheets.Item(1); $sheet.Name='Launch'
    $sheet.Cells.Interior.Color=2036492
    $sheet.Range('B3').Value2='MERIDIAN'; $sheet.Range('B3').Font.Size=36; $sheet.Range('B3').Font.Color=15198183
    $sheet.Range('B6').Value2='THE EXCEL FLIGHT EXPERIMENT'; $sheet.Range('B6').Font.Size=16; $sheet.Range('B6').Font.Color=12963447
    $sheet.Range('B9').Value2='KFCI / Virginia / Piper PA-28-161 Warrior II'; $sheet.Range('B9').Font.Color=15198183
    $sheet.Range('B11').Value2='Enable macros for this workbook, then open the simulator.'; $sheet.Range('B11').Font.Color=15198183
    $sheet.Range('B13').Value2='Keep the Assets folder beside this workbook. See Documentation/README.md.'; $sheet.Range('B13').Font.Color=15198183
    $shape=$sheet.Shapes.AddShape(5,25,280,330,64)
    $shape.TextFrame2.TextRange.Text='OPEN FLIGHT SIMULATOR'; $shape.TextFrame2.TextRange.Font.Size=19
    $shape.Fill.ForeColor.RGB=4274474; $shape.OnAction='LaunchSimulator'
    $book.Windows.Item(1).DisplayGridlines=$false
    $book.SaveAs((Join-Path $root 'ExcelFlightSimulator.xlsm'),52)
    if ($Test) {
        $result=$excel.Run("'ExcelFlightSimulator.xlsm'!RunSelfTests")
        Write-Output $result
        $book.Save()
        if ($result -match '(?m)^FAIL') { throw 'Native tests failed. Inspect Tests/results.txt before distributing this build.' }
        # Test-flight reports are retained as PDF evidence, not shipped as the user's history.
        foreach ($name in @('Debrief','Flight data','Personal bests')) {
            $book.Worksheets.Item($name).Delete()
        }
        $book.Worksheets.Item('Launch').Activate()
        $book.Save()
    }
    # Export actual forms including binary designer resources for reproducibility.
    $flight.Export((Join-Path $root 'Source/VBA/frmFlight.frm'))
    $menu.Export((Join-Path $root 'Source/VBA/frmMenu.frm'))
    Write-Output "Built $(Join-Path $root 'ExcelFlightSimulator.xlsm')"
} finally {
    if ($null -ne $book) { $book.Close($false) }
    $excel.Quit()
    [void][Runtime.InteropServices.Marshal]::FinalReleaseComObject($excel)
}
