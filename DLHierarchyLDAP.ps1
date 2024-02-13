Function New-TreeNode($group, $children) {
    $node = New-Object PSObject -Property @{
        Group = $group
        Children = $children
    }
    
    return $node
}

Function Get-GroupWithChildren($groupId,$processedGroupIds)
{
    Write-Host $groupId

    try{
        $group = get-adObject -identity $groupID -properties * -ErrorAction STOP
    }
    catch {
        write-host "Unable to obtain AD object by identity provided."
        write-error $_
        exit
    }

    Write-Host $group.distinguishedName
    write-host $group.objectClass

    $childNodes = @()

    if (!$processedGroupIds.Contains($group.distinguishedName))
    {
        $NULL = $processedGroupIds.add($group.distinguishedName)

        #$children = Get-MgGroupMember -GroupId $group.Id | where {$_.AdditionalProperties["@odata.type"] -eq "#microsoft.graph.group"}

        if ($group.objectClass -eq "Group")
        {
            $children = Get-adGroupMember -Identity $group.distinguishedName 
        }
        else {
            $children=@()
        }

        foreach ($child in $children)
        {
            write-host "ChildID"
            write-host $child.ExchangeObjectID 
            $childGroupIDs = New-Object System.Collections.Generic.HashSet[string] $processedGroupIds
            $childNode = Get-GroupWithChildren -groupId $child.distinguishedName -processedGroupIds $childGroupIDs
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
    $string = $node.group.displayName +" ("+$node.group.objectGUID+")"
    Write-Host ("-" * $indent) + $string
    foreach ($child in $node.Children)
    {
        Print-Tree $child ($indent + 2)
    }
}

# Main script start

$groupSMTPAddress = "CN=aTestGroup169,OU=MigrationTest,OU=DLConversion,DC=home,DC=e-mcmichael,DC=com"
#$groupSMTPAddress = "0b420cb8-db98-44cf-9562-1dc25e5314e8"

$processedGroupIds = New-Object System.Collections.Generic.HashSet[string]

$tree = Get-GroupWithChildren -groupId $groupSMTPAddress -processedGroupIds $processedGroupIds

print-tree $tree,0