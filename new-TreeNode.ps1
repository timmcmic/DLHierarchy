<#
    .SYNOPSIS

    This function creates the tree node and returns it.

    .DESCRIPTION

    This function creates the tree node and returns it.

    .PARAMETER OBJECT

    This is the entire object dicovered during the search process.

    .PARAMETER CHILDREN

    This is any children that are contained within the object if it is a group.

    #>
Function New-TreeNode() 
{
    Param
    (
        [Parameter(Mandatory = $true)]
        $object,
        [Parameter(Mandatory = $true)]
        $children
    )

    $node = New-Object PSObject -Property @{
        Group = $object
        Children = $children
    }
    
    return $node
}