$Host.UI.RawUI.WindowTitle = "PowerShell $($Host.Version.Major).$($Host.Version.Minor)"
Clear-Host
pfetch  # https://github.com/Gobidev/pfetch-rs

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
    }
    else {
        Write-Host "$" -NoNewLine
    }
    return " "
}

# Chocolatey profile
$ChocolateyProfile = "$($Env:ChocolateyInstall)\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
    Import-Module "$ChocolateyProfile"
}

# gsudo module and alias
Import-Module "gsudoModule"
Set-Alias sudo gsudo -Option ReadOnly  # https://github.com/gerardog/gsudo

# Other aliases
Set-Alias grep Select-String -Option ReadOnly
Set-Alias ll Get-ChildItem -Option ReadOnly
Set-Alias sublime "$($Env:ProgramFiles)\Sublime Text\sublime_text.exe" -Option ReadOnly
Set-Alias subl sublime -Option ReadOnly
Set-Alias vim "$($Env:ProgramFiles)\Vim\vim82\vim.exe" -Option ReadOnly

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
    Compare a file's hash to another file or a string
    #>

    param (
        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Hash algorithm to use'
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
            Position = 0,
            Mandatory = $true,
            HelpMessage = 'File path',
            ValueFromPipeline = $true
        )]
        [ValidateNotNullOrEmpty()]
        [System.IO.FileInfo]$Path,

        [Parameter(
            Position = 1,
            Mandatory = $true,
            HelpMessage = 'File or hash string to compare against'
        )]
        [ValidateNotNullOrEmpty()]
        [System.String]$Compare
    )

    $Hash1 = (Get-FileHash -Algorithm "$Algorithm" -Path "$Path").Hash.Trim().ToLower()
    if (Test-Path -Path $Compare -PathType Leaf) {
        $Hash2 = (Get-FileHash -Algorithm "$Algorithm" -Path "$Compare").Hash.Trim().ToLower()
    } elseif ($Compare -match '^[0-9a-fA-F]+$') {
        $Hash2 = $Compare.Trim().ToLower()
    }
    if ([Environment]::UserInteractive -and -not ([Environment]::GetCommandLineArgs() | Where-Object {$_ -like "-NonI*"})) {
        Write-Host "Algorithm: $Algorithm"
        Write-Host "Hash 1   : $Hash1"
        Write-Host "Hash 2   : $Hash2"
        Write-Host "Match    : " -NoNewLine
    }
    return ($Hash1 -eq $Hash2)
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
            Mandatory = $true,
            ValueFromPipeline = $true,
            HelpMessage = 'File path'
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
            Mandatory = $true,
            ValueFromPipeline = $true,
            HelpMessage = 'File path'
        )][ValidateNotNullOrEmpty()][System.IO.FileInfo]$Path,
        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Number of lines'
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
            Mandatory = $true,
            ValueFromPipeline = $true,
            HelpMessage = 'File path'
        )][ValidateNotNullOrEmpty()][System.IO.FileInfo]$Path,
        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Number of lines'
        )][ValidateNotNullOrEmpty()][Int]$Lines = 10,
        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Continue to follow'
        )][Switch]$Follow
    )

    if ($Follow) {
        Get-Content -Path $Path -Tail $Lines -Wait
    }
    else {
        Get-Content -Path $Path -Tail $Lines
    }
}
Set-Alias tail Get-ContentTail -Option ReadOnly



Function Open-WTSSH {
    <#
    .SYNOPSIS
    Launch OpenSSH in a Windows Terminal tab
    #>

    $SSHArgumentList = @()
    $CustomTitleNext = $false
    $ParameterNext = $false
    $Title = 'OpenSSH'
    ForEach ($arg in $args) {
        $arg_s = $arg.ToString()
        if ($CustomTitleNext) {
            $CustomTitleNext = $false
            $Title = $arg_s
        }
        elseif ($arg_s.StartsWith('ssh://')) {
            # Strip the protocol prefix and any trailing /
            $URL = ($arg_s -replace '^ssh://(.*)$', '$1').TrimEnd('/')
            if ($URL.Contains(':')) {
                $URL, $Port = $URL -split ':'
                $SSHArgumentList += '-p'
                $SSHArgumentList += $Port
            }
            if ($Title -eq 'OpenSSH') {
                $Title = $URL
            }
            $SSHArgumentList += $URL
        }
        elseif ($arg_s.StartsWith('-')) {
            if ($arg_s.ToLower() -in '-t', '--title') {
                $CustomTitleNext = $true
            }
            else {
                $ParameterNext = $true
                $SSHArgumentList += $arg_s
            }
        }
        else {
            if ($ParameterNext) {
                $ParameterNext = $false
            }
            else {
                if ($Title -eq 'OpenSSH') {
                    $Title = $arg_s
                }
            }
            $SSHArgumentList += $arg_s
        }
    }

    $WTArgumentList = @(
        "--window 0",
        "new-tab",
        "--profile OpenSSH",
        "--title `"$Title`"",
        "ssh $SSHArgumentList"
    )
    Start-Process wt -ArgumentList $WTArgumentList
}
Set-Alias wtssh Open-WTSSH -Option ReadOnly



Function Open-WTTelnet {
    <#
    .SYNOPSIS
    Launch Telnet in a Windows Terminal tab
    #>

    $TelnetArgumentList = @('-telnet')
    $CustomTitleNext = $false
    $ParameterNext = $false
    $Title = 'Telnet'
    ForEach ($arg in $args) {
        if ($CustomTitleNext) {
            $CustomTitleNext = $false
            $Title = $arg
        }
        elseif ($arg -is [string] -and $arg.StartsWith('telnet://')) {
            $Search = '^telnet://(?<user>.+@)?(?<host>.+?)(?<port>:.+)?$'
            $Groups = ([regex]::Matches($arg.TrimEnd('/'), $Search)).Groups
            ForEach ($Group in $Groups) {
                if ($Group.Name -eq 'user' -and $Group.Value.Length -gt 0) {
                    $TelnetArgumentList += '-l'
                    $TelnetArgumentList += $Group.Value.TrimEnd('@')
                }
                elseif ($Group.Name -eq 'host' -and $Group.Value.Length -gt 0) {
                    if ($Title -eq 'Telnet') {
                        $Title = $Group.Value
                    }
                    $TelnetArgumentList += $Group.Value
                }
                elseif ($Group.Name -eq 'port' -and $Group.Value.Length -gt 0) {
                    $TelnetArgumentList += '-P'
                    $TelnetArgumentList += $Group.Value.TrimStart(':')
                }
            }
        }
        elseif ($arg -is [string] -and $arg.StartsWith('-')) {
            if ($arg.ToLower() -eq '--title') {
                $CustomTitleNext = $true
            }
            else {
                $ParameterNext = $true
                $TelnetArgumentList += $arg
            }
        }
        else {
            if ($ParameterNext) {
                $ParameterNext = $false
            }
            else {
                if ($Title -eq 'Telnet') {
                    $Title = $arg
                }
            }
            $TelnetArgumentList += $arg
        }
    }

    $WTArgumentList = @(
        "--window 0",
        "new-tab",
        "--profile Telnet",
        "--title `"$Title`"",
        "plink $TelnetArgumentList"
    )
    Start-Process wt -ArgumentList $WTArgumentList
}
Set-Alias wttelnet Open-WTTelnet -Option ReadOnly



Function Open-WTCOM {
    <#
    .SYNOPSIS
    Launch WSL minicom in a Windows Terminal tab
    #>

    param (
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            HelpMessage = 'COM port to connect to'
        )][ValidateNotNullOrEmpty()][Int]$Port = 4,
        [Parameter(
            Mandatory = $false,
            HelpMessage = 'WSL distribution to launch'
        )][ValidateNotNullOrEmpty()][System.String]$Distribution = 'debian'
    )

    # Get a list of available WSL distributions
    $Distributions = @()
    (wsl --list --verbose) | Select-Object -Skip 1 | Where-Object Length -GT 1 | ForEach-Object {
        $Distributions += ($_.Split(' ') | Where-Object Length -GT 1)[1].ToLower()
    }

    # Make sure the requested distribution is availble
    if ($Distributions -contains $Distribution.ToLower()) {
        $ArgumentList = @(
            "new-tab",
            "--profile minicom",
            "--title COM$Port",
            "wsl --distribution $Distribution minicom --color=on --device /dev/ttyS$Port"
        )
        Start-Process wt -ArgumentList $ArgumentList
    }
    else {
        Write-Error "Distribution $Distribution not found"
    }
}
Set-Alias wtcom Open-WTCOM -Option ReadOnly
