#############################################################################################
# DISCLAIMER:																				#
#																							#
# THE SAMPLE SCRIPTS ARE NOT SUPPORTED UNDER ANY MICROSOFT STANDARD SUPPORT					#
# PROGRAM OR SERVICE. THE SAMPLE SCRIPTS ARE PROVIDED AS IS WITHOUT WARRANTY				#
# OF ANY KIND. MICROSOFT FURTHER DISCLAIMS ALL IMPLIED WARRANTIES INCLUDING, WITHOUT		#
# LIMITATION, ANY IMPLIED WARRANTIES OF MERCHANTABILITY OR OF FITNESS FOR A PARTICULAR		#
# PURPOSE. THE ENTIRE RISK ARISING OUT OF THE USE OR PERFORMANCE OF THE SAMPLE SCRIPTS		#
# AND DOCUMENTATION REMAINS WITH YOU. IN NO EVENT SHALL MICROSOFT, ITS AUTHORS, OR			#
# ANYONE ELSE INVOLVED IN THE CREATION, PRODUCTION, OR DELIVERY OF THE SCRIPTS BE LIABLE	#
# FOR ANY DAMAGES WHATSOEVER (INCLUDING, WITHOUT LIMITATION, DAMAGES FOR LOSS OF BUSINESS	#
# PROFITS, BUSINESS INTERRUPTION, LOSS OF BUSINESS INFORMATION, OR OTHER PECUNIARY LOSS)	#
# ARISING OUT OF THE USE OF OR INABILITY TO USE THE SAMPLE SCRIPTS OR DOCUMENTATION,		#
# EVEN IF MICROSOFT HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES						#
#############################################################################################


Function get-DLHierachyFromGraph
{
    <#
    .SYNOPSIS

    This function utilizes Microsoft Graph to generate a Tree view of DL membership.

    .DESCRIPTION

    This function utilizes Microsoft Graph to generate a Tree view of DL membership.

    .PARAMETER GROUPOBJECTID

    *REQUIRED*
    This is the group object ID from Entra ID.  

    .PARAMETER LOGFOLDERPATH

    *REQUIRED*
    This is the logging directory for storing the migration log and all backup XML files.
    If running multiple SINGLE instance migrations use different logging directories.

    .PARAMETER MSGRAPHENVIRONMENTNAME

    *OPTIONAL*
    This specifies the Entra ID instance to log into.
    Values include China, Global, USGov, and USGovDOD.

    .PARAMETER MSGRAPHTENANTID

    *MANDATORY*
    This specifies the tenant ID for the Entra ID instance.
    This is required as connect-MGGraph remembers the last connection and may result in wrong tenant collection.

    .PARAMETER MSGRAPHCERTIFICATETHUMBPRINT

    *OPTIONAL*
    The certificate thumbprint assocaited with the app registration allowing non-interactive credentials.

    .PARAMETER MSGRAPHAPPLICATIONID

    *OPTIONAL*
    This value specifies the application ID associated with the app registration allowing non-interactive credentials.

    .PARAMETER ALLOWTELEMETRYCOLLECTION

    *OPTIONAL*
    Specifies if telemetry collection is allowed.


    .OUTPUTS

    Logs all activities and backs up all original data to the log folder directory.
    Moves the distribution group from on premieses source of authority to office 365 source of authority.

    .NOTES

    The following blog posts maintain documentation regarding this module.

    https://timmcmic.wordpress.com.  

    Refer to the first pinned blog post that is the table of contents.

    
    .EXAMPLE

    get-DLHierarchyFromGraph -groupObjectID XXXXX-XXX-XXXX-XXXXXXX -logFolderPath c:\temp -msGraphTenantID ID (triggers interactive auth.)

    .EXAMPLE

    get-DLHierarchyFromGraph -groupObjectID XXXXX-XXX-XXXX-XXXXXXX -logFolderPath c:\temp -msGraphTenantID ID -msGraphCertificateThumbprint Thumprinter -msGraphApplicationID AppID

    #>

    [cmdletbinding()]

    Param
    (
        [Parameter(Mandatory = $true)]
        [string]$groupObjectID,
        #Define Microsoft Graph Parameters
        [Parameter(Mandatory = $false)]
        [ValidateSet("China","Global","USGov","USGovDod")]
        [string]$msGraphEnvironmentName="Global",
        [Parameter(Mandatory=$true)]
        [string]$msGraphTenantID="",
        [Parameter(Mandatory=$false)]
        [string]$msGraphCertificateThumbprint="",
        [Parameter(Mandatory=$false)]
        [string]$msGraphApplicationID="",
        #Define other mandatory parameters
        [Parameter(Mandatory = $true)]
        [string]$logFolderPath,
        [Parameter(Mandatory =$FALSE)]
        [boolean]$allowTelemetryCollection=$TRUE,
        #Define other non-mandatory parameters.
        [Parameter(Mandatory =$FALSE)]
        [boolean]$expandGroupMembership=$TRUE,
        [Parameter(Mandatory =$FALSE)]
        [boolean]$expandDynamicGroupMembership=$TRUE
    )

    #Define script based variables.

    #$logFileName = (Get-Date -Format FileDateTime) #Use random file date time for the log file name.
    $logFileName = $groupObjectID
    $msGraphScopesRequired = @("Directory.Read.All") #Define the grpah scopes required.

    #Define the output file.

    [string]$global:outputFile=""

    #Initialize telemetry collection.

    $appInsightAPIKey = "63d673af-33f4-401c-931e-f0b64a218d89"
    $traceModuleName = "DLHierarchy"

    #Create telemetry values.

    $telemetryDLHierachyVersion = $NULL
    $telemetryMSGraphAuthentication = $NULL
    $telemetryMSGraphUsers = $NULL
    $telemetryMSGraphGroups = $NULL
    $telemetryMSGraphDirectory = $NULL
    $telemetryOSVersion = (Get-CimInstance Win32_OperatingSystem).version
    $telemetryStartTime = get-universalDateTime
    $telemetryEndTime = $NULL
    [double]$telemetryElapsedSeconds = 0
    $telemetryEventName = "get-DLHierarchyFromGraph"
    [boolean]$telemetryError=$FALSE

    #Specify stub object types.

    $msGraphGroupType = "#microsoft.graph.group"
    $msGraphType = "MSGraph"

    [int]$defaultIndent = 0

    $global:msGraphObjects = @()
    $global:msGraphUserCount = @()
    $global:msGraphGroupCount = @()
    $global:msGraphContactCount = @()
    $totalObjectsProcessed = 0

    #Define windows title.

    $windowTitle = ("Start-DistributionListMigration "+$groupSMTPAddress)
    $host.ui.RawUI.WindowTitle = $windowTitle

    #Define variables utilized in the core function that are not defined by parameters.

    $coreVariables = @{ 
        msGraphAuthenticationPowershellModuleName = @{ "Value" = "Microsoft.Graph.Authentication" ; "Description" = "Static ms graph powershell name authentication" }
        msGraphUsersPowershellModuleName = @{ "Value" = "Microsoft.Graph.Users" ; "Description" = "Static ms graph powershell name users" }
        msGraphGroupsPowershellModuleName = @{ "Value" = "Microsoft.Graph.Groups" ; "Description" = "Static ms graph powershell name groups" }
        msGraphIdentityDirectoryManagement = @{ "Value" = "Microsoft.Graph.Identity.DirectoryManagement" ; "Description" = "Static ms graph powershell name groups" }
        DLHierarchy = @{ "Value" = "DLHierarchy" ; "Description" = "Static dlConversionv2 powershell module name" }
    }

    $processedGroupIds = New-Object System.Collections.Generic.HashSet[string]

    #Create the log file.

    new-logfile -logFileName $logFileName -logFolderPath $logFolderPath

    out-logfile -string "***********************************************************"
    out-logfile -string "Starting get-DLHierarchyFromGraph"
    out-logfile -string "***********************************************************"

    if ($allowTelemetryCollection -eq $TRUE)
    {
        start-telemetryConfiguration -allowTelemetryCollection $allowTelemetryCollection -appInsightAPIKey $appInsightAPIKey -traceModuleName $traceModuleName
    }

    out-logfile -string "Testing for supported version of Powershell engine."

    test-powershellVersion

    out-logfile -string "********************************************************************************"
    out-logfile -string "NOCTICE"
    out-logfile -string "Telemetry collection is now enabled by default."
    out-logfile -string "For information regarding telemetry collection see https://timmcmic.wordpress.com/2022/11/14/4288/"
    out-logfile -string "Administrators may opt out of telemetry collection by using -allowTelemetryCollection value FALSE"
    out-logfile -string "Telemetry collection is appreciated as it allows further development and script enhacement."
    out-logfile -string "********************************************************************************"

    #Output all parameters bound or unbound and their associated values.

    Out-LogFile -string "********************************************************************************"
    Out-LogFile -string "PARAMETERS"
    Out-LogFile -string "********************************************************************************"

    write-functionParameters -keyArray $MyInvocation.MyCommand.Parameters.Keys -parameterArray $PSBoundParameters -variableArray (Get-Variable -Scope Local -ErrorAction Ignore)

    out-logfile -string "Ensure that all strings specified have no leading or trailing spaces."

    #Perform cleanup of any strings so that no spaces existin trailing or leading.

    $groupObjectID = remove-stringSpace -stringToFix $groupObjectID
    $logFolderPath = remove-stringSpace -stringToFix $logFolderPath     
    $msGraphTenantID = remove-stringSpace -stringToFix $msGraphTenantID
    $msGraphCertificateThumbprint = remove-stringSpace -stringToFix $msGraphCertificateThumbprint
    $msGraphApplicationID = remove-stringSpace -stringToFix $msGraphApplicationID

    out-logfile -string "Testing to ensure group ID passed is a GUID format."

    if (test-isGUID -stringGUID $groupObjectID)
    {
        out-logfile -string "Group is vaild string format."
    }
    else 
    {
        Out-logfile -string "Identifier should be an acceptable GUID format.  This incldues objectGUID, externalDirectoryObjectID, ExchangeObjectID"
    }


    if ($msGraphCertificateThumbprint -eq "")
    {
        out-logfile -string "Validation all components available for MSGraph Cert Auth"

        start-parameterValidation -msGraphCertificateThumbPrint $msGraphCertificateThumbprint -msGraphTenantID $msGraphTenantID -msGraphApplicationID $msGraphApplicationID
    }
    else
    {
        out-logfile -string "MS graph cert auth is not being utilized - assume interactive auth."
    }

    out-logfile -string "Calling Test-PowershellModule to validate the DL Conversion Module version installed."

    $telemetryDLHierachyVersion = Test-PowershellModule -powershellModuleName $corevariables.DLHierarchy.value -powershellVersionTest:$TRUE

    out-logfile -string "Calling Test-PowershellModule to validate the Microsoft Graph Authentication versions installed."

    $telemetryMSGraphAuthentication = test-powershellModule -powershellmodulename $corevariables.msgraphauthenticationpowershellmodulename.value -powershellVersionTest:$TRUE

    out-logfile -string "Calling Test-PowershellModule to validate the Microsoft Graph Users versions installed."

    $telemetryMSGraphUsers = test-powershellModule -powershellmodulename $corevariables.msgraphuserspowershellmodulename.value -powershellVersionTest:$TRUE

    out-logfile -string "Calling Test-PowershellModule to validate the Microsoft Graph Users versions installed."

    $telemetryMSGraphGroups = test-powershellModule -powershellmodulename $corevariables.msgraphgroupspowershellmodulename.value -powershellVersionTest:$TRUE

    out-logfile -string "Calling Test-PowershellModule to validate the Microsoft Graph Director versions installed."

    $telemetryMSGraphDirectory = test-powershellModule -powershellmodulename $corevariables.msGraphIdentityDirectoryManagement.value -powershellVersionTest:$TRUE

    Out-LogFile -string "Calling nea-msGraphPowershellSession to create new connection to msGraph active directory."

    if ($msGraphCertificateThumbprint -ne "")
    {
       #User specified thumbprint authentication.
 
         try {
             new-msGraphPowershellSession -msGraphCertificateThumbprint $msGraphCertificateThumbprint -msGraphApplicationID $msGraphApplicationID -msGraphTenantID $msGraphTenantID -msGraphEnvironmentName $msGraphEnvironmentName -msGraphScopesRequired $msGraphScopesRequired
         }
         catch {
             out-logfile -string "Unable to create the msgraph connection using certificate."
             out-logfile -string $_ -isError:$TRUE
         }
    }
    elseif ($msGraphTenantID -ne "")
    {
         try
         {
             new-msGraphPowershellSession -msGraphTenantID $msGraphTenantID -msGraphEnvironmentName $msGraphEnvironmentName -msGraphScopesRequired $msGraphScopesRequired
         }
         catch
         {
             out-logfile -=string "Unable to create the msgraph connection using tenant ID and credentials."
         }
    }

    out-logfile -string "Start building tree from group..."

    $tree = Get-GroupWithChildren -objectID $groupObjectID -processedGroupIds $processedGroupIds -objectType $msGraphGroupType -queryMethodGraph:$TRUE -expandGroupMembership $expandGroupMembership -expandDynamicGroupMembership $expandDynamicGroupMembership

    out-logfile -string "Set header in output file to group name."

    $global:outputFile += "Group Hierachy for Group ID: "+$groupObjectID+"`n"

    out-logfile -string "Print hierarchy to log file."

    out-logfile -string $global:outputFile

    $sorted = New-Object System.Collections.Generic.List[pscustomobject]
    $tree.Children | % { $sorted.Add($_) }
    
    $sorted = [System.Linq.Enumerable]::OrderBy($sorted, [Func[pscustomobject,string]]{ param($x) $x.Object.AdditionalProperties.'@odata.type' })
    $sorted = [System.Linq.Enumerable]::ThenBy($sorted, [Func[pscustomobject,string]]{ param($x) $x.Object.AdditionalProperties.DisplayName })

    print-tree -node $sorted -indent $defaultIndent -outputType $msGraphType

    out-logfile -string "Export hierarchy to file."

    out-HierarchyFile -outputFileName  ("Hierarchy-"+$logFileName) -logFolderPath $global:logFolderPath

    $global:msGraphGroupCount = $global:msGraphGroupCount | Sort-Object -Unique
    $global:msGraphContactCount = $global:msGraphContactCount | Sort-Object -Unique
    $global:msGraphUserCount = $global:msGraphUserCount | Sort-Object -Unique

    $totalObjectsProcessed = $global:msGraphGroupCount.count + $global:msGraphContactCount.count + $global:msGraphUserCount.count

    out-logfile -string "Generate HTML File..."

    start-HTMLOutput -node $tree -outputType $msGraphType -groupObjectID $groupObjectID

    out-logfile -string ("Graph group count: "+$global:msGraphGroupCount.count)
    out-logfile -string ("Graph contact count: "+$global:msGraphContactCount.count)
    out-logfile -string ("Graph user count: "+$global:msGraphUserCount.count)
    out-logfile -string ("Total Objects Processed: "+$totalObjectsProcessed)

    $telemetryEndTime = get-universalDateTime
    $telemetryElapsedSeconds = get-elapsedTime -startTime $telemetryStartTime -endTime $telemetryEndTime

    $telemetryEventProperties = @{
        DLConversionV2Command = $telemetryEventName
        DLHierarchyVersion = $telemetryDLHierachyVersion
        MSGraphAuthentication = $telemetryMSGraphAuthentication
        MSGraphUsers = $telemetryMSGraphUsers
        MSGraphGroups = $telemetryMSGraphGroups
        MSGraphDirectory = $telemetryMSGraphDirectory
        OSVersion = $telemetryOSVersion
        MigrationStartTimeUTC = $telemetryStartTime
        MigrationEndTimeUTC = $telemetryEndTime
        MigrationErrors = $telemetryError
        GroupsProcessed = $global:msGraphGroupCount.Count
        ContactsProcessed = $global:msGraphContactCount.Count
        UsersProcessed = $global:msGraphUserCount.Count
        TotalObjectsProcessed = $totalObjectsProcessed
    }

    $telemetryEventMetrics = @{
        MigrationElapsedSeconds = $telemetryElapsedSeconds
    }

    if ($allowTelemetryCollection -eq $TRUE)
    {
        out-logfile -string "Telemetry1"
        out-logfile -string $traceModuleName
        out-logfile -string "Telemetry2"
        out-logfile -string $telemetryEventName
        out-logfile -string "Telemetry3"
        out-logfile -string $telemetryEventMetrics
        out-logfile -string "Telemetry4"
        out-logfile -string $telemetryEventProperties
        send-TelemetryEvent -traceModuleName $traceModuleName -eventName $telemetryEventName -eventMetrics $telemetryEventMetrics -eventProperties $telemetryEventProperties
    }
}
