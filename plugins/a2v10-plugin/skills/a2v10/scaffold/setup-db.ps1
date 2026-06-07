# setup-db.ps1
# Creates the database (if not exists) and applies the SQL script.
# Run 'dotnet build' first to generate MainApp\_sqlscripts\main.sql

$server      = "localhost"
$database    = "^AppName^"
$sqlScript   = "MainApp\_sqlscripts\main.sql"

if (-not (Test-Path $sqlScript)) {
    Write-Error "Not found: $sqlScript. Run 'dotnet build' first."
    exit 1
}

Write-Host "Server  : $server"
Write-Host "Database: $database"

Write-Host ""
Write-Host "Creating database if not exists..."
sqlcmd -S $server -Q @"
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'$database')
BEGIN
    CREATE DATABASE [$database];
    PRINT 'Database created.';
END
ELSE
    PRINT 'Database already exists.';
"@

if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed. Check SQL Server connection."
    exit 1
}

Write-Host ""
Write-Host "Applying SQL script..."
sqlcmd -S $server -d $database -i $sqlScript

if ($LASTEXITCODE -ne 0) {
    Write-Error "SQL script failed."
    exit 1
}

Write-Host ""
Write-Host "Done. Database '$database' is ready."
