Import-Module "$PSScriptRoot\RedisSimple.psm1"

# Change this to your Redis server's IP address and port
$redisHost = "192.168.0.25"
$redisPort = 6379

$scriptStart = Get-Date

Write-Host "Testing Redis connection with PING command..." -ForegroundColor Cyan
$response = Invoke-RedisPing -Host $redisHost -Port $redisPort
Write-Host "PING response: $response" -ForegroundColor Green

$modulePath = "$PSScriptRoot\RedisSimple.psm1"
$jobs = @()
$totalJobs = 50

Write-Host "`nInserting"$totalJobs" random key-value pairs using multithreading..." -ForegroundColor Cyan

for ($i = 1; $i -le $totalJobs; $i++) {
    $jobs += Start-Job -ScriptBlock {
        param ($redisHost, $redisPort, $index, $modulePath)
        Import-Module $modulePath
        $key = "key_" + ([guid]::NewGuid().ToString().Substring(0, 5))
        $value = "value_" + ([guid]::NewGuid().ToString().Substring(0, 8))
        $response = Set-RedisKeyValue -Host $redisHost -Port $redisPort -Key $key -Value $value
        if ($response -match "OK") {
            Write-Output "[$index/$using:totalJobs] Success: $key = $value"
        }
        else {
            Write-Output "[$index/$using:totalJobs] Failed: $key = $value, Response: $response"
        }
    } -ArgumentList $redisHost, $redisPort, $i, $modulePath
}

# Progress bar setup
$completed = 0
while ($completed -lt $totalJobs) {
    $finished = ($jobs | Where-Object { $_.State -eq 'Completed' }).Count
    $percent = [math]::Round(($finished / $totalJobs) * 100)
    Write-Progress -Activity "Inserting keys into Redis" -Status "$percent% Complete" -PercentComplete $percent
    Start-Sleep -Milliseconds 200
    $completed = $finished
}

# Wait for all jobs to complete and output their results
$jobs | ForEach-Object {
    $jobResult = Receive-Job -Job $_ -Wait
    Write-Host $jobResult -ForegroundColor Green
    Remove-Job -Job $_
}

Write-Host "`nVerifying with KEYS command..." -ForegroundColor Cyan
$response = Get-RedisKeys -Host $redisHost -Port $redisPort -Pattern "key_*"
Write-Host "Keys found: $response" -ForegroundColor Green

$scriptEnd = Get-Date
$duration = $scriptEnd - $scriptStart
Write-Host "`nOperation completed in $($duration.TotalSeconds) seconds." -ForegroundColor Cyan