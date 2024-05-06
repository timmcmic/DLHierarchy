<#
    .SYNOPSIS

    This function submits telemetry events to Azure.

    .DESCRIPTION

    This function submits telemetry events to Azure.

    .PARAMETER allowTelemetryCollection

    Boolean to allow for basic telemetry collection.

    .OUTPUTS

    None

    .EXAMPLE

    

    #>
    Function send-TelemetryEvent
     {
        [cmdletbinding()]

        Param
        (
            [Parameter(Mandatory = $TRUE)]
            [string]$traceModuleName,
            [Parameter(Mandatory = $TRUE)]
            $eventProperties,
            [Parameter(Mandatory = $TRUE)]
            $eventMetrics,
            [Parameter(Mandatory = $TRUE)]
            $eventName
        )

        out-logfile -string "***********************************************************"
        out-logfile -string "Entering Send-TelemetryEvent"
        out-logfile -string "***********************************************************"

        Send-THEvent -EventName $eventName -PropertiesHash $eventProperties -MetricsHash $eventMetrics -ModuleName $traceModuleName -Verbose

        out-logfile -string "***********************************************************"
        out-logfile -string "Exiting Send-TelemetryEvent"
        out-logfile -string "***********************************************************"
     }