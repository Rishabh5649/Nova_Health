# PowerShell script to test Multi-Org API
$baseUrl = "http://localhost:3000"

Write-Host "`n========== TESTING ADMIN LOGIN ==========" -ForegroundColor Cyan

$loginBody = @{
    email = "admin@cityhospital.com"
    password = "admin123"
} | ConvertTo-Json

try {
    $loginResponse = Invoke-RestMethod -Uri "$baseUrl/auth/login" `
        -Method Post `
        -Body $loginBody `
        -ContentType "application/json"
    
    Write-Host "✓ Login successful!" -ForegroundColor Green
    Write-Host "Token: $($loginResponse.token.Substring(0,20))..." -ForegroundColor Gray
    Write-Host "User: $($loginResponse.user.name) ($($loginResponse.user.role))" -ForegroundColor Gray
    
    $token = $loginResponse.token
    
    # Get organizations
    Write-Host "`n========== GETTING ORGANIZATIONS ==========" -ForegroundColor Cyan
    $orgs = Invoke-RestMethod -Uri "$baseUrl/organizations"
    $orgId = $orgs[0].id
    Write-Host "✓ Organization: $($orgs[0].name) (ID: $orgId)" -ForegroundColor Green
    
    # Get organization settings
    Write-Host "`n========== GETTING ORG SETTINGS ==========" -ForegroundColor Cyan
    $settings = Invoke-RestMethod -Uri "$baseUrl/organizations/$orgId/settings" `
        -Headers @{ Authorization = "Bearer $token" }
    Write-Host "✓ Settings retrieved:" -ForegroundColor Green
    Write-Host "  - Enable Receptionists: $($settings.enableReceptionists)" -ForegroundColor Gray
    Write-Host "  - Allow Patient Booking: $($settings.allowPatientBooking)" -ForegroundColor Gray
    Write-Host "  - Require Doctor Approval: $($settings.requireApprovalForDoctors)" -ForegroundColor Gray
    
    # Get pending staff
    Write-Host "`n========== GETTING PENDING STAFF ==========" -ForegroundColor Cyan
    $pendingStaff = Invoke-RestMethod -Uri "$baseUrl/organizations/$orgId/staff/pending" `
        -Headers @{ Authorization = "Bearer $token" }
    Write-Host "✓ Found $($pendingStaff.Count) pending staff members" -ForegroundColor Green
    
    # Get all staff
    Write-Host "`n========== GETTING ALL STAFF ==========" -ForegroundColor Cyan
    $allStaff = Invoke-RestMethod -Uri "$baseUrl/organizations/$orgId/staff" `
        -Headers @{ Authorization = "Bearer $token" }
    Write-Host "✓ Found $($allStaff.Count) total staff members:" -ForegroundColor Green
    foreach ($member in $allStaff) {
        $statusIcon = if ($member.status -eq "APPROVED") { "✓" } elseif ($member.status -eq "PENDING") { "⏳" } else { "✗" }
        Write-Host "  $statusIcon $($member.user.name) ($($member.role)) - $($member.status)" -ForegroundColor Gray
    }
    
    # Test doctor login
    Write-Host "`n========== TESTING DOCTOR LOGIN ==========" -ForegroundColor Cyan
    $doctorLoginBody = @{
        email = "sarah@cityhospital.com"
        password = "doc123"
    } | ConvertTo-Json
    
    $doctorResponse = Invoke-RestMethod -Uri "$baseUrl/auth/login" `
        -Method Post `
        -Body $doctorLoginBody `
        -ContentType "application/json"
    Write-Host "✓ Doctor login successful!" -ForegroundColor Green
    Write-Host "  Doctor: $($doctorResponse.user.name)" -ForegroundColor Gray
    
    # Test receptionist login
    Write-Host "`n========== TESTING RECEPTIONIST LOGIN ==========" -ForegroundColor Cyan
    $recepLoginBody = @{
        email = "mary@cityhospital.com"
        password = "recep123"
    } | ConvertTo-Json
    
    $recepResponse = Invoke-RestMethod -Uri "$baseUrl/auth/login" `
        -Method Post `
        -Body $recepLoginBody `
        -ContentType "application/json"
    Write-Host "✓ Receptionist login successful!" -ForegroundColor Green
    Write-Host "  Receptionist: $($recepResponse.user.name)" -ForegroundColor Gray
    
    Write-Host "`n========== ALL TESTS PASSED! 🎉 ==========" -ForegroundColor Green
    
} catch {
    Write-Host "✗ Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host $_.Exception -ForegroundColor Red
}
