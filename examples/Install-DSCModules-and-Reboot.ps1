# AWS IDs are examples only. You will need to replace these with values from your own account if you wish to test
# please don't commit genuine IDs to github

# This example installs a DSC community resource, reboots the server and uses the resource to perform some configuration
# Please see .\Install-DSCModules-and-Reboot\ for supporting files
# this module pulls supporting resources from a publically-available website

$MyInstance = New-EC2Instance -SecurityGroupId sg-12345678 `
                              -ImageId ami-12345678 `
                              -UserData (gc .\userdata.ps1 -raw) `
                              -KeyName my-pre-created-key `
                              -InstanceType t1.micro `
                              -SubnetId subnet-12345678 `
                              -region ap-southeast-2 `
                              -EncodeUserData