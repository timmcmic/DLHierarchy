Function Print-Tree($node, $indent)
{
    $string = $node.group.displayName +" ("+$node.group.id+")"
    Write-Host ("-" * $indent) + $string
    foreach ($child in $node.Children)
    {
        Print-Tree $child ($indent + 2)
    }
}