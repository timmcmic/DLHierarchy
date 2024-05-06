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

    out-logfile -string "***********************************************************"
    out-logfile -string "Entering new-TreeNode"
    out-logfile -string "***********************************************************"

    $node = New-Object PSObject -Property @{
        Object = $object
        Children = $children
    }

    out-logfile -string "***********************************************************"
    out-logfile -string "Exiting new-TreeNode"
    out-logfile -string "***********************************************************"
    
    return $node
}