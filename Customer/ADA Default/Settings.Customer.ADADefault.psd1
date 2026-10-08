####################################################################################################
<#
.SYNOPSIS
    This data file contains settings for the Application Delivery Assistant.
.DESCRIPTION
    This data is self-contained and does not refer to functions, variables or classes, that are in other files.
.NOTES
    Version         : 6.2.0
    Author          : Imraan Iotana
    Creation Date   : May 2026
    Last Update     : August 2026
#>
####################################################################################################

@{
    # GENERAL SETTINGS

    # Set the customer template schema and stable identity
    SchemaVersion = 2
    TemplateId    = '0b64193c-1f2c-4b87-902f-cca6871dc931'

    # Set the Identity Property of the Customer
    Identity = 'ADA - Default'

    # APPLICATION INTAKE SETTINGS

    # Set the default template name for the Application Intake
    TemplateName = 'Applicatie Dossier ADADefault.dotx'

    # Set the name of the Universal Deployment Framework (UDF) zip file
    UDFName = 'UniversalDeploymentFramework.zip'

    # Set the themed customer template component files
    Components = @{
        ApplicationFolderSubFolders = 'Settings.ApplicationFolders.psd1'
        AppLockerDefaultSettings    = 'Settings.AppLocker.psd1'
        MailTemplates               = 'Settings.MailTemplates.psd1'
    }
}