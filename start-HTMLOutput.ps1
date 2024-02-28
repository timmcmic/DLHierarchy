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
    $functionHTMLFile = $global:LogFile.replace("log","$functionHTMLSuffix")

    out-logfile -string $functionHTMLFile
}