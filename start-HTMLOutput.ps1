
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

        if ($node.object.groupType -ne "")
        {
            $functionReturnString = $node.object.displayName +" (ExchangeObjectID: "+$node.object.ExchangeObjectID+") ("+$node.object.recipientType+"/"+$node.object.recipientTypeDetails+"/"+$node.object.GroupType+")"
        }
        else 
        {
            $functionReturnString = $node.object.displayName +" (ExchangeObjectID: "+$node.object.ExchangeObjectID+") ("+$node.object.recipientType+"/"+$node.object.recipientTypeDetails+")"
        }
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

        $functionGraphUser = "MicrosoftGraphUser"
        $functionGraphGroup = "MicrosoftGraphGroup"
        $functionGraphContact = "MicrosoftGraphOrgContact"

        if ($outputType -eq $functionMSGraphType)
        {
            foreach ($child in $node.children)
            {
                $string = get-nodeString -node $child -outputType $functionMSGraphType
                out-logfile -string ("Prcessing HTML: "+$string)

                if (($child.object.getType().name -eq $functionGraphUser) -and ($isUserPNGPresent -eq $TRUE))
                {
                    New-HTMLTreeNode -Title $string -children {New-HTMLTreeChildNodes -node $child -outputType $functionMSGraphType} -icon $functionUserPNGPath
                }
                elseif (($child.object.getType().name -eq $functionGraphGroup) -and ($isGroupPNGPresent -eq $TRUE))
                {
                    New-HTMLTreeNode -Title $string -children {New-HTMLTreeChildNodes -node $child -outputType $functionMSGraphType} -icon $functionGroupPNGPath
                }
                elseif (($child.object.getType().name -eq $functionGraphContact) -and ($isContactPNGPresent -eq $TRUE))
                {
                    New-HTMLTreeNode -Title $string -children {New-HTMLTreeChildNodes -node $child -outputType $functionMSGraphType} -icon $functionContactPNGPath
                }
                else 
                {
                    New-HTMLTreeNode -Title $string -children {New-HTMLTreeChildNodes -node $child -outputType $functionMSGraphType}
                }
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
    $functionContactPNGPath = $functioModuleInstallPath + $functionContactPNG

    out-logfile -string $functionUserPNGPath
    out-logfile -string $functionGroupPNGPath
    out-logfile -string $functionContactPNGPath

    $isUserPNGPresent = $TRUE
    $isGroupPNGPresent = $TRUE
    $isContactPNGPresent = $TRUE

    if (-not (Test-Path -Path $functionUserPNGPath))
    {
        $isUserPNGPresent = $false
    }

    if ( -not (Test-Path -Path $functionGroupPNGPath))
    {
        $isGroupPNGPresent = $false
    }

    if (-not (Test-Path -Path $functionContactPNGPath))
    {
        $isContactPNGPresent = $false
    }

    out-logfile -string $isUserPNGPresent
    out-logfile -string $isGroupPNGPresent
    out-logfile -string $isContactPNGPresent

    $functionHTMLSuffix = "html"
    $functionHTMLFile = $global:LogFile.replace("log","$functionHTMLSuffix")

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

        if ($isGroupPNGPresent -eq $TRUE)
        {
            New-HTML -TitleText $groupObjectID -FilePath $functionHTMLFile {
                New-HTMLTree -Checkbox none {
                    New-HTMLTreeChildCounter -Deep -HideZero -HideExpanded
                    New-HTMLTreeNode -title $string -children {New-HTMLTreeChildNodes -node $node -outputType $functionMSGraphType} -icon $functionGroupPNGPath
                } -EnableChildCounter -AutoScroll -MinimumExpandLevel 1
            } -Online -ShowHTML
        }
        else {
            New-HTML -TitleText $groupObjectID -FilePath $functionHTMLFile {
                New-HTMLTree -Checkbox none {
                    New-HTMLTreeChildCounter -Deep -HideZero -HideExpanded
                    New-HTMLTreeNode -title $string -children {New-HTMLTreeChildNodes -node $node -outputType $functionMSGraphType}
                } -EnableChildCounter -AutoScroll -MinimumExpandLevel 1
            } -Online -ShowHTML
        }
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