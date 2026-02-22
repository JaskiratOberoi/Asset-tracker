# PowerShell script to set up the first admin user
# Usage: .\setup-admin.ps1 -UserEmail "admin@example.com"

param(
    [Parameter(Mandatory=$true)]
    [string]$UserEmail
)

Write-Host "Setting up admin user for: $UserEmail" -ForegroundColor Cyan

# Connect to Supabase database
$dbHost = "localhost"
$dbPort = "25432"
$dbName = "postgres"
$dbUser = "postgres"
$dbPassword = Read-Host "Enter Postgres password (default: your-super-secret-and-long-postgres-password)" -AsSecureString
$plainPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($dbPassword)
)

if ([string]::IsNullOrWhiteSpace($plainPassword)) {
    $plainPassword = "your-super-secret-and-long-postgres-password"
}

# Get user ID from auth.users
$query = "SELECT id FROM auth.users WHERE email = '$UserEmail';"
$env:PGPASSWORD = $plainPassword

Write-Host "`nFetching user ID from auth.users..." -ForegroundColor Yellow
$userId = & psql -h $dbHost -p $dbPort -U $dbUser -d $dbName -t -c $query 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Host "Error connecting to database. Make sure:" -ForegroundColor Red
    Write-Host "1. Docker containers are running (docker-compose ps)" -ForegroundColor Red
    Write-Host "2. psql is installed and in your PATH" -ForegroundColor Red
    Write-Host "3. Database is healthy" -ForegroundColor Red
    exit 1
}

$userId = $userId.Trim()

if ([string]::IsNullOrWhiteSpace($userId)) {
    Write-Host "User not found: $UserEmail" -ForegroundColor Red
    Write-Host "Please create the user first through Supabase Studio or Auth API" -ForegroundColor Yellow
    exit 1
}

Write-Host "Found user ID: $userId" -ForegroundColor Green

# Insert into admin_users
$insertQuery = "INSERT INTO public.admin_users (user_id) VALUES ('$userId') ON CONFLICT (user_id) DO NOTHING;"
Write-Host "`nAdding user to admin_users table..." -ForegroundColor Yellow

& psql -h $dbHost -p $dbPort -U $dbUser -d $dbName -c $insertQuery 2>&1 | Out-Null

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n✓ Successfully added $UserEmail as admin!" -ForegroundColor Green
    Write-Host "The user can now SELECT/UPDATE/DELETE from companies, locations, and assets tables." -ForegroundColor Green
} else {
    Write-Host "`nError adding admin user. User may already be an admin." -ForegroundColor Yellow
}

$env:PGPASSWORD = ""
