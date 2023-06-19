class CoreItemInfo {
    [string] $text = ""
    [hashtable] $coreState
    [System.Management.Automation.Host.PSHost] $hostContext

    CoreItemInfo([hashtable] $coreState, [System.Management.Automation.Host.PSHost] $hostContext) {
        $this.coreState = $coreState
        $this.coreState.plugins["CoreItemInfo"] = $this
        $this.hostContext = $hostContext
    }

    [void] Tick() {
        $item = $this.coreState.selectedItem
        if ($item.Name -ne "..") {
            $this.coreState.plugins.CoreStatus.text = "[$( $item.CreationTime )] [$( $item.LastWriteTime )] $( $item.Mode )"

            if (-not$item.PSIsContainer) {
                $units = 'B', 'KB', 'MB', 'GB'
                $scale = 0
                $itemLength = $item.Length
                while ($itemLength -ge 1024 -and $scale -lt $units.Length)
                {
                    $itemLength /= 1024
                    $scale++
                }
                $fileSizeString = if ($itemLength -eq [math]::Truncate($itemLength))
                {
                    "{0:N0}{1}" -f $itemLength, $units[$scale]
                }
                else
                {
                    "{0:N2}{1}" -f $itemLength, $units[$scale]
                }
                $fileSizeString = $fileSizeString.PadRight(10, ' ')

                $this.coreState.plugins.CoreStatus.text = $fileSizeString + " " + $this.coreState.plugins.CoreStatus.text
            }
        } else {
            $this.coreState.plugins.CoreStatus.text = ""
        }
    }
}