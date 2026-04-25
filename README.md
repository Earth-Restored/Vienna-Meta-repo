# Vienna meta repo

Scripts to build and run Vienna.

## build_vienna.ps1

Builds all Vienna components and copies relevant jars into staticdata, in the format of ViennaDotNet.StaticData.

## run_vienna.ps1

Runs Vienna, requires that `build_vienna.ps1` was ran before, the resourcepack should be placed in `build/resourcepack/resourcepack`.

## import_buildplate.ps1

Imports a Vienna buildplate, the server needs to be running.

## stop_vienna.ps1

Stop all currently running Vienna components.
