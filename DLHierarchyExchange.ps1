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
    write-host $objectType

    switch ($objectType)
    {
        "Group"
        {
            try {
                $group = get-group -identity $groupId -ErrorAction Stop
            }
            catch {
                write-host $_
                write-error "Object type is group - unable to obtain object."
                exit
            }    
        }
        "MailUniversalSecurityGroup" 
        {
            try {
                $group = get-group -identity $groupId -ErrorAction Stop
            }
            catch {
                write-host $_
                write-error "Object type is group - unable to obtain object."
                exit
            }    
        }
        "MailUniversalDistributionGroup"
        {
            try {
                $group = get-group -identity $groupId -ErrorAction Stop
            }
            catch {
                write-host $_
                write-error "Object type is group - unable to obtain object."
                exit
            }    
        }   
        "UserMailbox"
        {
            try {
                $group = get-user -Identity $groupID -ErrorAction Stop
            }
            catch {
                write-host $_
                write-error "Object type is User - unable to obtain object."
                exit
            }
        }
        "Mailuser"
        {
            try {
                $group = get-user -Identity $groupID -ErrorAction Stop
            }
            catch {
                write-host $_
                write-error "Object type is User - unable to obtain object."
                exit
            }
        }
        "GuestMailUser"
        {
            try {
                $group = get-user -Identity $groupID -ErrorAction Stop
            }
            catch {
                write-host $_
                write-error "Object type is User - unable to obtain object."
                exit
            }
        }
        "MailContact"
        {
            try {
                $group = get-contact -Identity $groupID -errorAction Stop
            }
            catch {
                write-host $_
                write-error "Object type is contact - unable to obtain object."
                exit
            }
        }
        Default
        {
            write-error "Invalid object type discovered - contact support."
        }
    }

    Write-Host $group.ExchangeObjectID
    write-host $group.displayName
    write-host $objectType

    $childNodes = @()

    if (!$processedGroupIds.Contains($group.ExchangeObjectID))
    {
        $NULL = $processedGroupIds.add($group.ExchangeObjectID)

        #$children = Get-MgGroupMember -GroupId $group.Id | where {$_.AdditionalProperties["@odata.type"] -eq "#microsoft.graph.group"}

        if (($objectType -eq "MailUniversalSecurityGroup") -or ($objectType -eq "MailUniversalDistributionGroup") -or ($objectType -eq "Group"))
        {
            if ($group.recipientTypeDetails -ne "GroupMailbox")
            {
                Write-Host "Group is not a unified group."
                $children = Get-distributionGroupMember -Identity $group.ExchangeObjectID 
            }
            else 
            {
                write-host "Group is a unified group."
                $children = get-UnifiedGroupLinks -identity $group.ExchangeObjectID -linkType Member
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
            $childNode = Get-GroupWithChildren -groupId $child.ExchangeObjectID -processedGroupIds $childGroupIDs -objectType $child.recipientTypeDetails
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
    $string = $node.group.recipientTypeDetails+": "+$node.group.displayName +" (ExchangeObjectID: "+$node.group.ExchangeObjectID+")"
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

$tree = Get-GroupWithChildren -groupId $groupSMTPAddress -processedGroupIds $processedGroupIds -objectType "Group"

print-tree $tree,0