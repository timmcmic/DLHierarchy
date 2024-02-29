
function get-NodeString
{
    param(
        $node,
        $outputType
    )

    $functionReturnString = ""

    if ($outputType -eq $functionExchangeOnlineType)
    {
        out-logfile -string "Calculating string for Exchange Online"
        $functionReturnString = $node.object.displayName +" (ExchangeObjectID: "+$node.object.ExchangeObjectID+") ("+$node.object.recipientType+"/"+$node.object.recipientTypeDetails+")"
    }
    elseif ($outputType -eq $functionMSGraphType)
    {
        out-logfile -string "Calculating string for Microsoft Graph"
        $functionReturnString = $node.object.displayName +" (ObjectID: "+$node.object.id+") ("+$node.object.getType().name+")"
    }

    out-logfile -string $functionReturnString
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

        <#
        $functionMSGraphType = "MSGraph"
        $functionExchangeOnlineType = "ExchangeOnline"
        $functionLDAPType = "LDAP"
        #>

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
    out-logfile -string $outputType

    if ($outputType -eq $functionExchangeOnlineType)
    {
        out-logfile -string "Entering Exchange Online Type"

        $string = get-nodeString -node $node -outputType $functionExchangeOnlineType
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
        out-logfile -string "Entering MS Graph Type"

        $string = get-nodeString -node $node -outputType $functionMSGraphType
        out-logfile -string ("Prcessing HTML: "+$string)

        New-HTML -TitleText $groupObjectID -FilePath $functionHTMLFile {
            New-HTMLTree -Checkbox none {
                New-HTMLTreeChildCounter -Deep -HideZero -HideExpanded
                New-HTMLTreeNode -title $string -children {New-HTMLTreeChildNodes -node $node -outputType $functionMSGraphType}
            } -EnableChildCounter -AutoScroll -MinimumExpandLevel 1
        } -Online -ShowHTML
    }
}