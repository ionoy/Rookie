class CoreQuickNav {
    [System.Management.Automation.PathInfo] $lastDir
    [hashtable] $coreState
    [System.Management.Automation.Host.PSHost] $hostContext
    
    [boolean] $isFocused = $false
    [hashtable] $paths = @{}
    [scriptblock] $previousPathLister = {}
    [scriptblock] $pathLister = {
        param (
            [string] $path,
            [hashtable] $coreState
        )
        
#        return @(
#            Get-Item "c:\projects\" 
#            Get-Item "c:\projects\springfin\net5\docutrack" 
#            Get-Item "c:\projects\springfin\net5\psr"
#        )
        
        # ignore $path, return the most used paths
        $self = $coreState.plugins.CoreQuickNav
        $paths = $self.paths.GetEnumerator() | Sort-Object -Property Value -Descending | Select-Object -First 10
        $items = $paths | ForEach-Object { Get-Item -LiteralPath $_.Key }
        
        return $items
    }

    CoreQuickNav([hashtable] $coreState, [System.Management.Automation.Host.PSHost] $hostContext) {
        $this.coreState = $coreState
        $this.coreState.plugins["CoreQuickNav"] = $this
        $this.hostContext = $hostContext
        
        $this.LoadPathsFromFile()
    }

    [void] Tick() {
         $this.AddCurrentDir()
         
         if ($this.isFocused) {
             if ($this.coreState.key.VirtualKeyCode -eq 13) {
                $this.Unfocus()
             }

             # esc
             if ($this.coreState.key.VirtualKeyCode -eq 27 -or $this.coreState.key.VirtualKeyCode -eq 8) {
                 if ($this.isFocused -eq $true) {
                     $this.Unfocus()
                 }
             }
         }
    }
    
    [void] Focus() {
        $this.isFocused = $true
        $this.coreState.key = $null
        $this.previousPathLister = $this.coreState.pathLister
        $this.coreState.pathLister = $this.pathLister
        $this.coreState.plugins.CoreNavigation.ShowDirectoryContent($true)
        $this.coreState.plugins.CoreNavigation.upNavigationEnabled = $false
        
        Log "qn Focused"
    }
    
    [void] Unfocus() {
        $this.isFocused = $false
        $this.coreState.key = $null
        $this.coreState.pathLister = $this.previousPathLister
        $this.coreState.plugins.CoreNavigation.ShowDirectoryContent($true)
        $this.coreState.plugins.CoreNavigation.upNavigationEnabled = $true

        Log "qn Focused"
    }
    
    [void] AddCurrentDir() {
        if ($this.coreState.currentDir -ne $this.lastDir) {
            $this.lastDir = $this.coreState.currentDir

            # increase weight of the current path in $paths
            if ($this.paths[$this.lastDir.Path]) {
                $this.paths[$this.lastDir.Path] += 1
            } else {
                $this.paths[$this.lastDir.Path] = 1
            }
        }
    }
    
    [void] OnQuit() {
        Log "CoreQuickNav OnQuit"
        $this.SavePathsToFile()
    }
    
    [void] SavePathsToFile() {
        Log "CoreQuickNav SavePathsToFile"
        $json = $this.paths | ConvertTo-Json -Depth 2
        $json | Set-Content -Path "$PSScriptRoot\paths.json"
    }
    
    [void] LoadPathsFromFile() {
        Log "CoreQuickNav LoadPathsFromFile from $PSScriptRoot\paths.json"
        if (-not (Test-Path "$PSScriptRoot\paths.json")) {
            return
        }

        $json = Get-Content -Path "$PSScriptRoot\paths.json" -Raw
        $psObject = $json | ConvertFrom-Json        
        $psObject.PSObject.Properties | ForEach-Object { $this.paths[$_.Name] = $_.Value }
    }
}