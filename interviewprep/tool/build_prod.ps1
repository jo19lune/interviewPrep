if (-not $env:BACKEND_API_KEY) {
  throw "BACKEND_API_KEY doit être définie dans l'environnement avant le build."
}
if (-not $env:GOOGLE_CLIENT_ID) {
  throw "GOOGLE_CLIENT_ID doit être définie dans l'environnement avant le build."
}

flutter build apk --release `
  --dart-define=API_BASE_URL=https://interviewprep-api-7lnr.onrender.com `
  --dart-define="BACKEND_API_KEY=$env:BACKEND_API_KEY" `
  --dart-define="GOOGLE_CLIENT_ID=$env:GOOGLE_CLIENT_ID"