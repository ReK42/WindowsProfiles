# Windows Terminal, PowerShell and OpenSSH Profiles
## Installation
1. Install the dependencies listed below
2. Copy the contents of `UserProfile` to `%UserProfile%`
3. [OPTIONAL] Apply the included registry file to register Windows Terminal to automatically handle `ssh://` and `telnet://` protocol links

### Dependencies
- PowerShell 5.1
- [Windows Terminal](https://aka.ms/terminal)
- [gsudo](https://github.com/gerardog/gsudo)
- [pfetch-rs](https://github.com/Gobidev/pfetch-rs)
- [OpenSSH Client](https://learn.microsoft.com/en-us/windows-server/administration/openssh/openssh_install_firstuse?tabs=gui#tabpanel_1_gui) (for `wtssh`)
- [plink](https://www.chiark.greenend.org.uk/~sgtatham/putty/latest.html) (for `wttelnet`)
- [WSL](https://learn.microsoft.com/en-us/windows/wsl/install) (for `wtcom`)
- [minicom](https://salsa.debian.org/minicom-team/minicom) (for `wtcom`)
- [CaskaydiaCove Nerd Font](https://www.nerdfonts.com/)

## Usage
- `wtssh`: Wrapper for OpenSSH that spawns a new tab
    - `-t`, `--title`: Set a custom title for the tab
    - Parses an SSH URI argument (`ssh://`)
    - All additional arguments are forwarded to OpenSSH
- `wttelnet`: Wrapper for plink that spawns a new tab
    - `--title`: Set a custom title for the tab
    - Parses a telnet URI argument (`telnet://`)
    - All additional arguments are forwarded to plink
- `wtcom`: Wrapper for minicom running in WSL that spawns a new tab
    - `-Port`: COM port to connect to, default: `4`
    - `-Distribution`: WSL distribution with minicom installed, default: `debian`
    - No additional arguments are forwarded to minicom
    - Requires that the serial port `COMX` is correctly forwarded to the WSL device `/dev/ttySX`
- `Compare-FileHash`: Compare two files, or a file to a hash string
    - `-Algorithm`: Hash algorithm to use, default: `SHA256`
    - `-Path`: Path to the first (or only) file to compare, may also be piped in via stdin
    - `-Compare`: Path to the second file, or a hash string, to compare against
- Other Utilities:
    - `head`, `tail`, `wc`: Super basic clones of standard POSIX tools
    - `Get-UserPrincipleName`: Get the UPN of the current user
- WSL Aliases:
    - Note: All WSL aliases use a distribution named `rocky` by default. That distribution must exist and have the below tools installed for these to function.
    - `dig`
    - `whois`
    - `bgpq3|bgpq4`
    - `mtr`
- Other Aliases:
    - `sudo` --> `gsudo`
    - `grep` --> `Select-String`
    - `ll` --> `Get-ChildItem`
    - `which` --> `Get-Command`
    - `subl|sublime` --> [Sublime Text](https://www.sublimetext.com/)
