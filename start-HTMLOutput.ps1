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

            New-HTMLTreeNode -Title $string {

                foreach ($child in $node.Children)
                {
                    New-HTMLTreeChildNodes -node $node -outputType $functionExchangeOnlineType
                }
                <#
                New-HTMLTreeNode -Title 'Live screen' {
                    New-HTMLTreeNode -Title 'New build'
                    New-HTMLTreeNode -Title '<b>No</b> new build' {
                        New-HTMLTreeNode -Title 'Need two tries to boot' {
                            New-HTMLTreeNode -Title 'Premature power_good signal. Try different power supply.' -Icon 'https://cdn-icons-png.flaticon.com/512/6897/6897039.png'
                        }
                        New-HTMLTreeNode -Title 'Does not need two tries to boot'
                    }
                }
                New-HTMLTreeNode -Title "<b>No</b> live screen" {
                    New-HTMLTreeNode -Title "Proceed to video failure chart" -Icon 'https://cdn-icons-png.flaticon.com/512/1294/1294758.png'
                }
                #>
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

    New-HTML -TitleText 'This is a test' -FilePath $functionHTMLFile {
        New-HTMLTree -Checkbox none {
            New-HTMLTreeChildCounter -Deep -HideZero -HideExpanded
            New-HTMLTreeChildNodes -node $node -outputType $functionExchangeOnlineType
        } -EnableChildCounter -AutoScroll -MinimumExpandLevel 1
    } -Online -ShowHTML
    <#

    New-HTML -TitleText $groupObjectID -FilePath $functionHTMLFile {
        New-HTMLTree -Checkbox none {
            New-HTMLTree -Checkbox none {
            New-HTMLTreeFileNodes -node $node -outputType $outputType 
        } -EnableChildCounter -AutoScroll -MinimumExpandLevel 1
    } -Online -ShowHTML

    #>
}