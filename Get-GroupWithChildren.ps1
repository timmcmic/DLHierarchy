
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
        [string]$objectType,
        [Parameter(Mandatory = $true,ParameterSetName = 'MSGraph')]
        [boolean]$queryMethodGraph=$false,
        [Parameter(Mandatory = $true,ParameterSetName = 'ExchangeOnline')]
        [boolean]$queryMethodExchangeOnline=$false,
        [Parameter(Mandatory = $true,ParameterSetName = 'LDAP')]
        [boolean]$queryMethodLDAP=$false
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

    out-logfile -string ("Parameter Set Name: "+$functionParamterSetName)
    out-logfile -string ("Processing group ID: "+$objectID)
    out-logfile -string ("Processing object type: "+$objectType)
    out-logfile -string ("QueryMethodGraph: "+$queryMethodGraph)
    out-logfile -string ("QueryMethodExchangeOnline: "+$queryMethodExchangeOnline)
    out-logfile -string ("QueryMethodLDAP: "+$queryMethodLDAP)

    out-logfile -string "Determine the path utilized based on paramter set name."

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
    elseif ($functionParamterSetName -eq $functionExchangeOnlineName)
    {
        out-logfile -string "Entering exchange online processing..."

        switch ($objectType)
        {
            $functionExchangeGroup
            {
                out-logfile -string $functionExchangeGroup
                $functionObject = get-ExchangeGroup -objectID $objectID 
            }
            $functionExchangeMailUniversalSecurityGroup
            {
                out-logfile -string $functionExchangeMailUniversalSecurityGroup
                $functionObject = get-ExchangeGroup -objectID $objectID 
            }
            $functionExchangeMailUniversalDistributionGroup
            {
                out-logfile -string $functionExchangeMailUniversalDistributionGroup
                $functionObject = get-ExchangeGroup -objectID $objectID 
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

            if (($objectType -eq $functionExchangeMailUniversalSecurityGroup) -or ($objectType -eq $functionExchangeMailUniversalDistributionGroup) -or ($objectType -eq $functionExchangeGroup))
            {
                if ($functionObject.recipientTypeDetails -ne $functionExchangeGroupMailbox)
                {
                    Write-Host "Group is not a unified group."
                    $children = Get-o365distributionGroupMember -Identity $functionObject.ExchangeObjectID 
                }
                else 
                {
                    write-host "Group is a unified group."
                    $children = get-o365UnifiedGroupLinks -identity $functionObject.ExchangeObjectID -linkType Member
                }
            }
            else {
                $children=@()
            }

            foreach ($child in $children)
            {
                write-host "ChildID"
                write-host $child.ExchangeObjectID 
                $childGroupIDs = New-Object System.Collections.Generic.HashSet[string] $processedGroupIds
                $childNode = Get-GroupWithChildren -objectID $child.ExchangeObjectID -processedGroupIds $childGroupIDs -objectType $child.recipientTypeDetails -queryMethodExchangeOnline:$TRUE
                $childNodes += $childNode
            }
        }
        else 
        {
            $functionObject.DisplayName = $functionObject.DisplayName + " (Circular Membership)"
        }
    }

    out-logfile -string "***********************************************************"
    out-logfile -string "Exiting Get-GroupWithChildren"
    out-logfile -string "***********************************************************"

    return $node
}