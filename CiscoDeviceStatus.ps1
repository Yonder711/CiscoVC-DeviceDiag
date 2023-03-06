$credentials1 = 'admin:BCSGlobal1'
$credentials2 = 'admin:695856'

$ip_list_file = ".\ips.txt"

$encodedCreds = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credentials1))
$basicAuthValue = "Basic $encodedCreds"
$Headers1 = @{
    Authorization = $basicAuthValue
}

$encodedCreds = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credentials2))
$basicAuthValue = "Basic $encodedCreds"
$Headers2 = @{
    Authorization = $basicAuthValue
}

add-type @"
using System.Net;
using System.Security.Cryptography.X509Certificates;
public class TrustAllCertsPolicy : ICertificatePolicy {
    public bool CheckValidationResult(
        ServicePoint srvPoint, X509Certificate certificate,
        WebRequest request, int certificateProblem) {
        return true;
    }
}
"@
$AllProtocols = [System.Net.SecurityProtocolType]'Ssl3,Tls,Tls11,Tls12'
[System.Net.ServicePointManager]::SecurityProtocol = $AllProtocols
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy

# Use the transcript method to write all actions out to a file.
Start-Transcript -path .\StatusResults.txt -append


foreach($line in Get-Content $ip_list_file) {
    $c1_success = $false
    write-host "Running IP: $($line):"
    # Creds 1
    write-host "  Using Credentials1:"
    ## Show current Cisco EP Alarms
    try {
        $r = Invoke-WebRequest -Uri "https://$($line)/putxml" -Headers $Headers1 -method POST -body @"
        <Command> <Diagnostics> <Run> ALL </Run> </Diagnostics> </Command>
"@
        write-host "    Show current alarms"
        write-host "      Output:"
        write-host " ####### "
        write-host "$($r.Content)"
        write-host " ####### "
        write-host ""
        $c1_success = $true
    } catch {
        write-host "    Show current alarms request error: $($_.Exception.Response.StatusCode.Value__)"
    }

    if ($c1_success -eq $false) {
        # Creds 2
        write-host "  Using Credentials2:"
        ## Show current Cisco EP Alarms
        try {
            $r = Invoke-WebRequest -Uri "https://$($line)/putxml" -Headers $Headers2 -method POST -body @"
            <Command> <Diagnostics> <Run> ALL </Run> </Diagnostics> </Command>
"@
            write-host "    Show current alarms"
            write-host "      Output:"
            write-host " ####### "
            write-host "$($r.Content)"
            write-host " ####### "
            write-host ""
        } catch {
            write-host "    Show current alarms request error: $($_.Exception.Response.StatusCode.Value__)"
        }
    }
}
# Stop Writing out to file after all IPs have been attempted.
Stop-Transcript