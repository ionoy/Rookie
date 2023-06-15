class CoreGlobalHotkeys {
    [hashtable] $coreState
    [System.Management.Automation.Host.PSHost] $hostContext    
    
    CoreGlobalHotkeys([hashtable] $coreState, [System.Management.Automation.Host.PSHost] $hostContext) {
        $this.coreState = $coreState
        $this.coreState["CoreGlobalHotkeys"] = $this
        $this.hostContext = $hostContext
    }
    
    [void] Tick() {
        if ($this.coreState.focus -eq "Core Navigation") {
            Log "CoreGlobalHotkeys: $($this.coreState.key.ControlKeyState)"
            
            if (($this.coreState.key.ControlKeyState -band 0x10) -ne 0)
            {
                switch ($this.coreState.key.VirtualKeyCode)
                {
                    67 { # c                        
                        $this.coreState.CoreCommand.InvokeCommand("copy")
                        $this.coreState.key = $null
                    }
                    86 { # v
                        $this.coreState.CoreCommand.InvokeCommand("paste")
                        $this.coreState.key = $null
                    }
                    88 { # x
                        $this.coreState.CoreCommand.InvokeCommand("cut")
                        $this.coreState.key = $null
                    }
                    46 { # del
                        $this.coreState.CoreCommand.InvokeCommand("delete")
                        $this.coreState.key = $null
                    }
                    65 { # a
                        $this.coreState.CoreCommand.InvokeCommand("selectall")
                        $this.coreState.key = $null                        
                    }
                }
            }
        }
    }
}