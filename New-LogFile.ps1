Function new-LogFile
{
    <#
    .SYNOPSIS

    This function creates a new-logFile for logging operations.

    .DESCRIPTION

    This function creates a new-logFile for logging operations.

    .PARAMETER LOGFILENAME

    *REQUIRED*
    Name of the log file. 

    .PARAMETER LOGFOLDERPATH

    *REQUIRED*
    This is the logging directory for storing the migration log and all backup XML files.
    If running multiple SINGLE instance migrations use different logging directories.

    .OUTPUTS

    Logs all activities and backs up all original data to the log folder directory.
    Moves the distribution group from on premieses source of authority to office 365 source of authority.

    .NOTES

    The following blog posts maintain documentation regarding this module.

    https://timmcmic.wordpress.com.  

    Refer to the first pinned blog post that is the table of contents.

    
    .EXAMPLE

n   new-logfile -logFileName NAME -logFolderPath PATH

    #>

    [cmdletbinding()]

    Param
    (
        [Parameter(Mandatory = $true)]
        [string]$logFileName,
        [Parameter(Mandatory = $true)]
        [string]$logFolderPath
    )

    [string]$logFileSuffix=".log"
    [string]$fileName=$logFileName+$logFileSuffix

    # Get our log file path

    $logFolderPath = $logFolderPath+"\"+$logFileName+"\"
    
    #Since $logFile is defined in the calling function - this sets the log file name for the entire script
    
    $global:LogFile = Join-path $logFolderPath $fileName

    #Test the path to see if this exists if not create.

    [boolean]$pathExists = Test-Path -Path $logFolderPath

    if ($pathExists -eq $false)
    {
        try 
        {
            #Path did not exist - Creating

            New-Item -Path $logFolderPath -Type Directory
        }
        catch 
        {
            throw $_
        } 
    }
}