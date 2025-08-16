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

# Set title and prompt
$Host.UI.RawUI.WindowTitle = "PowerShell $($Host.Version.Major).$($Host.Version.Minor)"
Function Prompt() {
    $AdminRole = [Security.Principal.WindowsBuiltInRole]::Administrator
    $Identity = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
    $PromptCWD = $PWD.ProviderPath.replace($Env:UserProfile, "~")
    $PromptCWD = $PromptCWD.replace("\\int.charter.ca\internal", "chtr:")

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

# Clear console and run fetch
Clear-Host
fastfetch --config $Env:UserProfile\.config\fastfetch.jsonc
Write-Host

# Aliases
Set-Alias grep Select-String -Option ReadOnly
Set-Alias ll Get-ChildItem -Option ReadOnly
Set-Alias sublime "$($Env:ProgramFiles)\Sublime Text\sublime_text.exe" -Option ReadOnly
Set-Alias subl sublime -Option ReadOnly
Set-Alias which Get-Command -Option ReadOnly

Set-Alias wtssh Open-WTSSH -Option ReadOnly
Set-Alias wttelnet Open-WTTelnet -Option ReadOnly
Set-Alias wttel Open-WTTelnet -Option ReadOnly
Set-Alias wtcom Open-WTCOM -Option ReadOnly
Set-Alias wtser Open-WTCOM -Option ReadOnly

Set-Alias head Get-ContentHead -Option ReadOnly
Set-Alias tail Get-ContentTail -Option ReadOnly
Set-Alias wc Count-Lines -Option ReadOnly

# WSL aliases
Set-Alias bgpq4 wsl_bgpq4 -Option ReadOnly
Set-Alias dig wsl_dig -Option ReadOnly
Set-Alias iperf3 wsl_iperf3 -Option ReadOnly
Set-Alias mtr wsl_mtr -Option ReadOnly
Set-Alias whois wsl_whois -Option ReadOnly
Function wsl_bgpq4 {Start-WSL bgpq4 -Arguments $args}
Function wsl_dig {Start-WSL dig -Arguments $args}
Function wsl_iperf3 {Start-WSL iperf3 -Arguments $args}
Function wsl_mtr {Start-WSL mtr -Arguments $args}
Function wsl_whois {Start-WSL whois -Arguments $args}



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

Function Open-WTTelnet {
    <#
    .SYNOPSIS
    Launch plink in a Windows Terminal tab
    .DESCRIPTION
    Run 'plink --help' or see the documentation at https://the.earth.li/~sgtatham/putty/0.83/htmldoc/Chapter7.html#plink
    #>

    Get-Command -Name plink -CommandType Application -ErrorAction Stop | Out-Null
    trap {
        $Message = "Dependency plink not found"
        $Question = "Attempt to install automatically?"
        $Choices = "&Yes", "&No"
        $Answer = $Host.UI.PromptForChoice($Message, $Question, $Choices, 1)
        if ($Answer -eq 0) {
            $ArgumentList = @(
                "install",
                "--exact",
                "PuTTY.PuTTY"
            )
            Start-Process winget -ArgumentList $ArgumentList -NoNewWindow -Wait
        }
        return
    }

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

Function Open-WTCOM {
    <#
    .SYNOPSIS
        Connect to a serial port in a new Windows Terminal tab
    .DESCRIPTION
        Uses plink to connect to a COM port. See 'Get-Help Open-WTCOM -detailed' for more.

        Plink is part of the PuTTY package to install visit
        https://www.chiark.greenend.org.uk/~sgtatham/putty/latest.html
        or use winget: 'winget install --exact PuTTY.PuTTY'
    .PARAMETER Port
        The COM device number
        Default: 4
    .PARAMETER BaudRate
        The baud rate
        Default: 9600
    .PARAMETER DataBits
        The number of bits per character
        Default: 8
    .PARAMETER Parity
        The parity mechanism behaviour, one of:
        - n: None (default)
        - o: Odd
        - e: Even
        - m: Mark
        - s: Space
    .PARAMETER StopBits
        The number of stop bits, one of 1, 1.5, or 2
        Default: 1
    .PARAMETER FlowControl
        Flow control mechanism, one of:
        - N: No flow control
        - X: Software XON/XOFF flow control (default)
        - R: Hardware RTS/CTS flow control
        - D: Hardware DSR/DTR flow control
    .EXAMPLE
        Open-WTCOM -Port 5 -BaudRate 115200
    .NOTES
        Author: Ryan Kozak
        Date:   August 14, 2025
    #>

    param (
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            HelpMessage = 'The COM device number'
        )][ValidateNotNullOrEmpty()][Int]$Port = 4,
        [Parameter(
            Mandatory = $false,
            HelpMessage = 'The baud rate'
        )][ValidateNotNullOrEmpty()][Int]$BaudRate = 9600,
        [Parameter(
            Mandatory = $false,
            HelpMessage = 'The number of bits per character <5-9>'
        )][ValidateSet(5,6,7,8,9)][Int]$DataBits = 8,
        [Parameter(
            Mandatory = $false,
            HelpMessage = 'The parity checking behaviour <n|o|e|m|s>'
        )][ValidateSet('n','o','e','m','s')][System.String]$Parity = 'n',

        [Parameter(
            Mandatory = $false,
            HelpMessage = 'The number of stop bits <1|1.5|2>'
        )][ValidateSet('1','1.5','2')][System.String]$StopBits = '1',
        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Flow control <N|X|R|D>'
        )][ValidateSet('N','X','R','D')][System.String]$FlowControl = 'X'
    )

    Get-Command -Name plink -CommandType Application -ErrorAction Stop | Out-Null
    trap {
        $Message = "Dependency plink not found"
        $Question = "Attempt to install automatically?"
        $Choices = "&Yes", "&No"
        $Answer = $Host.UI.PromptForChoice($Message, $Question, $Choices, 1)
        if ($Answer -eq 0) {
            $ArgumentList = @(
                "install",
                "--exact",
                "PuTTY.PuTTY"
            )
            Start-Process winget -ArgumentList $ArgumentList -NoNewWindow -Wait
        }
        return
    }

    $SerialConfig = "$BaudRate,$DataBits,$Parity,$StopBits,$FlowControl"
    $ArgumentList = @(
        "new-tab",
        "--profile plink",
        "--title COM$Port",
        "plink -serial $Port -sercfg $SerialConfig"
    )
    Start-Process wt -ArgumentList $ArgumentList
}

Function Start-WSL() {
    param (
        [Parameter(
            Mandatory = $false,
            HelpMessage = 'WSL distribution to launch'
        )][ValidateNotNullOrEmpty()][System.String]$Distribution = 'rocky',
        [Parameter(
            Mandatory = $true,
            Position = 0,
            HelpMessage = 'Command to call'
        )][ValidateNotNullOrEmpty()][System.String]$Command,
        [Parameter(
            Mandatory = $false,
            Position = 1,
            ValueFromRemainingArguments = $true
        )]$Arguments
    )

    # Get a list of available WSL distributions
    $Distributions = @()
    (wsl --list --verbose) | Select-Object -Skip 1 | Where-Object Length -GT 1 | ForEach-Object {
        $Distributions += ($_.Split(' ') | Where-Object Length -GT 1)[1].ToLower()
    }

    # Make sure the requested distribution is available
    if ($Distributions -contains $Distribution.ToLower()) {
        # Launch
        $ArgumentList = @(
            "--distribution $Distribution",
            "$Command"
        )
        if ($Arguments -ne $null) {$ArgumentList += $Arguments}
        Start-Process wsl -ArgumentList $ArgumentList -Wait -NoNewWindow
    }
    else {
        Write-Error "WSL distribution $Distribution not found"
    }
}

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
