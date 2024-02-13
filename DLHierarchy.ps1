Function New-TreeNode($group, $children) {
    $node = New-Object PSObject -Property @{
        Group = $group
        Children = $children
    }
    
    return $node
}

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

Function Print-Tree($node, $indent)
{
    $string = $node.group.displayName +" ("+$node.group.id+")"
    Write-Host ("-" * $indent) + $string
    foreach ($child in $node.Children)
    {
        Print-Tree $child ($indent + 2)
    }
}

# Main script start

#$groupSMTPAddress = "e98a2ff3-4a95-449d-a183-d9f2159d5432"
#$groupSMTPAddress = "0b420cb8-db98-44cf-9562-1dc25e5314e8"
$groupSMTPAddress = "2e891f57-a81d-4c8a-8eb4-b68febe9dbc3"

$processedGroupIds = New-Object System.Collections.Generic.HashSet[string]

$tree = Get-GroupWithChildren -groupId $groupSMTPAddress -processedGroupIds $processedGroupIds -objectType "#microsoft.graph.group"

print-tree $tree,0