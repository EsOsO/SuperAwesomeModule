$ModuleName = 'SuperAwesomeModule'

Remove-Module $ModuleName -Force -ErrorAction SilentlyContinue

$ManifestPath = '{0}\..\{1}\{1}.psd1' -f $PSScriptRoot, $ModuleName
$ChangeLogPath = '{0}\..\CHANGELOG.md' -f $PSScriptRoot

Import-Module $ManifestPath -Force

Describe -Tags Build, Unit "$ModuleName manifest" {
    $Script:Manifest = $null

    It 'has a valid manifest' {
        { $script:Manifest = Test-ModuleManifest -Path $ManifestPath -ErrorAction Stop } | Should -Not -Throw
    }

    It 'has a valid name in the manifest' {
        $script:Manifest.Name | Should -Be $ModuleName
    }

    It 'has a valid guid in the manifest' {
        $script:Manifest.Guid | Should -Match '^[a-z0-9]{8}-([a-z0-9]{4}-){3}[a-z0-9]{12}$'
    }

    It 'has a valid version in the manifest' {
        $script:Manifest.Version -as [Version] | Should -Not -BeNullOrEmpty
    }
}
