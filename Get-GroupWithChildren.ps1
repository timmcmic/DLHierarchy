
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
Function Get-GroupWithChildren($groupId,$processedGroupIds,$objectType)
{
    Write-Host $groupId

    switch ($objectType)
    {
        "#microsoft.graph.group"
        {
            try {
                $group = get-MGGroup -GroupId $groupId -ErrorAction Stop
            }
            catch {
                write-host $_
                write-error "Object type is group - unable to obtain object."
            }    
        }
        "#microsoft.graph.user"
        {
            try {
                $group = get-MGUser -userID $groupID -ErrorAction Stop
            }
            catch {
                write-host $_
                write-error "Object type is group - unable to obtain object."
            }
        }
        "#microsoft.graph.orgContact"
        {
            try {
                $group = get-MGContact -OrgContactId $groupID -errorAction Stop
            }
            catch {
                write-host $_
                write-error "Object type is contact - unable to obtain object."
            }
        }
        Default
        {
            write-error "Invalid object type discovered - contact support."
        }
    }

    <#
    try {
        $group = get-MGGroup -GroupId $groupId -ErrorAction Stop
    }
    catch {
        write-host "Object is not a group."
        try {
            $group = get-MGUser -userID $groupID -ErrorAction Stop
        }
        catch {
            write-host "Object is not a user."

            try {
                $group = get-MGContact -OrgContactId $groupID -errorAction Stop
            }
            catch {
                write-host "Object is not a contact."
            }
        }
    }

    #>
    
    Write-Host $group.Id
    write-host $group.displayName
    write-host $objectType

    $childNodes = @()

    if (!$processedGroupIds.Contains($group.Id))
    {
        $NULL = $processedGroupIds.add($group.id)

        #$children = Get-MgGroupMember -GroupId $group.Id | where {$_.AdditionalProperties["@odata.type"] -eq "#microsoft.graph.group"}

        if ($objectType -eq "#microsoft.graph.group")
        {
            $children = Get-MgGroupMember -GroupId $group.Id 
        }
        else {
            $children=@()
        }

        foreach ($child in $children)
        {
            write-host "ChildID"
            write-host $child.id 
            $childGroupIDs = New-Object System.Collections.Generic.HashSet[string] $processedGroupIds
            $childNode = Get-GroupWithChildren -groupId $child.id -processedGroupIds $childGroupIDs -objectType $child.additionalProperties["@odata.type"]
            $childNodes += $childNode
        }
    }
    else 
    {
        $group.DisplayName = $group.DisplayName + " (Circular Membership)"
    }

    $node = New-TreeNode -group $group -children $childNodes

    return $node
}