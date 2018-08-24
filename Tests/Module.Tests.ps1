Remove-Module SuperAwesomeModule -Force -ErrorAction SilentlyContinue

$ManifestPath   = '{0}\..\SuperAwesomeModule\SuperAwesomeModule.psd1' -f $PSScriptRoot
$ChangeLogPath  = '{0}\..\CHANGELOG.md' -f $PSScriptRoot

Import-Module $ManifestPath -Force

Describe -Tags Build, Unit 'SuperAwesomeModule manifest' {
    $script:Manifest = $null
    It 'has a valid manifest' {
        {
            $script:Manifest = Test-ModuleManifest -Path $ManifestPath -ErrorAction Stop -WarningAction SilentlyContinue
        } | Should Not Throw
    }

    It 'has a valid name in the manifest' {
        $script:Manifest.Name | Should Be SuperAwesomeModule
    }

    It 'has a valid guid in the manifest' {
        $script:Manifest.Guid | Should Be '6b8638dc-81f6-4a78-978e-81402faa2815'
    }

    It 'has a valid version in the manifest' {
        $script:Manifest.Version -as [Version] | Should Not BeNullOrEmpty
    }
}
