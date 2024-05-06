
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
    $functionUniversalDateTime = (get-date).toUniversalTime()

    return $functionUniversalDateTIme
}