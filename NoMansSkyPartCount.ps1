#determine the correct save file location
$checksteam = test-path -Path "~\AppData\Roaming\HelloGames\NMS\st_*"
if ($checksteam -eq $true) {
    $initialfolder = (get-childitem "~\AppData\Roaming\HelloGames\NMS" | where {$_.name -like "st_*"}).fullname
    write-host "Detected Steam save folder" -ForegroundColor Yellow
}

$checkxbgp = test-path -Path "~\AppData\Local\Packages\HelloGames.NoMansSky*"
if ($checkxbgp -eq $true -and $source -eq $null) {
    $initialfolder = (get-childitem "~\AppData\Local\Packages\HelloGames.NoMansSky*").fullname + "\SystemAppData\wgs\*"
        write-host "Detected Xbox Game Pass save folder" -ForegroundColor Yellow
}

$checkgog = test-path -Path "~\AppData\Roaming\HelloGames\NMS\defaultuser\*.hg"
if ($checkgog -eq $true -and $source -eq $null) {
    $initialfolder = (get-childitem "~\AppData\Roaming\HelloGames\NMS\defaultuser").fullname
    write-host "Detected GOG save folder" -ForegroundColor Yellow
}

if ($initialfolder -eq $null) {
    write-host "Cannot locate No Man's Sky saved files; start browsing from root folder" -ForegroundColor Yellow
    $initialfolder = $env:USERPROFILE
}

#open explorer window to select file for analysis
Add-Type -AssemblyName System.Windows.Forms
$FileBrowser = New-Object System.Windows.Forms.OpenFileDialog -Property @{
    InitialDirectory = $initialfolder #[Environment]::GetFolderPath('Desktop')
    Filter = "JSON (*.json)|*.json"
}
$FileBrowser.Title = "Select a No Man's Sky JSON export file (*.JSON)"
[void]$FileBrowser.ShowDialog()
$jsonfile = $FileBrowser.FileNames

#set vars depending on file type
if ($jsonfile -like "*.json") {
    $PlayerStateData = "PlayerStateData"
    $PersistentPlayerBases = "PersistentPlayerBases"
    $Objects = "Objects"
    $Name = "Name"
    $basetype = "basetype"
    $PersistentBaseTypes = "PersistentBaseTypes"
    write-host "Selected file is: $jsonfile" -ForegroundColor Yellow
}
else {
    write-host "You must select a No Man's Sky JSON export from a save editor." -ForegroundColor Red -BackgroundColor Black
    Write-Host -NoNewLine 'Press any key to continue...';
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
    exit
}

# remove trailing space in native save file
$savefilecontents = Get-Content $jsonfile
if ($jsonfile -eq $null) {
    write-host "You must select either a No Man's Sky save file, or a JSON export from a save editor." -ForegroundColor Red -BackgroundColor Black
    Write-Host -NoNewLine 'Press any key to continue...';
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
    exit
}

#load save file as a PowerShell object to be able to parse it
write-host
write-host "Parsing JSON content, please stand by..." -ForegroundColor Yellow
$savefilecontents = $savefilecontents | ConvertFrom-Json
cls

#create a temprary PowerShell object to store base info in
[System.Collections.ArrayList]$basepartarray = @()

#loop through each base and get info, and store in temp PowerShell object
foreach ($base in $savefilecontents.$PlayerStateData.$PersistentPlayerBases) {
	$basepartcount = ($base.$Objects | measure).count
	$basename = $base.$name
    if ($base.$basetype.$PersistentBaseTypes -eq "FreighterBase") {
        $basename = "Freighter"
    }
	if ($base.$basetype.$PersistentBaseTypes -eq "HomePlanetBase" -or $base.$basetype.$PersistentBaseTypes -eq "FreighterBase") {
	    $appendtobasepartlist = [PSCustomObject]@{
            Basename = $basename
            Basepartcount = $basepartcount
        }
        $basepartarray.Add($appendtobasepartlist) | out-null
    }
}

#sort the list of there are more than one entries
if ($basepartarray.count -gt 1) {
    $basepartarray = $basepartarray | sort-object -Property @{Expression = "Basepartcount"; Descending = $True}, basename
}

#display the base part counts
$defaultcolor = $host.ui.RawUI.ForegroundColor
$host.ui.RawUI.ForegroundColor = "Cyan"
write-host "Parts per base, sorted by part totals:"
$basepartarray | ft
$baseparttotal = ($basepartarray | measure-object -property Basepartcount -sum).sum
$host.ui.RawUI.ForegroundColor = "Yellow"
write-host "The total number of base parts: $baseparttotal"
write-host
$host.ui.RawUI.ForegroundColor = $defaultcolor

Write-Host -NoNewLine 'Press any key to continue...';
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');