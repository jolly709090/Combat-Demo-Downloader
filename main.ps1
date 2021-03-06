﻿if ($PSVersionTable.PSVersion.Major -lt 3) {
  Write-Host "Powershell 3 or higher is required, please follow link [1] in the description" -ForegroundColor Red
  exit
}

if ($PSVersionTable.PSVersion.Major -eq 3) {
  Write-Host "Powershell 3 is installed, if the script doesn't work upgrade to Powershell 4, please follow link [1] in the description" -ForegroundColor Red
  . .\Get-FileHash.ps1
}

. .\ConvertFrom-Gzip.ps1

$uri = 'http://cdn.zaonce.net/elitedangerous/win/manifests/Single+Player+Combat+Training+%282014.11.26.51787%29.xml.gz'

$dir = 'COMBAT_TUTORIAL_DEMO\'

$ProgressPreference = "SilentlyContinue"

Invoke-WebRequest -Uri $uri -UseBasicParsing -OutFile manifest.gz

$temp = Get-FileHash -Path manifest.gz -Algorithm SHA256

if ($temp.Hash -eq 'E42A3DA31255DFFA7FEB4D46B83AD4A9AD897FAC00F3228031819F94A5185F6B') {
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

    $VS2012 = 'http://download.microsoft.com/download/1/6/B/16B06F60-3B20-4FF2-B699-5E9B7962F9AE/VSU_4/vcredist_x86.exe'
    Invoke-WebRequest -Uri $VS2012 -UseBasicParsing -OutFile $dir+'vcredist_x86.exe'
} else {
    'Hash mismatch, check for update at https://github.com/xaduha/Combat-Demo-Downloader'
}
