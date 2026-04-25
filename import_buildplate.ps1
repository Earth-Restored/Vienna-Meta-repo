#!/usr/bin/env pwsh
Param (
    [string][Parameter(Mandatory=$true)] $playerId,
    [string][Parameter(Mandatory=$true)] $worldFile
)

. ./shared.ps1

Set-Location ./build

$IMPORTER_JAR = "./../modules/Vienna/utils/tools/buildplate-importer/target/utils-tools-buildplate-importer-0.0.1-SNAPSHOT-jar-with-dependencies.jar"

Start-ViennaProcess "Vienna-BuildplateImporter" "-jar $IMPORTER_JAR -db ./db/earth.db -eventbus $EVENTBUS_HOST -objectstore $OBJECTSTORE_HOST -playerId $playerId -worldFile $worldFile"

Set-Location ..