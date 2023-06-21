# Chocolatey profile
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
  Import-Module "$ChocolateyProfile"
}

Set-Alias sudo gsudo -Option ReadOnly  # https://github.com/gerardog/gsudo
Set-Alias grep Select-String -Option ReadOnly
Set-Alias ll Get-ChildItem -Option ReadOnly
Set-Alias sublime "$($Env:ProgramFiles)\Sublime Text\sublime_text.exe" -Option ReadOnly
Set-Alias vim "$($Env:ProgramFiles)\Vim\vim82\vim.exe" -Option ReadOnly

function CustomizeConsole {
  $hosttime = (Get-ChildItem -Path $PSHOME\pwsh.exe).CreationTime
  $hostversion="$($Host.Version.Major)`.$($Host.Version.Minor)"
  $Host.UI.RawUI.WindowTitle = "PowerShell $hostversion ($hosttime)"
  Clear-Host
  pfetch  # https://github.com/Gobidev/pfetch-rs
}
CustomizeConsole

Function Prompt() {
    $AdminRole = [Security.Principal.WindowsBuiltInRole]::Administrator
    $Identity = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
    $PromptCWD = $PWD.ProviderPath.replace($Env:UserProfile, "~")

    Write-Host "[" -NoNewLine
    Write-Host $Env:UserName -NoNewLine -ForegroundColor "Green"
    Write-Host "@" -NoNewLine
    Write-Host $Env:ComputerName -NoNewLine -ForegroundColor "Green"
    Write-Host " " -NoNewLine
    Write-Host $PromptCWD -NoNewLine -ForegroundColor "Blue"
    Write-Host "]" -NoNewLine
    if ($Identity.IsInRole($AdminRole)) {
        Write-Host "#" -NoNewLine -ForegroundColor "Red"
    } else {
        Write-Host "$" -NoNewLine
    }
    return " "
}

# Configure highlighting for dark terminal themes
$Host.PrivateData.ErrorForegroundColor = "Red"
$Host.PrivateData.WarningForegroundColor = "Yellow"
$Host.PrivateData.DebugForegroundColor = "Green"
$Host.PrivateData.VerboseForegroundColor = "Blue"
$Host.PrivateData.ProgressForegroundColor = "Gray"
$Host.PrivateData.ErrorBackgroundColor = "DarkGray"
$Host.PrivateData.WarningBackgroundColor = "DarkGray"
$Host.PrivateData.DebugBackgroundColor = "DarkGray"
$Host.PrivateData.VerboseBackgroundColor = "DarkGray"
$Host.PrivateData.ProgressBackgroundColor = "Cyan"
$PSReadLineOptions = Get-PSReadLineOption
$PSReadLineOptions.CommandColor = "Yellow"
$PSReadLineOptions.ContinuationPromptColor = "DarkBlue"
$PSReadLineOptions.DefaultTokenColor = "DarkBlue"
$PSReadLineOptions.EmphasisColor = "Cyan"
$PSReadLineOptions.ErrorColor = "Red"
$PSReadLineOptions.KeywordColor = "Green"
$PSReadLineOptions.MemberColor = "DarkCyan"
$PSReadLineOptions.NumberColor = "DarkCyan"
$PSReadLineOptions.OperatorColor = "DarkGreen"
$PSReadLineOptions.ParameterColor = "DarkGreen"
$PSReadLineOptions.StringColor = "Blue"
$PSReadLineOptions.TypeColor = "DarkYellow"
$PSReadLineOptions.VariableColor = "Green"

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

Function Open-WTSSH {
    <#
    .SYNOPSIS
    Launch OpenSSH in a Windows Terminal tab
    #>

    $Title = 'OpenSSH'
    $Skip = $false
    $CustomTitle = $false
    $RemoveArgs = @()
    ForEach($arg in $args) {
        if($Skip) {
            $Skip = $false
            Continue
        }
        if($CustomTitle) {
            $Title = $arg
            $RemoveArgs += $arg
            Break
        }
        if($arg.StartsWith('-')) {
            if($arg.ToLower() -eq '-t' -or $arg.ToLower() -eq '--title') {
                $CustomTitle = $true
                $RemoveArgs += $arg
                Continue
            } else {
                $Skip = $true
                Continue
            }
        }
        if($arg.Contains('@')) {
            $Title = "$(($arg -split '@')[1])"
        } else {
            $Title = "$arg"
        }
        Break
    }

    $FilteredArgs = $args | Where-Object {$RemoveArgs -notcontains $_}
    $ArgumentList = @(
        "--window 0",
        "new-tab",
        "--profile OpenSSH",
        "--title `"$Title`"",
        "ssh $FilteredArgs"
    )
    Start-Process wt -ArgumentList $ArgumentList
}
Set-Alias wtssh Open-WTSSH -Option ReadOnly

Function Open-WTCOM {
    <#
    .SYNOPSIS
    Launch WSL minicom in a Windows Terminal tab
    #>

    param (
        [Parameter(
            Mandatory=$false,
            ValueFromPipeline=$true,
            HelpMessage='COM port to connect to'
        )][ValidateNotNullOrEmpty()][Int]$Port = 4,
        [Parameter(
            Mandatory=$false,
            HelpMessage='WSL distribution to launch'
        )][ValidateNotNullOrEmpty()][System.String]$Distribution = 'debian'
    )

    # Get a list of available WSL distributions
    $Distributions = @()
    (wsl --list --verbose) | Select-Object -Skip 1 | Where-Object Length -GT 1 | ForEach-Object {
        $Distributions += ($_.Split(' ') | Where-Object Length -GT 1)[1].ToLower()
    }

    # Make sure the requested distribution is availble
    if($Distributions -contains $Distribution.ToLower()) {
        $ArgumentList = @(
            "new-tab",
            "--profile minicom",
            "--title COM$Port",
            "wsl --distribution $Distribution minicom --color=on --device /dev/ttyS$Port"
        )
        Start-Process wt -ArgumentList $ArgumentList
    } else {
        Write-Error "Distribution $Distribution not found"
    }
}
Set-Alias wtcom Open-WTCOM -Option ReadOnly
