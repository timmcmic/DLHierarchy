<#
    .SYNOPSIS

    This function outputs the file that contians the hierarchy.

    .DESCRIPTION

    This function outputs the file that contians the hierarchy.

    .PARAMETER outputFileName

    The output file name.

    .PARAMETER logFolderPath
    #>

    function out-HierarchyFile()
    {
        Param
        (
            [Parameter(Mandatory = $true)]
            $outputFileName,
            [Parameter(Mandatory = $true)]
            $logFolderPath
        )

        $functionPath = $logFolderPath +"\"+$outputFileName+".txt"

        out-logfile -string $functionPath

        out-logfile -string "***********************************************************"
        out-logfile -string "Entering Out-HierarchyFile"
        out-logfile -string "***********************************************************"

        $global:outputFile | Out-File -FilePath $functionPath

        out-logfile -string "***********************************************************"
        out-logfile -string "Exiting Out-HierarchyFile"
        out-logfile -string "***********************************************************"
    }