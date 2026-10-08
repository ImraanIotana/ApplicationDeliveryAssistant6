####################################################################################################
<#
.SYNOPSIS
    This data file contains settings for the Application Delivery Assistant.
.DESCRIPTION
    This data is self-contained and does not refer to functions, variables or classes, that are in other files.
.NOTES
    Version         : 6.9.1
    Author          : Imraan Iotana
    Creation Date   : May 2026
    Last Update     : October 2026
#>
####################################################################################################

@{
    # USER SETTINGS
    # Set the Registry path for the User Settings
    UserSettingsRegistryPath = 'HKCU:\Software\Application Delivery Assistant\UserSettings'

    # UPDATE SETTINGS
    # URL of the zip file on GitHub where the latest version of the Application Delivery Assistant can be found
    ZipFileOnGithub     = 'https://github.com/ImraanIotana/ApplicationDeliveryAssistant6/archive/refs/heads/main.zip'
    # URL of the raw StartAssistant.ps1 on GitHub, which contains the version number of the latest version of the Application Delivery Assistant
    VersionFileOnGithub = 'https://raw.githubusercontent.com/ImraanIotana/ApplicationDeliveryAssistant6/main/StartAssistant.ps1'
}