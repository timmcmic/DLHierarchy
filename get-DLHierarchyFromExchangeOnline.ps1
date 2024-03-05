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


Function get-DLHierarchyFromExchangeOnline
{
    <#
    .SYNOPSIS

    This function utilizes Microsoft Exchange Online to generate a Tree view of DL membership.

    .DESCRIPTION

    This function utilizes Microsoft Exchange Online to generate a Tree view of DL membership.

    .PARAMETER GROUPOBJECTID

    *REQUIRED*
    This is the group object ID from Entra ID.  

    .PARAMETER LOGFOLDERPATH

    *REQUIRED*
    This is the logging directory for storing the migration log and all backup XML files.
    If running multiple SINGLE instance migrations use different logging directories.

    .PARAMETER EXCHANGEONLINEENVIRONMENTNAME

    *OPTIONAL*
    This specifies the Exchange Online instance to log into.
    Values include China, Global, USGov, and USGovDOD.

    .PARAMETER EXCHANGEONLINEORGANIZTIONNAME

    *OPTIONAL*
    This specifies the organization name (.onmicrosoft.com) for the Exchange ONline TEnant..

    .PARAMETER EXCHANGEONLINECERTIFICATETHUMBPRINT

    *OPTIONAL*
    The certificate thumbprint assocaited with the app registration allowing non-interactive credentials.

    .PARAMETER EXCHANGEONLINEAPPID

    *OPTIONAL*
    This value specifies the application ID associated with the app registration allowing non-interactive credentials.

    .PARAMETER EXCHANGEONLINECREDENTIAL

    *OPTIONAL*
    Allows passing of a user name and password combination instead of certificate authentication.

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

    get-DLHierarchyFromExchangeOnline -groupObjectID XXXXX-XXX-XXXX-XXXXXXX -logFolderPath c:\temp -exchangeCredential $cred

    .EXAMPLE

    get-DLHierarchyFromExchangeOnline -groupObjectID XXXXX-XXX-XXXX-XXXXXXX -logFolderPath c:\temp -exchangeOrganizationName sometihng.onmicrosoft.com -exchangeCertificateThumbPrint ThumbPrint -ExchangeOnlineAppID APPID

    #>

    [cmdletbinding()]

    Param
    (
        [Parameter(Mandatory = $true)]
        [string]$groupObjectID,
        #Exchange Online Parameters
        [Parameter(Mandatory = $false)]
        [pscredential]$exchangeOnlineCredential=$NULL,
        [Parameter(Mandatory = $false)]
        [string]$exchangeOnlineCertificateThumbPrint="",
        [Parameter(Mandatory = $false)]
        [string]$exchangeOnlineOrganizationName="",
        [Parameter(Mandatory = $false)]
        [ValidateSet("O365Default","O365GermanyCloud","O365China","O365USGovGCCHigh","O365USGovDoD")]
        [string]$exchangeOnlineEnvironmentName="O365Default",
        [Parameter(Mandatory = $false)]
        [string]$exchangeOnlineAppID="",
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
    $telemetryExchangeOnlineVersion = $NULL
    $telemetryOSVersion = (Get-CimInstance Win32_OperatingSystem).version
    $telemetryStartTime = get-universalDateTime
    $telemetryEndTime = $NULL
    [double]$telemetryElapsedSeconds = 0
    $telemetryEventName = "get-DLHierarchyFromExchangeOnline"
    [boolean]$telemetryError=$FALSE

    #Specify stub object types.

    $exchangeOnlineGroupType = "Group"
    $exchangeOnlineType = "ExchangeOnline"

    [int]$defaultIndent = 0

    $global:exchangeObjects =@()
    $global:groupCounter = @()
    $global:mailUniversalSecurityGroupCounter = @()
    $global:mailUniversalDistributionGroupCounter = @()
    $global:userMailboxCounter = @()
    $global:mailUserCounter = @()
    $global:guestMailUserCounter = @()
    $global:mailContactCounter = @()
    $global:groupMailboxCounter = @()
    $global:dynamicGroupCounter = @()
    $global:userCounter = @()
    $global:equipmentMailboxCounter = @()
    $global:sharedMailboxCounter = @()
    $global:roomMailboxCounter = @()
    $totalObjectsProcessed = 0


    #Preare items for HTML Export.

    $global:HTMLSections = @()

    #Define windows title.

    $windowTitle = ("Get-DLHierarchyFromExchangeOnline "+$groupObjectID)
    $host.ui.RawUI.WindowTitle = $windowTitle

    #Define variables utilized in the core function that are not defined by parameters.

    $coreVariables = @{ 
        exchangeOnlinePowershellModuleName = @{ "Value" = "ExchangeOnlineManagement" ; "Description" = "Static Exchange Online powershell module name" }
        DLHierarchy = @{ "Value" = "DLHierarchy" ; "Description" = "Static dlConversionv2 powershell module name" }
    }

    $processedGroupIds = New-Object System.Collections.Generic.HashSet[string]

    #Create the log file.

    new-logfile -logFileName $logFileName -logFolderPath $logFolderPath

    out-logfile -string "***********************************************************"
    out-logfile -string "Starting get-DLHierarchyFromExchangeOnline"
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
    $exchangeOnlineCertificateThumbPrint=remove-stringSpace -stringToFix $exchangeOnlineCertificateThumbPrint  
    $exchangeOnlineEnvironmentName=remove-stringSpace -stringToFix $exchangeOnlineEnvironmentName
    $exchangeOnlineOrganizationName=remove-stringSpace -stringToFix $exchangeOnlineOrganizationName
    $exchangeOnlineAppID=remove-stringSpace -stringToFix $exchangeOnlineAppID  
    
    out-logfile -string "Testing to ensure group ID passed is a GUID format."

    if (test-isGUID -stringGUID $groupObjectID)
    {
        out-logfile -string "Group is vaild string format."
    }
    else 
    {
        Out-logfile -string "Identifier should be an acceptable GUID format.  This incldues objectGUID, externalDirectoryObjectID, ExchangeObjectID"
    }


    Out-LogFile -string "Validating Exchange Online Credentials."

    start-parameterValidation -exchangeOnlineCredential $exchangeOnlineCredential -exchangeOnlineCertificateThumbprint $exchangeOnlineCertificateThumbprint

    #Validating that all portions for exchange certificate auth are present.

    out-logfile -string "Validating parameters for Exchange Online Certificate Authentication"

    start-parametervalidation -exchangeOnlineCertificateThumbPrint $exchangeOnlineCertificateThumbprint -exchangeOnlineOrganizationName $exchangeOnlineOrganizationName -exchangeOnlineAppID $exchangeOnlineAppID

    out-logfile -string "Calling Test-PowershellModule to validate the DL Conversion Module version installed."

    $telemetryDLHierachyVersion = Test-PowershellModule -powershellModuleName $corevariables.DLHierarchy.value -powershellVersionTest:$TRUE

    Out-LogFile -string "Calling Test-PowerShellModule to validate the Exchange Module is installed."

    $telemetryExchangeOnlineVersion = Test-PowershellModule -powershellModuleName $corevariables.exchangeOnlinePowershellModuleName.value -powershellVersionTest:$TRUE

    Out-LogFile -string "Calling New-ExchangeOnlinePowershellSession to create session to office 365."

    if ($exchangeOnlineCertificateThumbPrint -eq "")
    {
        #User specified non-certifate authentication credentials.

            try {
                New-ExchangeOnlinePowershellSession -exchangeOnlineCredentials $exchangeOnlineCredential -exchangeOnlineEnvironmentName $exchangeOnlineEnvironmentName -debugLogPath $logFolderPath
            }
            catch {
                out-logfile -string "Unable to create the exchange online connection using credentials."
                out-logfile -string $_ -isError:$TRUE
            }
    }
    elseif ($exchangeOnlineCertificateThumbPrint -ne "")
    {
        #User specified thumbprint authentication.

            try {
                new-ExchangeOnlinePowershellSession -exchangeOnlineCertificateThumbPrint $exchangeOnlineCertificateThumbPrint -exchangeOnlineAppId $exchangeOnlineAppID -exchangeOnlineOrganizationName $exchangeOnlineOrganizationName -exchangeOnlineEnvironmentName $exchangeOnlineEnvironmentName -debugLogPath $logFolderPath
            }
            catch {
                out-logfile -string "Unable to create the exchange online connection using certificate."
                out-logfile -string $_ -isError:$TRUE
            }
    }

    out-logfile -string "Start building tree from group..."

    $tree = Get-GroupWithChildren -objectID $groupObjectID -processedGroupIds $processedGroupIds -objectType $exchangeOnlineGroupType -queryMethodExchangeOnline:$TRUE -expandGroupMembership $expandGroupMembership -expandDynamicGroupMembership $expandDynamicGroupMembership

    out-logfile -string "Set header in output file to group name."

    $global:outputFile += "Group Hierachy for Group ID: "+$groupObjectID+"`n"

    out-logfile -string "Print hierarchy to log file."

    print-tree -node $tree -indent $defaultIndent -outputType $exchangeOnlineType

    out-logfile -string "Export hierarchy to file."

    out-HierarchyFile -outputFileName  ("Hierarchy-"+$logFileName) -logFolderPath $global:logFolderPath

    out-logfile -string "Generate HTML File..."

    $global:GroupCounter = $global:GroupCounter | Sort-Object -unique
    $global:mailUniversalSecurityGroupCounter = $global:mailUniversalSecurityGroupCounter | Sort-Object -unique
    $global:mailUniversalDistributionGroupCounter = $global:mailUniversalDistributionGroupCounter | Sort-Object -unique
    $global:userMailboxCounter = $global:userMailboxCounter | Sort-Object -Unique
    $global:mailUserCounter = $global:mailUserCounter | Sort-Object -Unique
    $global:guestMailUserCounter = $global:guestMailUserCounter | Sort-Object -Unique
    $global:mailContactCounter = $global:mailContactCounter | Sort-Object -Unique
    $global:groupMailboxCounter = $global:groupMailboxCounter | Sort-Object -Unique
    $global:dynamicGroupCounter = $global:dynamicGroupCounter | Sort-Object -Unique
    $global:userCounter = $global:userCounter | Sort-Object -Unique
    $global:equipmentMailboxCounter = $global:equipmentMailboxCounter | Sort-Object -Unique
    $global:sharedMailboxCounter = $global:sharedMailboxCounter | Sort-Object -Unique
    $global:roomMailboxCounter = $global:roomMailboxCounter | Sort-Object -Unique

    start-HTMLOutput -node $tree -outputType $exchangeOnlineType -groupObjectID $groupObjectID

    out-logfile -string ("Total groups processed: "+$global:groupCounter.count)
    out-logfile -string ("Total mail security groups processed: "+$global:mailUniversalSecurityGroupCounter.count)
    out-logfile -string ("Total mail distribution groups processed: "+$global:mailUniversalDistributionGroupCounter.count)
    out-logfile -string ("Total user mailbox processed: "+$global:userMailboxCounter.count)
    out-logfile -string ("Total mail user processed: "+$global:mailUserCounter.count)
    out-logfile -string ("Total guest mail user processed: "+$global:guestMailUserCounter.count)
    out-logfile -string ("Total mail contact processed: "+$global:mailContactCounter.count)
    out-logfile -string ("Total group mailbox processed: "+$global:groupMailboxCounter.count)
    out-logfile -string ("Total dynamic groups processed: "+$global:dynamicGroupCounter.count)
    out-logfile -string ("Total user processed: "+$global:userCounter.count)
    out-logfile -string ("Total equipment mailbox processed: "+$global:equipmentMailboxCounter.count)
    out-logfile -string ("Total shared mailbox processed: "+$global:sharedMailboxCounter.count)
    out-logfile -string ("Total room mailbox processed: "+$global:roomMailboxCounter.count)

    $totalObjectsProcessed = $global:groupCounter.count+$global:mailUniversalSecurityGroupCounter.count+$global:mailUniversalDistributionGroupCounter.count+$global:userMailboxCounter.count+$global:mailUserCounter.count+$global:guestMailUserCounter.count+$global:mailContactCounter.count+$global:groupMailboxCounter.count+$global:dynamicGroupCounter.count+$global:userCounter.count+$global:equipmentMailboxCounter.count+$global:sharedMailboxCounter.count+$global:roomMailboxCounter.count

    out-logfile -string ("Total objects processed: "+$totalObjectsProcessed)

    $telemetryEndTime = get-universalDateTime
    $telemetryElapsedSeconds = get-elapsedTime -startTime $telemetryStartTime -endTime $telemetryEndTime

    $telemetryEventProperties = @{
        DLConversionV2Command = $telemetryEventName
        DLHierarchyVersion = $telemetryDLHierachyVersion
        ExchangeOnline = $telemetryExchangeOnlineVersion
        OSVersion = $telemetryOSVersion
        MigrationStartTimeUTC = $telemetryStartTime
        MigrationEndTimeUTC = $telemetryEndTime
        MigrationErrors = $telemetryError
        GroupsProcessed = $global:groupCounter.count
        MailSecurityGroupsProcessed = $global:mailUniversalSecurityGroupCounter.count
        MailDistributionGroupsProcessed = $global:mailUniversalDistributionGroupCounter.count
        UserMailboxProcessed = $global:userMailboxCounter.count
        MailUsersProcessed = $global:mailUserCounter.count
        GuestMailUserProcessed = $global:guestMailUserCounter.count
        MailContactProcessed = $global:mailContactCounter.count
        GroupMailboxProcessed = $global:groupMailboxCounter.count
        DynamicGroupsProcessed = $global:dynamicGroupCounter.count
        UsersProcessed = $global:userCounter.count
        RoomMailboxProcessed = $global:roomMailboxCounter.Count
        EquipmentMailboxProcessed = $global:equipmentMailboxCounter.Count
        SharedMailboxProcessed = $global:sharedMailboxCounter.Count
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
