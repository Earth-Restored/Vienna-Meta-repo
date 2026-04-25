#!/usr/bin/env pwsh

. ./shared.ps1

$modulesToBuild = "./.."

mkdir ./build
mkdir ./staticdata
mkdir ./staticdata/server_jars
mkdir ./staticdata/server_template_dir
mkdir ./staticdata/server_template_dir/mods

cd modules

# Fountain
cd Protocol
./gradlew publishToMavenLocal
cd ..

cd Fountain-connector-plugin-base
./mvnw install
cd ..

cd Fountain-bridge
./mvnw package
cd ..

cp ./Fountain-bridge/target/fountain-0.0.1-SNAPSHOT-jar-with-dependencies.jar $modulesToBuild/staticdata/server_jars/fountain-0.0.1-SNAPSHOT-jar-with-dependencies.jar

cd Fountain-fabric
./gradlew build
./gradlew publishToMavenLocal
cd ..

cp ./Fountain-fabric/build/libs/fountain-0.0.1.jar $modulesToBuild/staticdata/server_template_dir/mods/fountain-0.0.1.jar

# Vienna
cd Vienna
./mvnw package
./mvnw install
cd..

cp ./Vienna/buildplate/connector-plugin/target/buildplate-connector-plugin-0.0.1-SNAPSHOT-jar-with-dependencies.jar $modulesToBuild/staticdata/server_jars/buildplate-connector-plugin-0.0.1-SNAPSHOT-jar-with-dependencies.jar

cd Vienna-fabric
./gradlew build
cd ..

cp ./Vienna-fabric/build/libs/vienna-0.0.1.jar $modulesToBuild/staticdata/server_template_dir/mods/vienna-0.0.1.jar

cd ..
