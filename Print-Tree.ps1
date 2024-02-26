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
    $functionHTMLSection = $null

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
        $string = $node.object.displayName +" (ExchangeObjectID: "+$node.object.ExchangeObjectID+") ("+$node.object.recipientType+"/"+$node.object.recipientTypeDetails+")"

        out-logfile -string  (("-" * $indent) + $string)

        $global:outputFile += (("-" * $indent) + $string +"`n")

        #Prepare HTML information.

        $params = @{'As'='Table';
            'EvenRowCssClass'='even';
            'OddRowCssClass'='odd';
            'MakeTableDynamic'=$true;
            'TableCssClass'='grid';
            'MakeHiddenSection'=$true;
            'Properties'=   @{n='DisplayName';e={$_.object.displayName}},
                            @{n='ExchangeObjectID';e={$_.object.ExchangeObjectID}},
                            @{n='RecipientType';e={$_.object.RecipientType}}
            }

        $functionHTMLSection = ConvertTo-EnhancedHTMLFragment -InputObject $node.Children @params

        $htmlSections += $functionHTMLSection   

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

        foreach ($child in $node.Children)
        {
            Print-Tree -node $child -indent ($indent + 2) -outputType $functionLDAPType
        }
    }
}