if ($PSVersionTable.PSVersion.Major -lt 3) {
  Write-Host "Powershell 3 or higher is required, please follow link [1] in the description" -ForegroundColor Red
  exit
}

if ($PSVersionTable.PSVersion.Major -eq 3) {
  Write-Host "Powershell 3 is installed, if the script doesn't work upgrade to Powershell 4, please follow link [1] in the description" -ForegroundColor Red
  . .\Get-FileHash.ps1
}

. .\ConvertFrom-Gzip.ps1

 Write-Host "Please copy and paste the full URI to the latest manifest.xml.gz" -ForegroundColor Red
$uri = Read-Host "Manifest > "

 Write-Host "Please copy and paste the full path to the target folder." -ForegroundColor Red
 Write-Host "If you're upgrading then it's the folder that has EliteDangerous32.exe in it" -ForegroundColor Red
$dir = Read-Host "Folder > "
$dir = $dir + '\'

$ProgressPreference = "SilentlyContinue"

Invoke-WebRequest -Uri $uri -UseBasicParsing -OutFile manifest.gz

[xml]$manifest = ConvertFrom-Gzip -Path manifest.gz

function alreadyDownloaded($destPath, $hash) {
    $result = Get-FileHash -Path $destPath -Algorithm SHA1 -ErrorAction SilentlyContinue
    $result.Hash -eq $hash
}

$nodes = $manifest.SelectNodes('/Manifest/File')

foreach ($node in $nodes) {

    $destPath = $dir+$node.Path

    if (alreadyDownloaded -destPath $destPath -hash $node.Hash) {
        "Skipping    " + $destPath
    } else {
        $destFolder = Split-Path -Path $destPath
        $silent = New-Item -Path $destFolder -ItemType Directory -ErrorAction SilentlyContinue
        "Downloading " + $destPath
        Invoke-WebRequest -Uri $node.Download -UseBasicParsing -OutFile $destPath
    }

}
