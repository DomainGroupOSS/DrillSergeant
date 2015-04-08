Start-Transcript c:\ds\log.txt -Append # logging. Because this is very. very useful

Set-ExecutionPolicy -executionpolicy unrestricted -Force -verbose

Read-S3Object -bucketname example-bucket -key /DrillSergeant.ps1 -file c:\ds\DrillSergeant.ps1
Read-S3Object -bucketname example-bucket -key /rename.ps1 -file c:\ds\rename.ps1
Read-S3Object -bucketname example-bucket -key /join.ps1 -file c:\ds\join.ps1 
Read-S3Object -BucketName example-bucket -key /provision.ps1 -file c:\ds\provision.ps1

ipmo c:\ds\DrillSergeant.ps1

switch(Get-CurrentStep)
{
    1 { Execute-Step -script "c:\ds\rename.ps1" -followedby 2 -reboot }
    2 { Execute-Step -script "c:\ds\join.ps1" -followedby 3 -reboot }
    3 { Execute-Step -script "c:\ds\provision.ps1" }
}

Stop-Transcript