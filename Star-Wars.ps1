# Sample script to query the Star Wards API and store results in Redis
# This script fetches data from the Star Wars API and stores it in a Redis database.
# It uses the RESP protocol to communicate with Redis.
# The script fetches data for 10 characters from the API and stores their details in Redis.
# It uses the HMSET command to store the character details as a hash in Redis.
# The script also handles errors gracefully and provides feedback on the operations performed.

$redisHost = "192.168.0.25"
$redisPort = 6379

# Open one connection
$client = New-Object System.Net.Sockets.TcpClient($redisHost, $redisPort)
$stream = $client.GetStream()

$allResponses = @()

$personCount = 10

for ($i = 1; $i -le $personCount; $i++) {
    $url = "https://swapi.py4e.com/api/people/$i"
    try {
        $person = Invoke-RestMethod -Uri $url -UseBasicParsing
        if ($person) {
            $key = ($person.name -replace '[^a-zA-Z0-9]', '_').ToLower()
            $cmdParts = @("HMSET", $key)
            
            foreach ($prop in $person.PSObject.Properties) {
                if ($null -ne $prop.Value) {
                    $fieldName = $prop.Name
                    $fieldValue = [string]$prop.Value
                    $cmdParts += $fieldName
                    $cmdParts += $fieldValue
                }
            }
            
            # Format as RESP protocol
            $cmd = "*" + $cmdParts.Count + "`r`n"
            foreach ($part in $cmdParts) {
                $cmd += "$" + $part.Length + "`r`n" + $part + "`r`n"
            }
            
            # Send command and read response
            $cmdBytes = [System.Text.Encoding]::ASCII.GetBytes($cmd)
            $stream.Write($cmdBytes, 0, $cmdBytes.Length)
            
            # Read response
            $buffer = New-Object byte[] 1024
            $bytesRead = $stream.Read($buffer, 0, $buffer.Length)
            $response = [System.Text.Encoding]::ASCII.GetString($buffer, 0, $bytesRead)
            $allResponses += $response.Trim()
        }
    } catch {
        Write-Warning "Failed to fetch $url"
    }
}

Write-Host ($allResponses -join "`n")

$stream.Close()
$client.Close()