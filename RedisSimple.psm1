# RedisSimple.psm1 - Simple Redis functions for PowerShell

function Send-RedisCommand {
    param (
        [string]$Host,
        [int]$Port,
        [string]$Command
    )
    $client = New-Object System.Net.Sockets.TcpClient($Host, $Port)
    $stream = $client.GetStream()
    $cmdBytes = [System.Text.Encoding]::ASCII.GetBytes($Command)
    $stream.Write($cmdBytes, 0, $cmdBytes.Length)
    Start-Sleep -Milliseconds 100
    $buffer = New-Object byte[] 4096
    $bytesRead = $stream.Read($buffer, 0, 4096)
    $response = [System.Text.Encoding]::ASCII.GetString($buffer, 0, $bytesRead)
    $stream.Close()
    $client.Close()
    return $response
}

function Get-RandomString {
    param ([int]$length = 8)
    $chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
    $random = New-Object System.Random
    $result = ''
    for ($i = 0; $i -lt $length; $i++) {
        $result += $chars[$random.Next(0, $chars.Length)]
    }
    return $result
}

function Invoke-RedisPing {
    param (
        [string]$Host,
        [int]$Port
    )
    $pingCmd = "*1`r`n`$4`r`nPING`r`n"
    return Send-RedisCommand -Host $Host -Port $Port -Command $pingCmd
}

function Set-RedisKeyValue {
    param (
        [string]$Host,
        [int]$Port,
        [string]$Key,
        [string]$Value
    )
    $setCmd = "*3`r`n`$3`r`nSET`r`n`$" + $Key.Length + "`r`n" + $Key + "`r`n`$" + $Value.Length + "`r`n" + $Value + "`r`n"
    return Send-RedisCommand -Host $Host -Port $Port -Command $setCmd
}

function Get-RedisKeys {
    param (
        [string]$Host,
        [int]$Port,
        [string]$Pattern = "*"
    )
    $keysCmd = "*2`r`n`$4`r`nKEYS`r`n`$" + $Pattern.Length + "`r`n" + $Pattern + "`r`n"
    return Send-RedisCommand -Host $Host -Port $Port -Command $keysCmd
}