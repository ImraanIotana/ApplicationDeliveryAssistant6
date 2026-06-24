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
        '2. Request Source files' = @{
            Subject = 'Intake APPNAME - (REFERENCENUMBER)'
            Body    = 'Hallo NAAM,

(Ik zal me even kort voorstellen. Ik ben een nieuwe collega van o.a. Daniel/Olaf, en houd me ook bezig met de Intake van applicaties voor de AVD/DWR/MWP.)

Ik mail in verband met de applicatie: APPNAME

Ik wil hier graag de Intake van oppakken, en ben op zoek naar de Bron-software.
Ik wilde vragen of deze kan worden aangeleverd (Dit kan bijvoorbeeld via FTP, of KPN File Transfer)

Als er vragen of onduidelijkheden zijn, laat het me gerust weten.

Groet,
Imraan'
        }
        '3. Request Intake Approval' = @{
            Subject = 'Goedkeuring Intakedocument APPNAME - (REFERENCENUMBER)'
            Body    = 'Hallo NAAM,

Het Intake document van de applicatie APPNAME is gereed voor goedkeuring.
Het document is te vinden in de bijlage van deze mail.

Ik wilde vragen of je specifiek het Testplan (Hoofdstuk 6) wil controleren en goedkeuren.

Mocht je in de installatie of configuratie van de applicatie nog zaken tegenkomen die niet correct zijn, kun je dit aangeven. Ik zal dit dan verwerken in het Intake document.

Als er vragen of onduidelijkheden zijn, laat het me gerust weten.

Groet,
Imraan'
        }
        '4. Intake Reminder' = @{
            Subject = 'TEST: Intake Reminder Subject'
            Body    = 'TEST: Intake Reminder Body'
        }
    }
}