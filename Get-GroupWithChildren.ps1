
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
        [boolean]$expandDynamicGroupMembership=$TRUE
    )
    
    out-logfile -string "***********************************************************"
    out-logfile -string "Entering Get-GroupWithChildren"
    out-logfile -string "***********************************************************"

    $global:childCounter++
    out-logfile -string ("Recursion Counter: "+$global:childCounter.tostring())

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
    $functionExchangeUser = "User"
    $isExchangeGroupType = $false

    $functionLDAPGroup = "Group"
    $functionLDAPUser = "User"
    $functionLDAPContact = "Contact"
    $functionLDAPDynamicGroup = "msExchDynamicDistributionList"

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

    function get-ExchangeGroup
    {
        Param
        (
            [Parameter(Mandatory = $true)]
            $objectID,
            [Parameter(Mandatory = $false)]
            $queryType
        )

        if ($queryType -eq $functionExchangeMailUniversalSecurityGroup)
        {
            try {
                $returnObject = get-o365DistributionGroup -identity $objectID -ErrorAction Stop
            }
            catch {
                out-logfile -string "Unable to obtain Exchange Online Mail Enabled Security Group."
                out-logfile -string $_ -isError:$TRUE
            } 
        }        
        elseif ($queryType -eq $functionExchangeMailUniversalDistributionGroup)
        {
            try {
                $returnObject = get-o365DistributionGroup -identity $objectID -ErrorAction Stop
            }
            catch {
                out-logfile -string "Unable to obtain Exchange Online Mail Enabled Distribution Group."
                out-logfile -string $_
                out-logfile -string "Trying to obtain object as Unified Group."

                try {
                    $returnObject = get-o365UnifiedGroup -identity $objectID -ErrorAction Stop

                }
                catch {
                    out-logfile -string "Unable to obtain Exchange Online Unified Group."
                    out-logfile -string $_ -isError:$TRUE
                }
            } 
        }
        elseif ($queryType -eq $functionExchangeDynamicGroup)
        {
            try {
                $returnObject = get-o365DynamicDistributionGroup -Identity $objectID -errorAction Stop
            }
            catch {
                out-logfile -string "Unable to obtain Exchange Online Dynamic Distribution Group."
                out-logfile -string $_ -isError:$TRUE
            }
        }
        elseif ($queryType -eq $functionExchangeGroup) 
        {
            try {
                $returnObject = get-o365group -identity $objectID -ErrorAction Stop
            }
            catch {
                out-logfile -string "Unable to obtain Exchange Group object."
                out-logfile -string "This error may be expected.  If a security group was previously mail enabled.."
                out-logfile -string "And then mail disalbed it remains in Exchange Online and could be a member..."
                out-logfile -string "But is not returned by get-Group."
                out-logfile -string $_ -isError:$true
            } 
        }

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

        if ($queryType -eq $functionExchangeUser)
        {
            try {
                $returnObject = get-o365user -identity $objectID -ErrorAction Stop
            }
            catch {
                out-logfile -string "Unable to obtain Exchange Online User Object"
                out-logfile -string $_ -isError:$TRUE
            } 
        }
        elseif ($queryType -eq $functionExchangeUserMailbox)
        {
            try {
                $returnObject = get-o365Mailbox -identity $objectID -ErrorAction Stop
            }
            catch {
                out-logfile -string "Unable to obtain Exchange Online Mailbox Object"
                out-logfile -string $_ -isError:$TRUE
            } 
        }

        return $returnObject
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
                    out-logfile -string "Full group membership expansion disabled."

                    try {
                        $children = Get-MgGroupMember -GroupId $functionObject.Id -all -errorAction STOP | where {$_.AdditionalProperties.'@odata.type' -eq $functionGraphGroup}
                    }
                    catch {
                        out-logfile -string $_
                        out-logfile -string "Error obtaining group membership." -isError:$TRUE
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
                $global:childCounter++
                out-logfile -string $childCounter.tostring()
                $childNode = Get-GroupWithChildren -objectID $child.id -processedGroupIds $childGroupIDs -objectType $child.additionalProperties["@odata.type"] -queryMethodGraph:$true -expandGroupMembership $expandGroupMembership
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

        if ($functionObject.displayName -eq "")
        {
            $functionObject.displayName = $functionObject.name
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
            $functionExchangeUser
            {
                out-logfile -string $functionExchangeUser -queryType $functionExchangeUser
                $functionObject = get-ExchangeUser -objectID $objectID
            }
            $functionExchangeGroup
            {
                out-logfile -string $functionExchangeGroup
                $functionObject = get-ExchangeGroup -objectID $objectID -queryType $functionExchangeGroup
                $isExchangeGroupType=$TRUE 
            }
            $functionExchangeMailUniversalSecurityGroup
            {
                out-logfile -string $functionExchangeMailUniversalSecurityGroup
                $functionObject = get-ExchangeGroup -objectID $objectID -queryType $functionExchangeMailUniversalSecurityGroup
                $isExchangeGroupType=$TRUE  
            }
            $functionExchangeMailUniversalDistributionGroup
            {
                out-logfile -string $functionExchangeMailUniversalDistributionGroup
                $functionObject = get-ExchangeGroup -objectID $objectID -queryType $functionExchangeMailUniversalDistributionGroup
                $isExchangeGroupType=$TRUE  
            }   
            $functionExchangeUserMailbox
            {
                out-logfile -string $functionExchangeUserMailbox -queryType $functionExchangeUserMailbox
                $functionObject = get-ExchangeUser -objectID $objectID
            }
            $functionExchangeMailUser
            {
                out-logfile -string $functionExchangeMailUser
                $functionObject = get-ExchangeUser -objectID $objectID
            }
            $functionExchangeGuestMailUser
            {
                out-logfile -string $functionExchangeGuestMailUser
                $functionObject = get-ExchangeUser -objectID $objectID
            }
            $functionExchangeMailContact
            {
                out-logfile -string $functionExchangeMailContact
                try {
                    $functionObject = get-o365contact -Identity $objectID -errorAction Stop
                }
                catch {
                    write-host $_
                    write-error "Object type is contact - unable to obtain object."
                    exit
                }
            }
            $functionExchangeDynamicGroup
            {
                out-logfile -string $functionExchangeDynamicGroup
                $functionObject = get-ExchangeGroup -objectID $objectID -queryType $functionExchangeDynamicGroup
                $isExchangeGroupType=$TRUE 
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
                elseif ($functionObject.recipientTypeDetails -ne $functionExchangeGroupMailbox)
                {
                    out-logfile -string "Group is not a unified group or dynamic group - get standard membership."

                    if ($expandGroupMembership -eq $TRUE)
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
                        out-logfile -string "Full group membership expansion is disabled."

                        try {
                            $children = Get-o365distributionGroupMember -Identity $functionObject.ExchangeObjectID -resultSize unlimited -errorAction STOP | where {($_.recipientTypeDetails -eq $functionExchangeMailUniversalSecurityGroup) -or ($_.recipientTypeDetails -eq $functionExchangeMailUniversalDistributionGroup) -or ($_.recipientTypeDetails -eq $functionExchangeGroupMailbox) -or ($_.recipientTypeDetails -eq $functionExchangeDynamicGroup)}
                        }
                        catch {
                            out-logfile $_
                            out-logfile -string "Unable to obtain distribution group membership." -isError:$TRUE
                        }
                    }
                }
                else 
                {
                    out-logfile -string "Group is a unified group - perform link member query."
                    
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
            }
            else {
                $children=@()
            }

            foreach ($child in $children)
            {
                out-logfile -string "Processing child..."
                out-logfile -string $child.ExchangeObjectID
                $childGroupIDs = New-Object System.Collections.Generic.HashSet[string] $processedGroupIds
                $global:childCounter++
                out-logfile -string $global:childCounter.tostring()
                $childNode = Get-GroupWithChildren -objectID $child.ExchangeObjectID -processedGroupIds $childGroupIDs -objectType $child.recipientType -queryMethodExchangeOnline:$TRUE -expandGroupMembership $expandGroupMembership -expandDynamicGroupMembership $expandDynamicGroupMembership
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
            
            $functionObject.DisplayName = $functionObject.DisplayName + " (Circular Membership)"
        }

        if ($functionObject.displayName -eq "")
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
            out-logfile -string "Unablet obtain the ad object by ID." -isError:$TRUE
        }

        if (($functionObject.objectClass -ne $functionLDAPDynamicGroup) -and ($functionObject.objectClass -ne $functionLDAPGroup) -and ($firstLDAPQuery -eq $TRUE))
        {
            out-logfile -string $functionObject.objectClass
            out-logfile -string "Object specified is not a group or dynamic group." -isError:$TRUE
        }

        $childNodes = @()

        out-logfile -string $functionObject

        out-logfile -string "Beginning object processing..."

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
                    out-logfile -string "Dynamic group membership expansion disabled."
                    $children = @()
                }
            }
            elseif ($functionObject.objectClass -eq $functionLDAPGroup )
            {
                out-logfile -string "Object class id group - members determiend by member attribute on group."

                if ($expandGroupMembership -eq $TRUE)
                {
                    out-logfile -string "Expand full group membership eanbled."

                    $children = $functionObject.member
                }
                else
                {
                    out-logfile -string "Expand full group membership disabled."

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
            }
            else {
                out-logfile -string "Object is not a dynamic group or group."
                $children=@()
            }

            foreach ($child in $children)
            {
                write-host "ChildID"
                write-host $child
                $childGroupIDs = New-Object System.Collections.Generic.HashSet[string] $processedGroupIds
                $childNode = Get-GroupWithChildren -objectID $child -processedGroupIds $childGroupIDs -objectType "None" -globalCatalogServer $globalCatalogServer -activeDirectoryCredential $activeDirectoryCredential -queryMethodLDAP:$true -expandGroupMembership $expandGroupMembership -expandDynamicGroupMembership $expandDynamicGroupMembership -firstLDAPQuery $false
                $childNodes += $childNode
            }
        }
        else 
        {
            out-logfile -string "Group has already been processed."

            if ($functionObject.displayName -eq "")
            {
                $functionObject.displayName = $functionObject.name
            }

            $functionObject.DisplayName = $functionObject.DisplayName + " (Circular Membership)"
        }

        if ($functionObject.displayName -eq "")
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