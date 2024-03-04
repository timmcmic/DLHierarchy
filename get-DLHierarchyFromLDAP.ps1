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


Function get-DLHierachyFromLDAP
{
    <#
    .SYNOPSIS

    This function utilizes LDAP to create a tree view of group membership.

    .DESCRIPTION

    This function utilizes LDAP to create a tree view of group membership.

    .PARAMETER GROUPOBJECTID

    *REQUIRED*
    This is the group object ID from Entra ID.  

    .PARAMETER LOGFOLDERPATH

    *REQUIRED*
    This is the logging directory for storing the migration log and all backup XML files.
    If running multiple SINGLE instance migrations use different logging directories.

    .PARAMETER GLOBALCATALOGSERVER

    *REQUIERD*
    Specifies the global catalog to utilize for the query.

    .PARAMETER ACTIVEDIRECTORYCREDENTIALS

    *REQEUIRED*
    Specifies the active directory credentials to utilize for AD web service calls.

    .PARAMETER ALLOWTELEMETRYCOLLECTION

    *OPTIONAL*
    Specifies if telemetry collection is allowed.


    .OUTPUTS

    Generates a tree view hiearchy file.

    .NOTES

    The following blog posts maintain documentation regarding this module.

    https://timmcmic.wordpress.com.  

    Refer to the first pinned blog post that is the table of contents.

    
    .EXAMPLE

    get-DLHierarchyFromLDAP -globalCatalogServer GC -activeDirectoryCredentials $creds

    #>

    [cmdletbinding()]

    Param
    (
        [Parameter(Mandatory = $true)]
        [string]$groupObjectID,
        #Local Active Director Domain Controller Parameters
        [Parameter(Mandatory = $true)]
        [string]$globalCatalogServer,
        [Parameter(Mandatory = $true)]
        [pscredential]$activeDirectoryCredential,
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

    #Define the output file.

    [string]$global:outputFile=""

    #Initialize telemetry collection.

    $appInsightAPIKey = "63d673af-33f4-401c-931e-f0b64a218d89"
    $traceModuleName = "DLHierarchy"

    #Create telemetry values.

    $telemetryDLHierachyVersion = $NULL
    $telemetryActiveDirectoryVersion = $NULL
    $telemetryOSVersion = (Get-CimInstance Win32_OperatingSystem).version
    $telemetryStartTime = get-universalDateTime
    $telemetryEndTime = $NULL
    [double]$telemetryElapsedSeconds = 0
    $telemetryEventName = "get-DLHierarchyFromExchangeOnline"
    [boolean]$telemetryError=$FALSE

    #Specify stub object types.

    $LDAPGroupType = "Group"
    $LDAPType = "LDAP"

    [int]$defaultIndent = 0

    $global:childCounter = 0

    $global:ldapObjects =@()

    #Define windows title.

    $windowTitle = ("Get-DLHierarchyFromLDAP "+$groupObjectID)
    $host.ui.RawUI.WindowTitle = $windowTitle

    #Define variables utilized in the core function that are not defined by parameters.

    $coreVariables = @{ 
        globalCatalogPort = @{ "Value" = ":3268" ; "Description" = "Global catalog port definition" }
        globalCatalogWithPort = @{ "Value" = ($globalCatalogServer+($corevariables.globalCatalogPort.value)) ; "Description" = "Global catalog server with port" }
        activeDirectoryPowershellModuleName = @{ "Value" = "ActiveDirectory" ; "Description" = "Static active directory powershell module name" }
        DLHierarchy = @{ "Value" = "DLHierarchy" ; "Description" = "Static dlConversionv2 powershell module name" }
    }

    $processedGroupIds = New-Object System.Collections.Generic.HashSet[string]

    #Create the log file.

    new-logfile -logFileName $logFileName -logFolderPath $logFolderPath

    out-logfile -string "***********************************************************"
    out-logfile -string "Starting get-DLHierarchyFromLDAP"
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
    $globalCatalogServer=remove-stringSpace -stringToFix $globalCatalogServer 

    out-logfile -string "Testing to ensure group ID passed is a GUID format."

    if (test-isGUID -stringGUID $groupObjectID)
    {
        out-logfile -string "Group is vaild string format."
    }
    else 
    {
        Out-logfile -string "Identifier should be an acceptable GUID format.  This incldues objectGUID, externalDirectoryObjectID, ExchangeObjectID"
    }

    Out-LogFile -string "Calling Test-PowerShellModule to validate the Active Directory is installed."

    $telemetryActiveDirectoryVersion = Test-PowershellModule -powershellModuleName $corevariables.activeDirectoryPowershellModuleName.value

    out-logfile -string "Calling Test-PowershellModule to validate the DL Conversion Module version installed."

    $telemetryDLHierachyVersion = Test-PowershellModule -powershellModuleName $corevariables.DLHierarchy.value -powershellVersionTest:$TRUE

    out-logfile -string "Start building tree from group..."

    $tree = Get-GroupWithChildren -objectID $groupObjectID -processedGroupIds $processedGroupIds -objectType $LDAPGroupType -queryMethodLDAP:$TRUE -globalCatalogServer $coreVariables.globalCatalogWithPort.Value -activeDirectoryCredential $activeDirectoryCredential -expandGroupMembership $expandGroupMembership -expandDynamicGroupMembership $expandDynamicGroupMembership -firstLdapQuery $TRUE

    out-logfile -string "Set header in output file to group name."

    $global:outputFile += "Group Hierachy for Group ID: "+$groupObjectID+"`n"

    out-logfile -string "Print hierarchy to log file."

    print-tree -node $tree -indent $defaultIndent -outputType $LDAPType

    out-logfile -string "Export hierarchy to file."

    out-HierarchyFile -outputFileName  ("Hierarchy-"+$logFileName) -logFolderPath $global:logFolderPath

    out-logfile -string "Generate HTML File..."

    start-HTMLOutput -node $tree -outputType $LDAPType -groupObjectID $groupObjectID

    $telemetryEndTime = get-universalDateTime
    $telemetryElapsedSeconds = get-elapsedTime -startTime $telemetryStartTime -endTime $telemetryEndTime

    $telemetryEventProperties = @{
        DLConversionV2Command = $telemetryEventName
        DLHierarchyVersion = $telemetryDLHierachyVersion
        ActiveDirectoryVersion = $telemetryActiveDirectoryVersion
        OSVersion = $telemetryOSVersion
        MigrationStartTimeUTC = $telemetryStartTime
        MigrationEndTimeUTC = $telemetryEndTime
        MigrationErrors = $telemetryError
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
