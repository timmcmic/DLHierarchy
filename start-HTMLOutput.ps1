
function get-NodeString
{
    param(
        [Parameter(Mandatory = $true)]
        $node,
        [Parameter(Mandatory = $true)]
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
    elseif ($outputType -eq $functionLDAPType)
    {
        out-logfile -string "Calculating string for LDAP"
        $functionReturnString = $node.object.DisplayName +" (ObjectGUID:"+$node.object.objectGUID+") ("+$node.object.objectClass+")"
    }

    out-logfile -string $functionReturnString
    return $functionReturnString
}
function New-HTMLTreeChildNodes 
    {
        param(
            [Parameter(Mandatory = $true)]
            $node,
            [Parameter(Mandatory = $true)]
            $outputType
        )

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
            foreach ($child in $node.children)
            {
                
                $string = get-nodeString -node $child -outputType $functionLDAPType
                out-logfile -string ("Prcessing HTML: "+$string)

                New-HTMLTreeNode -Title $string -children {New-HTMLTreeChildNodes -node $child -outputType $functionLDAPType}
            }
        }
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

    $functionModuleName = "DLHierarchy"
    $functionUserPNG = "user.png"
    $functionGroupPNG = "group.png"
    $functionContactPNG = "contact.png"

    $functionUserPNGPath = 

    $functionHTMLSuffix = "html"
    $functionHTMLFile = $global:LogFile.replace("log","$functionHTMLSuffix")

    $functionMSGraphType = "MSGraph"
    $functionExchangeOnlineType = "ExchangeOnline"
    $functionLDAPType = "LDAP"

    out-logfile -string "Determine installation path for powershell module -> expect to find icons here."
    $functioModuleInstallPath = (get-installedModule -Name $functionModuleName).InstalledLocation
    $functioModuleInstallPath = $functioModuleInstallPath + "\"
    out-logfile -string $functioModuleInstallPath

    out-logfile -string "Calculate ICON paths."

    $functionUserPNGPath = $functioModuleInstallPath + $functionUserPNG
    $functionGroupPNGPath = $functioModuleInstallPath + $functionGroupPNG
    $functionContactPNGPath = $functioModuleInstallPath + $functionGroupPNG

    $isUserPNGPresent = $TRUE
    $isGroupPNGPresent = $TRUE
    $isContactPNGPresent = $TRUE

    if (!Test-Path -Path $functionUserPNGPath)
    {
        $isUserPNGPresent = $false
    }

    if (!Test-Path -Path $functionGroupPNGPath)
    {
        $isGroupPNGPresent = $false
    }

    if (!Test-Path -Path $functionContactPNGPath)
    {
        $isContactPNGPresent = $false
    }

    out-logfile -string $isUserPNGPresent
    out-logfile -string $isGroupPNGPresent
    out-logfile -string $isContactPNGPresent

    out-logfile -string $functionUserPNGPath
    out-logfile -string $functionGroupPNGPath
    out-logfile -string $functionContactPNGPath

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
    elseif ($outputType -eq $functionLDAPType)
    {
        out-logfile -string "Entering LDAP Type"

        $string = get-nodeString -node $node -outputType $functionLDAPType
        out-logfile -string ("Prcessing HTML: "+$string)

        New-HTML -TitleText $groupObjectID -FilePath $functionHTMLFile {
            New-HTMLTree -Checkbox none {
                New-HTMLTreeChildCounter -Deep -HideZero -HideExpanded
                New-HTMLTreeNode -title $string -children {New-HTMLTreeChildNodes -node $node -outputType $functionLDAPType}
            } -EnableChildCounter -AutoScroll -MinimumExpandLevel 1
        } -Online -ShowHTML
    }
}