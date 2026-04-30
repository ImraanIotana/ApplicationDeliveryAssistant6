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
    # GRAPHICAL SETTINGS
    # Assemblies needed for graphics (Forms, Fonts)
    Assemblies          = @('System.Windows.Forms','System.Drawing')

    # Font settings
    MainFont            = @{
        Name            = 'Calibri' # Name of the font used in the GUI of this application
        Size            = 11        # Size of the font used in the GUI of this application
    }

    # MainForm settings
    MainForm            = @{
        IconFileName    = 'KPN.ico' # The name of the icon file for the Main Form
        Width           = 800       # Width of the Main Form
        Height          = 600       # Height of the Main Form
    }

    # MainTabControl settings
    MainTabControl      = @{
        TopMargin       = 5         # Between the top of the Form, and the top of the TabControl
        LeftMargin      = 5         # Between the left of the Form, and the left of the TabControl
        BottomMargin    = 50        # Between the bottom of the Form, and the bottom of the TabControl
        RightMargin     = 25        # Between the right of the Form, and the right of the TabControl
    }

    <# GroupBox settings (# This will be filled by the function Add-GraphicalDimensionsToSettings)
    GroupBox            = @{
        RowHeight       = 40        # Height of the rows inside the GroupBox
        RightMargin     = 15        # Between the right of the GroupBox Parent, and the right of the GroupBox
        SubTabMargin    = 3         # If the GroupBox is placed in a SubTab, then this value is added to the RightMargin
        BetweenMargin   = 4         # Between two GroupBoxes on top of each other
        OneRowMargin    = 7         # Extra margin if a GroupBox has only 1 row
    }

    # TextBox settings
    TextBox             = @{
        Height          = 30        # Height of the TextBoxes and ComboBoxes
        TopMargin       = 13
        LeftMargin      = 200
        RightMargin     = 15
    }

    # Label settings
    Label               = @{
        LeftMargin      = 5         # Between the left of the Parent, and the left of the Label
    }

    # Button settings (# This will be filled by the function Add-GraphicalDimensionsToSettings)
    Button              = @{
    }

    # ColumnNumber settings (# This will be filled by the function Add-GraphicalDimensionsToSettings)
    ColumnNumber        = @{
    }

    # UPDATE SETTINGS
    # URL of the zip file on GitHub where the latest version of the Application Delivery Assistant can be found
    ZipFileOnGithub     = 'https://github.com/ImraanIotana/ADA6/archive/refs/heads/main.zip'
    # URL of the version file on GitHub where the version number of the latest version of the Application Delivery Assistant can be found
    VersionFileOnGithub = 'https://github.com/ImraanIotana/ADA6/blob/main/ApplicationDeliveryAssistant.ps1'#>
}