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
    Identity = 'Default'

    # APPLICATION INTAKE SETTINGS
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
}