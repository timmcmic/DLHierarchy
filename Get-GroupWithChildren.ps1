
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
        [string]$groupID,
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

    out-logfile -string ("Parameter Set Name: "+$functionParamterSetName)
    out-logfile -string ("Processing group ID: "+$groupID)
    out-logfile -string ("Processing object type: "+$objectType)
    out-logfile -string ("QueryMethodGraph: "+$queryMethodGraph)
    out-logfile -string ("QueryMethodExchangeOnline: "+$queryMethodExchangeOnline)
    out-logfile -string ("QueryMethodLDAP: "+$queryMethodLDAP)

    out-logfile -string "Determine the path utilized based on paramter set name."

    if ($functionParamterSetName -eq $functionGraphName)
    {
        out-logfile -string "Entering graph processing..."

        switch ($objectType)
        {
            $functionGraphGroup
            {
                try {
                    $functionObject = get-MGGroup -GroupId $groupId -ErrorAction Stop
                }
                catch {
                    out-logfile -string $_
                    out-logfile -string "Error obtaining group." -isError:$TRUE
                }    
            }
            $functiongraphUser
            {
                try {
                    $functionObject = get-MGUser -userID $groupID -ErrorAction Stop
                }
                catch {
                    out-logfile -string $_
                    out-logfile -string "Error obtaining user." -isError:$TRUE
                }
            }
            $functionGraphContact
            {
                try {
                    $functionObject = get-MGContact -OrgContactId $groupID -errorAction Stop
                }
                catch {
                    out-logfile -string $_
                    out-logfile -string "Error obtaining contact." -isError:$TRUE
                }
            }
            Default
            {
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

                $children = Get-MgGroupMember -GroupId $functionObject.Id 
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
                $childNode = Get-GroupWithChildren -groupId $child.id -processedGroupIds $childGroupIDs -objectType $child.additionalProperties["@odata.type"] -queryMethodGraph:$true
                $childNodes += $childNode
            }
        }
        else 
        {
            $functionObject.DisplayName = $functionObject.DisplayName + " (Circular Membership)"
        }

        $node = New-TreeNode -group $functionObject -children $childNodes
    }

    out-logfile -string "***********************************************************"
    out-logfile -string "Entering Get-GroupWithChildren"
    out-logfile -string "***********************************************************"

    return $node
}