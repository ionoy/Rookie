function Show-NavigationMode {
    param (
        [Parameter(Mandatory=$false)] [string] $filter,
        [Parameter(Mandatory=$false)] [int] $selected
    )

    $host.UI.RawUI.CursorPosition = New-Object -TypeName System.Management.Automation.Host.Coordinates -ArgumentList 0, 0

    $itemsToShow = $script:favoritePaths.GetEnumerator() | Sort-Object -Property Value -Descending | Select-Object -ExpandProperty Key

    if ($selected -ge $itemsToShow.Count) {
        $selected = $itemsToShow.Count - 1
    }

    $start = $selected - $Host.UI.RawUI.WindowSize.Height / 2
    if ($start -lt 0) { $start = 0 }

    $linesPrinted = 0

    for ($i=$start; $i -lt $itemsToShow.Count; $i++) {
        $itemName = $itemsToShow[$i]
        $fg = 'White'        

        if ($i -eq $selected) {
            Write-Host $itemName -NoNewline -BackgroundColor Yellow -ForegroundColor Black
            $script:selectedName = $itemName
        } else {
            Write-Host $itemName -NoNewline -ForegroundColor $fg
        }

        # Fill the rest of the line with spaces
        Write-Host (''.PadRight($host.UI.RawUI.WindowSize.Width - $itemName.Length, ' ')) -NoNewline
        Write-Host ''  # To move to the next line
        $linesPrinted++

        if ($linesPrinted -ge $Host.UI.RawUI.WindowSize.Height - 3) {            
            break
        }
    }

    # Clear remaining lines and print the filter
    while ($linesPrinted -lt $Host.UI.RawUI.WindowSize.Height - 2) {
        Write-Host (''.PadRight($host.UI.RawUI.WindowSize.Width, ' '))
        $linesPrinted++
    }

    Write-Host ("$filter".PadRight($host.UI.RawUI.WindowSize.Width - 1, ' '))
    [console]::CursorVisible = $false
}


# switch ($key.VirtualKeyCode) {                    
#     # tab
#     9 {
#         $script:navigationMode = -not $script:navigationMode
#         Log "navigation mode: $script:navigationMode"
#     }
# }


# 44 { # ctrl+,
#     $script:navigationMode = -not $script:navigationMode
# }