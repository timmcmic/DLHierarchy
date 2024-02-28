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
            <#
            $string = $node.object.displayName +" (ObjectID: "+$node.object.id+") ("+$node.object.getType().name+")"

            out-logfile -string  (("-" * $indent) + $string)

            $global:outputFile += (("-" * $indent) + $string +"`n")

            foreach ($child in $node.Children)
            {
                Print-Tree -node $child -indent ($indent + 2) -outputType $functionMSGraphType
            }
            #>
        }
        elseif ($outputType -eq $functionExchangeOnlineType)
        {
            $string = $node.object.displayName +" (ExchangeObjectID: "+$node.object.ExchangeObjectID+") ("+$node.object.recipientType+"/"+$node.object.recipientTypeDetails+")"

            out-logfile -string $string 

            foreach ($child in $node.children)
            {
                New-HTMLTreeNode -Title $string -children {New-HTMLTreeChildNodes -node $child -outputType $functionExchangeOnlineType}
            }

            <#
            out-logfile -string $node
            out-logfile -string $node.object.displayName
            $string = $node.object.displayName +" (ExchangeObjectID: "+$node.object.ExchangeObjectID+") ("+$node.object.recipientType+"/"+$node.object.recipientTypeDetails+")"
            out-logfile -string $string

            foreach ($child in $node.Children)
            {
                New-HTMLTreeNode -Title $string -children {New-HTMLTreeFileNodes -node $child -outputType $functionExchangeOnlineType}
            }
            #>
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

    New-HTML -TitleText $groupObjectID -FilePath $functionHTMLFile {

        New-HTMLTree -Checkbox none {
            New-HTMLTreeChildCounter -Deep -HideZero -HideExpanded
            New-HTMLTree $string $node  
        }-EnableChildCounter -AutoScroll -MinimumExpandLevel 1
    }-Online -ShowHTML

    <#

    New-HTML -TitleText $groupObjectID -FilePath $functionHTMLFile {
        New-HTMLTree -Checkbox none {
            New-HTMLTreeChildCounter -Deep -HideZero -HideExpanded
            New-HTMLTreeChildNodes -node $node -outputType $functionExchangeOnlineType
        } -EnableChildCounter -AutoScroll -MinimumExpandLevel 1
    } -Online -ShowHTML

    New-HTML -TitleText $groupObjectID -FilePath $functionHTMLFile {
        New-HTMLTree -Checkbox none {
            New-HTMLTree -Checkbox none {
            New-HTMLTreeFileNodes -node $node -outputType $outputType 
        } -EnableChildCounter -AutoScroll -MinimumExpandLevel 1
    } -Online -ShowHTML

    #>
}