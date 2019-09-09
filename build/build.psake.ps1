Properties {
    $Timestamp = Get-Date -uformat "%Y%m%d-%H%M%S"
    $RequiredCodeCoverage = .8

    if ($PSVersionTable.Platform -eq 'Win32NT') {
        $Version = & gitversion | ConvertFrom-Json
        $ModuleVersion = $Version.MajorMinorPatch
        $SemVer = $Version.SemVer
        $BuildFolder = '{0}\{1}-{2}' -f $ENV:BHBuildOutput, $ENV:BHProjectName, $SemVer
    }
}

FormatTaskName (('-' * 25) + ('[ {0,-28} ]') + ('-' * 25))

Task Default -Depends Test

Task Init {
    Set-Location -Path $ENV:BHProjectPath
    'Environment Variables:'
    Get-ChildItem -Path ENV:
    "`n"

    'PowerShell Details:'
    $PSVersionTable
    "`n"
}

Task Clean -Depends Init {
    if (Test-Path $ENV:BHBuildOutput) {
        Remove-Item -Recurse -Path $ENV:BHBuildOutput
    }
}

Task IncreaseVersion -Depends Clean {
    "Setting version [$ModuleVersion]"
    Update-Metadata -Path $ENV:BHPSModuleManifest -PropertyName ModuleVersion -Value $ModuleVersion
}

Task ExportFunctions -Depends IncreaseVersion {
    "Updating manifest FunctionsToExport"
    Set-ModuleFunction
}

Task Build -Depends ExportFunctions {
    New-Item -ItemType Directory -Path $BuildFolder | Out-Null

    Copy-Item -Path $ENV:BHPSModuleManifest -Destination $BuildFolder

    $ModuleFileName = '{0}.psm1' -f $ENV:BHProjectName
    $sb = [Text.StringBuilder]::new()

    Get-ChildItem $ENV:BHModulePath -Filter *.ps1 -Recurse | %{
        'Appending file {0}' -f $_
        $null = $sb.AppendLine([IO.File]::ReadAllText($_))
        $null = $sb.AppendLine()
    }

    Set-Content -Path $BuildFolder\$ModuleFileName -Value $sb.ToString() -Encoding 'UTF8'

    Copy-Item -Path $ENV:BHProjectPath\docs\LICENSE.md -Destination $BuildFolder\LICENSE

    'Packing module'
    Compress-Archive -Path $BuildFolder -DestinationPath ('{0}\{1}-{2}.zip' -f $ENV:BHBuildOutput, $ENV:BHProjectName, $SemVer)
}

Task StaticAnalysis -Depends Init {
    'Starting PSScriptAnalyzer'
    Invoke-ScriptAnalyzer -Path $ENV:BHModulePath -Settings PSGallery -Recurse
    'Ended PSScriptAnalyzer'
}

Task Test -Depends StaticAnalysis {
    $TestsPath = Join-Path -Path $env:BHProjectPath -ChildPath 'Tests'

    # Execute tests
    $Params = @{
        Script = $TestsPath
        OutputFile = $ENV:BHBuildOutput + '\test_results.xml'
        OutputFormat = 'NUnitXml'
        PassThru = $true
    }

    if ($RequiredCodeCoverage -gt .0) {
        $Params['CodeCoverage'] = $ENV:BHBuildOutput + '\*\*.psm1'
        $Params['CodeCoverageOutputFile'] = $ENV:BHBuildOutput + '\code_coverage.xml'
    }

    Remove-Module $env:BHProjectName -Force -ErrorAction SilentlyContinue
    Import-Module ('{0}\{1}.psd1' -f $ENV:BHModulePath ,$ENV:BHProjectName) -Force

    $TestResults = Invoke-Pester @Params

    if ($TestResults.FailedCount -gt 0) {
        Write-Error -Message ('Failed {0} tests' -f $TestResults.FailedCount)
    }

    if ($TestResults.codecoverage.NumberOfCommandsAnalyzed -gt 0) {
        $CodeCoverage = $TestResults.codecoverage.NumberOfCommandsExecuted / $TestResults.codecoverage.NumberOfCommandsAnalyzed

        if ($CodeCoverage -lt $RequiredCodeCoverage) {
            Write-Error -Message ('Code coverage lower than {0:P}: {1:P}' -f $RequiredCodeCoverage, $CodeCoverage)
        }
    }

    Remove-Module $env:BHProjectName -Force -ErrorAction SilentlyContinue
}

Task Release {
    if ($ENV:BHBranchName -eq 'master') {
        Invoke-PSDeploy -Tags Release
    } else {
        "Not publishing to PowershellGallery as we aren't in master branch"
    }
}