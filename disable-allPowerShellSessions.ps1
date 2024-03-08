<#
    .SYNOPSIS

    This function disables all open powershell sessions.

    .DESCRIPTION

    This function disables all open powershell sessions.

    .OUTPUTS

    No return.

    #>
    Function disable-allPowerShellSessions
     {

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "BEGIN disable-allPowerShellSessions"
        Out-LogFile -string "********************************************************************************"

        try {
            Disconnect-ExchangeOnline -ErrorAction Stop -confirm:$false
        }
        catch {
            out-logfile -string "Error getting PSSessions - hard abort since this is called in exit code."
        }

        try {
            Disconnect-MgGraph -errorAction STOP 
        }
        catch {
            out-logfile -string "Error disconnecting powershell graph - hard abort since this is called in exit code."
        }

        out-logfile -string "***IT MAY BE NECESSARY TO EXIT THIS POWERSHELL WINDOW AND REOPEN TO RESTART FROM A FAILED MIGRATION***"

        Out-LogFile -string "END disable-allPowerShellSessions"
        Out-LogFile -string "********************************************************************************"
    }