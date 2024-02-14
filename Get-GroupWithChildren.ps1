
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
        $activeDirectoryCredential
    )
    
    out-logfile -string "***********************************************************"
    out-logfile -string "Entering Get-GroupWithChildren"
    out-logfile -string "***********************************************************"

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
    $isExchangeGroupType = $false

    $functionLDAPGroup = "Group"
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
            $objectID
        )

        try {
            $returnObject = get-o365group -identity $objectID -ErrorAction Stop
        }
        catch {
            write-host $_
            write-error "Object type is group - unable to obtain object."
            exit
        } 
        
        return $returnObject
    }

    function get-ExchangeUser
    {
        Param
        (
            [Parameter(Mandatory = $true)]
            $objectID
        )

        try {
            $returnObject = get-o365user -identity $objectID -ErrorAction Stop
        }
        catch {
            write-host $_
            write-error "Object type is user - unable to obtain object."
            exit
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

                try {
                    $children = Get-MgGroupMember -GroupId $functionObject.Id 
                }
                catch {
                    out-logfile -string $_
                    out-logfile -string "Error obtaining group membership." -isError:$TRUE
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
                $childGroupIDs = New-Object System.Collections.Generic.HashSet[string] $processedGroupIds
                $childNode = Get-GroupWithChildren -objectID $child.id -processedGroupIds $childGroupIDs -objectType $child.additionalProperties["@odata.type"] -queryMethodGraph:$true
                $childNodes += $childNode
            }
        }
        else 
        {
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
            $functionExchangeGroup
            {
                out-logfile -string $functionExchangeGroup
                $functionObject = get-ExchangeGroup -objectID $objectID
                $isExchangeGroupType=$TRUE 
            }
            $functionExchangeMailUniversalSecurityGroup
            {
                out-logfile -string $functionExchangeMailUniversalSecurityGroup
                $functionObject = get-ExchangeGroup -objectID $objectID
                $isExchangeGroupType=$TRUE  
            }
            $functionExchangeMailUniversalDistributionGroup
            {
                out-logfile -string $functionExchangeMailUniversalDistributionGroup
                $functionObject = get-ExchangeGroup -objectID $objectID
                $isExchangeGroupType=$TRUE  
            }   
            $functionExchangeUserMailbox
            {
                out-logfile -string $functionExchangeUserMailbox
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
                out-logfile -string $functionExchangeMailContact
                try {
                    $functionObject = get-o365DynamicDistributionGroup -Identity $objectID -errorAction Stop
                }
                catch {
                    write-host $_
                    write-error "Object type is contact - unable to obtain object."
                    exit
                }
                $isExchangeGroupType=$TRUE 
            }
            Default
            {
                out-logfile -string "Default"
                out-logfile -string "Invalid object type discovered - contact support." -isError:$TRUE
            }
        }

        out-logfile -string $functionObject

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

                    try {
                        $children = get-o365Recipient -RecipientPreviewFilter $functionObject.RecipientFilter -resultsize unlimited -errorAction STOP
                    }
                    catch {
                        out-logfile $_
                        out-logfile -string "Unable to obtain dynamic DL members by recipient filter preview." -isError:$TRUE
                    }
                }
                elseif ($functionObject.recipientTypeDetails -ne $functionExchangeGroupMailbox)
                {
                    out-logfile -string "Group is not a unified group or dynamic group - get standard membership."
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
                    out-logfile -string "Group is a unified group - perform link member query."
                    
                    try {
                        $children = get-o365UnifiedGroupLinks -identity $functionObject.ExchangeObjectID -linkType Member -resultSize unlimited -errorAction STOP
                    }
                    catch {
                        out-logfile $_
                        out-logfile -string "Unable to obtain unified group membership." -isError:$TRUE
                    }
                }
            }
            else {
                $children=@()
            }

            foreach ($child in $children)
            {
                out-logfile -string "Processing child..."
                out-logfile -string $child.distinguishedName 
                $childGroupIDs = New-Object System.Collections.Generic.HashSet[string] $processedGroupIds
                $childNode = Get-GroupWithChildren -objectID $child.ExchangeObjectID -processedGroupIds $childGroupIDs -objectType $child.recipientType -queryMethodExchangeOnline:$TRUE
                $childNodes += $childNode
            }
        }
        else 
        {
            $functionObject.DisplayName = $functionObject.DisplayName + " (Circular Membership)"
        }

        if ($group.displaynnme -eq "")
        {
            $group.displayName = $group.name
        }
    
        $node = New-TreeNode -object $functionObject -children $childNodes
    }

    #===============================================================================
    #LDAP Code
    #===============================================================================

    elseif ($functionParamterSetName -eq $functionLDAPName)
    {
        out-logfile -string "Entering LDAP processing..."

        if ($objectType -eq $functionLDAPGroup)
        {
            out-logfile -string "This call specifies an object type as group."
            out-logfile -string "This is only utilized on the first call to ensure the object specified is a group."

            try {
                $functionObject = get-ADGroup -identity $objectID -properties * -server $globalCatalogServer -Credential $activeDirectoryCredential -errorAction STOP
            }
            catch {
                out-logfile -string $_
                out-logfile -string "Unable to obtain the group by object ID provided.  This is the initial group properties call."
            }
        }
        else {
            try{
                $functionObject = get-adObject -identity $objectID -properties * -server $globalCatalogServer -Credential $activeDirectoryCredential -ErrorAction STOP
            }
            catch {
                out-logfile -string $_
                out-logfile -string "Unablet obtain the ad object by ID." -isError:$TRUE
            }
        }

        $childNodes = @()

        if (!$processedGroupIds.Contains($functionObject.distinguishedName))
        {
            $NULL = $processedGroupIds.add($functionObject.distinguishedName)

            if ($functionObject.objectClass -eq $functionLDAPDynamicGroup)
            {
                out-logfile -string "Object class is dynamic group - members determined via query."

                try {
                    $children = Get-ADObject -LDAPFilter $functionObject.msExchDynamicDLFilter -SearchBase $functionObject.msExchDynamicDLBaseDN -Properties * -server $globalCatalogServer -Credential $activeDirectoryCredential -ErrorAction STOP
                }
                catch {
                    out-logfile $_
                    out-logfile -string "Unable to obtain dynamic group membership via LDAP call."
                }
            }
            elseif ($functionObject.objectClass -eq $functionLDAPGroup )
            {
                out-logfile -string "Object class id group - members determiend by member attribute on group."
                $children = $functionObject.member
            }
            else {
                out-logfile -string "Object is not a dynamic group or group."
                $children=@()
            }

            foreach ($child in $children)
            {
                write-host "ChildID"
                write-host $child.distinguishedName 
                $childGroupIDs = New-Object System.Collections.Generic.HashSet[string] $processedGroupIds
                $childNode = Get-GroupWithChildren -objectID $child -processedGroupIds $childGroupIDs -objectType "None" -globalCatalogServer $globalCatalogServer -activeDirectoryCredential $activeDirectoryCredential -queryMethodLDAP:$true
                $childNodes += $childNode
            }
        }
        else 
        {
            $group.DisplayName = $group.DisplayName + " (Circular Membership)"
        }

        if ($group.displaynnme -eq "")
        {
            $group.displayName = $group.name
        }

        $node = New-TreeNode -group $group -children $childNodes
    }


    out-logfile -string "***********************************************************"
    out-logfile -string "Exiting Get-GroupWithChildren"
    out-logfile -string "***********************************************************"

    return $node
}