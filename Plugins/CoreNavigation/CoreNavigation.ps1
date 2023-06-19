class CoreNavigation {
    [hashtable] $coreState
    [string] $name = "Core Navigation"
    [string] $filter = ""
    [string] $lastFilter = ""
    [string] $lastPath = ""
    [array] $itemsCache = @()
    [array] $itemsToShow = @()
    [int] $selectedIndex = 0
    [string] $selectedName = ""
    [boolean] $upNavigationEnabled = $true
    
    [System.Management.Automation.Host.PSHost] $hostContext
    [scriptblock] $pathLister = {
        param ([string]$path)
        
        $items = Get-ChildItem $path
        $rootItem = Get-Item -LiteralPath $path
        
        if ($rootItem.FullName -ne $rootItem.Root.FullName) {
            $parent = New-Object PSObject -Property @{
                Name = ".."
                FullName = (Get-Item -LiteralPath (Join-Path $path "..")).FullName
                PSIsContainer = $true
            }
            $items = @($parent) + $items
        }

        return $items
    }
    
    CoreNavigation ([hashtable] $coreState, [System.Management.Automation.Host.PSHost] $hostContext) {
        $this.coreState = $coreState
        $this.coreState.plugins["CoreNavigation"] = $this
        $this.hostContext = $hostContext
        $this.coreState.focus = $this.name        
        $this.coreState.pathLister = $this.pathLister
    }

    [void] Tick() {
        $this.ReceiveKeyboardInput()
        $this.ShowDirectoryContent($false)
    }

    [void] UpdateCurrentDirectory([bool] $forceUpdate = $false) {
        $path = $this.coreState.currentDir.Path

        if ($path -ne $this.lastPath -or $forceUpdate) {
            Log $this.coreState.pathLister
            $this.itemsCache = & $this.coreState.pathLister $path $this.coreState
            $this.itemsToShow = $this.itemsCache
            $this.lastPath = $path
            
            Log $this.itemsCache.Count
        }
    }

    [void] UpdateFilteredDirectory() {
        if ($this.filter -ne $this.lastFilter) {
            if ($this.filter) {
                $this.itemsToShow = $this.itemsCache.Where({ $_.Name -like ("*"+$this.filter+"*") })
            } else {
                $this.itemsToShow = $this.itemsCache
            }
            $this.lastFilter = $this.filter
        }
    }

    [void] ShowDirectoryContent([bool] $forceUpdate) {
        $this.UpdateCurrentDirectory($forceUpdate)
        $this.UpdateFilteredDirectory()

        $this.hostContext.UI.RawUI.CursorPosition = New-Object -TypeName System.Management.Automation.Host.Coordinates -ArgumentList 0, 0

        if ($this.selectedIndex -ge $this.itemsToShow.Count) {
            $this.selectedIndex = $this.itemsToShow.Count - 1
        }

        $start = $this.selectedIndex - $this.hostContext.UI.RawUI.WindowSize.Height / 2
        if ($start -lt 0) { $start = 0 }

        $linesPrinted = 0

        for ($i=$start; $i -lt $this.itemsToShow.Count; $i++) {
            $item = $this.itemsToShow[$i]
            if ($item.PSIsContainer) {
                $fg = 'Green'
            } else {
                $fg = 'White'
            }

            $itemName = $item.Name

            if ($item.PSIsContainer -and $itemName -ne "..") {
                $itemName = $itemName + '/'
            }

            if ($i -eq $this.selectedIndex) {
                Write-Host $itemName -NoNewline -BackgroundColor Yellow -ForegroundColor Black
                $this.coreState.selectedItem = $item
            } else {
                Write-Host $itemName -NoNewline -ForegroundColor $fg
            }

            Write-Host (''.PadRight($this.hostContext.UI.RawUI.WindowSize.Width - $itemName.Length, ' ')) -NoNewline
            Write-Host ''

            $linesPrinted++

            if ($linesPrinted -ge $this.hostContext.UI.RawUI.WindowSize.Height - 1) {
                break
            }
        }

        while ($linesPrinted -lt $this.hostContext.UI.RawUI.WindowSize.Height - 1) {
            Write-Host (''.PadRight($this.hostContext.UI.RawUI.WindowSize.Width, ' '))
            $linesPrinted++
        }

        Write-Host ($this.filter.PadRight($this.hostContext.UI.RawUI.WindowSize.Width - 2, ' ')) -NoNewline
        $this.hostContext.UI.RawUI.CursorPosition = New-Object -TypeName System.Management.Automation.Host.Coordinates -ArgumentList ($this.filter.Length), ($this.hostContext.UI.RawUI.WindowSize.Height - 1)
    }

    [void]ReceiveKeyboardInput() {
        if ($this.coreState.focus -eq $this.name) {
            $pageSize = $this.hostContext.UI.RawUI.WindowSize.Height - 3

            switch ($this.coreState.key.VirtualKeyCode) {
                38 { # up
                    if ($this.selectedIndex -gt 0)
                    {
                        $this.selectedIndex--
                        $this.ReplaceSelectedPaths()
                    }
                }
                40 { # down
                    if ($this.selectedIndex -lt $this.itemsToShow.Count - 1) {
                        $this.selectedIndex++
                        $this.ReplaceSelectedPaths()
                    }
                }
                32 { # space
                    $this.AppendSelectedPath()
                }                
                13 { # enter
                    if ($this.itemsToShow[$this.selectedIndex].PSIsContainer) {
                        Set-Location -Path $this.itemsToShow[$this.selectedIndex].FullName
                        $this.coreState.currentDir = Get-Location
                        $this.filter = ""
                        $this.selectedIndex = 0
                    } else {
                        Invoke-Item $this.itemsToShow[$this.selectedIndex].FullName
                    }
                }
                8 { # backspace
                    if ($this.filter) {
                        $this.filter = $this.filter.Substring(0, $this.filter.Length - 1)
                    } else {
                        if ($this.upNavigationEnabled)
                        {
                            Set-Location ..
                            $this.coreState.currentDir = Get-Location
                            $this.selectedIndex = 0
                        }
                    }
                }
                33 { # page up
                    $this.selectedIndex -= $pageSize
                    if ($this.selectedIndex -lt 0) { $this.selectedIndex = 0 }
                }
                34 { # page down
                    $this.selectedIndex += $pageSize
                    if ($this.selectedIndex -gt $this.itemsToShow.Count - 1) { $this.selectedIndex = $this.itemsToShow.Count - 1 }
                }
                36 { # home
                    $this.selectedIndex = 0
                }
                35 { # end
                    $this.selectedIndex = $this.itemsToShow.Count - 1
                }
                default {
                    if ($this.coreState.key -and $this.coreState.key.VirtualKeyCode -lt 255) {
                        $char = [char]$this.coreState.key.Character
                        # Using regex to check for valid path characters: alphanumeric, underscores, hyphens, dots, and slashes
                        if ($char -match '^[a-zA-Z0-9_\-\.\\/]$') {
                            $this.filter += $char
                            $this.selectedIndex = 0
                        }                        
                    }
                }
            }
        }
    }
    
    [void] ReplaceSelectedPaths() {
        $this.coreState.selectedPaths = @($this.itemsToShow[$this.selectedIndex].FullName)
    }
    
    [void] AppendSelectedPath() {
        $this.coreState.selectedPaths += @($this.itemsToShow[$this.selectedIndex].FullName)
    }
}
