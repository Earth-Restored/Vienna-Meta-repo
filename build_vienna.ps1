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

cp ./Fountain-bridge/target/fountain-0.0.1-SNAPSHOT-jar-with-dependencies.jar $modulesToBuild/staticdata/server_jars/fountain-0.0.1-SNAPSHOT-jar-with-dependencies.jar

Write-Header "Building Fountain Fabric"
cd Fountain-fabric
./gradlew build
./gradlew publishToMavenLocal
cd ..

cp ./Fountain-fabric/build/libs/fountain-0.0.1.jar $modulesToBuild/staticdata/server_template_dir/mods/fountain-0.0.1.jar

Write-Header "Building Vienna Core"
cd Vienna
./mvnw package
./mvnw install
cd ..

cp ./Vienna/buildplate/connector-plugin/target/buildplate-connector-plugin-0.0.1-SNAPSHOT-jar-with-dependencies.jar $modulesToBuild/staticdata/server_jars/buildplate-connector-plugin-0.0.1-SNAPSHOT-jar-with-dependencies.jar

Write-Header "Building Vienna Fabric"
cd Vienna-fabric
./gradlew build
cd ..

cp ./Vienna-fabric/build/libs/vienna-0.0.1.jar $modulesToBuild/staticdata/server_template_dir/mods/vienna-0.0.1.jar

cd ..