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
        [string]$logFolderPath
    )

    #Define script based variables.

    $logFileName = (Get-Date -Format FileDateTime) #Use random file date time for the log file name.

    #Create the log file.

    new-logfile -logFileName $logFileName -logFolderPath $logFolderPath
}
