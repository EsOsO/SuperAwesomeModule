function Update-AdditionalReleaseArtifact {
    param(
        [string] $Version
    )

    Write-Host ('Updating Module Manifest version number to: {0}' -f $Version)
    Update-Metadata -Path $env:BHPSModuleManifest -PropertyName ModuleVersion -Value $Version
}

Properties {
    $GitVersion = gitversion | ConvertFrom-Json
    $Artifact = '{0}-{1}.zip' -f $env:BHProjectName.ToLower(), $GitVersion.SemVer
    $ArtifactPath = Join-Path $env:BHBuildOutput $Artifact
    $StableVersion = $GitVersion.MajorMinorPatch
    $BranchName = $GitVersion.BranchName
    $SemVer = $GitVersion.SemVer
}

FormatTaskName (('-' * 25) + ('[ {0,-28} ]') + ('-' * 25))

Task Default -Depends Build

Task Init {
    Set-Location $env:BHProjectPath

    Exec {git config --global credential.helper store}
    Add-Content "$HOME\.git-credentials" "https://$($env:APPVEYOR_PERSONAL_ACCESS_TOKEN):x-oauth-basic@github.com`n"
    Exec {git config --global user.name "$env:APPVEYOR_GITHUB_USERNAME"}
    Exec {git config --global user.email "$env:APPVEYOR_GITHUB_EMAIL"}

    New-Item -Path $env:BHBuildOutput -ItemType Directory | Out-Null

    Write-Host ('Working folder: {0}' -f $PWD)
    Write-Host ('Build output: {0}' -f $env:BHBuildOutput)
    Write-Host ('Git Version: {0}' -f $SemVer)
    Write-Host ('Git Version (Stable): {0}' -f $StableVersion)
    Write-Host ('Git Branch: {0}' -f $BranchName)
    Write-Host ('Git Username: {0}' -f $env:APPVEYOR_GITHUB_USERNAME)
    Write-Host ('Git Email: {0}' -f $env:APPVEYOR_GITHUB_EMAIL)
}

Task IncrementVersion -Depends Init {
    # trap {
    #     Pop-Location
    #     Write-Error "$_"
    #     exit 1
    # }

    Push-Location $env:BHProjectPath

    $PendingChanges = git status --porcelain
    if ($null -ne $PendingChanges) {
        throw 'You have pending changes, aborting release'
    }

    Write-Host 'Git: Fetchin origin'
    Exec {git fetch origin}

    Write-Host "Git: Merging origin/$BranchName"
    Exec {git merge origin/$BranchName --ff-only}

    Update-AdditionalReleaseArtifact -Version $StableVersion

    Write-Host 'Git: Committing new release'
    Exec {git commit -am "Create release $SemVer [skip ci]" --allow-empty}

    Write-Host 'Git: Tagging branch'
    Exec {git tag $SemVer}

    if ($LASTEXITCODE -ne 0) {
        Exec {git reset --hard HEAD^}
        throw 'No changes detected since last release'
    }

    Write-Host 'Git: Pushing to origin'
    Exec {git push origin $BranchName --tags}

    Pop-Location
}

Task Build -Depends IncrementVersion {
    Write-Host "Build: Compressing release to $ArtifactPath"
    Compress-Archive -Path $env:BHModulePath -DestinationPath $ArtifactPath
}