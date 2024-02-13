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
        [boolean]$allowTelemetryCollection=$TRUE
    )

    #Define script based variables.

    #$logFileName = (Get-Date -Format FileDateTime) #Use random file date time for the log file name.
    $logFileName = $groupObjectID
    $msGraphScopesRequired = @("Directory.Read.All") #Define the grpah scopes required.

    #Initialize telemetry collection.

    $appInsightAPIKey = "63d673af-33f4-401c-931e-f0b64a218d89"
    $traceModuleName = "DLHierarchy"

    #Create telemetry values.

    $telemetryDLConversionV2Version = $NULL
    $telemetryExchangeOnlineVersion = $NULL
    $telemetryMSGraphAuthentication = $NULL
    $telemetryMSGraphUsers = $NULL
    $telemetryMSGraphGroups = $NULL
    $telemetryMSGraphDirectory = $NULL
    $telemetryActiveDirectoryVersion = $NULL
    $telemetryOSVersion = (Get-CimInstance Win32_OperatingSystem).version
    $telemetryStartTime = get-universalDateTime
    $telemetryEndTime = $NULL
    [double]$telemetryElapsedSeconds = 0
    $telemetryEventName = "get-DLHierarchyFromGraph"
    [boolean]$telemetryError=$FALSE

    #Define windows title.

    $windowTitle = ("Start-DistributionListMigration "+$groupSMTPAddress)
    $host.ui.RawUI.WindowTitle = $windowTitle

    #Define variables utilized in the core function that are not defined by parameters.

    $coreVariables = @{ 
        msGraphAuthenticationPowershellModuleName = @{ "Value" = "Microsoft.Graph.Authentication" ; "Description" = "Static ms graph powershell name authentication" }
        msGraphUsersPowershellModuleName = @{ "Value" = "Microsoft.Graph.Users" ; "Description" = "Static ms graph powershell name users" }
        msGraphGroupsPowershellModuleName = @{ "Value" = "Microsoft.Graph.Groups" ; "Description" = "Static ms graph powershell name groups" }
        msGraphIdentityDirectoryManagement = @{ "Value" = "Microsoft.Graph.Identity.DirectoryManagement" ; "Description" = "Static ms graph powershell name groups" }
        DLHierachy = @{ "Value" = "DLHierachy" ; "Description" = "Static dlConversionv2 powershell module name" }
    }


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

    $groupSMTPAddress = remove-stringSpace -stringToFix $groupSMTPAddress
    $globalCatalogServer = remove-stringSpace -stringToFix $globalCatalogServer
    $logFolderPath = remove-stringSpace -stringToFix $logFolderPath 

    if ($aadConnectServer -ne $NULL)
    {
        $aadConnectServer = remove-stringSpace -stringToFix $aadConnectServer
    }

    if ($exchangeServer -ne $NULL)
    {
        $exchangeServer=remove-stringSpace -stringToFix $exchangeServer
    }
    
    if ($exchangeOnlineCertificateThumbPrint -ne "")
    {
        $exchangeOnlineCertificateThumbPrint=remove-stringSpace -stringToFix $exchangeOnlineCertificateThumbPrint
    }

    $exchangeOnlineEnvironmentName=remove-stringSpace -stringToFix $exchangeOnlineEnvironmentName

    if ($exchangeOnlineOrganizationName -ne "")
    {
        $exchangeOnlineOrganizationName=remove-stringSpace -stringToFix $exchangeOnlineOrganizationName
    }

    if ($exchangeOnlineAppID -ne "")
    {
        $exchangeOnlineAppID=remove-stringSpace -stringToFix $exchangeOnlineAppID
    }

    $exchangeAuthenticationMethod=remove-StringSpace -stringToFix $exchangeAuthenticationMethod
    
    $dnNoSyncOU = remove-StringSpace -stringToFix $dnNoSyncOU
    
    $groupTypeOverride=remove-stringSpace -stringToFix $groupTypeOverride
    
    <#
    if ($azureTenantID -ne $NULL)
    {
        $azureTenantID = remove-StringSpace -stringToFix $azureTenantID
    }

    if ($azureCertificateThumbprint -ne $NULL)
    {
        $azureCertificateThumbprint = remove-StringSpace -stringToFix $azureCertificateThumbPrint
    }

    if ($azureEnvironmentName -ne $NULL)
    {
        $azureEnvironmentName = remove-StringSpace -stringToFix $azureEnvironmentName
    }

    if ($azureApplicationID -ne $NULL)
    {
        $azureApplicationID = remove-stringSpace -stringToFix $azureApplicationID
    }

    #>

    $msGraphTenantID = remove-stringSpace -stringToFix $msGraphTenantID
    $msGraphCertificateThumbprint = remove-stringSpace -stringToFix $msGraphCertificateThumbprint
    $msGraphApplicationID = remove-stringSpace -stringToFix $msGraphApplicationID

    if ($aadConnectCredential -ne $null)
    {
        Out-LogFile -string ("AADConnectUserName = "+$aadConnectCredential.UserName.tostring())
    }

    if ($exchangecredential -ne $null)
    {
        Out-LogFile -string ("ExchangeUserName = "+$exchangeCredential.UserName.toString())
    }

    if ($exchangeOnlineCredential -ne $null)
    {
        Out-LogFile -string ("ExchangeOnlineUserName = "+ $exchangeOnlineCredential.UserName.toString())
    }

    <#
    if ($azureADCreential -ne $NULL)
    {
        out-logfile -string ("AzureADUserName = "+$azureADCredential.userName.toString())
    }
    #>
}
