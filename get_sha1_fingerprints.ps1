# PowerShell script to get SHA-1 fingerprints for Google Maps API key
# Run this script to get the fingerprints you need to add to your Google Cloud Console

Write-Host "Getting SHA-1 fingerprints for Google Maps API key..." -ForegroundColor Green

# Get debug SHA-1
Write-Host "`n1. Debug SHA-1 fingerprint:" -ForegroundColor Yellow
try {
    $debugKey = keytool -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
    $debugSha1 = ($debugKey | Select-String "SHA1:").ToString().Split(":")[1].Trim()
    Write-Host "Debug SHA-1: $debugSha1" -ForegroundColor Cyan
} catch {
    Write-Host "Error getting debug SHA-1: $_" -ForegroundColor Red
}

# Get release SHA-1 (if you have a release keystore)
Write-Host "`n2. Release SHA-1 fingerprint:" -ForegroundColor Yellow
Write-Host "Note: For now, we're using debug keystore for release builds too." -ForegroundColor Yellow
Write-Host "In production, you should create a proper release keystore." -ForegroundColor Yellow

# Instructions
Write-Host "`n3. Next steps:" -ForegroundColor Green
Write-Host "1. Go to Google Cloud Console" -ForegroundColor White
Write-Host "2. Navigate to APIs & Services > Credentials" -ForegroundColor White
Write-Host "3. Find your Google Maps API key" -ForegroundColor White
Write-Host "4. Add the SHA-1 fingerprints above to the key restrictions" -ForegroundColor White
Write-Host "5. Make sure the package name 'com.example.memory_pins_app' is also added" -ForegroundColor White

Write-Host "`n4. Build commands:" -ForegroundColor Green
Write-Host "For debug build: flutter build apk --debug" -ForegroundColor White
Write-Host "For release build: flutter build apk --release" -ForegroundColor White
Write-Host "For app bundle: flutter build appbundle --release" -ForegroundColor White

Write-Host "`nScript completed!" -ForegroundColor Green 