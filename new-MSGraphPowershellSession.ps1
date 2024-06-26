<#
    .SYNOPSIS

    This function creates the powershell session to msGraph AD.

    .DESCRIPTION

    This function creates the powershell session to msGraph AD.

    .PARAMETER msGraphADCredential

    The credential utilized to connect to msGraph ad.

    .PARAMETER msGraphCertificateThumbprint

    The certificate thumbprint for the associated msGraph application.

    .PARAMETER msGraphTenantID

    The tenant ID associated with the msGraph application.

    .PARAMETER msGraphApplicationID

    The application ID for msGraph management.

    .PARAMETER msGraphEnvironmentName

    The msGraph environment for the connection to msGraph ad.

	.OUTPUTS

    Powershell session to use for exchange online commands.

    .EXAMPLE

    new-msGraphADPowershellSession -msGraphADCredential $CRED -msGraphEnvironmentName NAME

    #>
    Function New-MSGraphPowershellSession
     {
        [cmdletbinding()]

        Param
        (
            [Parameter(ParameterSetName = "CertificateCredentials",Mandatory = $true)]
            [string]$msGraphCertificateThumbPrint="",
            [Parameter(ParameterSetName = "CertificateCredentials",Mandatory = $true)]
            [Parameter(ParameterSetName = "UserCredentials",Mandatory = $true)]
            [string]$msGraphTenantID,
            [Parameter(ParameterSetName = "CertificateCredentials",Mandatory = $true)]
            [string]$msGraphApplicationID,
            [Parameter(ParameterSetName = "UserCredentials",Mandatory = $true)]
            [Parameter(ParameterSetName = "CertificateCredentials",Mandatory = $true)]
            [string]$msGraphEnvironmentName,
            [Parameter(ParameterSetName = "UserCredentials",Mandatory = $false)]
            [Parameter(ParameterSetName = "CertificateCredentials",Mandatory = $false)]
            [boolean]$isAudit=$FALSE,
            [Parameter(ParameterSetName = "CertificateCredentials",Mandatory = $true)]
            [Parameter(ParameterSetName = "UserCredentials",Mandatory = $true)]
            [array]$msGraphScopesRequired=@()
        )

        #Output all parameters bound or unbound and their associated values.

        write-functionParameters -keyArray $MyInvocation.MyCommand.Parameters.Keys -parameterArray $PSBoundParameters -variableArray (Get-Variable -Scope Local -ErrorAction Ignore)

        #Define variables that will be utilzed in the function.

        [boolean]$isCertAuth=$false
        #$exchangeOnlineCommands=@('get-ExoRecipient','new-distributionGroup','get-recipient','set-distributionGroup','get-distributionGroupMember','get-mailbox','get-unifiedGroup','set-UnifiedGroup')
        #Initiate the session.
        
        out-logfile -string "***********************************************************"
        out-logfile -string "Entering new-MSGraphPowershellSession"
        out-logfile -string "***********************************************************"

        if ($msGraphCertificateThumbPrint -ne "")
        {
            $isCertAuth=$true
            out-logfile -string ("Is certificate auth = "+$isCertAuth)
        }

        if ($isCertAuth -eq $False)
        {
            out-logfile -string "Making MS Graph connection using interactive credentials."

            try {
                connect-mgGraph -tenantID $msGraphTenantID -environment $msGraphEnvironmentName -scopes $msGraphScopesRequired -errorAction STOP
            }
            catch {
                out-logfile -string "Unable to make ms graph connection using interactive authentication."
                out-logfile -string "https://timmcmic.wordpress.com/2023/04/11/office-365-distribution-list-migrations-version-2-0-part-33/"
                out-logfile $_ -isError:$TRUE
            }
        }   
        elseif ($isCertAuth -eq $TRUE) 
        {
            try 
            {
                out-logfile -string "Creating the connection to exchange online powershell using certificate authentication."

                connect-mgGraph -certificateThumbprint $msGraphCertificateThumbPrint -ClientId $msGraphApplicationID -tenantID $msGraphTenantID -environment $msGraphEnvironmentName
            } 
            catch 
            {
                out-logfile -string "Unable to connect to graph using certificate authentication."
                out-logfile -string "https://timmcmic.wordpress.com/2023/04/11/office-365-distribution-list-migrations-version-2-0-part-33/"
                out-logfile -string $_ -isError:$TRUE -isAudit $isAudit
            }
        }
               
        Out-LogFile -string "The MS Graph powershell session was created successfully."

        out-logfile -string (Get-MgContext)

        out-logfile -string "***********************************************************"
        out-logfile -string "Exiting new-MSGraphPowershellSession"
        out-logfile -string "***********************************************************"
    }
