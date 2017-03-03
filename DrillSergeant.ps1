<#
 DrillSergeant is a supporting script module for streamlined, multi-boot user data on Windows Server in AWS

 He takes raw recruits and beats them into shape. And probably calls them maggots while he's doing it

 an example, which is fed into New-EC2Instance's -UserData parameter as Base-64:

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
 <persist>true</persist>
 ==================================================================================================================
 
 As you can see, we first execute ol\base.ps1, then we declare the next step to be '2' and reboot.
 On restart, we then execute step 2, which is an inline directory creation step, then we declare the next step as 3 and reboot again
 Finally, we run post.ps1, with no reboot, and no further steps. 

 You don't have to execute steps in a strict order. You can skip steps, and you don't have to reboot after every step. 
 Though it's best if you keep it simple and consistent, naturally

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
 <persist>true</persist>
 =================================================================================================================


 #>

#variables
$stateKey = "HKLM:\SOFTWARE\Domain-Ops\DrillSergeant"                    # do not change this unless absolutely necessary. There's a nonzero risk you could hose your instance's registry
$ec2configfolder = "$env:ProgramFiles\Amazon\EC2ConfigService"
$persistencemode = "registry"                                            # TODO: add a "file" persistence mode, for those uncomfortable with the registry

<#
.Synopsis
   Executes arbitrary PowerShell code or command lines
.DESCRIPTION
   Execute-Step takes arbitrary strings of powershell and executes them. Can be used to execute batch files, executables or arbitrary code
.EXAMPLE
   Execute-Step -script "New-Item -path c:\step2 -itemtype directory" -followedby 4 -reboot
.EXAMPLE
   Execute-Step -script "& finalise.exe"
.INPUTS
   -Script (aka -command, -c or -s)
   The script or command to run, in powershell format, as a quoted string or bareword

   Can be bare Powershell script

   -script "Read-S3Object -bucketname mybucket -key /subfolder/something.zip -file c:\target\something.zip"

   or an executed powershell, executable or batch file

   -script "& configuremyserver.ps1"
   -script "post.ps1"
   -script "& installstuff.bat"
.NOTES
   As with all runtime evaluation, with great power comes great responsibility. Take care to never allow externally-supplied code to creep into the $script parameter
   Think of it as a potential SQL Injection risk. If you're putting a variable here, make sure that variable isn't coming from a location you don't rigorously control
.COMPONENT
   DrillSergeant
.FUNCTIONALITY
   Runs things, then schedules the next step and reboots
#>
Function Execute-Step
{
    param
    (
        [Parameter(Mandatory=$true,
                   Position=0)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [Alias("s", "c", "command", "file")]
        [string]
        $script,
        [Alias("r", "restart")]
        [Parameter(Mandatory=$false, Position=1)]
        [switch]
        $reboot,
        [Parameter(Mandatory=$false, Position=2)]
        [Alias("f", "n", "nextstep", "next")]
        [int]
        $followedby
    )

    # TODO: need a bit of basic validation here, to prevent gross terrible horrible things

    # check if we've been passed a file
    if(Test-Path $script)
    {
        & $script
    }
    else # we've been passed code
    {
        iex $script 
    }
    if($followedby)
    {
        Set-NextStep -step $followedby
    }
    else
    {
        Remove-NextStep # tidy up
    }
    # set userdata to run on next reboot
    Set-UserDataConfig
    if($reboot)
    {
        Restart-Computer -force
    }
    else
    {
        # is there a next step? but no reboot specified here? We should probably execute that next step then
        if($followedby)
        {
            # run the UserScript again
            & "$ec2configfolder\scripts\UserScript.ps1"
        }
    }
}

<#
.Synopsis
   Gets the DrillSergeant's next step
.DESCRIPTION
   Internal function to DrillSergeant
.NOTES
   Should not be called directly, but is used by Execute-Step
.COMPONENT
   DrillSergeant
.FUNCTIONALITY
   Gets a registry key
#>
Function Get-CurrentStep
{
    $targetKey = "$stateKey\CurrentStep"
    if(Test-Path $stateKey)
    {
        $property = Get-ItemProperty -path "HKLM:\SOFTWARE\Domain-Ops\DrillSergeant" | select -ExpandProperty CurrentStep
    }
    else
    {
        $property = 1
    }
    return [int]$property
}

<#
.Synopsis
   Persists DrillSergeant's next step to the registry
.DESCRIPTION
   Internal function to DrillSergeant
.NOTES
   SHould not be called directly, but is used by Execute-Step
.COMPONENT
   DrillSergeant
.FUNCTIONALITY
   Sets a registry key
#>
Function Set-NextStep
{
    param
    (
        [int]$step
    )
    $path = $stateKey
    if(!(Test-Path $path)) {
        New-Item -path $path -force
    }
    Set-ItemProperty -Path $path -Name CurrentStep -Value $step
}

<#
.Synopsis
   Removes DrillSergeant's Registry key(s)
.DESCRIPTION
   Internal function to DrillSergeant
.NOTES
   Should not be called directly, but is used by Execute-Step
.COMPONENT
   DrillSergeant
.FUNCTIONALITY
   removes registry keys
#>
Function Remove-NextStep
{
    $parentKey = Split-Path $stateKey -Parent
    # should probably be validate. could hose the registry
    Remove-Item $stateKey
    if($parentKey -ne "HKLM:\Software") 
    {
        Remove-Item $parentKey
    }
    # there is an argument to made for leaving the key in place.
}

<#
.Synopsis
   Sets the EC2Config Service's "EC2HandleUserData" field
.DESCRIPTION
   Internal function to DrillSergeant
.NOTES
   Should not be called directly, but is used by Execute-Step
.COMPONENT
   DrillSergeant
.FUNCTIONALITY
   Sets a config value
#>
Function Set-UserDataConfig
{
    param
    (
        $state = "Enabled"
    )
    # are we on 2012 or 2016? 
    $ver = [Environment]::OSVersion.Version.Major # this is enough
    if($ver -eq 10)
    {
        # it should be enough to make sure <persist>true</persist> is in the userdata
    }
    else
    {
        # server 2012
        $targetPath = "$ec2configfolder\Settings\config.xml"
        $config = [xml](gc $targetPath -raw)
        $userdatanode = $config.Ec2ConfigurationSettings.Plugins.Plugin | ? { $_.Name -eq "EC2HandleUserData"}
        $userdatanode.State = $state
        $config.Save($targetPath)
    }
}