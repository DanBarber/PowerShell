# Requires -PSEdition Desktop
# Requires -Modules AzureAD
<#
.SYNOPSIS
    Processes the specified .csv file and adds the users to Azure AD
.DESCRIPTION
    Processes the specified .csv file and adds the users to Azure AD, ensure you run Connect-AzureAD CMDlet prior to running this script
.EXAMPLE
    ./Add-AzureUsers.ps1 -CsvFilePath 'C:\SomePath\users.csv' -CsvDelimiter ','
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
    [string] $CsvDelimiter = ','
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
        if ($_.'Name [displayName] Required' -ne "") {$userObject | Add-Member -MemberType NoteProperty -Name 'DisplayName' -Value $_.'Name [displayName] Required'} else {Write-Error "CSV field 'Name [displayName] Required' cannot be empty." -ErrorAction Stop}
        if ($_.'User name [userPrincipalName] Required' -ne "") {$userObject | Add-Member -MemberType NoteProperty -Name 'Username' -Value $_.'User name [userPrincipalName] Required'} else {Write-Error "CSV field 'User name [userPrincipalName] Required' cannot be empty." -ErrorAction Stop}
        if ($_.'Initial password [passwordProfile] Required' -ne "") {$userObject | Add-Member -MemberType NoteProperty -Name 'Password' -Value $_.'Initial password [passwordProfile] Required'} else {Write-Error "CSV field 'Initial password [passwordProfile] Required' cannot be empty." -ErrorAction Stop}
        if ($_.'Email' -ne "") {$userObject | Add-Member -MemberType NoteProperty -Name 'Email' -Value $_.'Email'} else {Write-Error "CSV field 'Email' cannot be empty." -ErrorAction Stop}
        $userObject | Add-Member -MemberType NoteProperty -Name 'FirstName' -Value $_.'First name [givenName]'
        $userObject | Add-Member -MemberType NoteProperty -Name 'LastName' -Value $_.'Last name [surname]'
        $userObject | Add-Member -MemberType NoteProperty -Name 'JobTitle' -Value $_.'Job title [jobTitle]'
        $userObject | Add-Member -MemberType NoteProperty -Name 'Department' -Value $_.'Department [department]'
        $userObject | Add-Member -MemberType NoteProperty -Name 'UsageLocation' -Value $_.'Usage location [usageLocation]'
        $userObject | Add-Member -MemberType NoteProperty -Name 'StreetAddress' -Value $_.'Street address [streetAddress]'
        $userObject | Add-Member -MemberType NoteProperty -Name 'State' -Value $_.'State or province [state]'
        $userObject | Add-Member -MemberType NoteProperty -Name 'Country' -Value $_.'Country or region [country]'
        $userObject | Add-Member -MemberType NoteProperty -Name 'Office' -Value $_.'Office [physicalDeliveryOfficeName]'
        $userObject | Add-Member -MemberType NoteProperty -Name 'City' -Value $_.'City [city]'
        $userObject | Add-Member -MemberType NoteProperty -Name 'Zip' -Value $_.'ZIP or postal code [postalCode]'
        $userObject | Add-Member -MemberType NoteProperty -Name 'OfficePhone' -Value $_.'Office phone [telephoneNumber]'
        $userObject | Add-Member -MemberType NoteProperty -Name 'MobilePhone' -Value $_.'Mobile phone [mobile]'

        # Add our userObject to our collection of objects
        $usersCollection.Add($userObject)
    }
    return $usersCollection

}

<#
.SYNOPSIS
    Processes a collection of PSObjects and creates the user in Azure AD
.DESCRIPTION
    Processes a collection of PSObjects and creates the user in Azure AD
.EXAMPLE
    Add-UsersToAzureAD -UsersObject $UsersObject
.PARAMETER UsersObject
    PSObject containing a collection of user metadata
#>
Function Add-UsersToAzureAD {
    [CmdletBinding()]
    param (
        [Parameter (Mandatory = $true)]
        [System.Object[]] $UsersObject
    )

    # Parse user parameters and add the user to azure
    foreach($user in $UsersObject) {

    # Set Azure Password profile
    $PasswordProfile = New-Object -TypeName Microsoft.Open.AzureAD.Model.PasswordProfile
    $PasswordProfile.Password = $user.Password

    # Parse mail nickname from users Email field
    $mailNickname = ($user.Email).split("@")


    # Add our mandatory parameters into our parameter hashtable
    $parameters = @{
        DisplayName = $user.DisplayName
        UserPrincipalName = $user.Username
        PasswordProfile = $PasswordProfile
        AccountEnabled = $true
        MailNickName = $mailNickname[0]
    }

    # Add any optional parameters if applicable
    if (![string]::IsNullOrEmpty($user.Company)) {$parameters.Add("Company", $user.Company)}
    if (![string]::IsNullOrEmpty($user.FirstName)) {$parameters.Add("GivenName", $user.FirstName)}
    if (![string]::IsNullOrEmpty($user.LastName)) {$parameters.Add("Surname", $user.LastName)}
    if (![string]::IsNullOrEmpty($user.JobTitle)) {$parameters.Add("JobTitle", $user.JobTitle)}
    if (![string]::IsNullOrEmpty($user.Department)) {$parameters.Add("Department", $user.Department)}
    if (![string]::IsNullOrEmpty($user.Email)) {$parameters.Add("OtherMails", $user.Email)}

    # Attempt to add new user to AzureAD
    try {
        New-AzureADUser @parameters
    } catch {
        Write-Warning "An error occured. $_"
    }
  }
}

$userCollection = Import-CsvData -CsvFilePath $CsvFilePath -CsvDelimiter $CsvDelimiter
Add-UsersToAzureAD -UsersObject $userCollection