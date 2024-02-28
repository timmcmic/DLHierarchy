
function get-NodeString
{
    param(
        $node,
        $outputType
    )
    
    $functionMSGraphType = "MSGraph"
    $functionExchangeOnlineType = "ExchangeOnline"
    $functionLDAPType = "LDAP"
    $functionReturnString = ""

    if ($outputType -eq $functionExchangeOnlineType)
    {
        $functionReturnString = $node.object.displayName +" (ExchangeObjectID: "+$node.object.ExchangeObjectID+") ("+$node.object.recipientType+"/"+$node.object.recipientTypeDetails+")"
    }
    elseif ($outputType -eq $functionMSGraphType)
    {
        $functionReturnString = $node.object.displayName +" (ObjectID: "+$node.object.id+") ("+$node.object.getType().name+")"
    }

    return $functionReturnString
}


function start-HTMLOutput
{
    param(
        [Parameter(Mandatory = $true)]
        $node,
        [Parameter(Mandatory = $true)]
        $outputType,
        [Parameter(Mandatory = $true)]
        $groupObjectID
    )

    function New-HTMLTreeChildNodes 
    {
        param(
        $node,
        $outputType
        )

        $functionMSGraphType = "MSGraph"
        $functionExchangeOnlineType = "ExchangeOnline"
        $functionLDAPType = "LDAP"

        if ($outputType -eq $functionMSGraphType)
        {
            foreach ($child in $node.children)
            {
                
                $string = get-nodeString -node $child -outputType $functionMSGraphType
                out-logfile -string ("Prcessing HTML: "+$string)

                New-HTMLTreeNode -Title $string -children {New-HTMLTreeChildNodes -node $child -outputType $functionMSGraphType}
            }
        }
        elseif ($outputType -eq $functionExchangeOnlineType)
        {
            foreach ($child in $node.children)
            {
                
                $string = get-nodeString -node $child -outputType $functionExchangeOnlineType
                out-logfile -string ("Prcessing HTML: "+$string)

                New-HTMLTreeNode -Title $string -children {New-HTMLTreeChildNodes -node $child -outputType $functionExchangeOnlineType}
            }
        }
        elseif ($outputType -eq $functionLDAPType)
        {
            <#
            $string = $node.object.DisplayName +" (ObjectGUID:"+$node.object.objectGUID+") ("+$node.object.objectClass+")"
            
            out-logfile -string  (("-" * $indent) + $string)

            $global:outputFile += (("-" * $indent) + $string +"`n")

            foreach ($child in $node.Children)
            {
                Print-Tree -node $child -indent ($indent + 2) -outputType $functionLDAPType
            }
            #>
        }
    }

    $functionHTMLSuffix = "html"
    $functionHTMLFile = $global:LogFile.replace("log","$functionHTMLSuffix")

    $functionMSGraphType = "MSGraph"
    $functionExchangeOnlineType = "ExchangeOnline"
    $functionLDAPType = "LDAP"

    out-logfile -string $functionHTMLFile

    if ($outputType -eq $functionExchangeOnlineType)
    {
        $string = get-nodeString -node $node -outputType $functionExchangeOnlineType
        $string = "<b>"+$string+</b>
        out-logfile -string ("Prcessing HTML: "+$string)

        New-HTML -TitleText $groupObjectID -FilePath $functionHTMLFile {
            New-HTMLTree -Checkbox none {
                New-HTMLTreeChildCounter -Deep -HideZero -HideExpanded
                New-HTMLTreeNode -title $string -children {New-HTMLTreeChildNodes -node $node -outputType $functionExchangeOnlineType}
            } -EnableChildCounter -AutoScroll -MinimumExpandLevel 1
        } -Online -ShowHTML
    }
    elseif ($outputType -eq $functionMSGraphType)
    {
        $string = get-nodeString -node $node -outputType $functionMSGraphType
        $string = "<b>"+$string+"</b>"
        out-logfile -string ("Prcessing HTML: "+$string)

        New-HTML -TitleText $groupObjectID -FilePath $functionHTMLFile {
            New-HTMLTree -Checkbox none {
                New-HTMLTreeChildCounter -Deep -HideZero -HideExpanded
                New-HTMLTreeNode -title $string -children {New-HTMLTreeChildNodes -node $node -outputType $functionMSGraphType}
            } -EnableChildCounter -AutoScroll -MinimumExpandLevel 1
        } -Online -ShowHTML
    }
}