Properties {
    $Timestamp = Get-Date -uformat "%Y%m%d-%H%M%S"
    $PSVersion = $PSVersionTable.PSVersion.Major
    $BuildFolder = Join-Path -Path $env:BHBuildOutput -ChildPath $env:BHProjectName
}

FormatTaskName (('-' * 25) + ('[ {0,-28} ]') + ('-' * 25))

Task Default -Depends Test

Task Init {
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

Task StaticAnalysis -Depends Init {
    Invoke-ScriptAnalyzer -Path $env:BHModulePath -Settings PSGallery -Recurse
}

Task Test -Depends StaticAnalysis {
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
}
