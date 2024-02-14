
<#
    .SYNOPSIS

    This function gathers and returns the universal date time.

    .DESCRIPTION

    This function gathers and returns the universal date time.

    .OUTPUTS

    Returns universal date time.


n   get-universalDateTime

    #>
function get-universalDateTime
{
    out-logfile -string "***********************************************************"
    out-logfile -string "Entering get-UniversalDateTime"
    out-logfile -string "***********************************************************"

    $functionUniversalDateTime = (get-date).toUniversalTime()

    out-logfile -string "***********************************************************"
    out-logfile -string "Exiting get-UniversalDateTime"
    out-logfile -string "***********************************************************"

    return $functionUniversalDateTIme
}