#!/usr/bin/env pwsh

. ./shared.ps1

function Write-Header {
    param (
        [string]$Title
    )
    $Width = if ($Host.UI.RawUI.WindowSize.Width) { $Host.UI.RawUI.WindowSize.Width } else { 64 }
    
    $Border = "═" * $Width
    
    $PadLeft = [Math]::Max(0, [Math]::Floor(($Width - $Title.Length - 4) / 2))
    $PadRight = [Math]::Max(0, $Width - $Title.Length - 4 - $PadLeft)
    
    $DisplayTitle = "║" + (" " * $PadLeft) + " $Title " + (" " * $PadRight) + "║"
    
    Write-Host "" -ForegroundColor Cyan
    Write-Host $Border -ForegroundColor Cyan
    Write-Host $DisplayTitle -ForegroundColor Yellow -BackgroundColor Black
    Write-Host $Border -ForegroundColor Cyan
    Write-Host "" -ForegroundColor Cyan
}

function New-DirectorySafe {
    param ([string]$Path)
    if (-not (Test-Path -Path $Path)) {
        $null = New-Item -Path $Path -ItemType Directory
    }
}

function Copy-NewestVersion {
    param (
        [string]$SourceDir,
        [string]$Filter,
        [string]$Destination
    )
    
    $Files = Get-ChildItem -Path $SourceDir -Filter $Filter | Where-Object { $_.Name -match '\d+\.\d+\.\d+' }
    
    if ($Files) {
        $NewestFile = $Files | Sort-Object { 
            [version]($_.Name -replace '^.*?(\d+\.\d+\.\d+).*$', '$1') 
        } | Select-Object -Last 1

        Write-Host "Copying newest found: $($NewestFile.Name) -> $Destination" -ForegroundColor Green
        Copy-Item -Path $NewestFile.FullName -Destination $Destination -Force
    } else {
        Write-Error "No versioned files matching '$Filter' found in $SourceDir"
    }
}

$modulesToBuild = "./.."

New-DirectorySafe "./build"
New-DirectorySafe "./staticdata"
New-DirectorySafe "./staticdata/server_jars"
New-DirectorySafe "./staticdata/server_template_dir"
New-DirectorySafe "./staticdata/server_template_dir/mods"

cd modules

Write-Header "Building Protocol"
cd Protocol
./gradlew publishToMavenLocal
cd ..

Write-Header "Building Connector Plugin Base"
cd Fountain-connector-plugin-base
./mvnw install
cd ..

Write-Header "Building Fountain Bridge"
cd Fountain-bridge
./mvnw package
cd ..

Copy-NewestVersion -SourceDir "./Fountain-bridge/target" -Filter "fountain-*-jar-with-dependencies.jar" -Destination "$modulesToBuild/staticdata/server_jars/"

Write-Header "Building Fountain Fabric"
cd Fountain-fabric
./gradlew build
./gradlew publishToMavenLocal
cd ..

Copy-NewestVersion -SourceDir "./Fountain-fabric/build/libs" -Filter "fountain-*.jar" -Destination "$modulesToBuild/staticdata/server_template_dir/mods/"

Write-Header "Building Vienna Core"
cd Vienna
./mvnw package
./mvnw install
cd ..

Copy-NewestVersion -SourceDir "./Vienna/buildplate/connector-plugin/target" -Filter "buildplate-connector-plugin-*-jar-with-dependencies.jar" -Destination "$modulesToBuild/staticdata/server_jars/"

Write-Header "Building Vienna Fabric"
cd Vienna-fabric
./gradlew build
cd ..

Copy-NewestVersion -SourceDir "./Vienna-fabric/build/libs" -Filter "vienna-*.jar" -Destination "$modulesToBuild/staticdata/server_template_dir/mods/"

cd ..