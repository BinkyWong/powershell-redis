Import-Module "$PSScriptRoot\RedisSimple.psm1"

$redisHost = "192.168.0.25"
$redisPort = 6379
$totalJobs = 1000

$scriptStart = Get-Date

# Open one connection
$client = New-Object System.Net.Sockets.TcpClient($redisHost, $redisPort)
$stream = $client.GetStream()

# Build all commands in one string (pipeline)
$allCmds = ""
for ($i = 1; $i -le $totalJobs; $i++) {
    $key = "key_" + ([guid]::NewGuid().ToString().Substring(0, 5))
    $value = "value_" + ([guid]::NewGuid().ToString().Substring(0, 8))
    $allCmds += "*3`r`n`$3`r`nSET`r`n`$" + $key.Length + "`r`n$key`r`n`$" + $value.Length + "`r`n$value`r`n"
}

# Send all at once
$cmdBytes = [System.Text.Encoding]::ASCII.GetBytes($allCmds)
$stream.Write($cmdBytes, 0, $cmdBytes.Length)

# Read all responses (one per SET)
$buffer = New-Object byte[] ($totalJobs * 16)
$bytesRead = $stream.Read($buffer, 0, $buffer.Length)
$response = [System.Text.Encoding]::ASCII.GetString($buffer, 0, $bytesRead)

$stream.Close()
$client.Close()

$scriptEnd = Get-Date
$duration = $scriptEnd - $scriptStart
Write-Host "`nOperation completed in $($duration.TotalSeconds) seconds." -ForegroundColor Cyan