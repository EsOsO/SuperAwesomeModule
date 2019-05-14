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
}