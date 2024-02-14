#
# Module manifest for module 'DLHierachy'
#
# Generated by: timmcmic
#
# Generated on: 3/1/2021
#

@{

    # Script module or binary module file associated with this manifest.
    RootModule = '.\DLHierachy.psm1'
    
    # Version number of this module.
    ModuleVersion = '1.1'
    
    # Supported PSEditions
    # CompatiblePSEditions = @()
    
    # ID used to uniquely identify this module
    GUID = 'f1df7ce7-26f4-4bf5-9ddd-fa5df863b0f0'
    
    # Author of this module
    Author = 'timmcmic@microsoft.com'
    
    # Company or vendor of this module
    CompanyName = 'Microsoft CSS'
    
    # Copyright statement for this module
    Copyright = '(c) 2021 CSS Support. All rights reserved.'
    
    # Description of the functionality provided by this module
    Description = 'This module facilitiates collection of tree view of distribution list membership. '
    
    # Minimum version of the Windows PowerShell engine required by this module
    # PowerShellVersion = ''
    
    # Name of the Windows PowerShell host required by this module
    # PowerShellHostName = ''
    
    # Minimum version of the Windows PowerShell host required by this module
    # PowerShellHostVersion = ''
    
    # Minimum version of Microsoft .NET Framework required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
    # DotNetFrameworkVersion = ''
    
    # Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
    # CLRVersion = ''
    
    # Processor architecture (None, X86, Amd64) required by this module
    # ProcessorArchitecture = ''
    
    # Modules that must be imported into the global environment prior to importing this module
    RequiredModules = @(
        @{ModuleName = 'ExchangeOnlineManagement'; ModuleVersion = '3.1.0' },
        @{ModuleName = 'Microsoft.Graph.Authentication' ; ModuleVersion = '1.9.2'}
        @{ModuleName = 'Microsoft.Graph.Users' ; ModuleVersion = '1.9.2'}
        @{ModuleName = 'Microsoft.Graph.Groups' ; ModuleVersion = '1.9.2'}
        @{ModuleName = 'Microsoft.Graph.Identity.DirectoryManagement' ; ModuleVersion = '1.9.2'}
        'ActiveDirectory'
    )
    
    # Assemblies that must be loaded prior to importing this module
    # RequiredAssemblies = @()
    
    # Script files (.ps1) that are run in the caller's environment prior to importing this module.
    # ScriptsToProcess = @()
    
    # Type files (.ps1xml) to be loaded when importing this module
    # TypesToProcess = @()
    
    # Format files (.ps1xml) to be loaded when importing this module
    # FormatsToProcess = @()
    
    # Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
    NestedModules = @('get-DLHierarchyFromLDAP.ps1','new-ExchangeOnlinePowershellSession.ps1','send-TelemetryEvent.ps1','get-elapsedTime.ps1','out-HierarchyFile.ps1','get-DLHierachyFromExchangeOnline.ps1','Print-Tree.ps1','new-treeNode.ps1','Get-GroupWithChildren.ps1','new-MSGraphPowershellSession.ps1','test-powershellmodule.ps1','get-universalDateTime.ps1','start-parameterValidation.ps1','write-functionParameters.ps1','remove-stringSpace.ps1','test-powerShellVersion.ps1','New-LogFile.ps1','out-logFile.ps1','start-telemetryConfiguration.ps1')
    
    # Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
    FunctionsToExport = @('get-DLHierarchyFromLDAP','get-DLHierachyFromExchangeOnline','get-DLHierachyFromGraph','get-DLHierachyFromLDAP','get-DLHierarchyFromExchangeOnline')
    
    # Cmdlets to export from th'is module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
    CmdletsToExport = @()
    
    # Variables to export from this module
    VariablesToExport = '*'
    
    # Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
    AliasesToExport = @()
    
    # DSC resources to export from this module
    # DscResourcesToExport = @()
    
    # List of all modules packaged with this module
    # ModuleList = @()
    
    # List of all files packaged with this module
    # FileList = @()
    
    # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData = @{
    
        PSData = @{
    
            # Tags applied to this module. These help with module discovery in online galleries.
            Tags = @("Exchange","Office365","AzureAD","AzureActiveDirectory","ExchangeOnline","DistributionList","DL","DLMigration","ExchangeOnline")
    
            # A URL to the license for this module.
            LicenseUri = 'https://github.com/timmcmic/DLConversionV2/blob/master/license.md'
    
            # A URL to the main website for this project.
            ProjectUri = 'https://github.com/microsoft/DLConversionV2'
    
            # A URL to an icon representing this module.
            # IconUri = ''
    
            # ReleaseNotes of this module
            ReleaseNotes ='
            2.0.0 Initial release of version 2.
            '
    
            # External dependent modules of this module
            ExternalModuleDependencies = @('ActiveDirectory')
    
            #Establishing this version as a pre-release.
    
            #Prerelease = 'beta'
    
        } # End of PSData hashtable
    
    } # End of PrivateData hashtable
    
    # HelpInfo URI of this module
    # HelpInfoURI = ''
    
    # Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
    # DefaultCommandPrefix = ''
    
    }
    
    