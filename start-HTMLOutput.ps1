function start-HTMLOutput
{
    [Parameter(Mandatory = $true)]
    $node,
    [Parameter(Mandatory = $true)]
    $outputType

    $functionMSGraphType = "MSGraph"
    $functionExchangeOnlineType = "ExchangeOnline"
    $functionLDAPType = "LDAP"
    $functionHTMLSuffix = "html"
    $functionHTMLFile = $global:LogFile.replace("Log","$functionHTMLSuffix")

    out-logfile -string $functionHTMLFile
}