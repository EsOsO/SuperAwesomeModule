Remove-Module $env:BHProjectName -Force -ErrorAction SilentlyContinue
Import-Module $env:BHPSModuleManifest -Force

Describe -Tags Build, Unit ('{0} manifest' -f $env:BHProjectName) {
    It 'output a capitalized string' {
        $str = 'Hello, World!'
        Get-SuperAwesomeFunction -Text $str | Should -Be $str.ToUpper()
    }
}