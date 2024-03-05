
function get-NodeString
{
    param(
        [Parameter(Mandatory = $true)]
        $node,
        [Parameter(Mandatory = $true)]
        $outputType
    )

    $functionReturnString = ""

    if ($outputType -eq $functionExchangeOnlineType)
    {
        out-logfile -string "Calculating string for Exchange Online"

        if ($node.object.groupType -ne $null)
        {
            $functionReturnString = $node.object.displayName +" (ExchangeObjectID: "+$node.object.ExchangeObjectID+") ("+$node.object.recipientType+"/"+$node.object.recipientTypeDetails+"/"+$node.object.GroupType+")"
        }
        else 
        {
            $functionReturnString = $node.object.displayName +" (ExchangeObjectID: "+$node.object.ExchangeObjectID+") ("+$node.object.recipientType+"/"+$node.object.recipientTypeDetails+")"
        }
    }
    elseif ($outputType -eq $functionMSGraphType)
    {
        out-logfile -string "Calculating string for Microsoft Graph"
        $functionReturnString = $node.object.displayName +" (ObjectID: "+$node.object.id+") ("+$node.object.getType().name+")"
    }
    elseif ($outputType -eq $functionLDAPType)
    {
        out-logfile -string "Calculating string for LDAP"
        $functionReturnString = $node.object.DisplayName +" (ObjectGUID:"+$node.object.objectGUID+") ("+$node.object.objectClass+")"
    }

    out-logfile -string $functionReturnString
    return $functionReturnString
}
function New-HTMLTreeChildNodes 
{
    param(
        [Parameter(Mandatory = $true)]
        $node,
        [Parameter(Mandatory = $true)]
        $outputType
    )

    $functionGraphUser = "MicrosoftGraphUser"
    $functionGraphGroup = "MicrosoftGraphGroup"
    $functionGraphContact = "MicrosoftGraphOrgContact"

    $functionExchangeGroup = "Group"
    $functionExchangeMailUniversalSecurityGroup = "MailUniversalSecurityGroup"
    $functionExchangeMailUniversalDistributionGroup = "MailUniversalDistributionGroup"
    $functionExchangeUserMailbox = "UserMailbox"
    $functionExchangeMailUser = "Mailuser"
    $functionExchangeGuestMailUser = "GuestMailUser"
    $functionExchangeMailContact = "MailContact"
    $functionExchangeGroupMailbox = "GroupMailbox"
    $functionExchangeDynamicGroup = "DynamicDistributionGroup"

    $functionLDAPGroup = "Group"
    $functionLDAPUser = "User"
    $functionLDAPContact = "Contact"
    $functionLDAPDynamicGroup = "msExchDynamicDistributionList"

    if ($outputType -eq $functionMSGraphType)
    {
        foreach ($child in $node.children)
        {
            $string = get-nodeString -node $child -outputType $functionMSGraphType
            out-logfile -string ("Prcessing HTML: "+$string)

            if ($child.object.getType().name -eq $functionGraphUser)
            {
                New-HTMLTreeNode -Title $string -children {New-HTMLTreeChildNodes -node $child -outputType $functionMSGraphType} -icon $functionUserPNGHTML
            }
            elseif ($child.object.getType().name -eq $functionGraphGroup)
            {
                New-HTMLTreeNode -Title $string -children {New-HTMLTreeChildNodes -node $child -outputType $functionMSGraphType} -icon $functionGroupPNGHTML
            }
            elseif ($child.object.getType().name -eq $functionGraphContact)
            {
                New-HTMLTreeNode -Title $string -children {New-HTMLTreeChildNodes -node $child -outputType $functionMSGraphType} -icon $functionContactPNGHTML
            }
        }
    }
    elseif ($outputType -eq $functionExchangeOnlineType)
    {
        $sorted = New-Object System.Collections.Generic.List[pscustomobject]
        $node.Children | % { $sorted.Add($_) }
     
        $sorted = [System.Linq.Enumerable]::OrderBy($sorted, [Func[pscustomobject,string]]{ param($x) $x.Object.RecipientTypeDetails })
        $sorted = [System.Linq.Enumerable]::ThenBy($sorted, [Func[pscustomobject,string]]{ param($x) $x.Object.DisplayName })

        foreach ($child in $sorted)
        {
            $string = get-nodeString -node $child -outputType $functionExchangeOnlineType
            out-logfile -string ("Prcessing HTML: "+$string)

            if ($child.object.recipientType -eq $functionExchangeGroup)
            {
                New-HTMLTreeNode -Title $string -children {New-HTMLTreeChildNodes -node $child -outputType $functionExchangeOnlineType} -icon $functionGroupPNGHTML
            }
            elseif ($child.object.recipientType -eq $functionExchangeMailUniversalSecurityGroup)
            {
                New-HTMLTreeNode -Title $string -children {New-HTMLTreeChildNodes -node $child -outputType $functionExchangeOnlineType} -icon $functionGroupPNGHTML
            }
            elseif ($child.object.recipientType -eq $functionExchangeDynamicGroup)
            {
                New-HTMLTreeNode -Title $string -children {New-HTMLTreeChildNodes -node $child -outputType $functionExchangeOnlineType} -icon $functionGroupPNGHTML
            }
            elseif ($child.object.recipientType -eq $functionExchangeMailUniversalDistributionGroup)
            {
                New-HTMLTreeNode -Title $string -children {New-HTMLTreeChildNodes -node $child -outputType $functionExchangeOnlineType} -icon $functionGroupPNGHTML
            }
            elseif ($child.object.recipientType -eq $functionExchangeGroupMailbox)
            {
                New-HTMLTreeNode -Title $string -children {New-HTMLTreeChildNodes -node $child -outputType $functionExchangeOnlineType} -icon $functionGroupPNGHTML
            }
            elseif ($child.object.recipientType -eq $functionExchangeGuestMailUser)
            {
                New-HTMLTreeNode -Title $string -children {New-HTMLTreeChildNodes -node $child -outputType $functionExchangeOnlineType} -icon $functionUserPNGHTML
            }
            elseif ($child.object.recipientType -eq $functionExchangeMailUser)
            {
                New-HTMLTreeNode -Title $string -children {New-HTMLTreeChildNodes -node $child -outputType $functionExchangeOnlineType} -icon $functionUserPNGHTML
            }
            elseif ($child.object.recipientType -eq $functionExchangeUserMailbox)
            {
                New-HTMLTreeNode -Title $string -children {New-HTMLTreeChildNodes -node $child -outputType $functionExchangeOnlineType} -icon $functionUserPNGHTML
            }
            elseif ($child.object.recipientType -eq $functionExchangeUser)
            {
                New-HTMLTreeNode -Title $string -children {New-HTMLTreeChildNodes -node $child -outputType $functionExchangeOnlineType} -icon $functionUserPNGHTML
            }
            elseif ($child.object.recipientType -eq $functionExchangeMailContact)
            {
                New-HTMLTreeNode -Title $string -children {New-HTMLTreeChildNodes -node $child -outputType $functionExchangeOnlineType} -icon $functionContactPNGHTML
            }
        }
    }
    elseif ($outputType -eq $functionLDAPType)
    {
        $sorted = New-Object System.Collections.Generic.List[pscustomobject]
        $node.Children | % { $sorted.Add($_) }
     
        $sorted = [System.Linq.Enumerable]::OrderBy($sorted, [Func[pscustomobject,string]]{ param($x) $x.Object.objectClass })
        $sorted = [System.Linq.Enumerable]::ThenBy($sorted, [Func[pscustomobject,string]]{ param($x) $x.Object.Name })

        foreach ($child in $sorted)
        {
            $string = get-nodeString -node $child -outputType $functionLDAPType
            out-logfile -string ("Prcessing HTML: "+$string)

            if ($child.object.objectClass -eq  $functionLDAPGroup)
            {
                New-HTMLTreeNode -Title $string -children {New-HTMLTreeChildNodes -node $child -outputType $functionLDAPType} -icon $functionGroupPNGHTML
            }
            elseif ($child.object.objectClass -eq  $functionLDAPDynamicGroup)
            {
                New-HTMLTreeNode -Title $string -children {New-HTMLTreeChildNodes -node $child -outputType $functionLDAPType} -icon $functionGroupPNGHTML
            }
            elseif ($child.object.objectClass -eq  $functionLDAPUser)
            {
                New-HTMLTreeNode -Title $string -children {New-HTMLTreeChildNodes -node $child -outputType $functionLDAPType} -icon $functionUserPNGHTML
            }
            elseif ($child.object.objectClass -eq  $functionLDAPContact)
            {
                New-HTMLTreeNode -Title $string -children {New-HTMLTreeChildNodes -node $child -outputType $functionLDAPType} -icon $functionContactPNGHTML
            }
        }
    }
}


function start-HTMLOutput
{
    param(
        [Parameter(Mandatory = $true)]
        $node,
        [Parameter(Mandatory = $true)]
        $outputType,
        [Parameter(Mandatory = $true)]
        $groupObjectID
    )

    $functionMSGraphType = "MSGraph"
    $functionExchangeOnlineType = "ExchangeOnline"
    $functionLDAPType = "LDAP"

    $functionContactPNGHTML = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABAAAAAMCAMAAABcOc2zAAAAIGNIUk0AAHomAACAhAAA+gAAAIDoAAB1MAAA6mAAADqYAAAXcJy6UTwAAADkUExURdPT08nJyczMzMrKyuzs7Pb29vn29vn39vf29vX19c3Nzf////X8/q/k8qLg8Or4/Pv7+/b19vj4+KTg7yq32yW22n7T6f3+/+fm5+bm5vT09IjX6yK12mHK5Pj9/vb29dHv917J5FLF4rbm8ufn5+jn6O3t7bzo9GvN5sLq9Nfx+HDP56Pg7/v+/+7t7vLy8ufx81TG4iC02mXL5SS22jm93tvz+ff29c7Nzdzt8UbB4CO12ia22zK63cnt9vj29u3s7fP19cjt9pLb7X3U6XzT6YzY7Lno8/b8/vz8+/n39/f397c048AAAAABYktHRAsf18TAAAAACXBIWXMAABYlAAAWJQFJUiTwAAAAB3RJTUUH6AIdFDYNAvIJCQAAAKBJREFUCNddjscSgkAQRJcw4jImUBBMGNY1Y8IcMMf//x8BL5bv+KqruwkRxB8EQiQZIKbEKYUQWSIqYCKZSiNmADSdikSkmM0ZZh6pZdlyIRLFUqlcwQgIhIPVWr2BSFmT8TDhtNqdbq8/0F2XDwOhjsaTqenN5gv727FcrTfG1tvtfcbYIUwcT+fL9XZ/PDUtmpX4ywfwlejXm0vk//oHL48QM5PBxIEAAAAldEVYdGRhdGU6Y3JlYXRlADIwMjQtMDItMjlUMjA6NTQ6MDErMDA6MDASa647AAAAJXRFWHRkYXRlOm1vZGlmeQAyMDI0LTAyLTI5VDIwOjU0OjAxKzAwOjAwYzYWhwAAACh0RVh0ZGF0ZTp0aW1lc3RhbXAAMjAyNC0wMi0yOVQyMDo1NDoxMyswMDowMG8WJu8AAAAASUVORK5CYII="
    $functionGroupPNGHTML = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABAAAAANCAMAAACXZR4WAAAAIGNIUk0AAHomAACAhAAA+gAAAIDoAAB1MAAA6mAAADqYAAAXcJy6UTwAAAGVUExURf///+P5/nbi+DvW9Xfj+OT5/vT9/nPg9i/R8jDQ8jDQ8S7P8HTe9PX9/vj7/snw+TXJ6i3G6C3F6C3D5yvC5jXE5svw+LnZ80qf4Eed4K/V8rjo9Cu63im43Si33Ci22ye12iy22prW7SqN2wB10x+I2djq+Njx9zi01iKr0CSr0CSpzyGozTuy0qHS7Q1/1gB41Ad81b3c9JLS5SWixxybwxyawiWfxZjS5O31/ECa3wB20zmW3unz+8/1/XLg92PN52+/2G++2GrO54Tl+LHg9lal4kyg4czk9r7w+kXV8yvQ8l/c9tH1/NP1/WXd9i7R8izC7QyJ2ozB65HF7AN51CyP29Dm99/2+0/O6yrF6DfI6bDp9rXq9znJ6SzF6C7H6R2s4USe4EWc3wB21AB31F6q5I/Z7Cm43Ce33HjS6X7U6ie23BKP1wN51RSC10272SOr0Diz1Dqz1SSs0Ceg1T2Y3j6Z3z6Z3k2h4Smixx+dxB+exBycxFGz0uz2+/b6/vX6/UupySOVvCCUu2250/r9/qaz2UMAAAABYktHRACIBR1IAAAACXBIWXMAABYlAAAWJQFJUiTwAAAAB3RJTUUH6AIdFDYNAvIJCQAAAMRJREFUCNdjYGBgYGRiZmZhZYADNnYOTi5uHl4GPj6IAL+AoJCwiKiYuISkFFhAWkZWTl5BUUlZRUVVDSSgrqGppa2jq6dvYGBoBFZibGJqZm5haWVtbWML4tvZOzg6Obu4Sri5uXsA+Z5e3j6+fv4BgUHBIaFh4QwRkVFC0TGxcfEJiUnJKalpDOkZGRmZWdmZGRk5uXnWKvkMBZpaWoVFxYVaWiWlZeUVlQxV1TU1NdUgorauvqGRj6GpGQZaWtuAdgAA0tUvmIxhubgAAAAldEVYdGRhdGU6Y3JlYXRlADIwMjQtMDItMjlUMjA6NTQ6MDErMDA6MDASa647AAAAJXRFWHRkYXRlOm1vZGlmeQAyMDI0LTAyLTI5VDIwOjU0OjAxKzAwOjAwYzYWhwAAACh0RVh0ZGF0ZTp0aW1lc3RhbXAAMjAyNC0wMi0yOVQyMDo1NDoxMyswMDowMG8WJu8AAAAASUVORK5CYII="
    $functionUserPNGHTML = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAA8AAAAQCAMAAAD+iNU2AAAAIGNIUk0AAHomAACAhAAA+gAAAIDoAAB1MAAA6mAAADqYAAAXcJy6UTwAAAGSUExURf///+/8/pLo+knZ9jbV9UjZ9pDo+u77/vX9/n7j+DPT9DDT9DHS9DDS8zLS83rh9vP8/rXt+TLN7y/M7i/L7S/K7C7J7C7J6zDI6rDp93/a8CjB5SzB5SvA5Cu/4yu+4iu+4Sa84HnV63nS6SS22yi22yi12ie12Se02Cez2COx1nPN5f7//6Xe7SSt0iSs0SSr0CSq0CSqzyOpziKnzaDa6u34+2C92B+gxiCfxh6exR6cw1y41Or2+vP9/5/k9Eq41zOixSebwTKgxEm11afl8/r+/9L1/Wff9zXV9W/g97zp9LDh77vo9G3f9zrW9nrj+OT5/tX1/E/W8i3P8C/P8UTU8r/w+9v3/b7w+0PU8i7P8S3P8WTb9Oj5/WvW7irE6C3F6Ivf8tn1+4ve8izF6ITc8fz+/7fn8zG83ym63ie53lPH5MHr9Si63jq/4crt9nDK4ySv1Caw1SWv1C+z1nPL43/Q5j6w0SGlyiKlyyinzCClykSz0yadwx6awSaew1qvzR6Suh2RuR+SuluwzTyKhB8AAAABYktHRACIBR1IAAAACXBIWXMAABYlAAAWJQFJUiTwAAAAB3RJTUUH6AIdFDYOm/tYswAAAMFJREFUCNdjYAACRiZmFlY2dgYo4ODk4ubh5eMXgPIFhYRFRMXEJSShfClpGVk5eQVFJShfWUVVTV1DU0tbB8LX1dM3MDQyNjGFypuZW1hYWlnb2EL5dvYOjk7OLq5uEK67h6eXt4+vn39AIIgbFBwSGhYeERkVHRMbx8AgEJ+QmJiYlJySmpiYkJbOkJGZlZWVnZObk52VlZdfwFBYVFxcXFJaVloCossZKiqrQKAaTNbUMtTVI4MGhsamZgRoaQUAG1I6c6Lf74UAAAAldEVYdGRhdGU6Y3JlYXRlADIwMjQtMDItMjlUMjA6NTQ6MDErMDA6MDASa647AAAAJXRFWHRkYXRlOm1vZGlmeQAyMDI0LTAyLTI5VDIwOjU0OjAxKzAwOjAwYzYWhwAAACh0RVh0ZGF0ZTp0aW1lc3RhbXAAMjAyNC0wMi0yOVQyMDo1NDoxMyswMDowMG8WJu8AAAAASUVORK5CYII="


    $functionHTMLSuffix = "html"
    $functionHTMLFile = $global:LogFile.replace("log","$functionHTMLSuffix")


    out-logfile -string $functionHTMLFile
    out-logfile -string $outputType

    if ($outputType -eq $functionExchangeOnlineType)
    {
        out-logfile -string "Entering Exchange Online Type"

        $string = get-nodeString -node $node -outputType $functionExchangeOnlineType
        out-logfile -string ("Prcessing HTML: "+$string)

        New-HTML -TitleText $groupObjectID -FilePath $functionHTMLFile {
            New-HTMLTableOption -DataStore JavaScript
            new-htmlSection -HeaderText ("Group membership hierarchy for group object id: "+$groupObjectID){
                New-HTMLTree -Checkbox none {
                    New-HTMLTreeChildCounter -Deep -HideZero -HideExpanded
                    New-HTMLTreeNode -title $string -children {New-HTMLTreeChildNodes -node $node -outputType $functionExchangeOnlineType} -icon $functionGroupPNGHTML
                } -EnableChildCounter -AutoScroll -MinimumExpandLevel 1 -EnableQuickSearch
            }-HeaderTextAlignment "Left" -HeaderTextSize "16" -HeaderTextColor "White" -HeaderBackGroundColor "Black"  -CanCollapse -BorderRadius 10px
            new-htmlSection -HeaderText ("Group membership table for group object id: "+$groupObjectID){
                new-htmlTable -DataTable ($global:exchangeObjects | select-object DisplayName,Alias,ExternalDirectoryObjectId,ExchangeObjectId,Identity,ID,Name,PrimarySmtpAddress,EmailAddresses,LegacyExchangeDN,externalEmailAddress,RecipientType,RecipientTypeDetails,GroupType,IsDirSynced | sort-object externalDirectoryObjectID -Unique) -Filtering {
                } -AutoSize
            } -HeaderTextAlignment "Left" -HeaderTextSize "16" -HeaderTextColor "White" -HeaderBackGroundColor "Black"  -CanCollapse -BorderRadius 10px
        } -Online -ShowHTML
    }
    elseif ($outputType -eq $functionMSGraphType)
    {
        out-logfile -string "Entering MS Graph Type"

        $string = get-nodeString -node $node -outputType $functionMSGraphType
        out-logfile -string ("Prcessing HTML: "+$string)

        New-HTML -TitleText $groupObjectID -FilePath $functionHTMLFile {
            New-HTMLTableOption -DataStore JavaScript
            new-htmlSection -HeaderText ("Group membership hierarchy for group object id: "+$groupObjectID){
                New-HTMLTree -Checkbox none {
                    New-HTMLHeading -HeadingText ('Group Expansion for: '+$groupObjectID) -Heading h1
                    New-HTMLTreeChildCounter -Deep -HideZero -HideExpanded
                    New-HTMLTreeNode -title $string -children {New-HTMLTreeChildNodes -node $node -outputType $functionMSGraphType} -icon $functionGroupPNGHTML
                } -EnableChildCounter -AutoScroll -MinimumExpandLevel 1 -EnableQuickSearch
            }-HeaderTextAlignment "Left" -HeaderTextSize "16" -HeaderTextColor "White" -HeaderBackGroundColor "Black"  -CanCollapse -BorderRadius 10px
            new-htmlSection -HeaderText ("Group membership table for group object id: "+$groupObjectID){
                new-htmlTable -DataTable ($global:msGraphObjects | select-object DisplayName,Id,Mail,MailEnabled,MailNickname,ProxyAddresses,SecurityEnabled | sort-object ID -Unique) -Filtering {
                } -AutoSize
            } -HeaderTextAlignment "Left" -HeaderTextSize "16" -HeaderTextColor "White" -HeaderBackGroundColor "Black"  -CanCollapse -BorderRadius 10px
            new-htmlSection -HeaderText ("Group membership breakdown for group object id: "+$groupObjectID){
                New-HTMLPanel {
                    New-HTMLChart -Gradient {
                        New-ChartDonut -Name 'Groups' -Value $global:groupCounter
                        New-ChartDonut -Name 'DynamicGroups' -Value $global:dynamicGroupCounter
                        new-ChartDonut -Name 'MailSecurityGroups' -value $global:mailUniversalSecurityGroupCounter
                        new-chartDonut -name 'MailDistributionGroups' -value $global:mailUniversalDistributionGroupCounter
                        new-chartDonut -name 'UnifiedGroups' -value $global:groupMailboxCounter
                    }
                }
                New-HTMLPanel {
                    New-HTMLChart -Gradient {
                        New-ChartDonut -Name 'Users' -Value $global:userCounter
                        New-ChartDonut -Name 'MailContacts' -Value $global:mailContactCounter
                        New-ChartDonut -Name 'GuestMailUsers' -Value $global:guestMailUserCounter
                        New-ChartDonut -Name 'MailUsers' -Value $global:mailUserCounter
                        New-ChartDonut -Name 'UserMailbox' -Value $global:userMailboxCounter
                    }
                }
                New-HTMLPanel {
                    New-HTMLChart -Gradient {
                        New-ChartDonut -Name 'Groups' -Value $global:groupCounter
                        New-ChartDonut -Name 'DynamicGroups' -Value $global:dynamicGroupCounter
                        new-ChartDonut -Name 'MailSecurityGroups' -value $global:mailUniversalSecurityGroupCounter
                        new-chartDonut -name 'MailDistributionGroups' -value $global:mailUniversalDistributionGroupCounter
                        new-chartDonut -name 'UnifiedGroups' -value $global:groupMailboxCounter
                        New-ChartDonut -Name 'Users' -Value $global:userCounter
                        New-ChartDonut -Name 'MailContacts' -Value $global:mailContactCounter
                        New-ChartDonut -Name 'GuestMailUsers' -Value $global:guestMailUserCounter
                        New-ChartDonut -Name 'MailUsers' -Value $global:mailUserCounter
                        New-ChartDonut -Name 'UserMailbox' -Value $global:userMailboxCounter
                    }
                }
            } -HeaderTextAlignment "Left" -HeaderTextSize "16" -HeaderTextColor "White" -HeaderBackGroundColor "Black"  -CanCollapse -BorderRadius 10px
        } -Online -ShowHTML
    }
    elseif ($outputType -eq $functionLDAPType)
    {
        out-logfile -string "Entering LDAP Type"

        $string = get-nodeString -node $node -outputType $functionLDAPType
        out-logfile -string ("Prcessing HTML: "+$string)

        New-HTML -TitleText $groupObjectID -FilePath $functionHTMLFile {
            New-HTMLTableOption -DataStore JavaScript
            new-htmlSection -HeaderText ("Group membership hierarchy for group object id: "+$groupObjectID){
                New-HTMLTree -Checkbox none {
                    New-HTMLTreeChildCounter -Deep -HideZero -HideExpanded
                    New-HTMLTreeNode -title $string -children {New-HTMLTreeChildNodes -node $node -outputType $functionLDAPType} -icon $functionGroupPNGHTML
                } -EnableChildCounter -AutoScroll -MinimumExpandLevel 1 -EnableQuickSearch
            } -HeaderTextAlignment "Left" -HeaderTextSize "16" -HeaderTextColor "White" -HeaderBackGroundColor "Black"  -CanCollapse -BorderRadius 10px
            new-htmlSection -HeaderText ("Group membership table for group object id: "+$groupObjectID){
                new-htmlTable -DataTable (($global:ldapObjects | select-object DistinguishedName,CanonicalName,objectGUID,Name,DisplayName,groupType,mail,mailnickanme,proxyAddresses,targetAddress,legacyExchangeDN,'mS-DS-ConsistencyGuid','msDS-ExternalDirectoryObjectId',msExchRecipientDisplayType,msExchRecipientTypeDetails,msExchRemoteRecipientType,msExchMailboxGuid,msExchArchiveGUID) | sort-object distinguishedName -Unique) -Filtering {
                } -AutoSize
            } -HeaderTextAlignment "Left" -HeaderTextSize "16" -HeaderTextColor "White" -HeaderBackGroundColor "Black"  -CanCollapse -BorderRadius 10px
            new-htmlSection -HeaderText ("Group membership breakdown for group object id: "+$groupObjectID){
                New-HTMLPanel {
                    New-HTMLChart -Gradient {
                        New-ChartDonut -Name 'Groups' -Value $global:groupCounter
                        New-ChartDonut -Name 'DynamicGroups' -Value $global:dynamicGroupCounter
                    }
                }
                New-HTMLPanel {
                    New-HTMLChart -Gradient {
                        New-ChartDonut -Name 'Users' -Value $global:userCounter
                        New-ChartDonut -Name 'Contacts' -Value $global:contactCounter
                    }
                }
                New-HTMLPanel {
                    New-HTMLChart -Gradient {
                        New-ChartDonut -Name 'Users' -Value $global:userCounter
                        New-ChartDonut -Name 'Contacts' -Value $global:contactCounter
                        New-ChartDonut -Name 'Groups' -Value $global:groupCounter
                        New-ChartDonut -Name 'DynamicGroups' -Value $global:dynamicGroupCounter
                    }
                }
            } -HeaderTextAlignment "Left" -HeaderTextSize "16" -HeaderTextColor "White" -HeaderBackGroundColor "Black"  -CanCollapse -BorderRadius 10px
        } -Online -ShowHTML 
    }
}