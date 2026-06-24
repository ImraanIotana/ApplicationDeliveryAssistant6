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
    Identity = 'KPN - Antea SGD'

    # APPLICATION INTAKE SETTINGS

    # Set the default template name for the Application Intake
    TemplateName = 'KPN Dossier KPNAnteaSGD.dotx'

    # Set the name of the Universal Deployment Framework (UDF) zip file
    UDFName = 'UniversalDeploymentFramework.zip'

    # Set the subfolders for the Application Folder
    ApplicationFolderSubFolders = @{
        Documentation   = '1. Documentation'
        SourceFiles     = '2. SourceFiles'
        Archive         = '9. Archive'
        Metadata        = '9. Archive\Metadata'
        Screenshots     = '9. Archive\Screenshots'
        Shortcuts       = '9. Archive\Shortcuts'
        Other           = '9. Archive\Other'
    }

    MailTemplates = @{
        '1. Introductory Mail' = @{
            Subject = 'TEST: Introductory Mail Subject'
            Body    = 'TEST: Introductory Mail Body'
        }
        '2. Intake Approval'     = @{
            Subject = 'TEST: Intake Approval Subject'
            Body    = 'TEST: Intake Approval Body'
        }
        '3. Intake Reminder'     = @{
            Subject = 'TEST: Intake Reminder Subject'
            Body    = 'TEST: Intake Reminder Body'
        }
    }
}