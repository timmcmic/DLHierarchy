
<#
    .SYNOPSIS

    This function pulls the groups information and then starts recursively passing through all membership.

    .DESCRIPTION

    This function pulls the groups information and then starts recursively passing through all membership.

    .PARAMETER GROUPID

    This is the ID of the parent group.

    .PARAMETER PROCESSEDGROUPIDS

    This is a hash collection of all groups processed - this is what prevents circular references from reprocessing.

    .PARAMETER OBJECTTYPE

    Utilized to determine the type of query that is made.

    .OUTPUTS

    None

    .EXAMPLE

    Get-GroupWithChildren -groupID GROUPID -processedGroupIDs PROCESSEDGROUPIDs -objectType OBJECTTYPE

    #>
Function Get-GroupWithChildren()
{

    Param
    (
        [Parameter(Mandatory = $true,ParameterSetName = 'MSGraph')]
        [Parameter(Mandatory = $true,ParameterSetName = 'ExchangeOnline')]
        [Parameter(Mandatory = $true,ParameterSetName = 'LDAP')]
        [string]$objectID,
        [Parameter(Mandatory = $true,ParameterSetName = 'MSGraph')]
        [Parameter(Mandatory = $true,ParameterSetName = 'ExchangeOnline')]
        [Parameter(Mandatory = $true,ParameterSetName = 'LDAP')]
        $processedGroupIDs,
        [Parameter(Mandatory = $true,ParameterSetName = 'MSGraph')]
        [Parameter(Mandatory = $true,ParameterSetName = 'ExchangeOnline')]
        [Parameter(Mandatory = $true,ParameterSetName = 'LDAP')]
        [string]$objectType,
        [Parameter(Mandatory = $true,ParameterSetName = 'MSGraph')]
        [boolean]$queryMethodGraph=$false,
        [Parameter(Mandatory = $true,ParameterSetName = 'ExchangeOnline')]
        [boolean]$queryMethodExchangeOnline=$false,
        [Parameter(Mandatory = $true,ParameterSetName = 'LDAP')]
        [boolean]$queryMethodLDAP=$false,
        [Parameter(Mandatory = $true,ParameterSetName = 'LDAP')]
        $globalCatalogServer,
        [Parameter(Mandatory = $true,ParameterSetName = 'LDAP')]
        $activeDirectoryCredential,
        [Parameter(Mandatory = $true,ParameterSetName = 'LDAP')]
        [boolean]$firstLDAPQuery,
        [Parameter(Mandatory =$FALSE)]
        [boolean]$expandGroupMembership=$TRUE,
        [Parameter(Mandatory =$FALSE)]
        [boolean]$expandDynamicGroupMembership=$TRUE,
        [Parameter(Mandatory = $false,ParameterSetName = 'LDAP')]
        [Parameter(Mandatory = $true,ParameterSetName = 'ExchangeOnline')]
        [Parameter(Mandatory = $true,ParameterSetName = 'MSGraph')]
        [boolean]$reverseHierarchy=$FALSE,
        [Parameter(Mandatory = $false,ParameterSetName = 'LDAP')]
        [Parameter(Mandatory = $true,ParameterSetName = 'ExchangeOnline')]
        [Parameter(Mandatory = $true,ParameterSetName = 'MSGraph')]
        [string]$parentObjectID="N/A"

    )
    
    out-logfile -string "***********************************************************"
    out-logfile -string "Entering Get-GroupWithChildren"
    out-logfile -string "***********************************************************"

    if ($reverseHierarchy -eq $FALSE)
    {
        $global:childCounter++
        out-logfile -string ("Recursion Counter: "+$global:childCounter.tostring())
    }
    else 
    {
        $global:childCounter--
        out-logfile -string ("Recursion Counter: "+$global:childCounter.tostring())
    }
   

    $functionObject = $NULL
    $childNodes = @()
    $children=@()

    $functionParamterSetName = $PsCmdlet.ParameterSetName
    $functionGraphName = "MSGraph"
    $functionExchangeOnlineName = "ExchangeOnline"
    $functionLDAPName = "LDAP"

    $functionGraphGroup = "#microsoft.graph.group"
    $functiongraphUser = "#microsoft.graph.user"
    $functionGraphContact = "#microsoft.graph.orgContact"

    $functionExchangeGroup = "Group"
    $functionExchangeMailUniversalSecurityGroup = "MailUniversalSecurityGroup"
    $functionExchangeMailUniversalDistributionGroup = "MailUniversalDistributionGroup"
    $functionExchangeUserMailbox = "UserMailbox"
    $functionExchangeMailUser = "Mailuser"
    $functionExchangeGuestMailUser = "GuestMailUser"
    $functionExchangeMailContact = "MailContact"
    $functionExchangeGroupMailbox = "GroupMailbox"
    $functionExchangeDynamicGroup = "DynamicDistributionGroup"
    $functionExchangeSharedMailbox = "SharedMailbox"
    $functionExchangeRoomMailbox = "RoomMailbox"
    $functionExchangeEquipmentMailbox = "EquipmentMailbox"
    $functionExchangeUser = "User"
    $isExchangeGroupType = $false

    $functionLDAPGroup = "Group"
    $functionLDAPUser = "User"
    $functionLDAPContact = "Contact"
    $functionLDAPDynamicGroup = "msExchDynamicDistributionList"

    $exchangeMembersAttribute = "Members"

    out-logfile -string ("Parameter Set Name: "+$functionParamterSetName)
    out-logfile -string ("Processing group ID: "+$objectID)
    out-logfile -string ("Processing object type: "+$objectType)
    out-logfile -string ("QueryMethodGraph: "+$queryMethodGraph)
    out-logfile -string ("QueryMethodExchangeOnline: "+$queryMethodExchangeOnline)
    out-logfile -string ("QueryMethodLDAP: "+$queryMethodLDAP)

    out-logfile -string "Determine the path utilized based on paramter set name."

    #===============================================================================
    #Exchange Functions
    #===============================================================================

    function reset-exchangeOnlinePowershell
    {
        if ($exchangeOnlineCertificateThumbPrint -eq "")
        {
            #User specified non-certifate authentication credentials.

                try {
                    New-ExchangeOnlinePowershellSession -exchangeOnlineCredentials $exchangeOnlineCredential -exchangeOnlineEnvironmentName $exchangeOnlineEnvironmentName -debugLogPath $logFolderPath
                }
                catch {
                    out-logfile -string "Unable to create the exchange online connection using credentials."
                    out-logfile -string $_ -isError:$TRUE
                }
        }
        elseif ($exchangeOnlineCertificateThumbPrint -ne "")
        {
            #User specified thumbprint authentication.

                try {
                    new-ExchangeOnlinePowershellSession -exchangeOnlineCertificateThumbPrint $exchangeOnlineCertificateThumbPrint -exchangeOnlineAppId $exchangeOnlineAppID -exchangeOnlineOrganizationName $exchangeOnlineOrganizationName -exchangeOnlineEnvironmentName $exchangeOnlineEnvironmentName -debugLogPath $logFolderPath
                }
                catch {
                    out-logfile -string "Unable to create the exchange online connection using certificate."
                    out-logfile -string $_ -isError:$TRUE
                }
        }
    }

    function get-ExchangeGroup
    {
        Param
        (
            [Parameter(Mandatory = $true)]
            $objectID,
            [Parameter(Mandatory = $false)]
            $queryType,
            [Parameter(Mandatory = $false)]
            $secondTry = $FALSE
        )

        $retryCounter = 0
        $retryRequired = $TRUE

        do {
            if ($queryType -eq $functionExchangeMailUniversalSecurityGroup)
            {
                try {
                    $returnObject = get-o365DistributionGroup -identity $objectID -ErrorAction Stop
                    $global:mailUniversalSecurityGroupCounter+=$returnObject.exchangeObjectID
                    $retryRequired = $FALSE
                }
                catch {
                    $retryCounter++
                    if ($returnCounter -gt 4)
                    {
                        out-logfile -string "Unable to obtain Exchange Online Mail Enabled Security Group."
                        out-logfile -string $_ -isError:$TRUE
                    }
                    else {
                        start-sleepProgress -sleepString "Error obtaining Exchange Online object - resetting connection." -sleepSeconds 60
                        disable-allPowerShellSessions
                        reset-exchangeOnlinePowershell
                    }
                } 
            }        
            elseif ($queryType -eq $functionExchangeMailUniversalDistributionGroup)
            {
                try {
                    $returnObject = get-o365DistributionGroup -identity $objectID -ErrorAction Stop
                    $global:mailUniversalDistributionGroupCounter+=$returnObject.exchangeObjectID
                    $retryRequired = $FALSE
                }
                catch {
                    $retryCounter++
                    if ($retryCounter -gt 4)
                    {
                        out-logfile -string "Unable to obtain Exchange Online Mail Enabled Distribution Group."
                        out-logfile -string $_ -isError:$TRUE
                    }
                    else {
                        start-sleepProgress -sleepString "Error obtaining Exchange Online object - resetting connection." -sleepSeconds 60
                        disable-allPowerShellSessions
                        reset-exchangeOnlinePowershell
                    }
                } 
            }
            elseif ($queryType -eq $functionExchangeGroupMailbox)
            {
                try {
                    $returnObject = get-o365UnifiedGroup -identity $objectID -ErrorAction Stop

                    if ($returnObject.IsMembershipDynamic -eq $TRUE)
                    {
                        $global:groupMailboxDynamicCounter+=$returnObject.exchangeObjectID
                    }
                    else {
                        $global:groupMailboxCounter+=$returnObject.exchangeObjectID
                    }
                    $retryRequired = $FALSE
                }
                catch {
                    $retryCounter++
                    if ($retryCounter -gt 4)
                    {
                        out-logfile -string "Unable to obtain Exchange Online Unified Group."
                        out-logfile -string $_ -isError:$TRUE
                    }
                    else {
                        start-sleepProgress -sleepString "Error obtaining Exchange Online object - resetting connection." -sleepSeconds 60
                        disable-allPowerShellSessions
                        reset-exchangeOnlinePowershell
                    }
                }
            }
            elseif ($queryType -eq $functionExchangeDynamicGroup)
            {
                try {
                    $returnObject = get-o365DynamicDistributionGroup -Identity $objectID -errorAction Stop
                    $global:dynamicGroupCounter+=$returnObject.exchangeObjectID
                    $retryRequired = $FALSE
                }
                catch {
                    $retryCounter++
                    out-logfile -string "Unable to obtain Exchange Online Dynamic Distribution Group."

                    if ($secondTry -eq $FALSE)
                    {
                        if ($retryCounter -gt 4)
                        {
                            out-logfile -string $_ -isError:$TRUE
                        }
                        else
                        {
                            start-sleepProgress -sleepString "Error obtaining Exchange Online object - resetting connection." -sleepSeconds 60
                            disable-allPowerShellSessions
                            reset-exchangeOnlinePowershell
                        }
                    }
                    else 
                    {
                        out-logfile -string $_
                    }
                }
            }
            elseif ($queryType -eq $functionExchangeGroup) 
            {
                try {
                    $returnObject = get-o365group -identity $objectID -ErrorAction Stop
                    $global:groupCounter+=$returnObject.exchangeObjectID
                    $retryRequired = $FALSE
                }
                catch {
                    out-logfile -string "It is possible the root group is a dynamic group - this is not returned by get-group."
                    out-logfile -string "Try obtaining dynamic group."

                    try {
                        $returnObject = get-ExchangeGroup -objectID $objectID -queryType $functionExchangeDynamicGroup -ErrorAction Stop -secondTry $TRUE
                        $retryRequired = $FALSE
                    }
                    catch {
                        out-logfile -string "Group is neither a root dynamic group or returned by get-group."
                        out-logfile -string "Unable to obtain Exchange Group object."
                        out-logfile -string "This error may be expected.  If a security group was previously mail enabled.."
                        out-logfile -string "And then mail disalbed it remains in Exchange Online and could be a member..."
                        out-logfile -string "But is not returned by get-Group."
                        out-logfile -string "Testing to ensure root group is not a dynamic group."
                        out-logfile -string $_ -isError:$true
                    }
                } 
            }
            
        } until (
            $retryRequired -eq $false
        )

        return $returnObject
    }

    function get-ExchangeUser
    {
        Param
        (
            [Parameter(Mandatory = $true)]
            $objectID,
            [Parameter(Mandatory = $true)]
            $queryType
        )

        $retryCounter = 0
        $retryRequired = $TRUE

        do {
            if ($queryType -eq $functionExchangeUser)
            {
                try {
                    $returnObject = get-o365user -identity $objectID -ErrorAction Stop
                    $global:userCounter+=$returnObject.exchangeObjectID
                    $retryRequired = $FALSE
                }
                catch {
                    $retryCounter++

                    if ($retryCounter -gt 4)
                    {
                        out-logfile -string "Unable to obtain Exchange Online User Object"
                        out-logfile -string $_ -isError:$TRUE
                    }
                    else {
                        start-sleepProgress -sleepString "Error obtaining Exchange Online object - resetting connection." -sleepSeconds 60
                        disable-allPowerShellSessions
                        reset-exchangeOnlinePowershell
                    }
                } 
            }
            elseif ($queryType -eq $functionExchangeSharedMailbox)
            {
                try {
                    $returnObject = get-o365Mailbox -identity $objectID -ErrorAction Stop
                    $global:sharedMailboxCounter+=$returnObject.exchangeObjectID
                    $retryRequired = $FALSE
                }
                catch {
                    $retryCounter++

                    if ($retryCounter -gt 4)
                    {
                        out-logfile -string "Unable to obtain Exchange Online Mailbox Object"
                        out-logfile -string $_ -isError:$TRUE
                    }
                    else {
                        start-sleepProgress -sleepString "Error obtaining Exchange Online object - resetting connection." -sleepSeconds 60
                        disable-allPowerShellSessions
                        reset-exchangeOnlinePowershell
                    }
                } 
            }
            elseif ($queryType -eq $functionExchangeEquipmentMailbox)
            {
                try {
                    $returnObject = get-o365Mailbox -identity $objectID -ErrorAction Stop
                    $global:equipmentMailboxCounter+=$returnObject.exchangeObjectID
                    $retryRequired = $FALSE
                }
                catch {
                    $retryCounter++

                    if ($retryCounter -gt 4)
                    {
                        out-logfile -string "Unable to obtain Exchange Online Mailbox Object"
                        out-logfile -string $_ -isError:$TRUE
                    }
                    else {
                        start-sleepProgress -sleepString "Error obtaining Exchange Online object - resetting connection." -sleepSeconds 60
                        disable-allPowerShellSessions
                        reset-exchangeOnlinePowershell
                    }
                } 
            }
            elseif ($queryType -eq $functionExchangeRoomMailbox)
            {
                try {
                    $returnObject = get-o365Mailbox -identity $objectID -ErrorAction Stop
                    $global:roomMailboxCounter+=$returnObject.exchangeObjectID
                    $retryRequired = $FALSE
                }
                catch {
                    $retryCounter++

                    if ($retryCounter -gt 4)
                    {
                        out-logfile -string "Unable to obtain Exchange Online Mailbox Object"
                        out-logfile -string $_ -isError:$TRUE
                    }
                    else {
                        start-sleepProgress -sleepString "Error obtaining Exchange Online object - resetting connection." -sleepSeconds 60
                        disable-allPowerShellSessions
                        reset-exchangeOnlinePowershell
                    }
                } 
            }
            elseif ($queryType -eq $functionExchangeUserMailbox)
            {
                try {
                    $returnObject = get-o365Mailbox -identity $objectID -ErrorAction Stop
                    $global:userMailboxCounter+=$returnObject.exchangeObjectID
                    $retryRequired = $FALSE
                }
                catch {
                    $retryCounter++

                    if ($retryCounter -gt 4)
                    {
                        out-logfile -string "Unable to obtain Exchange Online Mailbox Object"
                        out-logfile -string $_ -isError:$TRUE
                    }
                    else {
                        start-sleepProgress -sleepString "Error obtaining Exchange Online object - resetting connection." -sleepSeconds 60
                        disable-allPowerShellSessions
                        reset-exchangeOnlinePowershell
                    }
                } 
            }
            elseif ($queryType -eq $functionExchangeMailUser)
            {
                try {
                    $returnObject = get-o365MailUser -identity $objectID -ErrorAction Stop
                    $global:mailUserCounter+=$returnObject.exchangeObjectID
                    $retryRequired = $FALSE
                }
                catch {
                    $retryCounter++

                    if ($retryCounter -gt 4)
                    {
                        out-logfile -string "Unable to obtain Exchange Online Mail User Object"
                        out-logfile -string $_ -isError:$TRUE
                    }
                    else {
                        start-sleepProgress -sleepString "Error obtaining Exchange Online object - resetting connection." -sleepSeconds 60
                        disable-allPowerShellSessions
                        reset-exchangeOnlinePowershell
                    }
                } 
            }
            elseif ($queryType -eq $functionExchangeGuestMailUser)
            {
                try {
                    $returnObject = get-o365MailUser -identity $objectID -ErrorAction Stop
                    $global:guestMailUserCounter+=$returnObject.exchangeObjectID
                    $retryRequired = $FALSE
                }
                catch {
                    $retryCounter++

                    if ($retryCounter -gt 4)
                    {
                        out-logfile -string "Unable to obtain Exchange Online Guest Mail Object"
                        out-logfile -string $_ -isError:$TRUE
                    }
                    else {
                        start-sleepProgress -sleepString "Error obtaining Exchange Online object - resetting connection." -sleepSeconds 60
                        disable-allPowerShellSessions
                        reset-exchangeOnlinePowershell
                    }
                } 
            }
            elseif ($queryType -eq $functionExchangeMailContact)
            {
                try {
                    $returnObject = get-o365contact -Identity $objectID -errorAction Stop
                    $global:mailContactCounter+=$returnObject.exchangeObjectID
                    $retryRequired = $FALSE

                }
                catch {
                    $retryCounter++

                    if ($retryCounter -gt 4)
                    {
                        out-logfile -string "Unable to obtain Exchange Online Mail Contact Object"
                        out-logfile -string $_ -isError:$TR
                    }
                    else {
                        start-sleepProgress -sleepString "Error obtaining Exchange Online object - resetting connection." -sleepSeconds 60
                        disable-allPowerShellSessions
                        reset-exchangeOnlinePowershell
                    }
                }
            }
        } until (
            $retryRequired -eq $FALSE
        )

        return $returnObject
    }

    function get-GraphGroupMemberOf
    {
        Param
        (
            [Parameter(Mandatory = $true)]
            $objectID
        )

        $returnObjects = Get-MGGroupMemberOf -groupID $objectID -all -errorAction STOP

        return $returnObjects
    }

    function get-ExchangeGroupMemberOf
    {
        Param
        (
            [Parameter(Mandatory = $true)]
            $distinguishedName
        )

        $returnObjects = @()

        out-logfile -string "Entering get-ExchangeGroupMemberOF"

        $functionCommand = "Get-o365DistributionGroup -Filter { $exchangeMembersAttribute -eq `"$distinguishedName`" } -errorAction 'STOP'"

        out-logfile -string $functionCommand

        $scriptBlock=[scriptBlock]::create($functionCommand)

        try {
            $returnObjects += invoke-command -scriptBlock $scriptBlock
        }
        catch {
            out-logfile $_
            out-logfile -string "Unable to obtain distribution group membership." -isError:$TRUE
        }

        return $returnObjects
    }


    #===============================================================================
    #Graph Code
    #===============================================================================


    if ($functionParamterSetName -eq $functionGraphName)
    {
        out-logfile -string "Entering graph processing..."

        switch ($objectType)
        {
            $functionGraphGroup
            {
                out-logfile -string $functionGraphGroup
                try {
                    $functionObject = get-MGGroup -GroupId $objectID -ErrorAction Stop

                    if ($functionObject.groupTypes -contains "DynamicMembership")
                    {
                        $global:msGraphObjects+=$functionObjects
                        $global:msGraphGroupDynamicCount+=$functionObject.id
                    }
                    else 
                    {    
                        $global:msGraphObjects+=$functionObject
                        $global:msGraphGroupCount+=$functionObject.id
                    }
                }
                catch {
                    out-logfile -string $_
                    out-logfile -string "Error obtaining group." -isError:$TRUE
                }    
            }
            $functiongraphUser
            {
                out-logfile -string $functiongraphUser
                try {
                    $functionObject = get-MGUser -userID $objectID -ErrorAction Stop
                    $global:msGraphObjects+=$functionObject
                    $global:msGraphUserCount+=$functionObject.id
                }
                catch {
                    out-logfile -string $_
                    out-logfile -string "Error obtaining user." -isError:$TRUE
                }
            }
            $functionGraphContact
            {
                out-logfile -string $functionGraphContact
                try {
                    $functionObject = get-MGContact -OrgContactId $objectID -errorAction Stop
                    $global:msGraphObjects+=$functionObject
                    $global:msGraphContactCount+=$functionObject.id
                }
                catch {
                    out-logfile -string $_
                    out-logfile -string "Error obtaining contact." -isError:$TRUE
                }
            }
            Default
            {
                out-logfile -string "Default"
                out-logfile -string "Invalid object type discovered - contact support." -isError:$TRUE
            }
        }
        
        out-logfile -string $functionObject

        if (!$processedGroupIds.Contains($functionObject.Id))
        {
            out-logfile -string "Group has not already been processed."

            $NULL = $processedGroupIds.add($functionObject.id)

            if ($objectType -eq $functionGraphGroup)
            {
                out-logfile -string "Object is a group - determining children."

                if ($expandGroupMembership -eq $TRUE)
                {
                    if ($reverseHierarchy -eq $FALSE)
                    {
                        out-logfile -string "Full group membership expansion is enabled."

                        try {
                            $children = Get-MgGroupMember -GroupId $functionObject.Id -all -errorAction STOP
                        }
                        catch {
                            out-logfile -string $_
                            out-logfile -string "Error obtaining group membership." -isError:$TRUE
                        }
                    }
                    else 
                    {
                        out-logfile -string "Full group membership expansion is enabled - reverse"

                       try {
                         $children = get-GraphGroupMemberOf -objectID $functionObject.id
                       }
                       catch {
                        out-logfile -string $_
                        out-logfile -string "Error obtaining parent group membership." -isError:$TRUE
                       }
                    }
                }
                else 
                {
                    if ($reverseHierarchy -eq $FALSE)
                    {
                        out-logfile -string "Full group membership expansion disabled."

                        try {
                            $children = Get-MgGroupMember -GroupId $functionObject.Id -all -errorAction STOP | where {$_.AdditionalProperties.'@odata.type' -eq $functionGraphGroup}
                        }
                        catch {
                            out-logfile -string $_
                            out-logfile -string "Error obtaining group membership." -isError:$TRUE
                        }
                    }
                    else {
                        out-logfile -string "Full group membership expansion disabled - reverse."

                        try {
                            $children = get-GraphGroupMemberOf -objectID $functionObject.id
                          }
                          catch {
                           out-logfile -string $_
                           out-logfile -string "Error obtaining parent group membership." -isError:$TRUE
                          }
                    }
                }
            }
            else {
                out-logfile -string "Object is not a group - no children."

                $children=@()
            }

            foreach ($child in $children)
            {
                out-logfile -string "Processing child..."
                out-logfile -string $child.id
                $global:childGroupIDs = New-Object System.Collections.Generic.HashSet[string] $processedGroupIds

                if ($reverseHierarchy -eq $FALSE)
                {
                    $global:childCounter++
                }
                else 
                {
                    $global:childCounter--
                }
                
                out-logfile -string $childCounter.tostring()
                $childNode = Get-GroupWithChildren -objectID $child.id -processedGroupIds $childGroupIDs -objectType $child.additionalProperties["@odata.type"] -queryMethodGraph:$true -expandGroupMembership $expandGroupMembership -reverseHierarchy $reverseHierarchy
                $childNodes += $childNode
                $global:childCounter--
                out-logfile -string $global:childCounter.tostring()
            }
        }
        else 
        {
            out-logfile -string "Group has already been processed."

            $functionObject.DisplayName = $functionObject.DisplayName + " (Circular Membership)"
        }

        $node = New-TreeNode -object $functionObject -children $childNodes
    }

    #===============================================================================
    #Exchange Online Code
    #===============================================================================

    elseif ($functionParamterSetName -eq $functionExchangeOnlineName)
    {
        out-logfile -string "Entering exchange online processing..."

        switch ($objectType)
        {
            $functionExchangeGroupMailbox
            {
                out-logfile -string $functionExchangeGroupMailbox 
                $functionObject = get-ExchangeGroup -objectID $objectID -queryType $functionExchangeGroupMailbox
                $isExchangeGroupType=$TRUE 
                $global:exchangeObjects += $functionObject
            }
            $functionExchangeRoomMailbox
            {
                out-logfile -string $functionExchangeRoomMailbox 
                $functionObject = get-ExchangeUser -objectID $objectID -queryType $functionExchangeRoomMailbox
                $global:exchangeObjects += $functionObject
            }
            $functionExchangeSharedMailbox
            {
                out-logfile -string $functionExchangeSharedMailbox 
                $functionObject = get-ExchangeUser -objectID $objectID -queryType $functionExchangeSharedMailbox
                $global:exchangeObjects += $functionObject
            }
            $functionExchangeEquipmentMailbox
            {
                out-logfile -string $functionExchangeEquipmentMailbox 
                $functionObject = get-ExchangeUser -objectID $objectID -queryType $functionExchangeEquipmentMailbox
                $global:exchangeObjects += $functionObject
            }
            $functionExchangeUser
            {
                out-logfile -string $functionExchangeUser 
                $functionObject = get-ExchangeUser -objectID $objectID -queryType $functionExchangeUser
                $global:exchangeObjects += $functionObject
            }
            $functionExchangeGroup
            {
                out-logfile -string $functionExchangeGroup
                $functionObject = get-ExchangeGroup -objectID $objectID -queryType $functionExchangeGroup
                $isExchangeGroupType=$TRUE
                $global:exchangeObjects += $functionObject 
            }
            $functionExchangeMailUniversalSecurityGroup
            {
                out-logfile -string $functionExchangeMailUniversalSecurityGroup
                $functionObject = get-ExchangeGroup -objectID $objectID -queryType $functionExchangeMailUniversalSecurityGroup
                $isExchangeGroupType=$TRUE  
                $global:exchangeObjects += $functionObject
            }
            $functionExchangeMailUniversalDistributionGroup
            {
                out-logfile -string $functionExchangeMailUniversalDistributionGroup
                $functionObject = get-ExchangeGroup -objectID $objectID -queryType $functionExchangeMailUniversalDistributionGroup
                $isExchangeGroupType=$TRUE  
                $global:exchangeObjects += $functionObject
            }   
            $functionExchangeUserMailbox
            {
                out-logfile -string $functionExchangeUserMailbox 
                $functionObject = get-ExchangeUser -objectID $objectID -queryType $functionExchangeUserMailbox
                $global:exchangeObjects += $functionObject
            }
            $functionExchangeMailUser
            {
                out-logfile -string $functionExchangeMailUser 
                $functionObject = get-ExchangeUser -objectID $objectID -queryType $functionExchangeMailUser
                $global:exchangeObjects += $functionObject
            }
            $functionExchangeGuestMailUser
            {
                out-logfile -string $functionExchangeGuestMailUser
                $functionObject = get-ExchangeUser -objectID $objectID -queryType $functionExchangeGuestMailUser
                $global:exchangeObjects += $functionObject
            }
            $functionExchangeMailContact
            {
                out-logfile -string $functionExchangeMailContact
                $functionObject = get-ExchangeUser -objectID $objectID -queryType $functionExchangeMailContact
                $global:exchangeObjects += $functionObject
            }
            $functionExchangeDynamicGroup
            {
                out-logfile -string $functionExchangeDynamicGroup
                $functionObject = get-ExchangeGroup -objectID $objectID -queryType $functionExchangeDynamicGroup
                $isExchangeGroupType=$TRUE 
                $global:exchangeObjects += $functionObject
            }
            Default
            {
                out-logfile -string "Default"
                out-logfile -string "Invalid object type discovered - contact support." -isError:$TRUE
            }
        }

        out-logfile -string $functionObject

        out-logfile -string "Beginning object processing..."

        if (!$processedGroupIds.Contains($functionObject.ExchangeObjectID))
        {
            out-logfile -string "Group has not already been processed."

            $NULL = $processedGroupIds.add($functionObject.ExchangeObjectID)

            out-logfile -string "Determine if object is an Exchange Group type and if so enumerate membership."
            out-logfile -string ("Exchange Group Type: "+$isExchangeGroupType)

            if ($isExchangeGroupType -eq $TRUE)
            {
                if ($functionObject.recipientTypeDetails -eq $functionExchangeDynamicGroup)
                {
                    out-logfile -string "Group is a dynamic group - children determined by recipient filter."

                    if ($reverseHierarchy -eq $false)
                    {
                        if ($expandDynamicGroupMembership -eq $TRUE)
                        {
                            out-logfile -string "Dynamic group membership expansion enabled."
    
                            try {
                                $children = get-o365Recipient -RecipientPreviewFilter $functionObject.RecipientFilter -resultsize unlimited -errorAction STOP
                            }
                            catch {
                                out-logfile $_
                                out-logfile -string "Unable to obtain dynamic DL members by recipient filter preview." -isError:$TRUE
                            }
                        }
                        else 
                        {
                            out-logfile -string "Dynamic group membership expansion is disabled."
                            $childern=@()
                        }
                    }
                    else 
                    {
                        out-logfile -string "Full group membership expansion is enabled - reverse."

                        $children = get-ExchangeGroupMemberOf -distinguishedName $functionObject.distinguishedName
                    }
                }
                elseif ($functionObject.recipientTypeDetails -ne $functionExchangeGroupMailbox)
                {
                    out-logfile -string "Group is not a unified group or dynamic group - get standard membership."

                    if ($expandGroupMembership -eq $TRUE)
                    {
                        if ($reverseHierarchy -eq $FALSE)
                        {
                            out-logfile -string "Full group membership expansion is enabled."
                            try {
                                $children = Get-o365distributionGroupMember -Identity $functionObject.ExchangeObjectID -resultSize unlimited -errorAction STOP
                            }
                            catch {
                                out-logfile $_
                                out-logfile -string "Unable to obtain distribution group membership." -isError:$TRUE
                            }
                        }
                        else 
                        {
                            out-logfile -string "Full group membership expansion is enabled - reverse."

                            $children = get-ExchangeGroupMemberOf -distinguishedName $functionObject.distinguishedName
                        }
                    }
                    else 
                    {
                        out-logfile -string "Full group membership expansion is disabled."

                        if ($reverseHierarchy -eq $FALSE)
                        {
                            try {
                                $children = Get-o365distributionGroupMember -Identity $functionObject.ExchangeObjectID -resultSize unlimited -errorAction STOP | where {($_.recipientTypeDetails -eq $functionExchangeMailUniversalSecurityGroup) -or ($_.recipientTypeDetails -eq $functionExchangeMailUniversalDistributionGroup) -or ($_.recipientTypeDetails -eq $functionExchangeGroupMailbox) -or ($_.recipientTypeDetails -eq $functionExchangeDynamicGroup)}
                            }
                            catch {
                                out-logfile $_
                                out-logfile -string "Unable to obtain distribution group membership." -isError:$TRUE
                            }
                        }
                        else
                        {
                            out-logfile -string "Full group membership expansion is enabled - reverse."

                            $children = get-ExchangeGroupMemberOf -distinguishedName $functionObject.distinguishedName
                        }                      
                    }
                }
                else 
                {
                    out-logfile -string "Group is a unified group - perform link member query."

                    if ($reverseHierarchy -eq $FALSE)
                    {
                        if ($expandGroupMembership -eq $TRUE)
                        {
                            out-logfile -string "Full group membership expansion is enabled."
    
                            try {
                                $children = get-o365UnifiedGroupLinks -identity $functionObject.ExchangeObjectID -linkType Member -resultSize unlimited -errorAction STOP
                            }
                            catch {
                                out-logfile $_
                                out-logfile -string "Unable to obtain unified group membership." -isError:$TRUE
                            }
                        }
                        else 
                        {
                            out-logfile -string "Full group membership expansion is disabled."
    
                            $children=@()
                        }
                    }
                    else 
                    {
                        out-logfile -string "Full group membership expansion is enabled - reverse."

                        $children = get-ExchangeGroupMemberOf -distinguishedName $functionObject.distinguishedName
                    }
                }
            }
            else {
                $children=@()
            }

            foreach ($child in $children)
            {
                out-logfile -string "Processing child..."
                out-logfile -string $child.ExchangeObjectID
                $childGroupIDs = New-Object System.Collections.Generic.HashSet[string] $processedGroupIds

                if ($reverseHierarchy -eq $FALSE)
                {
                    $global:childCounter++
                }
                else 
                {
                    $global:childCounter--
                }

                out-logfile -string $global:childCounter.tostring()
                $childNode = Get-GroupWithChildren -objectID $child.ExchangeObjectID -processedGroupIds $childGroupIDs -objectType $child.RecipientTypeDetails -queryMethodExchangeOnline:$TRUE -expandGroupMembership $expandGroupMembership -expandDynamicGroupMembership $expandDynamicGroupMembership -reverseHierarchy $reverseHierarchy
                $childNodes += $childNode
                $global:childCounter--
                out-logfile -string $global:childCounter.tostring()
            }
        }
        else 
        {
            out-logfile -string "Group has already been processed."

            if ($functionObject.displayName -eq "")
            {
                $functionObject.displayName = $functionObject.name
            }
            elseif ($functionObject.displayName -eq $NULL)
            {
                $functionObject.displayName = $functionObject.name
            }
            
            $functionObject.DisplayName = $functionObject.DisplayName + " (Circular Membership)"
        }

        if ($functionObject.displayName -eq "")
        {
            $functionObject.displayName = $functionObject.name
        }
        elseif ($functionObject.displayName -eq $NULL)
        {
            $functionObject.displayName = $functionObject.name
        }
    
        $node = New-TreeNode -object $functionObject -children $childNodes
    }

    #===============================================================================
    #LDAP Code
    #===============================================================================

    elseif ($functionParamterSetName -eq $functionLDAPName)
    {
        out-logfile -string "Entering LDAP processing..."

        out-logfile -string "Obtaining group getting adobject."

        try{
            $functionObject = get-adObject -identity $objectID -properties * -server $globalCatalogServer -Credential $activeDirectoryCredential -ErrorAction STOP
            $global:ldapObjects += $functionObject
        }
        catch {
            out-logfile -string $_
            out-logfile -string "Unable to obtain the ad object by ID." -isError:$TRUE
        }

        if (($functionObject.objectClass -ne $functionLDAPDynamicGroup) -and ($functionObject.objectClass -ne $functionLDAPGroup) -and ($firstLDAPQuery -eq $TRUE))
        {
            out-logfile -string $functionObject.objectClass
            out-logfile -string "Object specified is not a group or dynamic group." -isError:$TRUE
        }

        $childNodes = @()

        out-logfile -string $functionObject

        out-logfile -string "Beginning object processing..."

        if ($functionObject.objectClass -eq $functionLDAPDynamicGroup)
        {
            $global:dynamicGroupCounter+=$functionObject.objectGUID
        }
        elseif ($functionObject.objectClass -eq $functionLDAPContact)
        {
            $global:contactCounter+=$functionObject.objectGUID
        }
        elseif ($functionObject.objectClass -eq $functionLDAPUser)
        {
            $global:userCounter+=$functionObject.objectGUID
        }
        elseif ($functionObject.objectClass -eq $functionLDAPGroup)
        {
            $global:groupCounter+=$functionObject.objectGUID
            
            if ($functionObject.mail -ne $NULL)
            {   
                $outputObject = New-Object PSObject -Property @{
                    ParentObjectID = $parentObjectID
                    CN = $functionObject.cn
                    Mail = $functionObject.Mail
                    NestingLevel = $global:childCounter.tostring()
                }

                $global:groupTracking+=$outputObject
            }
            else 
            {
                $outputObject = New-Object PSObject -Property @{
                    ParentObjectID = $objectID
                    CN = $functionObject.cn
                    Mail = "CAUTION:  Group in hierarchy with no mail address."
                    NestingLevel = $global:childCounter.tostring()
                }

                $global:groupTracking+=$outputObject
            }
        }

        if (!$processedGroupIds.Contains($functionObject.distinguishedName))
        {
            out-logfile -string "Object has not been previously processed..."

            $NULL = $processedGroupIds.add($functionObject.distinguishedName)

            if ($functionObject.objectClass -eq $functionLDAPDynamicGroup)
            {
                out-logfile -string "Object class is dynamic group - members determined via query."

                if ($expandDynamicGroupMembership -eq $TRUE)
                {
                    out-logfile -string "Dynamic group membership expansion enabled."

                    if ($reverseHierarchy -eq $FALSE)
                    {
                        try {
                            $children = Get-ADObject -LDAPFilter $functionObject.msExchDynamicDLFilter -SearchBase $functionObject.msExchDynamicDLBaseDN -Properties * -server $globalCatalogServer -Credential $activeDirectoryCredential -ErrorAction STOP
                        }
                        catch {
                            out-logfile $_
                            out-logfile -string "Unable to obtain dynamic group membership via LDAP call."
                        }
    
                        out-logfile -string "Filter children to only contain users, groups, or contacts since LDAP query inclues all object classes."
                        out-logfile -string $children.Count.tostring()
                        $children = $children | where {($_.objectClass -eq $functionLDAPuser) -or ($_.objectClass -eq $functionLDAPGroup) -or ($_.objectClass -eq $functionLDAPContact) -or ($_.objectClass -eq $functionLDAPDynamicGroup)}
                        out-logfile -string $children.Count.tostring()
                    }
                    else 
                    {
                        out-logfile -string "Expand full group membership enabled."
                        out-logfile -string "Reverse hierarchy in use."

                        $children = $functionObject.memberof
                    }
                }
                else 
                {
                    out-logfile -string "Dynamic group membership expansion disabled."
                    $children = @()
                }
            }
            elseif ($functionObject.objectClass -eq $functionLDAPGroup )
            {
                out-logfile -string "Object class id group - members determiend by member attribute on group."

                if ($expandGroupMembership -eq $TRUE)
                {
                    if ($reverseHierarchy -eq $FALSE)
                    {
                        out-logfile -string "Expand full group membership enabled."
                        out-logfile -string "Reverse hierarchy not in use."

                        $children = $functionObject.member
                    }
                    else 
                    {
                        out-logfile -string "Expand full group membership enabled."
                        out-logfile -string "Reverse hierarchy in use."

                        $children = $functionObject.memberof
                    }
                }
                else
                {
                    if ($reverseHierarchy -eq $FALSE)
                    {
                        out-logfile -string "Expand full group membership disabled."
                        out-logfile -string "Reverse hierarchy not in use."

                        out-logfile -string "Construct LDAP Filter"

                        $groupLdapFilter = "(&(objectCategory=Group)(memberof="+$functionObject.distinguishedName+"))"
                        
                        out-logfile -string $groupLDAPFilter

                        try 
                        {
                            $children = get-adGroup -ldapFilter $groupLDAPFilter -server $globalCatalogServer -Credential $activeDirectoryCredential -ErrorAction STOP
                        }
                        catch 
                        {
                            out-logfile -string $_
                            out-logfile "Unable to obtain group membership filtered by groups only." -isError:$TRUE
                        }
                    }
                    else 
                    {
                        out-logfile -string "Expand full group membership disabled."
                        out-logfile -string "Reverse hierarchy in use."

                        out-logfile -string "Construct LDAP Filter"

                        $groupLdapFilter = "(&(objectCategory=Group)(member="+$functionObject.distinguishedName+"))"
                        
                        out-logfile -string $groupLDAPFilter

                        try 
                        {
                            $children = get-adGroup -ldapFilter $groupLDAPFilter -server $globalCatalogServer -Credential $activeDirectoryCredential -ErrorAction STOP
                        }
                        catch 
                        {
                            out-logfile -string $_
                            out-logfile "Unable to obtain group membership filtered by groups only." -isError:$TRUE
                        }
                    }
                }
            }
            else {
                out-logfile -string "Object is not a dynamic group or group."
                $children=@()
            }

            foreach ($child in $children)
            {
                if ($reverseHierarchy -eq $FALSE)
                {
                    write-host "ChildID"
                    write-host $child
                    $childGroupIDs = New-Object System.Collections.Generic.HashSet[string] $processedGroupIds
                    $childNode = Get-GroupWithChildren -objectID $child -processedGroupIds $childGroupIDs -objectType "None" -globalCatalogServer $globalCatalogServer -activeDirectoryCredential $activeDirectoryCredential -queryMethodLDAP:$true -expandGroupMembership $expandGroupMembership -expandDynamicGroupMembership $expandDynamicGroupMembership -firstLDAPQuery $false -parentObjectID $functionObject.ID
                    $childNodes += $childNode
                }
                else 
                {
                    write-host "ChildID"
                    write-host $child
                    $childGroupIDs = New-Object System.Collections.Generic.HashSet[string] $processedGroupIds
                    $childNode = Get-GroupWithChildren -objectID $child -processedGroupIds $childGroupIDs -objectType "None" -globalCatalogServer $globalCatalogServer -activeDirectoryCredential $activeDirectoryCredential -queryMethodLDAP:$true -expandGroupMembership $expandGroupMembership -expandDynamicGroupMembership $expandDynamicGroupMembership -firstLDAPQuery $false -reverseHierarchy:$TRUE -parentObjectID $functionObject.ID
                    $childNodes += $childNode
                }  
            }
        }
        else 
        {
            out-logfile -string "Group has already been processed."

            if ($functionObject.displayName -eq "")
            {
                $functionObject.displayName = $functionObject.name
            }
            elseif ($functionObject.displayname -eq $NULL)
            {
                $functionObject.displayName = $functionObject.name
            }

            $functionObject.DisplayName = $functionObject.DisplayName + " (Circular Membership)"
        }

        if ($functionObject.displayName -eq "")
        {
            $functionObject.displayName = $functionObject.name
        }
        elseif ($functionObject.displayname -eq $NULL)
        {
            $functionObject.displayName = $functionObject.name
        }

        $node = New-TreeNode -object $functionObject -children $childNodes
    }

    $global:childCounter--
    out-logfile -string $global:childCounter.tostring()

    out-logfile -string "***********************************************************"
    out-logfile -string "Exiting Get-GroupWithChildren"
    out-logfile -string "***********************************************************"

    return $node
}