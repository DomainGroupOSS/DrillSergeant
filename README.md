# DrillSergeant
A simple AWS EC2 UserData manager for Windows instances

### What is DrillSergeant? ###

Sometimes, in Windows World, you need to reboot before you can carry on provisioning a server.

It's a fact of life.

DrillSergeant helps you do that, in AWS EC2, without user input.

DrillSergeant is part of the extended platoons in Domain's [Robot Army v2.x](http://tech.domain.com.au/2015/01/robot-army-v2-0/)

He takes raw EC2 recruits and beats them into shape. And probably calls them 'maggots' while he's doing it. Because that's what Drill Sergeants do, right?

An example, which is fed into the New-EC2Instance cmdlet's -UserData parameter (as Base-64), or pasted into UserData when creating instances at the console:

=================================================================================================================
`<powershell>
 Read-S3Object -bucketname domain-files -key /windows/ra2/DrillSergeant.ps1 -file c:\dom\DrillSergeant.ps1
 # or perhaps
 # Invoke-WebRequest http://devops.fixt.co/resources/DrillSergeant.ps1 -outFile c:\dom\DrillSergeant.ps1
 
 Import-Module c:\dom\DrillSergeant.ps1

 Switch(Get-CurrentStep)
 {
    1 { Execute-Step -script "& c:\dom\ol\base.ps1" -followedby 2 -reboot  }
    2 { Execute-Step -script "New-Item -path c:\step2 -itemtype directory" -followedby 3 -reboot }
    3 { Execute-Step -script post.ps1  }
 }
</powershell>`
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

There are some examples in, naturally, the /examples/ folder

Feel free to add one or two more

### Licence ###

The MIT License (MIT)

Copyright (c) 2015 Domain Group (http://www.domain.com.au/group)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.