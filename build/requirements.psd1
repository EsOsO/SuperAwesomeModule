@{
    PSDependOptions = @{
        Target = 'CurrentUser'
    }

    'psake' = @{
        Version = 'latest'
    }

    'PSDeploy' = @{
        Version = 'latest'
    }

    'BuildHelpers' = @{
        Version = 'latest'
    }

    'Pester' = @{
        Version = 'latest'
        Parameters = @{
            SkipPublisherCheck = $true
        }
    }

    'PSScriptAnalyzer' = @{
        Version = '1.18.1'
    }

    'platyPS' = @{
        Version = 'latest'
    }
}
