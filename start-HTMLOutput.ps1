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

    New-HTML -TitleText $groupObjectID -FilePath $functionHTMLFile {
        New-HTMLTree -Checkbox none {
            New-HTMLTreeChildCounter -Deep -HideZero -HideExpanded
            New-HTMLTreeNode -Title 'Power comes on' {
                New-HTMLTreeNode -Title 'Live screen' {
                    New-HTMLTreeNode -Title 'New build'
                    New-HTMLTreeNode -Title '<b>No</b> new build' {
                        New-HTMLTreeNode -Title 'Need two tries to boot' {
                            New-HTMLTreeNode -Title 'Premature power_good signal. Try different power supply.' -Icon 'https://cdn-icons-png.flaticon.com/512/6897/6897039.png'
                        }
                        New-HTMLTreeNode -Title 'Does not need two tries to boot'
                    }
                }
                New-HTMLTreeNode -Title "<b>No</b> live screen" {
                    New-HTMLTreeNode -Title "Proceed to video failure chart" -Icon 'https://cdn-icons-png.flaticon.com/512/1294/1294758.png'
                }
            }
        } -EnableChildCounter -AutoScroll -MinimumExpandLevel 1
    } -Online -ShowHTML

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