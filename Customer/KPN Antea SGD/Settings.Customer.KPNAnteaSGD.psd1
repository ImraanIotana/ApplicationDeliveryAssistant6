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

    # APPLOCKER SETTINGS
    # Set the default AppLocker settings
    AppLockerDefaultSettings    = @{
        DevelopmentURL          = 'LDAP://servername.domain.nl/CN={DEVELOPM-75F6-4AA2-89D0-034917004AA3},CN=Policies,CN=System,DC=domain,DC=nl'
        TestURL                 = 'LDAP://servername.domain.nl/CN={TEST1234-ABCD-4AA2-89D0-034917004AA3},CN=Policies,CN=System,DC=domain,DC=nl'
        AcceptanceURL           = 'LDAP://servername.domain.nl/CN={ACCEPTAN-1234-4AA2-89D0-034917004AA3},CN=Policies,CN=System,DC=domain,DC=nl'
        ProductionURL           = 'LDAP://servername.domain.nl/CN={PRODUCTI-6098-4CBA-9233-E1512BF88ABA},CN=Policies,CN=System,DC=domain,DC=nl'
    }

    # MAIL TEMPLATES
    # Set the mail templates for the Application Intake process
    MailTemplates = @{
        '1. Introductory Mail' = @{
            Subject = 'Introductie Intake APPNAME - (REFERENCENUMBER)'
            Body    = 'Hallo NAAM,

Ik mail in verband met de applicatie: APPNAME

Ik wil hier graag de Intake van oppakken, en wilde graag een afspraak maken om de Intake te bespreken. Ik wilde vragen of je beschikbaar bent voor een korte call, zodat we de Intake kunnen doornemen.

Als er vragen of onduidelijkheden zijn, laat het me gerust weten.

Groet,
NAAM'
        }
        '2. Request Source files' = @{
            Subject = 'Intake APPNAME - (REFERENCENUMBER)'
            Body    = 'Hallo NAAM,

Ik mail in verband met de applicatie: APPNAME

Ik wil hier graag de Intake van oppakken, en ben op zoek naar de Bron-software.
Ik wilde vragen of deze kan worden aangeleverd (Dit kan bijvoorbeeld via FTP, of KPN File Transfer)

Als er vragen of onduidelijkheden zijn, laat het me gerust weten.

Groet,
NAAM'
        }
        '3. Request Intake Approval' = @{
            Subject = 'Goedkeuring Intakedocument APPNAME - (REFERENCENUMBER)'
            Body    = 'Hallo NAAM,

Het Intake document van de applicatie APPNAME is gereed voor goedkeuring. Het document is te vinden in de bijlage van deze mail.

Ik wilde vragen of je specifiek het Testplan (Hoofdstuk 6) wil controleren en goedkeuren. Je kunt dan simpelweg antwoorden op deze mail met een akkoord.

Mocht je in de Installatie of Configuratie van de applicatie nog zaken tegenkomen die niet correct zijn, kun je dit aangeven. Ik zal dit dan verwerken in het Intake document.

Als er vragen of onduidelijkheden zijn, laat het me gerust weten.

Groet,
NAAM'
        }
        '4. Intake Reminder' = @{
            Subject = 'Reminder Goedkeuring Intakedocument APPNAME - (REFERENCENUMBER)'
            Body    = 'Hallo NAAM,

Dit is een herinnering voor de intake van de applicatie APPNAME.

Als er vragen of onduidelijkheden zijn, laat het me gerust weten.

Groet,
NAAM'
        }
    }
}