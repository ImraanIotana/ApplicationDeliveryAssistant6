####################################################################################################
<#
.SYNOPSIS
    This data file contains settings for the Application Delivery Assistant.
.DESCRIPTION
    This data is self-contained and does not refer to functions, variables or classes, that are in other files.
.NOTES
    Version         : 6.0.0
    Author          : Imraan Iotana
    Creation Date   : May 2026
    Last Update     : May 2026
#>
####################################################################################################

@{
    # GENERAL SETTINGS

    # Set the Identity Property of the Customer
    Identity = 'KPN - Hema'

    # APPLICATION INTAKE SETTINGS

    # Set the default template name for the Application Intake
    TemplateName = 'KPN Dossier KPNHema.dotx'

    # Set the name of the Universal Deployment Framework (UDF) zip file
    UDFName = 'UniversalDeploymentFramework.zip'

    # Set the subfolders for the Application Folder
    ApplicationFolderSubFolders = @{
        Documentation   = '1. Documentation'
        SourceFiles     = '2. SourceFiles'
        Package         = '3. Package'
        SCCMPackage     = '3. Package\SCCM'
        Security        = '4. Security'
        AppLocker       = '4. Security\AppLocker'
        Work            = '8. Work'
        Archive         = '9. Archive'
        Logs            = '9. Archive\Logs'
        Metadata        = '9. Archive\Metadata'
        Screenshots     = '9. Archive\Screenshots'
        Shortcuts       = '9. Archive\Shortcuts'
        Other           = '9. Archive\Other'
    }

    # APPLOCKER SETTINGS
    # Set the default AppLocker settings
    AppLockerDefaultSettings    = @{
        DevelopmentURL          = 'LDAP://servername.domain.nl/CN={DEVELOPM-75F6-4AA2-89D0-034917004AA3},CN=Policies,CN=System,DC=domain,DC=nl'
        TestURL                 = 'LDAP://servername.domain.nl/CN={TEST1234-ABCD-4AA2-89D0-034917004AA3},CN=Policies,CN=System,DC=domain,DC=nl'
        AcceptanceURL           = 'LDAP://servername.domain.nl/CN={ACCEPTAN-1234-4AA2-89D0-034917004AA3},CN=Policies,CN=System,DC=domain,DC=nl'
        ProductionURL           = 'LDAP://servername.domain.nl/CN={PRODUCTI-6098-4CBA-9233-E1512BF88ABA},CN=Policies,CN=System,DC=domain,DC=nl'
    }
}