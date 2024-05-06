<#
    .SYNOPSIS

    This function removes all spaces from any user inputted string.  Prevents trianing and leading spaces.

    .DESCRIPTION

    This function removes all spaces from any user inputted string.  Prevents trianing and leading spaces.

    .PARAMETER stringToFix

    The string to remove all spaces from.

	.OUTPUTS

    Empty status file directory.

    .EXAMPLE

    remove-StringSpace -stringToFix STRING

    #>
    Function remove-StringSpace
    {
        [cmdletbinding()]

        Param
        (
            [Parameter(Mandatory = $false)]
            [string]$stringToFix=0
        )

        #Output all parameters bound or unbound and their associated values.

        write-functionParameters -keyArray $MyInvocation.MyCommand.Parameters.Keys -parameterArray $PSBoundParameters -variableArray (Get-Variable -Scope Local -ErrorAction Ignore)

        

        out-logfile -string "***********************************************************"
        out-logfile -string "Entering remove-StringSpace"
        out-logfile -string "***********************************************************"

        out-logfile -string ("String to remove spaces: "+$stringToFix)
        out-logfile -string ("String Length "+$stringToFix.length.toString())

        $workingString = $stringToFix.trim()

        out-logfile -string ("String with spaces removed: "+$workingString)
        out-logfile -string ("String Length "+$workingString.length.toString())

        out-logfile -string "***********************************************************"
        out-logfile -string "Exiting remove-StringSpace"
        out-logfile -string "***********************************************************"

        return $workingString
    }