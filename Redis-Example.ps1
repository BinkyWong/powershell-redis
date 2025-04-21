$redisHost = "192.168.0.25"
$redisPort = 6379
$totalJobs = 130000

$scriptStart = Get-Date

# Open one connection
$client = New-Object System.Net.Sockets.TcpClient($redisHost, $redisPort)
$stream = $client.GetStream()

$batchSize = 1000
for ($offset = 0; $offset -lt $totalJobs; $offset += $batchSize) {
    $allCmds = ""
    $end = [math]::Min($offset + $batchSize, $totalJobs)
    for ($i = $offset + 1; $i -le $end; $i++) {
        $key = "key_" + ([guid]::NewGuid().ToString().Substring(0, 5))
        $value = "value_" + ([guid]::NewGuid().ToString().Substring(0, 8))
        $allCmds += "*3`r`n`$3`r`nSET`r`n`$" + $key.Length + "`r`n$key`r`n`$" + $value.Length + "`r`n$value`r`n"
    }
    $cmdBytes = [System.Text.Encoding]::ASCII.GetBytes($allCmds)
    $stream.Write($cmdBytes, 0, $cmdBytes.Length)

    # Read responses for this batch
    $buffer = New-Object byte[] ($batchSize * 16)
    $bytesRead = $stream.Read($buffer, 0, $buffer.Length)
    # Optionally process $bytesRead/$buffer here
}

$stream.Close()
$client.Close()

$scriptEnd = Get-Date
$duration = $scriptEnd - $scriptStart
Write-Host "`nOperation completed in $($duration.TotalSeconds) seconds." -ForegroundColor Cyan