#!/usr/bin/env pwsh
param (
    [Parameter(Mandatory=$true)]
    [string]$ADDRESS,
    [switch]$e, # Eventbus
    [switch]$o, # Objectstore
    [switch]$s, # Server (API, CDN, Locator)
    [switch]$t, # Tappables
    [switch]$l  # Launcher
)

. ./shared.ps1

$modulesDir = "./../modules"

if (-not ($e -or $o -or $s -or $t -or $l)) {
    $e = $o = $s = $t = $l = $true
}

Set-Location ./build

$EVENTBUS_JAR = "$modulesDir/Vienna/eventbus/server/target/eventbus-server-0.0.1-SNAPSHOT-jar-with-dependencies.jar"
$OBJECTSTORE_JAR = "$modulesDir/Vienna/objectstore/server/target/objectstore-server-0.0.1-SNAPSHOT-jar-with-dependencies.jar"
$APISERVER_JAR = "$modulesDir/Vienna/apiserver/target/apiserver-0.0.1-SNAPSHOT-jar-with-dependencies.jar"
$LAUNCHER_JAR = "$modulesDir/Vienna/buildplate/launcher/target/buildplate-launcher-0.0.1-SNAPSHOT-jar-with-dependencies.jar"
$TAPPABLES_JAR = "$modulesDir/Vienna/tappablesgenerator/target/tappablesgenerator-0.0.1-SNAPSHOT-jar-with-dependencies.jar"
$CDN_JAR = "$modulesDir/Vienna/utils/cdn/target/utils-cdn-0.0.1-SNAPSHOT-jar-with-dependencies.jar"
$LOCATOR_JAR = "$modulesDir/Vienna/utils/locator/target/utils-locator-0.0.1-SNAPSHOT-jar-with-dependencies.jar"

$BRIDGE_JAR = "$modulesDir/Fountain-bridge/target/fountain-0.0.1-SNAPSHOT-jar-with-dependencies.jar"
$CONNECTOR_PLUGIN_JAR = "$modulesDir/Vienna/buildplate/connector-plugin/target/buildplate-connector-plugin-0.0.1-SNAPSHOT-jar-with-dependencies.jar"
$FABRIC_DIR = "$modulesDir/fabric_template"
$FABRIC_JAR_NAME = "fabric-server-mc.1.20.4-loader.0.15.10-launcher.1.0.1.jar"

Write-Host "Initializing Vienna Directories..." -ForegroundColor Cyan
foreach ($dir in "objects", "static", "db", "resourcepack", "world") {
    if (!(Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
}

Copy-Item -Path "$modulesDir/Vienna-data/*" -Destination "./static" -Recurse -Force

if ($e) {
    Start-ViennaProcess "Vienna-EventBus" "-jar $EVENTBUS_JAR"
}

if ($o) {
    Start-ViennaProcess "Vienna-ObjectStore" "-jar $OBJECTSTORE_JAR -dataDir ./objects"
}

Start-Sleep -Seconds 2

if ($s) {
    Start-ViennaProcess "Vienna-APIServer" "-jar $APISERVER_JAR -port $API_PORT -eventbus $EVENTBUS_HOST -objectstore $OBJECTSTORE_HOST -db ./db/earth.db -staticData ./static"
    Start-ViennaProcess "Vienna-CDN" "-jar $CDN_JAR -port $CDN_PORT -resourcePackFile ./resourcepack/resourcepack"
    Start-ViennaProcess "Vienna-Locator" "-jar $LOCATOR_JAR -port $LOCATOR_PORT -playfabTitleId 20CA2 -api http://$($ADDRESS):$($API_PORT)/ -cdn http://$($ADDRESS):$($CDN_PORT)/"
}

if ($t) {
    Start-ViennaProcess "Vienna-Tappables" "-jar $TAPPABLES_JAR -eventbus $EVENTBUS_HOST -staticData ./static"
}

if ($l) {
    Start-ViennaProcess "Vienna-Launcher" "-jar $LAUNCHER_JAR -eventbus $EVENTBUS_HOST -publicAddress $ADDRESS -bridgeJar $BRIDGE_JAR -serverTemplateDir $FABRIC_DIR -fabricJarName $FABRIC_JAR_NAME -connectorPluginJar $CONNECTOR_PLUGIN_JAR"
}

Write-Host "-----------------------------------------------" -ForegroundColor Green
Write-Host "Startup complete."

Set-Location ..