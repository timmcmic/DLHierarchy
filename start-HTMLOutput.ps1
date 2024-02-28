function start-HTMLOutput
{
    [Parameter(Mandatory = $true)]
    $node,
    [Parameter(Mandatory = $true)]
    $outputType,
    [Parameter(Mandatory = $true)]
    $groupObjectID

    $functionMSGraphType = "MSGraph"
    $functionExchangeOnlineType = "ExchangeOnline"
    $functionLDAPType = "LDAP"
    $functionHTMLSuffix = "html"
    $functionHTMLFile = $global:LogFile.replace("log","$functionHTMLSuffix")

    out-logfile -string $functionHTMLFile

    new-HTML -TitlText $groupObjectID -FilePath $functionHTMLFile
    {

    }-Online -ShowHTML

    <#

    New-HTML -TitleText $groupObjectID -FilePath $functionHTMLFile {
        New-HTMLTreeChildCounter -Deep -HideZero -HideExpanded
        New-HTMLSection -Invisible {
            New-HTMLSection {
                New-HTMLTree -Checkbox none {
                    New-HTMLTreeFileNodes -Path 'C:\Support\GitHub\PSWriteHTML\Examples' -Filter *.html -IsExpanded
                } -EnableChildCounter -AutoScroll
                New-HTMLSection -Invisible {
                    New-HTMLFrame -Name 'contentFrame' -Scrolling Auto -Height 1500px
                }
            }
        }
    } -Online -ShowHTML

    #>
}