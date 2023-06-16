class CoreStatus {
    [string] $text = ""
    [hashtable] $coreState
    [System.Management.Automation.Host.PSHost] $hostContext

    CoreStatus([hashtable] $coreState, [System.Management.Automation.Host.PSHost] $hostContext) {
        $this.coreState = $coreState
        $this.coreState.plugins["CoreStatus"] = $this
        $this.hostContext = $hostContext
    }

    [void] Tick() {
        # set cursor to the last line of the console
        $this.hostContext.UI.RawUI.CursorPosition = New-Object -TypeName System.Management.Automation.Host.Coordinates -ArgumentList 0, ($this.hostContext.UI.RawUI.WindowSize.Height - 1)
        Write-Host ($this.text).PadRight($this.hostContext.UI.RawUI.WindowSize.Width - 2, ' ') -NoNewline
    }
}