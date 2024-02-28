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

    function New-HTMLTreeFileNodes 
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
            $string = $node.object.displayName +" (ObjectID: "+$node.object.id+") ("+$node.object.getType().name+")"

            New-HTMLTreeNode -Title $string

            foreach ($child in $node.Children)
            {
                New-HTMLTreeFileNodes -node $child -outputType $functionExchangeOnlineType
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

    out-logfile -string $functionHTMLFile

    New-HTML -TitleText $groupObjectID -FilePath $functionHTMLFile {
        New-HTMLTree -Checkbox none {
            New-HTMLTreeChildCounter -Deep -HideZero -HideExpanded
            New-HTMLTreeNode -Title $groupObjectID {
                New-HTMLTreeFileNodes -node $node -outputType $outputType
            }
        } -EnableChildCounter -AutoScroll -MinimumExpandLevel 1
    } -Online -ShowHTML

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

    <#

    New-HTML -TitleText $groupObjectID -FilePath $functionHTMLFile {
        New-HTMLTreeChildCounter -Deep -HideZero -HideExpanded
        New-HTMLSection -Invisible {
            New-HTMLSection {
                New-HTMLTree -Checkbox none {
                    New-HTMLTreeFileNodes -Path 'C:\Support\GitHub\PSWriteHTML\Examples' -Filter *.html -IsExpanded
                } -EnableChildCounter -AutoScroll
                New-HTMLSection -Invisible {
                    New-HTMLFrame -Name 'contentFrame' -Scrolling Auto -Height 1500px
                }
            }
        }
    } -Online -ShowHTML

    #>
}