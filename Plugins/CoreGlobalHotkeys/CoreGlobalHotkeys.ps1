class CoreGlobalHotkeys {
    [hashtable] $coreState
    [System.Management.Automation.Host.PSHost] $hostContext    
    
    CoreGlobalHotkeys([hashtable] $coreState, [System.Management.Automation.Host.PSHost] $hostContext) {
        $this.coreState = $coreState
        $this.coreState.plugins["CoreGlobalHotkeys"] = $this
        $this.hostContext = $hostContext
    }
    
    [void] Tick() {
        Log "CoreGlobalHotkeys ControlKeyState: $($this.coreState.key)"
        if (($this.coreState.key.ControlKeyState -band 0x10) -ne 0)
        {
            switch ($this.coreState.key.VirtualKeyCode)
            {
                67 { # c                        
                    $this.coreState.plugins.CoreCommand.InvokeCommand("copy")
                    $this.coreState.key = $null
                }
                86 { # v
                    $this.coreState.plugins.CoreCommand.InvokeCommand("paste")
                    $this.coreState.key = $null
                }
                88 { # x
                    $this.coreState.plugins.CoreCommand.InvokeCommand("cut")
                    $this.coreState.key = $null
                }
                46 { # del
                    $this.coreState.plugins.CoreCommand.InvokeCommand("delete")
                    $this.coreState.key = $null
                }
                65 { # a
                    $this.coreState.plugins.CoreCommand.InvokeCommand("selectall")
                    $this.coreState.key = $null                        
                }
                84 { # t
                    Log "CoreGlobalHotkeys Toggling CoreQuickNav"
                    if ($this.coreState.focus -ne "CoreQuickNav") {
                        $this.coreState.plugins.CoreQuickNav.Focus()
                    }
                    else {
                        $this.coreState.plugins.CoreQuickNav.Unfocus()
                    }
                }
            }
        }
    }
}