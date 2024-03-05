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

    $sorted = New-Object System.Collections.Generic.List[pscustomobject]
    $node.Children | % { $sorted.Add($_) }
 
    $sorted = [System.Linq.Enumerable]::OrderBy($sorted, [Func[pscustomobject,string]]{ param($x) $x.Object.objectClass })
    $sorted = [System.Linq.Enumerable]::ThenBy($sorted, [Func[pscustomobject,string]]{ param($x) $x.Object.Name })

    if ($outputType -eq $functionMSGraphType)
    {
        $string = $node.object.displayName +" (ObjectID: "+$node.object.id+") ("+$node.object.getType().name+")"

        out-logfile -string  (("-" * $indent) + $string)

        $global:outputFile += (("-" * $indent) + $string +"`n")

        foreach ($child in $node.Children)
        {
            Print-Tree -node $child -indent ($indent + 2) -outputType $functionMSGraphType
        }
    }
    elseif ($outputType -eq $functionExchangeOnlineType)
    {
        if ($node.object.groupType -ne $NULL)
        {
            $string = $node.object.displayName +" (ExchangeObjectID: "+$node.object.ExchangeObjectID+") ("+$node.object.recipientType+"/"+$node.object.recipientTypeDetails+"/"+$node.object.GroupType+")"
        }
        else 
        {
            $string = $node.object.displayName +" (ExchangeObjectID: "+$node.object.ExchangeObjectID+") ("+$node.object.recipientType+"/"+$node.object.recipientTypeDetails+")"
        }

        out-logfile -string  (("-" * $indent) + $string)

        $global:outputFile += (("-" * $indent) + $string +"`n")

        foreach ($child in $node.Children)
        {
            Print-Tree -node $child -indent ($indent + 2) -outputType $functionExchangeOnlineType
        }
    }
    elseif ($outputType -eq $functionLDAPType)
    {
        $string = $node.object.DisplayName +" (ObjectGUID:"+$node.object.objectGUID+") ("+$node.object.objectClass+")"
        
        out-logfile -string  (("-" * $indent) + $string)

        $global:outputFile += (("-" * $indent) + $string +"`n")

        foreach ($child in $sorted)
        {
            Print-Tree -node $child -indent ($indent + 2) -outputType $functionLDAPType
        }
    }
}