# DrillSergeant
A simple AWS EC2 UserData manager for Windows instances

### What is DrillSergeant? ###

DrillSergeant is a supporting script module for streamlined, multi-boot user data on Windows in AWS

DrillSergeant is part of the extended platoons in Domain's [Robot Army v2](http://tech.domain.com.au/2015/01/robot-army-v2-0/)

He takes raw EC2 recruits and beats them into shape. And probably calls them 'you maggots' while he's doing it

an example, which is fed into the New-EC2Instance cmdlet's -UserData parameter (as Base-64):

=================================================================================================================
<powershell>
 Read-S3Object -bucketname domain-common -key /windows/ra2/DrillSergeant.ps1 -file c:\dom\DrillSergeant.ps1
 # or perhaps
 # Invoke-WebRequest http://devops.fixt.co/resources/DrillSergeant.ps1 -outFile c:\dom\DrillSergeant.ps1
 
 Import-Module c:\dom\DrillSergeant.ps1

 Switch(Get-CurrentStep)
 {
    1 { Execute-Step -script "& c:\dom\ol\base.ps1" -followedby 2 -reboot  }
    2 { Execute-Step -script "New-Item -path c:\step2 -itemtype directory" -followedby 3 -reboot }
    3 { Execute-Step -script post.ps1  }
 }
</powershell>
==================================================================================================================
 
As you can see, we first execute c:\dom\ol\base.ps1, declaring the next step to be '2', and reboot.
After the restart, EC2 will then execute step 2, which is an inline directory creation step, then we declare the next step as 3 and reboot again
Finally, we run post.ps1, with no reboot, and no further steps. 

You don't have to execute steps in a strict order. You can skip steps, and you don't have to reboot after every step. 
Though it's best if you keep it simple and consistent, naturally.

Another, slightly more convoluted example

=================================================================================================================
<powershell>
 Read-S3Object -bucketname domain-common -key /windows/ra2/DrillSergeant.ps1 -file c:\dom\DrillSergeant.ps1
 # or perhaps
 # iwr http://devops.fixt.co/resources/DrillSergeant.ps1 -outFile c:\dom\DrillSergeant.ps1
 
 ipmo c:\dom\DrillSergeant.ps1

 Switch(Get-CurrentStep)
 {
    1 { Execute-Step -script "& c:\dom\ol\base.ps1" -followedby 3 -reboot  }
    2 { Execute-Step -script "New-Item -path c:\step2 -itemtype directory" -followedby 4 -reboot }
    3 { Execute-Step -script post.ps1 -followedby 2  }
    4 { Execute-Step -script "& finalise.exe" }
 }
</powershell>
=================================================================================================================

As you'd expect, this executes step 1, reboots, executes step 3, then executes step 2, reboots, then finally executes step 4.

I don't know why you'd want to do it like this, but *you can if you like*.
