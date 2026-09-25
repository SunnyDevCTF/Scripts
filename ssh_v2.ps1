Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
Start-Service sshd
Set-Service -Name sshd -StartupType 'Automatic'

$password = ConvertTo-SecureString "1234" -AsPlainText -Force
Set-LocalUser -Name $env:USERNAME -Password $password
