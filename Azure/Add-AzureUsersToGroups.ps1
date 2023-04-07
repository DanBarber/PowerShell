# Requires -PSEdition Desktop
# Requires -Modules AzureAD
<#
.SYNOPSIS
Processes the specified .csv file and adds the users to specified Azure AD Groups
.DESCRIPTION
Processes the specified .csv file and adds the users to specified Azure AD Groups, ensure you run Connect-AzureAD CMDlet prior to running this script
.EXAMPLE
./Add-AzureUsersToGroups.ps1 -CsvFilePath 'C:\SomePath\users.csv' -CsvDelimiter ','
.PARAMETER CsvFilePath
The full path to the .csv file to process
.PARAMETER CsvDelimiter
OPTIONAL: The delimiter used for the .csv file to be parsed, default value is comma delimited ','
#>

[CmdletBinding()]
param (
    # Path to Csv file
    [Parameter (Mandatory = $true)]
    [string] $CsvFilePath ,
    # Delimiter used within .csv, most commonly comma delimited is used
    [string] $CsvDelimiter = ',',
    # Delimiter used for delimiting Azure group Object IDs within GroupObjectID of .csv, default value is ';'
    [string]$AzureGroupDelimiter = ';'
)

<#
.SYNOPSIS
    Imports CSV data and parses each user row into a collection of PSObjects
.DESCRIPTION
    Imports CSV data and parses each user row into a collection of PSObjects
.EXAMPLE
    Import-CsvData -CsvFilePath $CsvPath -CsvDelimiter $CsvDelimiter
.PARAMETER CsvFilePath
    The full path to the .csv file to process
.PARAMETER CsvDelimiter
    The delimiter used for the .csv file to be parsed
#>
Function Import-CsvData {
    [CmdletBinding()]
    [OutputType([System.Object[]])]
    param (
        [Parameter (Mandatory = $true)]
        [string] $CsvFilePath,
        [Parameter (Mandatory = $true)]
        [string] $CsvDelimiter
    )

    # Create arraylist to store objects
    [System.Collections.ArrayList]$usersCollection = @()

    # Import CSV data
    Import-Csv -Path $CsvFilePath -Delimiter $CsvDelimiter | ForEach-Object {

        # Initialize PSObject
        $userObject = New-Object -TypeName PSObject

        # Add required values from CSV
        $userObject | Add-Member -MemberType NoteProperty -Name 'ObjectId' -Value $_.ObjectId
        $userObject | Add-Member -MemberType NoteProperty -Name 'UserPrincipalName' -Value $_.UserPrincipalName
        $userObject | Add-Member -MemberType NoteProperty -Name 'GroupObjectID' -Value $_.GroupObjectID

        # Add our userObject to our collection of objects
        $usersCollection.Add($userObject)
    }
    return $usersCollection

}

<#
.SYNOPSIS
    Processes a collection of PSObjects and assigns the user to Azure AD group(s)
.DESCRIPTION
    Processes a collection of PSObjects and assigns the user to Azure AD group(s)
.EXAMPLE
    Add-UsersToAzureADGroups -UsersObjet $UsersObject
.PARAMETER UsersObject
    PSObject containing a collection of user metadata
.PARAMETER AzureGroupDelimiter
    The delimiter used for delimiting Azure group Object IDs
#>
Function Add-UsersToAzureADGroup {
    [CmdletBinding()]
    param (
        [Parameter (Mandatory = $true)]
        [System.Object[]] $UsersObject,
        [Parameter (Mandatory = $true)]
        [string]$AzureGroupDelimiter
    )

    # Parse user parameters and add the user to azure
    foreach($user in $UsersObject) {

        # Split our Azure AD groups using our defined delimiter
        $AzureGroups = $user.GroupObjectID.Split($AzureGroupDelimiter)

        # Add the user to all groups
        foreach($group in $AzureGroups) {
            try {
                Add-AzureADGroupMember -ObjectId $group -RefObjectId $user.ObjectId
            } catch {
                Write-Warning "Error adding user $($user.UserPrincipalName) to Azure Group $group. $_"
            }
        }
    }
}

$userCollection = Import-CsvData -CsvFilePath $CsvFilePath -CsvDelimiter $CsvDelimiter
Add-UsersToAzureADGroup -UsersObject $userCollection -AzureGroupDelimiter $AzureGroupDelimiter