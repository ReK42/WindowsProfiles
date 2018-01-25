# https://github.com/Pscx/Pscx.git
# Use latest release tag, e.g. v3.3.2
Import-Module Pscx

# https://github.com/jasonmarcher/PowerTab
# Use branch powershell-core-compatibility
Import-Module PowerTab -ArgumentList "$($Env:UserProfile)\Documents\WindowsPowerShell\PowerTabConfig.xml"

Function Get-UserPrincipalName {
	<#
	.SYNOPSIS
	Get the current user's user principal name attribute from LDAP
	#>

	$obj = New-Object System.DirectoryServices.DirectorySearcher
	$obj.SearchRoot = (New-Object System.DirectoryServices.DirectoryEntry)
	$obj.PageSize = 1
	$obj.Filter = “(&(objectCategory=User)(sAMAccountName=$env:USERNAME))”
	$obj.SearchScope = “Subtree”
	$obj.PropertiesToLoad.Add(“userPrincipalName”) | Out-Null
	return $obj.FindAll()[0].Properties.userprincipalname
}
Set-Alias -Name gupn -Value Get-UserPrincipalName -Option ReadOnly

Function Count-Lines {
	<#
	.SYNOPSIS
	Count the number of lines in a text file
	#>

	param (
		[Parameter(
			Mandatory=$true,
			ValueFromPipeline=$true,
			HelpMessage='File path'
		)][ValidateNotNullOrEmpty()][System.IO.FileInfo]$Path
	)

	# https://stackoverflow.com/a/34255890
	$count = 0
	Get-Content -Path $Path -ReadCount 1000 | ForEach-Object {
		$count += $_.Count
	}
	Write-Output $count
}
Set-Alias -Name wc -Value Count-Lines -Option ReadOnly

Function Get-ContentHead {
	<#
	.SYNOPSIS
	Display a number of lines from the start of a text file
	#>

	param (
		[Parameter(
			Mandatory=$true,
			ValueFromPipeline=$true,
			HelpMessage='File path'
		)][ValidateNotNullOrEmpty()][System.IO.FileInfo]$Path,
		[Parameter(
			Mandatory=$false,
			HelpMessage='Number of lines'
		)][ValidateNotNullOrEmpty()][Int]$Lines = 10
	)

	Get-Content -Path $Path -TotalCount $Lines
}
Set-Alias -Name head -Value Get-ContentHead -Option ReadOnly

Function Get-ContentTail {
	<#
	.SYNOPSIS
	Display a number of lines from the end of a text file
	#>

	param (
		[Parameter(
			Mandatory=$true,
			ValueFromPipeline=$true,
			HelpMessage='File path'
		)][ValidateNotNullOrEmpty()][System.IO.FileInfo]$Path,
		[Parameter(
			Mandatory=$false,
			HelpMessage='Number of lines'
		)][ValidateNotNullOrEmpty()][Int]$Lines = 10,
		[Parameter(
			Mandatory=$false,
			HelpMessage='Continue to follow'
		)][Switch]$Follow
	)

	if($Follow) {
		Get-Content -Path $Path -Tail $Lines -Wait
	} else {
		Get-Content -Path $Path -Tail $Lines
	}
}
Set-Alias -Name tail -Value Get-ContentTail -Option ReadOnly

Set-Alias -Name grep -Value Select-String -Option ReadOnly
Set-Alias -Name ll -Value Get-ChildItem -Option ReadOnly
