#
# Module manifest for module 'MGN-Toolkit'
#
# Generated by: aaalzand@
# Generated on: 6/12/2023
#

@{

    # Script module or binary module file associated with this manifest.
    RootModule = 'MGN-Toolkit.psm1'

    # Version number of this module.
    ModuleVersion = '0.1.0'

    # ID used to uniquely identify this module
    GUID = '0c0b1894-1c1f-40a4-997d-aa2712d5589d'

    # Author of this module
    Author = "Ali Alzand / Tim Hall"

    # Company or vendor of this module
    CompanyName = 'Amazon'
    Copyright = '(c) 2023 Amazon, Inc.'

    # Minimum version of the Windows PowerShell engine required by this module
    PowerShellVersion = '3.0'

    # Description of the functionality provided by this module
    Description = 'Provides a set of PowerShell functions for requirements/consideration/replication checks'

    # Functions to export from this module
    FunctionsToExport = @(
        "Invoke-MGNToolkit",
        "Get-DomainControllerStatus",
        "Get-AntivirusEnabled",
        "Get-BitLockerStatus",
        "Get-BootMode",
        "Get-BootDiskSpace",
        "Get-Authenticationmethod",
        "Get-DotNETFramework",
        "Get-FreeRAM",
        "Get-TrustedRootCertificate",
        "Get-SCandNET",
        "Get-WMIServiceStatus",
        "Get-ProxySetting",
        "Get-NetworkInterfaceandIPCount",
        "Test-EndpointsNetworkAccess",
        "Get-Bandwidth",
        "Get-DiskActivity"
    )

    # Cmdlets to export from this module (leave empty if none)
    CmdletsToExport = @()

    # Variables to export from this module
    VariablesToExport = '*'

    # Aliases to export from this module (leave empty if none)
    AliasesToExport = @()

    # Private data to pass to the module specified in RootModule/ModuleToProcess
    PrivateData = @{
        PSData = @{
            # Tags applied to this module. These help with module discovery in online galleries.
            # Tags = @()

            # A URL to the license for this module.
            # LicenseUri = ''

            # A URL to the main website for this project.
            # ProjectUri = ''

            # A URL to an icon representing this module.
            # IconUri = ''

            # ReleaseNotes of this module
            # ReleaseNotes = ''
        } # End of PSData hashtable
    } # End of PrivateData hashtable

    # HelpInfo URI of this module
    # HelpInfoURI = ''

    # Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
    # DefaultCommandPrefix = ''

}
