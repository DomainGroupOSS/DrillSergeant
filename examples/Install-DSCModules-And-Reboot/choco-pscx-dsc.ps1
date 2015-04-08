#install chocolatey

Invoke-Expression ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1'))

# install powershell community extensions

cinst pscx -y

# download DSC community resource

Invoke-WebRequest -uri https://gallery.technet.microsoft.com/scriptcenter/xWebAdministration-Module-3c8bb6be/file/135740/1/xWebAdministration_1.3.2.4.zip -OutFile c:\ds\xWebAdministration.zip

# install community resource

Expand-Archive -Path c:\ds\xWebAdministration.zip -DestinationPath "$env:ProgramFiles\WindowsPowerShell\Modules\xWebAdministration" -Force

# now you need to reboot, because DSC resources are finnicky. It may be enough to restart WMI. Or it may not