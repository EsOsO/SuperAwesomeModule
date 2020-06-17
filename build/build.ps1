param (
    [string[]] $Task = 'Default'
)

$ErrorView = 'NormalView'

Write-Verbose -Message ('Beginning "{0}" process...' -f ($Task -join ','))

# Bootstrap the environment
Get-PackageProvider -Name NuGet -ForceBootstrap

# Install PSDepend module if it is not already installed
if (-not (Get-Module -Name PSDepend -ListAvailable)) {
    Install-Module -Name PSDepend -Scope CurrentUser -Force -Confirm:$false
}

# Install build dependencies required for Init task
Import-Module -Name PSDepend
Invoke-PSDepend -Path $PSScriptRoot -Force -Import -Install

Set-BuildEnvironment -Force

# Execute the PSake tasts from the psakefile.ps1
Invoke-Psake -buildFile (Join-Path -Path $PSScriptRoot -ChildPath 'build.psake.ps1') -nologo -taskList $Task

exit ( [int]( -not $psake.build_success ) )
