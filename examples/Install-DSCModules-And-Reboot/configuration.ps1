# configuration example lifted directly from the xWebAdministration page at https://gallery.technet.microsoft.com/scriptcenter/xWebAdministration-Module-3c8bb6be

# Composite configuration to install the IIS pre-requisites for php 
Configuration IisPreReqs_php 
{ 
param 
    ( 
        [Parameter(Mandatory = $true)] 
        [Validateset("Present","Absent")] 
        [String] 
        $Ensure 
    )     
    foreach ($Feature in @("Web-Server","Web-Mgmt-Tools","web-Default-Doc", ` 
"Web-Dir-Browsing","Web-Http-Errors","Web-Static-Content",` 
            "Web-Http-Logging","web-Stat-Compression","web-Filtering",` 
            "web-CGI","web-ISAPI-Ext","web-ISAPI-Filter")) 
    { 
        WindowsFeature "$Feature$Number" 
        { 
            Ensure = $Ensure 
            Name = $Feature 
        } 
    } 
} 
# Composite configuration to install PHP on IIS 
configuration xPhp 
{ 
    param( 
        [Parameter(Mandatory = $true)] 
        [switch] $installMySqlExt, 
        [Parameter(Mandatory = $true)] 
        [string] $PackageFolder, 
        [Parameter(Mandatory = $true)] 
        [string] $DownloadUri, 
        [Parameter(Mandatory = $true)] 
        [string] $Vc2012RedistDownloadUri, 
        [Parameter(Mandatory = $true)] 
        [String] $DestinationPath, 
        [Parameter(Mandatory = $true)] 
        [string] $ConfigurationPath 
    ) 
        # Make sure the IIS Prerequisites for PHP are present 
        IisPreReqs_php Iis 
        { 
            Ensure = "Present" 
            # Removed because this dependency does not work in  
     # Windows Server 2012 R2 and below 
            # This should work in WMF v5 and above 
            # DependsOn = "[File]PackagesFolder" 
        } 
        # Download and install Visual C Redist2012 from chocolatey.org 
        Package vcRedist 
        { 
            Path = $Vc2012RedistDownloadUri 
            ProductId = "{CF2BEA3C-26EA-32F8-AA9B-331F7E34BA97}" 
            Name = "Microsoft Visual C++ 2012 x64 Minimum Runtime - 11.0.61030" 
            Arguments = "/install /passive /norestart" 
        } 
        $phpZip = Join-Path $PackageFolder "php.zip" 
        # Make sure the PHP archine is in the package folder 
        xRemoteFile phpArchive 
        { 
            uri = $DownloadURI 
            DestinationPath = $phpZip 
        } 
        # Make sure the content of the PHP archine are in the PHP path 
        Archive php 
        { 
            Path = $phpZip 
            Destination  = $DestinationPath 
        } 
        if ($installMySqlExt ) 
        {                
            # Make sure the MySql extention for PHP is in the main PHP path 
            File phpMySqlExt 
            { 
                SourcePath = "$($DestinationPath)\ext\php_mysql.dll" 
                DestinationPath = "$($DestinationPath)\php_mysql.dll" 
                Ensure = "Present" 
                DependsOn = @("[Archive]PHP") 
                MatchSource = $true 
            } 
        } 
             
            # Make sure the php.ini is in the Php folder 
            File PhpIni 
            { 
                SourcePath = $ConfigurationPath 
                DestinationPath = "$($DestinationPath)\php.ini" 
                DependsOn = @("[Archive]PHP") 
                MatchSource = $true 
            } 
            # Make sure the php cgi module is registered with IIS 
            xIisModule phpHandler 
            { 
               Name = "phpFastCgi" 
               Path = "$($DestinationPath)\php-cgi.exe" 
               RequestPath = "*.php" 
               Verb = "*" 
               Ensure = "Present" 
               DependsOn = @("[Package]vcRedist","[File]PhpIni")  
               # Removed because this dependency does not work in  
 # Windows Server 2012 R2 and below 
            # This should work in WMF v5 and above 
                # "[IisPreReqs_php]Iis"  
            } 
        # Make sure the php binary folder is in the path 
        Environment PathPhp 
        { 
            Name = "Path" 
            Value = ";$($DestinationPath)" 
            Ensure = "Present" 
            Path = $true 
            DependsOn = "[Archive]PHP" 
        } 
} 
xPhp -PackageFolder "C:\packages" ` 
    -DownloadUri  -DownloadUri "http://windows.php.net/downloads/releases/php-5.5.13-Win32-VC11-x64.zip" ` 
    -Vc2012RedistDownloadUri "http://download.microsoft.com/download/1/6/B/16B06F60-3B20-4FF2-B699-5E9B7962F9AE/VSU_4/vcredist_x64.exe" ` 
    -DestinationPath "C:\php" ` 
    -ConfigurationPath "C:\MyPhp.ini" ` 
    -installMySqlExt $false  