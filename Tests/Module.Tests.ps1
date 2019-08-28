Remove-Module $env:BHProjectName -Force -ErrorAction SilentlyContinue
Import-Module $env:BHPSModuleManifest -Force

Describe -Tags Build, Unit ('{0} manifest' -f $env:BHProjectName) {
    $Script:Manifest = $null

    It 'has a valid manifest' {
        { $script:Manifest = Test-ModuleManifest -Path $env:BHPSModuleManifest -ErrorAction Stop } | Should -Not -Throw
    }

    It 'has a valid name in the manifest' {
        $script:Manifest.Name | Should -Be $env:BHProjectName
    }

    It 'has a valid guid in the manifest' {
        $script:Manifest.Guid | Should -Match '^[a-z0-9]{8}-([a-z0-9]{4}-){3}[a-z0-9]{12}$'
    }

    It 'has a valid version in the manifest' {
        $script:Manifest.Version -as [Version] | Should -Not -BeNullOrEmpty
    }
}
