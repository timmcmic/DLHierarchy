Function Print-Tree()
{
    Param
    (
        [Parameter(Mandatory = $true)]
        $node,
        [Parameter(Mandatory = $true)]
        $indent,
        [Parameter(Mandatory = $true)]
        $outputType
    )

    $string = $node.group.displayName +" ("+$node.group.id+")"
    out-logfile -string  (("-" * $indent) + $string)
    foreach ($child in $node.Children)
    {
        Print-Tree $child ($indent + 2)
    }
}