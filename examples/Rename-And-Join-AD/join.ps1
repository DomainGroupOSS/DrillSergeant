# example assumes your Active Directory is in place and discoverable in DNS
# it also assumes you have a better way to manage credentials

Function Get-Credential
{
    $cred = New-Object PSCredential
    $cred.UserName = "DOMAIN\LimitedAdmin"
    $cred.Password = "MyPassword" | ConvertTo-SecureString
    return $cred

}

Add-Computer -DomainName "mydomain.myorganisation.com" -Credential (Get-Credential)