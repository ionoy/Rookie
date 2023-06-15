class CoreCommand {
    [hashtable] $coreState
    [string] $name = "Core Command"
    [string] $command = ""
    [System.Management.Automation.Host.PSHost] $hostContext
    [hashtable] $commands = @{}

    CoreCommand ([hashtable] $coreState, [System.Management.Automation.Host.PSHost] $hostContext) {
        $this.coreState = $coreState
        $this.coreState["CoreCommand"] = $this
        $this.hostContext = $hostContext

        $commandFiles = Get-ChildItem -Path . -Filter "_*.ps1" -Recurse

        foreach ($commandFile in $commandFiles) {
            Log "Loading command file $commandFile"
            . $commandFile.FullName $this            
        }
    }

    [void] Tick () {
        $this.ReceiveKeyboardInput()
        if ($this.coreState.focus -eq $this.name) {
            $this.ShowCommandMode()
        }
    }

    [void] ReceiveKeyboardInput () {
        if ($this.coreState.focus -eq $this.name) {
            switch ($this.coreState.key.VirtualKeyCode) {
                # tab
                9 {
                    $this.command = ""
                    Release-RookieFocus
                }
                # enter
                13 {
                    $this.InvokeSelectedCommand()
                    $this.command = ""                   
                    
                    Release-RookieFocus
                }
                8 {
                    if ($this.command.Length -gt 0) {
                        $this.command = $this.command.Substring(0, $this.command.Length - 1)
                        $cmd = $this.command
                        Log "command: $cmd"
                    }
                }
                default {
                    if ($this.coreState.key -and $this.coreState.key.VirtualKeyCode -lt 255) {
                        $char = [char]$this.coreState.key.Character
                        if ($char -match '[a-zA-Z0-9]') {
                            $this.command += $char
                            $cmd = $this.command
                            Log "command: $cmd"
                        }
                    }
                }
            }
        } else {
            switch ($this.coreState.key.VirtualKeyCode) {
                # tab
                9 {
                    Set-RookieFocus $this.name
                    Log "command mode"
                }
            }
        }
    }

    [void] ShowCommandMode () {
        $this.hostContext.UI.RawUI.CursorPosition = New-Object -TypeName System.Management.Automation.Host.Coordinates -ArgumentList 0, ($this.hostContext.UI.RawUI.WindowSize.Height - 2)
        $cmd = $this.command
        Write-Host (":$cmd".PadRight($this.hostContext.UI.RawUI.WindowSize.Width - 2, ' ')) -NoNewline        
        $this.hostContext.UI.RawUI.CursorPosition = New-Object -TypeName System.Management.Automation.Host.Coordinates -ArgumentList ($cmd.Length + 1), ($this.hostContext.UI.RawUI.WindowSize.Height - 2)
    }
    
    [void] InvokeSelectedCommand() {
        $this.InvokeCommand($this.command)
    }
    
    [void] InvokeCommand([string] $command) {
        try
        {
            $cmd = $this.commands[$command]
            if (-not $cmd) {
                foreach ($command in $this.commands.Values) {
                    if ($command.aliases -contains $command) {
                        $cmd = $command
                        break
                    }
                }
            }

            if ($cmd)
            {
                &$cmd.scriptblock $this

                $this.coreState.CoreNavigation.ShowDirectoryContent($true)
            }
            else
            {
                $this.coreState.CoreStatus.text = "Command not found: $($command)"
            }
        }
        catch
        {
            Log $_.Exception.Message
        }

    }
    
    [hashtable] GetContext() {
        if (-not $this.coreState.commandContext) {
            $this.coreState.commandContext = @{}
        }
        
        return $this.coreState
    }
    
    #add command method that takes: command name, aliases, description, and a scriptblock
    [void] AddCommand ([string] $name, [string[]] $aliases, [string] $description, [scriptblock] $scriptblock) {
        $this.commands[$name] = @{
            "name" = $name
            "aliases" = $aliases
            "description" = $description
            "scriptblock" = $scriptblock
        }
    }
}