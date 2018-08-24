<#
.SYNOPSIS
    Function synopsis

.DESCRIPTION
    Function description

.PARAMETER Text
    Parameter description

.EXAMPLE
    > Get-SuperAwesomeFunction -Text 'Hello, World!'

.LINK
    http://foo.bar/#help

#>
function Get-SuperAwesomeFunction {
    [CmdletBinding(HelpUri='http://foo.bar/#help')]
    param(
        [string] $Text
    )

    return $Text.ToUpper()
}