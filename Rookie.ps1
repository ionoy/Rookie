$coreState = @{
    currentDir = Get-Location
    plugins = @{}
    renderQueue = @{}
    selectedPaths = @()
    needUIRefresh = $false
    focus = "core"
}

function Add-RookiePlugin {
    param (
        [Parameter(Mandatory=$true)] [string] $name,
        [Parameter(Mandatory=$true)] [int] $renderPriority,
        [Parameter(Mandatory=$true)] [scriptblock] $mainLoop
    )

    $coreState.plugins[$name] = $mainLoop
    $coreState.renderQueue[$renderPriority] = $mainLoop

    Log "Added plugin $name with render priority $renderPriority"
}

function Start-Rookie {
    try {
        $pluginFiles = Get-ChildItem -Path "Plugins" -Filter "*.ps1" -Recurse | Where-Object { $_.BaseName -eq $_.Directory.Name }        
                
        foreach ($pluginFile in $pluginFiles) {
            Log "Loading plugin $pluginFile"
            $pluginPath = $pluginFile.FullName
            . $pluginPath         
        }

        $coreState.renderQueue[0] = [CoreGlobalHotkeys]::new($coreState, $host)
        $coreState.renderQueue[100] = [CoreNavigation]::new($coreState, $host)
        $coreState.renderQueue[200] = [CoreCommand]::new($coreState, $host)
        $coreState.renderQueue[300] = [CoreStatus]::new($coreState, $host)
    
        $coreState.focus = "Core Navigation"

        [Console]::CursorVisible = $false
        
        $orderedPlugins = $coreState.renderQueue.GetEnumerator() | Sort-Object -Property Name | Select-Object -ExpandProperty Value

        while ($true) {
            foreach ($plugin in $orderedPlugins) {
                $plugin.Tick()
            }

            $coreState.key = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

            if (($coreState.key.Modifiers -band [System.ConsoleModifiers]::Control) -eq [System.ConsoleModifiers]::Control) {
                switch ($key.VirtualKeyCode) {                                         
                    67 { # c 
                        exit
                    }
                }
            } else {
                switch ($coreState.key.VirtualKeyCode) {
                    # escape
                    27 { 
                        exit
                    }
                }
            }
        }
    }
    catch {
        Log $_.Exception.Message
        Write-Host $_.Exception.Message -ForegroundColor Red
    }
}

function Set-RookieFocus {
    param (
        [Parameter(Mandatory=$true)] [string] $focus
    )

    $script:oldFocus = $coreState.focus
    $coreState.focus = $focus

    Log "focus: $focus"
}

function Release-RookieFocus {
    $coreState.focus = $script:oldFocus

    Log "focus: $script:oldFocus"
}

function Log {
    param (
        [Parameter(Mandatory=$true)] [string] $message = ""
    )

    #$time = Get-Date -Format "HH:mm:ss"

    add-content -path "$PSScriptRoot\nc.log.txt" -value $message
}

Clear-Content -Path "$PSScriptRoot\nc.log.txt"

Log "Loading Rookie from $PSScriptRoot"
set-alias r Start-Rookie -ErrorAction Stop

Start-Rookie