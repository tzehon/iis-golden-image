Write-Host "Installing IIS..."
Import-Module ServerManager
$features = @(
   "Web-WebServer",
   "Web-Static-Content",
   "Web-Http-Errors",
   "Web-Http-Redirect",
   "Web-Stat-Compression",
   "Web-Filtering",
   "Web-Asp-Net45",
   "Web-Net-Ext45",
   "Web-ISAPI-Ext",
   "Web-ISAPI-Filter",
   "Web-Mgmt-Console",
   "Web-Mgmt-Tools",
   "NET-Framework-45-ASPNET"
)
Add-WindowsFeature $features -Verbose

Write-Host "Opening port 80..."
netsh advfirewall firewall add rule name="open_80_api" dir=in localport=80 protocol=TCP action=allow

Set-Content -Path C:\inetpub\wwwroot\index.html -Value '<!doctype html><html><body><h1>Hello World!</h1></body></html>'
Get-Content -Path C:\inetpub\wwwroot\index.html

choco install -y webdeploy