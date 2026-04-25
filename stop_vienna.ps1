#!/usr/bin/env pwsh

. ./shared.ps1

Write-Host "Starting shutdown..." -ForegroundColor Cyan

$JarIdentifiers = @(
    "eventbus-server",
    "objectstore-server",
    "apiserver",
    "utils-cdn",
    "utils-locator",
    "tappablesgenerator",
    "buildplate-launcher",
    "fabric-server" 
)

$Titles = @(
    "Vienna-EventBus", "Vienna-ObjectStore", "Vienna-APIServer", 
    "Vienna-CDN", "Vienna-Locator", "Vienna-Tappables", "Vienna-Launcher"
)

if ($IsWindows) {
    Write-Host "Sending graceful close signals to Windows terminals..." -ForegroundColor Gray
    
    foreach ($Title in $Titles) {
        Write-Host "Sending close signal to $Title..."
        taskkill /FI "WINDOWTITLE eq *$Title*" > $null 2>&1
    }

    Write-Host "Shutdown signals sent. Terminals will close once Java processes exit." -ForegroundColor Green
}
elseif ($IsLinux -or $IsMacOS) {
    Write-Host "Locating Vienna processes..." -ForegroundColor Gray

    $psOutput = bash -c "ps -eww -o pid,command"
    $JavaPids = @()
    $WrapperPids = @()

    foreach ($line in $psOutput) {
        if ($line -match "stop_vienna" -or $line -match "pwsh") { continue }

        foreach ($jar in $JarIdentifiers) {
            if ($line -match [regex]::Escape($jar)) {
                $parts = $line.Trim() -split '\s+', 2
                if ($parts.Length -lt 2) { continue }
                
                $procId = $parts[0]
                $command = $parts[1]

                if ($command -match "exec bash") {
                    if ($procId -notin $WrapperPids) { $WrapperPids += $procId }
                }
                elseif ($command -match "java ") {
                    if ($procId -notin $JavaPids) { $JavaPids += $procId }
                }
                break
            }
        }
    }

    if ($JavaPids.Count -eq 0 -and $WrapperPids.Count -eq 0) {
        Write-Host "No running Vienna processes found." -ForegroundColor Yellow
    } else {
        if ($JavaPids.Count -gt 0) {
            Write-Host "Sending shutdown to $($JavaPids.Count) Java process(es)..."
            foreach ($ppid in $JavaPids) {
                bash -c "kill -15 $ppid 2>/dev/null"
            }

            Write-Host "Waiting 5 seconds for shutdown..." -ForegroundColor Gray
            Start-Sleep -Seconds 5
        }

        if ($WrapperPids.Count -gt 0) {
            Write-Host "Closing $($WrapperPids.Count) terminal wrapper(s)..."
            foreach ($ppid in $WrapperPids) {
                bash -c "kill -HUP $ppid 2>/dev/null"
                bash -c "kill -9 $ppid 2>/dev/null" # Fallback
            }
        }

        if ($IsMacOS) {
            Write-Host "Cleaning up macOS Terminal GUI windows..." -ForegroundColor Gray
            foreach ($Title in $Titles) {
                bash -c "osascript -e 'tell application `"Terminal`" to close (every window whose name contains `"$Title`")' 2>/dev/null"
            }
        }
        
        Write-Host "Shutdown signals sent." -ForegroundColor Green
    }
}

Write-Host "-----------------------------------------------" -ForegroundColor Green
Write-Host "Shutdown complete."