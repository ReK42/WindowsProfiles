Set-Alias sudo gsudo -Option ReadOnly  # https://github.com/gerardog/gsudo
Set-Alias grep Select-String -Option ReadOnly
Set-Alias ll Get-ChildItem -Option ReadOnly
Set-Alias sublime "$($Env:ProgramFiles)\Sublime Text 3\sublime_text.exe" -Option ReadOnly
Set-Alias vim "$($Env:ProgramFiles)\Vim\vim82\vim.exe"

Function Prompt() {
    $AdminRole = [Security.Principal.WindowsBuiltInRole]::Administrator
    $Identity = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
    $PromptPWD = $PWD.ProviderPath.replace($Env:UserProfile, "~")

    Write-Host "[" -NoNewLine
    Write-Host $Env:UserName -NoNewLine -ForegroundColor "Green"
    Write-Host "@" -NoNewLine
    Write-Host $Env:ComputerName -NoNewLine -ForegroundColor "Green"
    Write-Host " " -NoNewLine
    Write-Host $PromptPWD -NoNewLine -ForegroundColor "Blue"
    Write-Host "]" -NoNewLine
    if ($Identity.IsInRole($AdminRole)) {
        Write-Host "#" -NoNewLine -ForegroundColor "Red"
    } else {
        Write-Host "$" -NoNewLine
    }
    return " "
}

Function Compare-FileHash {
    <#
    .SYNOPSIS
    Compare a file's hash to a string or another file
    #>

    param (
        [cmdletbinding(
            DefaultParameterSetName="String"
        )]

        [Parameter(
            Mandatory=$false,
            HelpMessage='Hash algorithm to use'
        )]
        [ValidateSet(
            "SHA1",
            "SHA256",
            "SHA384",
            "SHA512",
            "MACTripleDES",
            "MD5",
            "RIPEMD160"
        )]
        [System.String]$Algorithm = "SHA256",

        [Parameter(
            Position=0,
            Mandatory=$true,
            HelpMessage='File path'
        )]
        [ValidateNotNullOrEmpty()]
        [System.IO.FileInfo]$Path1,

        [Parameter(
            Position=1,
            Mandatory=$true,
            HelpMessage='Hash string to compare against',
            ParameterSetName="String",
            ValueFromPipeline=$true
        )]
        [ValidateNotNullOrEmpty()]
        [System.String]$Hash,

        [Parameter(
            Position=1,
            Mandatory=$true,
            HelpMessage='File to compare against',
            ParameterSetName="File",
            ValueFromPipeline=$true
        )]
        [ValidateNotNullOrEmpty()]
        [System.IO.FileInfo]$Path2
    )

    [hashtable]$Return = @{}
    $Return.Algorithm = $Algorithm
    $Return.File1Hash = (Get-FileHash -Algorithm "$Algorithm" -Path "$Path1").Hash.Trim().ToLower()
    if($Hash) {
        $Return.Hash = $Hash.Trim().ToLower()
        $Return.Match = ($Return.File1Hash -eq $Return.Hash)
    } else {
        $Return.File2Hash = (Get-FileHash -Algorithm "$Algorithm" -Path "$Path2").Hash.Trim().ToLower()
        $Return.Match = ($Return.File1Hash -eq $Return.File2Hash)
    }
    return $Return
}

Function Get-UserPrincipalName {
    <#
    .SYNOPSIS
    Get the current user's user principal name attribute from LDAP
    #>

    $obj = New-Object System.DirectoryServices.DirectorySearcher
    $obj.SearchRoot = (New-Object System.DirectoryServices.DirectoryEntry)
    $obj.PageSize = 1
    $obj.Filter = "(&(objectCategory=User)(sAMAccountName=$env:USERNAME))"
    $obj.SearchScope = "Subtree"
    $obj.PropertiesToLoad.Add("userPrincipalName") | Out-Null
    return $obj.FindAll()[0].Properties.userprincipalname
}

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
Set-Alias wc Count-Lines -Option ReadOnly

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
Set-Alias head Get-ContentHead -Option ReadOnly

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
Set-Alias tail Get-ContentTail -Option ReadOnly
