# debug-wrapper.ps1
try {
    & ".\install-vcxsrv.ps1"
} catch {
    Write-Host "ERRO: $_" -ForegroundColor Red
    Read-Host "Pressione Enter"
}