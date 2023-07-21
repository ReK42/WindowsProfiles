Clear-Host
pfetch
oh-my-posh init pwsh --config "$($Env:UserProfile)\.omp.yml" | Invoke-Expression

Import-Module "gsudoModule"
Set-Alias sudo gsudo -Option ReadOnly  # https://github.com/gerardog/gsudo
Set-Alias grep Select-String -Option ReadOnly
Set-Alias ll Get-ChildItem -Option ReadOnly
Set-Alias sublime "$($Env:ProgramFiles)\Sublime Text\sublime_text.exe" -Option ReadOnly
Set-Alias subl sublime -Option ReadOnly
Set-Alias vim "$($Env:ProgramFiles)\Vim\vim82\vim.exe" -Option ReadOnly

# Chocolatey profile
$ChocolateyProfile = "$($Env:ChocolateyInstall)\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
  Import-Module "$ChocolateyProfile"
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

    $SSHArgumentList = @()
    $CustomTitleNext = $false
    $ParameterNext = $false
    $Title = 'OpenSSH'
    ForEach($arg in $args) {
        if($CustomTitleNext) {
            $CustomTitleNext = $false
            $Title = $arg
        } elseif($arg.StartsWith('ssh://')) {
            # Strip the protocol prefix and any trailing /
            $URL = ($arg -replace '^ssh://(.*)$', '$1').TrimEnd('/')
            if($URL.Contains(':')) {
                $URL, $Port = $URL -split ':'
                $SSHArgumentList += '-p'
                $SSHArgumentList += $Port
            }
            if($Title -eq 'OpenSSH') {
                $Title = $URL
            }
            $SSHArgumentList += $URL
        } elseif($arg.StartsWith('-')) {
            if($arg.ToLower() -in '-t', '--title') {
                $CustomTitleNext = $true
            } else {
                $ParameterNext = $true
                $SSHArgumentList += $arg
            }
        } else {
            if($ParameterNext) {
                $ParameterNext = $false
            } else {
                if($Title -eq 'OpenSSH') {
                    $Title = $arg
                }
            }
            $SSHArgumentList += $arg
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
    ForEach($arg in $args) {
        if($CustomTitleNext) {
            $CustomTitleNext = $false
            $Title = $arg
        } elseif($arg -is [string] -and $arg.StartsWith('telnet://')) {
            $Search = '^telnet://(?<user>.+@)?(?<host>.+?)(?<port>:.+)?$'
            $Groups = ([regex]::Matches($arg.TrimEnd('/'), $Search)).Groups
            ForEach($Group in $Groups) {
                if($Group.Name -eq 'user' -and $Group.Value.Length -gt 0) {
                    $TelnetArgumentList += '-l'
                    $TelnetArgumentList += $Group.Value.TrimEnd('@')
                } elseif($Group.Name -eq 'host' -and $Group.Value.Length -gt 0) {
                    if($Title -eq 'Telnet') {
                        $Title = $Group.Value
                    }
                    $TelnetArgumentList += $Group.Value
                } elseif($Group.Name -eq 'port' -and $Group.Value.Length -gt 0) {
                    $TelnetArgumentList += '-P'
                    $TelnetArgumentList += $Group.Value.TrimStart(':')
                }
            }
        } elseif($arg -is [string] -and $arg.StartsWith('-')) {
            if($arg.ToLower() -eq '--title') {
                $CustomTitleNext = $true
            } else {
                $ParameterNext = $true
                $TelnetArgumentList += $arg
            }
        } else {
            if($ParameterNext) {
                $ParameterNext = $false
            } else {
                if($Title -eq 'Telnet') {
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
