# Variables - use environment variables for sensitive data
$server = if ($env:SQL_SERVER_HOST) { $env:SQL_SERVER_HOST } else { "192.168.1.50" }
$user   = "sa"
$pass   = if ($env:SQL_SA_PASSWORD) { $env:SQL_SA_PASSWORD } else { throw "SQL_SA_PASSWORD environment variable not set" }

Write-Host "Starting Smoke Test for $server..." -ForegroundColor Cyan

try {
    # Attempt to run a simple version query
    $result = Invoke-Sqlcmd -ServerInstance $server -Username $user -Password $pass -Query "SELECT @@VERSION as Version" -ConnectTimeout 10
    
    if ($result.Version -like "*Microsoft SQL Server 2022*") {
        Write-Host "SUCCESS: SQL Server is up and running!" -ForegroundColor Green
        Write-Host $result.Version
        exit 0
    } else {
        Write-Host "FAILURE: Connected, but version string didn't match." -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "FAILURE: Could not connect to SQL Server. Error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}