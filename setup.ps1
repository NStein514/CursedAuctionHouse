# One-time setup for Windows. Run from the project folder (the one containing pubspec.yaml):
#   powershell -ExecutionPolicy Bypass -File .\setup.ps1
# Adds the platform folders (android, ios, windows, web) WITHOUT touching the game code.
if (-not (Test-Path .\pubspec.yaml) -or -not (Test-Path .\lib\main.dart)) {
  Write-Error "Run this from the project folder that contains pubspec.yaml and lib\main.dart"; exit 1
}
foreach ($d in @("lib", "test")) { if (Test-Path ".\$d") { Copy-Item ".\$d" ".\${d}_backup" -Recurse -Force } }
Copy-Item .\pubspec.yaml .\pubspec.yaml.bak -Force
flutter create --platforms=windows,android,ios,web --org com.example .
# Restore the game files in case the template replaced anything.
foreach ($d in @("lib", "test")) { if (Test-Path ".\${d}_backup") { Remove-Item ".\$d" -Recurse -Force; Move-Item ".\${d}_backup" ".\$d" } }
Move-Item .\pubspec.yaml.bak .\pubspec.yaml -Force
flutter pub get
Write-Host "Done. Run:  flutter run -d windows   (or -d edge / -d chrome)"
