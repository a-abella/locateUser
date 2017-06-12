# Get IPs of users connected to Windows server via PSRemoting.
function winShareSearch($user) {
    $s = New-PSSession -Computername "winShareServer.domain.tld"
    $nsout = Invoke-Command -Session $s -Scriptblock {
        net session
    }
    Remove-PSSession $s
    Write-Output $nsout | select-string $user
}

# Get IPs and hostnames of users connected to Samba DFS cluster.
# Groups connected IPs by samba host. Requires Powershell SSH module.
function sambaShareSearch($user) {
    $username = "SSHuser"
    # yes this is bad practice, I know
    $pw = "SSHpassword"
    $secpw = New-Object -TypeName System.Security.SecureString
    $pw.ToCharArray() | foreach-object { 
        $secpw.AppendChar($_) 
    }
    $cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $username,$secpw
    $s = New-SSHSession -ComputerName ansibleHost -Credential $cred
    $curhost = ""
    (Invoke-SSHCommand -SSHSession $s -Command "ansible sambas -m shell -a ""smbstatus -p | grep '$user'"" | grep '$user\|SUCCESS'").output -split "`n" | foreach-object {
        if ($_ -like "*SUCCESS*") {
            $curhost = $($_ -split "\.")[0]
            write-host ""
        } else {
            $curname = $($_ -split "\s+")[1] 
            $curip = $($_ -split "\s+")[4]
            try {
                    $hostname = ([system.net.dns]::GetHostByAddress($curip)).hostname
            } catch {
                    $hostname = ""
            }
            write-host "$curhost    $curname    $curip    $hostname"
        }
    }
    Remove-SSHSession $s | Out-Null
    Write-Host ""
}