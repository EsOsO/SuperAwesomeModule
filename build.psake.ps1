Properties {
    $Timestamp = Get-Date -uformat "%Y%m%d-%H%M%S"
    $PSVersion = $PSVersionTable.PSVersion.Major
}

FormatTaskName (('-' * 25) + ('[ {0,-28} ]') + ('-' * 25))

Task Default -Depends Init

Task Init {
    Set-BuildEnvironment -Force
    Set-Location -Path $env:BHProjectPath

    'Build System Details:'
    Get-Item -Path ENV:BH*
    "`n"

    'Other Environment Variables:'
    Get-ChildItem -Path ENV:
    "`n"

    'PowerShell Details:'
    $PSVersionTable
    "`n"
}

Task Test -Depends Init {
    'Running Tests'
    Invoke-PSDepend -Path $env:BHProjectPath -Force -Import -Install -Tags 'Test'

    # Execute tests
    $TestScriptsPath = Join-Path -Path $env:BHProjectPath -ChildPath 'Tests'
    $TestResultsFile = Join-Path -Path $TestScriptsPath -ChildPath 'TestResults.xml'
    $CodeCoverageFile = Join-Path -Path $TestScriptsPath -ChildPath 'CodeCoverage.xml'
    $CodeCoverageJson = Join-Path -Path $TestScriptsPath -ChildPath 'CodeCoverage.json'
    $CodeCoverageSource = Get-ChildItem -Path (Join-Path -Path $env:BHModulePath -ChildPath '*.ps1') -Recurse
    $TestResults = Invoke-Pester `
        -Script $TestScriptsPath `
        -OutputFormat NUnitXml `
        -OutputFile $TestResultsFile `
        -PassThru `
        -ExcludeTag Incomplete `
        -CodeCoverage $CodeCoverageSource `
        -CodeCoverageOutputFile $CodeCoverageFile `
        -CodeCoverageOutputFileFormat 'JaCoCo'

    if ($TestResults.CodeCoverage) {
        Export-CodeCovIoJson -CodeCoverage $TestResults.CodeCoverage -RepoRoot $PWD -Path $CodeCoverageJson
    }
}