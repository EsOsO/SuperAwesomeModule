Properties {
    Set-BuildEnvironment -Force

    $Timestamp = Get-Date -uformat "%Y%m%d-%H%M%S"
    $PSVersion = $PSVersionTable.PSVersion.Major
    $BuildFolder = Join-Path -Path $env:BHBuildOutput -ChildPath $env:BHProjectName
}

FormatTaskName (('-' * 25) + ('[ {0,-28} ]') + ('-' * 25))

Task Default -Depends Init

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

Task Clean -Depends Init {
    if (Test-Path $env:BHBuildOutput) {
        Remove-Item -Force -Recurse $env:BHBuildOutput -ErrorAction Ignore | Out-Null
    }

    New-Item -Path $env:BHBuildOutput -ItemType Directory -Force | Out-Null
}

Task Build -Depends Clean {
    New-Item -Path $BuildFolder -ItemType Directory -Force | Out-Null

    Get-ChildItem -Path $env:BHPSModulePath | Copy-Item -Destination $BuildFolder -Force -PassThru | ForEach-Object {'  Copy [.{0}]' -f $_.FullName.Replace($PSScriptRoot, '')}
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
