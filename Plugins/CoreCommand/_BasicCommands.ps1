param(
    [object] $commandPlugin
)

Add-Type -AssemblyName System.Windows.Forms

$commandPlugin.AddCommand("copy", @("c", "cp"), "Copy selected file or files into clipboard", {
    param (
        [Parameter(Mandatory=$true)] [object] $commandPlugin
    )
    $context = $commandPlugin.GetContext()
    Log "copy"
    Log $context.selectedPaths[0]

    $context.commandContext.copyBuffer = $context.selectedPaths
    
    if ($IsWindows) {
        [System.Windows.Forms.Clipboard]::SetFileDropList($context.selectedPaths)
    }
})

$commandPlugin.AddCommand("paste", @("v"), "Paste selected file or files", {
    param (
        [Parameter(Mandatory=$true)] [object] $commandPlugin
    )
    $context = $commandPlugin.GetContext()
    Log "paste"
    $context.commandContext.copyBuffer | Copy-Item -Destination $context.selectedPath
})

$commandPlugin.AddCommand("delete", @("d", "rm"), "Delete selected file or files", {
    param (
        [Parameter(Mandatory=$true)] [object] $commandPlugin
    )
    $context = $commandPlugin.GetContext()
    Log "delete"
    $context.selectedPaths | Remove-Item -Recurse -Force
})