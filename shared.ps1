$API_PORT = 8088
$CDN_PORT = 8089
$LOCATOR_PORT = 8080

$EVENTBUS_HOST = "localhost"
$OBJECTSTORE_HOST = "localhost"

function Start-ViennaProcess {
    param (
        [string]$Title,
        [string]$LaunchArgs
    )

    Write-Host "Spawning $Title..." -ForegroundColor Gray

    if ($IsWindows) {
        Start-Process cmd -ArgumentList "/c", "title $Title & java $LaunchArgs & pause"
    }
    elseif ($IsLinux) {
        $term = Get-Command x-terminal-emulator, gnome-terminal, xfce4-terminal, konsole, xterm -ErrorAction SilentlyContinue | Select-Object -First 1
        
        if ($null -ne $term) {
            $bin = $term.Source
            $BashCmd = "echo '--- $Title ---'; java $LaunchArgs; echo 'Process exited.'; exec bash"
            
            if ($bin -match "gnome-terminal") {
                Start-Process $bin -ArgumentList "--", "bash", "-c", "$BashCmd"
            }
            else {
                Start-Process $bin -ArgumentList "-e", "bash -c ""$BashCmd"""
            }
        }
        else {
            Write-Warning "No terminal found for $Title. Running in background."
            Start-Process java -ArgumentList ($LaunchArgs -split ' ')
        }
    }
    elseif ($IsMacOS) {
        $FullCommand = "echo '--- $Title ---'; java $LaunchArgs; echo 'Process exited.'; exec bash"
        $AppleScript = "tell app `"Terminal`" to do script `"$FullCommand`""
        Start-Process osascript -ArgumentList "-e", $AppleScript
    }
}