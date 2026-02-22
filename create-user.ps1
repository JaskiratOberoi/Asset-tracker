# PowerShell script to create a user via Supabase Auth API
# Usage: .\create-user.ps1 -Email "admin@example.com" -Password "secure-password"

param(
    [Parameter(Mandatory=$true)]
    [string]$Email,
    
    [Parameter(Mandatory=$true)]
    [string]$Password
)

$anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE4MDMyMDQ1NDF9.Zjp54s-IyfdfyB2z0veijDFJgMZmunXmqHXkD94gWHs"

Write-Host "Creating user: $Email" -ForegroundColor Cyan

$headers = @{
    'apikey' = $anonKey
    'Content-Type' = 'application/json'
}

$body = @{
    email = $Email
    password = $Password
    email_confirm = $true
    auto_confirm = $true
} | ConvertTo-Json

try {
    $response = Invoke-WebRequest -Uri "http://localhost:8000/auth/v1/admin/users" -Method POST -Headers $headers -Body $body
    
    if ($response.StatusCode -eq 200) {
        $userData = $response.Content | ConvertFrom-Json
        Write-Host ""
        Write-Host "User created successfully!" -ForegroundColor Green
        Write-Host "User ID: $($userData.id)" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Next step: Add this user to admin_users table:" -ForegroundColor Cyan
        Write-Host "INSERT INTO public.admin_users (user_id) VALUES ('$($userData.id)');" -ForegroundColor White
    }
} catch {
    Write-Host ""
    Write-Host "Error creating user:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    
    # Try alternative method
    Write-Host ""
    Write-Host "Trying alternative signup method..." -ForegroundColor Yellow
    try {
        $signupBody = @{
            email = $Email
            password = $Password
        } | ConvertTo-Json
        
        $signupResponse = Invoke-WebRequest -Uri "http://localhost:8000/auth/v1/signup" -Method POST -Headers $headers -Body $signupBody
        
        if ($signupResponse.StatusCode -eq 200) {
            $userData = $signupResponse.Content | ConvertFrom-Json
            Write-Host ""
            Write-Host "User created via signup!" -ForegroundColor Green
            Write-Host "User ID: $($userData.user.id)" -ForegroundColor Yellow
            Write-Host ""
            Write-Host "Next step: Add this user to admin_users table:" -ForegroundColor Cyan
            Write-Host "INSERT INTO public.admin_users (user_id) VALUES ('$($userData.user.id)');" -ForegroundColor White
        }
    } catch {
        Write-Host "Signup also failed:" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
    }
}
