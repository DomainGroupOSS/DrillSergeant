Start-Transcript c:\ds\log.txt -Append # logging. Because this is very. very useful

Set-ExecutionPolicy -executionpolicy unrestricted -Force -verbose

Invoke-WebRequest -uri http://www.myserver.com/DrillSergeant.ps1 -outfile c:\ds\DrillSergeant.ps1
Invoke-WebRequest -uri http://www.myserver.com/choco-pscx-dsc.ps1 -outfile c:\ds\choco-pscx-dsc.ps1
Invoke-WebRequest -uri http://www.myserver.com/configuration.ps1 -outfile c:\ds\configuration.ps1 

ipmo c:\ds\DrillSergeant.ps1

switch(Get-CurrentStep)
{
    1 { Execute-Step -script "c:\ds\choco-pscx-dsc.ps1" -followedby 2 -reboot }
    2 { Execute-Step -script "c:\ds\configuration.ps1" }
    3 { Execute-Step -script "Write-S3Object -bucket logging-bucket -key /logs/ds/log.txt -file c:\ds\log.txt" } # might hit a file lock here
}

Stop-Transcript