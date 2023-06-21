# Windows Terminal, PowerShell and OpenSSH Profiles
## Dependencies
- PowerShell 5.1
- [Windows Terminal](https://aka.ms/terminal)
- [OpenSSH Client](https://learn.microsoft.com/en-us/windows-server/administration/openssh/openssh_install_firstuse?tabs=gui#tabpanel_1_gui)
- [Chocolatey](https://chocolatey.org)
- [gsudo](https://github.com/gerardog/gsudo)
- [pfetch](https://github.com/dylanaraps/pfetch)
- [WSL](https://learn.microsoft.com/en-us/windows/wsl/install) with a distribution with [minicom](https://salsa.debian.org/minicom-team/minicom) installed (default assumes debian)

## File Locations
- `Microsoft.PowerShell_profile.ps1`: `%UserProfile%\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1`
- `settings.json`: `%UserProfile%\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json`
- `ssh_config`: `%UserProfile%\.ssh\config`
- Place images directly in `%UserProfile`