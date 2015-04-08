# AWS IDs are examples only. You will need to replace these with values from your own account if you wish to test
# please don't commit genuine IDs to github

# This example renames a computer, reboots it, joins it to the domain, reboots it again, then performs finishing touches
# Please see .\Rename-And-Join-AD\ for supporting files
# In this example, supporting files are pulled from AWS S3

Function Get-UserData
{
    # Pick up the userdata from a PS1 file
    # convert it to Base64, as AWS requires
    # NOT needed if new-ec2instance has the -encodeuserdata flag set
    $path = ".\S3Files\Rename-and-Join-AD-userdata.ps1" # your working directory may vary
    $RawData = Get-Content $path -Raw
    $b64UserData = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes("<powershell>$RawData</powershell>"))
    return $b64UserData
}

$MyInstance = New-EC2Instance -SecurityGroupId sg-12345678 `
                              -ImageId ami-12345678 `
                              -UserData (Get-UserData) `
                              -KeyName my-pre-created-key `
                              -InstanceType t1.micro `
                              -SubnetId subnet-12345678 `
                              -region ap-southeast-2 