# PowerShell script to get iOS Bundle ID for Google Maps API key
# Run this script to get the bundle ID you need to add to your Google Cloud Console

Write-Host "Getting iOS Bundle ID for Google Maps API key..." -ForegroundColor Green

Write-Host "`n1. iOS Bundle ID:" -ForegroundColor Yellow
Write-Host "Bundle ID: com.example.memoryPinsApp" -ForegroundColor Cyan

Write-Host "`n2. Next steps for Google Cloud Console:" -ForegroundColor Green
Write-Host "1. Go to Google Cloud Console" -ForegroundColor White
Write-Host "2. Navigate to APIs & Services > Credentials" -ForegroundColor White
Write-Host "3. Find your Google Maps API key: AIzaSyCUKmzzfYOtY2MuKtIBTobiNI07sYH3F_E" -ForegroundColor White
Write-Host "4. Click on the API key to edit it" -ForegroundColor White
Write-Host "5. Under 'Application restrictions', select 'iOS apps'" -ForegroundColor White
Write-Host "6. Add the following:" -ForegroundColor White
Write-Host "   - Bundle ID: com.example.memoryPinsApp" -ForegroundColor Cyan
Write-Host "7. Save the changes" -ForegroundColor White

Write-Host "`n3. Required APIs to enable:" -ForegroundColor Green
Write-Host "- Maps SDK for iOS" -ForegroundColor White
Write-Host "- Places API (if you plan to add location search)" -ForegroundColor White
Write-Host "- Geocoding API" -ForegroundColor White
Write-Host "- Directions API" -ForegroundColor White

Write-Host "`n4. Testing commands:" -ForegroundColor Green
Write-Host "For iOS simulator: flutter run -d ios" -ForegroundColor White
Write-Host "For iOS device: flutter run -d ios --release" -ForegroundColor White
Write-Host "For iOS release build: flutter build ios --release" -ForegroundColor White

Write-Host "`nScript completed!" -ForegroundColor Green 