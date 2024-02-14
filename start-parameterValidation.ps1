<#
    .SYNOPSIS

    This function validates the parameters within the script.  Paramter validation is shared across functions.

    .PARAMETER EXCHANGEONLINECREDENTIAL

    The Exchnage Online user name and password.

    .PARAMETER EXCHANGEONLINECERTIFICATETHUMBPRINT

    The certificate thumbprint for the exchange online app registration.

    .PARAMETER EXCHANGEONLINEORGANIZATIONNAME

    The organization name associated with the exchange online tenant for app registration.

    .PARAMETER EXCHANGEONLINEAPPID

    The application id of the associated app registration in Entra ID for Exchange permissions.

    .PARAMETER ACTIVEDIRECTORYCREDENTIAL

    The active directory connection credential provided.

    .PARAMETER MSGRAPHCERTIFICATETHUMBPRINT

    The certificate thumbprint associated with the MSGraph app registration.

    .PARAMETER MSGRAPHTENANTID

    The tenant ID where the app registration for MS Graph is created.

    .PARAMETER MSGRAPHAPPLICATIONID

    The app registration for MS Graph app id.

    This function validates the parameters within the script.  Paramter validation is shared across functions.
    
    .DESCRIPTION

    This function validates the parameters within the script.  Paramter validation is shared across functions.

    #>
    Function start-parameterValidation
    {
        [cmdletbinding()]

        Param
        (
            [Parameter(Mandatory = $true,ParameterSetName = 'ExchangeOnline')]
            [AllowNull()]
            $exchangeOnlineCredential,
            [Parameter(Mandatory = $true,ParameterSetName = 'ExchangeOnline')]
            [Parameter(Mandatory = $true,ParameterSetName = 'ExchangeOnlineCertAuth')]
            [AllowNull()]
            $exchangeOnlineCertificateThumbprint,
            [Parameter(Mandatory = $true,ParameterSetName = 'ExchangeOnlineCertAuth')]
            [AllowNull()]
            $exchangeOnlineOrganizationName,
            [Parameter(Mandatory = $true,ParameterSetName = 'ExchangeOnlineCertAuth')]
            [AllowNull()]
            $exchangeOnlineAppID,
            [Parameter(Mandatory = $true,ParameterSetName = 'ActiveDirectory')]
            [AllowNull()]
            $activeDirectoryCredential,
            [Parameter(Mandatory = $true,ParameterSetName = 'msGraphCertAuth')]
            [AllowNull()]
            $msGraphCertificateThumbprint,
            [Parameter(Mandatory = $true,ParameterSetName = 'msGraphCertAuth')]
            [AllowNull()]
            $msGraphTenantID,
            [Parameter(Mandatory = $true,ParameterSetName = 'msGraphCertAuth')]
            [AllowNull()]
            $msGraphApplicationID
        )

        #Output all parameters bound or unbound and their associated values.

        write-functionParameters -keyArray $MyInvocation.MyCommand.Parameters.Keys -parameterArray $PSBoundParameters -variableArray (Get-Variable -Scope Local -ErrorAction Ignore)

        $functionParameterSetName = $PsCmdlet.ParameterSetName
        $exchangeOnlineParameterSetName = "ExchangeOnline"
        $exchangeOnlineParameterSetNameCertAuth = "ExchangeOnlineCertAuth"
        $msGraphParameterSetNameCertAuth = "MSGraphCertAuth"
        $activeDirectoryParameterSetName = "ActiveDirectory"
        $functionTrueFalse = $false

        #Start function processing.

        out-logfile -string "***********************************************************"
        out-logfile -string "Entering start-ParameterValidation"
        out-logfile -string "***********************************************************"

        out-logfile -string ("The parameter set name for validation: "+$functionParameterSetName)

        if ($functionParameterSetName -eq $activeDirectoryParameterSetName)
        {
            test-credentials -credentialsToTest $activeDirectoryCredential

            test-itemCount -itemsToCount $activeDirectoryCredential -itemsToCompareCount $serverNames
        }

        if ($functionParameterSetName -eq $msGraphParameterSetNameCertAuth)
        {
            if (($msGraphCertificateThumbprint -ne "") -and ($msGraphTenantID -eq "") -and ($msGraphApplicationID -eq ""))
            {
                out-logfile -string "The msGraph tenant ID and msGraph App ID are required when using certificate authentication to msGraph." -isError:$TRUE
            }
            elseif (($msGraphCertificateThumbprint -ne "") -and ($msGraphTenantID -ne "") -and ($msGraphApplicationID -eq ""))
            {
                out-logfile -string "The msGraph app id is required to use certificate authentication to msGraph." -isError:$TRUE
            }
            elseif (($msGraphCertificateThumbprint -ne "") -and ($msGraphTenantID -eq "") -and ($msGraphApplicationID -ne ""))
            {
                out-logfile -string "The msGraph tenant ID is required to use certificate authentication to msGraph." -isError:$TRUE
            }
            elseif (($msGraphCertificateThumbprint -eq "") -and ($msGraphTenantID -eq "") -and ($msGraphApplicationID -ne ""))
            {
                out-logfile -string "No componets of msGraph Cert Authentication were provided - this is not necessarily an issue."
            }
            else 
            {
                out-logfile -string "All components necessary for Exchange certificate thumbprint authentication were specified."    
            }
        }

        if ($functionParameterSetName -eq $exchangeOnlineParameterSetNameCertAuth)
        {
            if (($exchangeOnlineCertificateThumbPrint -ne "") -and ($exchangeOnlineOrganizationName -eq "") -and ($exchangeOnlineAppID -eq ""))
            {
                out-logfile -string "The exchange organiztion name and application ID are required when using certificate thumbprint authentication to Exchange Online." -isError:$TRUE
            }
            elseif (($exchangeOnlineCertificateThumbPrint -ne "") -and ($exchangeOnlineOrganizationName -ne "") -and ($exchangeOnlineAppID -eq ""))
            {
                out-logfile -string "The exchange application ID is required when using certificate thumbprint authentication." -isError:$TRUE
            }
            elseif (($exchangeOnlineCertificateThumbPrint -ne "") -and ($exchangeOnlineOrganizationName -eq "") -and ($exchangeOnlineAppID -ne ""))
            {
                out-logfile -string "The exchange organization name is required when using certificate thumbprint authentication." -isError:$TRUE
            }
            elseif (($exchangeOnlineCertificateThumbPrint -eq "") -and ($exchangeOnlineOrganizationName -eq "") -and ($exchangeOnlineAppID -eq ""))
            {
                out-logfile -string "No components of certificate authentication were specified.  This is not necessary an error."
            }
            else 
            {
                out-logfile -string "All components necessary for Exchange certificate thumbprint authentication were specified."    
                $functionTrueFalse = $TRUE
            }
        }

        if ($functionParameterSetName -eq $exchangeOnlineParameterSetName) 
        {
            if (($exchangeOnlineCredential -ne $NULL) -and ($exchangeOnlineCertificateThumbPrint -ne ""))
            {
                Out-LogFile -string "ERROR:  Only one method of cloud authentication can be specified.  Use either cloud credentials or cloud certificate thumbprint." -isError:$TRUE
            }
            elseif (($exchangeOnlineCredential -eq $NULL) -and ($exchangeOnlineCertificateThumbPrint -eq "")
            {
                out-logfile -string "ERROR:  One permissions method to connect to Exchange Online must be specified." -isError:$TRUE
            }
            else
            {
                Out-LogFile -string "Only one method of Exchange Online authentication specified."
            } 
        }        

        out-logfile -string "***********************************************************"
        out-logfile -string "Exiting start-ParameterValidation"
        out-logfile -string "***********************************************************"

        return $functionTrueFalse
    }