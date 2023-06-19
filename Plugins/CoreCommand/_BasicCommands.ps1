param(
    [object] $commandPlugin
)

Add-Type -AssemblyName System.Windows.Forms

$commandPlugin.AddCommand("copy", @("c", "cp"), "Copy selected file or files into clipboard", {
    param (
        [Parameter(Mandatory=$true)] [object] $commandPlugin
    )
    $context = $commandPlugin.GetContext()

    $context.commandContext.copyBuffer = $context.selectedPaths
    $context.plugins.CoreStatus.text = "Copied $($context.commandContext.copyBuffer.Count) items"
    
    if ($IsWindows) {
        [System.Windows.Forms.Clipboard]::SetFileDropList($context.selectedPaths)
    }
})

$commandPlugin.AddCommand("paste", @("v"), "Paste selected file or files", {
    param (
        [Parameter(Mandatory=$true)] [object] $commandPlugin
    )
    $context = $commandPlugin.GetContext()
    
    $context.commandContext.copyBuffer | Copy-Item -Destination $context.selectedPath
    $context.plugins.CoreStatus.text = "Pasted $($context.commandContext.copyBuffer.Count) items"
})

$commandPlugin.AddCommand("delete", @("d", "rm"), "Delete selected file or files", {
    param (
        [Parameter(Mandatory=$true)] [object] $commandPlugin
    )
    $context = $commandPlugin.GetContext()
    Log "delete"
    $context.selectedPaths | Remove-Item -Recurse -Force
})

$commandPlugin.AddCommand("quit", @("q"), "Quit Rookie", {
    param (
        [Parameter(Mandatory=$true)] [object] $commandPlugin
    )
    $context = $commandPlugin.GetContext()
    Log "delete"
    $context.quitting = $true
})