Function Print-Tree()
{
    Param
    (
        [Parameter(Mandatory = $true)]
        $node,
        [Parameter(Mandatory = $true)]
        $indent,
        [Parameter(Mandatory = $true)]
        $outputType
    )

    $functionMSGraphType = "MSGraph"
    $functionExchangeOnlineType = "ExchangeOnline"
    $functionLDAPType = "LDAP"

    if ($outputType -eq $functionMSGraphType)
    {
        $string = $node.group.displayName +" ("+$node.group.id+")"

        out-logfile -string  (("-" * $indent) + $string)

        foreach ($child in $node.Children)
        {
            Print-Tree -node $child -indent ($indent + 2) -outputType $functionMSGraphType
        }
    }
}