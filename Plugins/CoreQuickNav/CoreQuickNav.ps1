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
    }

    [void] Tick() {
         $this.AddCurrentDir()
         
         if ($this.isFocused) {
             if ($this.coreState.key.VirtualKeyCode -eq 13) {
                $this.Unfocus()
             }
         }
    }
    
    [void] Focus() {
        $this.isFocused = $true
        $this.coreState.key = $null
        $this.previousPathLister = $this.coreState.pathLister
        $this.coreState.pathLister = $this.pathLister
        $this.coreState.plugins.CoreNavigation.ShowDirectoryContent($true)
    }
    
    [void] Unfocus() {
        $this.isFocused = $false
        $this.coreState.key = $null
        $this.coreState.pathLister = $this.previousPathLister
        $this.coreState.plugins.CoreNavigation.ShowDirectoryContent($true)
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
}