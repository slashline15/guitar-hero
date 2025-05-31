# install-vcxsrv.ps1
# Instalador automático do VcXsrv para Windows
# LEX KING - THE CODE REIGNS HERE

param(
    [switch]$Silent = $false
)

$ErrorActionPreference = "Stop"

# Cores
function Write-ColorOutput($ForegroundColor) {
    $fc = $host.UI.RawUI.ForegroundColor
    $host.UI.RawUI.ForegroundColor = $ForegroundColor
    if ($args) {
        Write-Output $args
    }
    $host.UI.RawUI.ForegroundColor = $fc
}

# Banner
Clear-Host
Write-Host "╔═══════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║     VcXsrv Installer for WSL          ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""
Write-Host "          ----------------------          " -ForegroundColor Green
Write-Host "              L E X   K I N G             " -ForegroundColor Green
Write-Host "          ----------------------          " -ForegroundColor Green
Write-Host ""

# Verificar se já está instalado
$vcxsrvPath = "${env:ProgramFiles}\VcXsrv\vcxsrv.exe"
if (Test-Path $vcxsrvPath) {
    Write-Host "[✓] VcXsrv já está instalado!" -ForegroundColor Green
    $reinstall = Read-Host "Deseja reinstalar? (S/N)"
    if ($reinstall -ne "S" -and $reinstall -ne "s") {
        exit 0
    }
}

# Criar diretório temporário
$tempDir = "$env:TEMP\vcxsrv-installer"
if (!(Test-Path $tempDir)) {
    New-Item -ItemType Directory -Path $tempDir | Out-Null
}

Write-Host "[*] Baixando VcXsrv..." -ForegroundColor Yellow

# URL do VcXsrv
$vcxsrvUrl = "https://sourceforge.net/projects/vcxsrv/files/latest/download"
$installerPath = "$tempDir\vcxsrv-installer.exe"

try {
    # Download com barra de progresso
    $webClient = New-Object System.Net.WebClient
    $webClient.DownloadProgressChanged += {
        Write-Progress -Activity "Baixando VcXsrv" -Status "$($_.ProgressPercentage)% Completo" -PercentComplete $_.ProgressPercentage
    }
    
    $downloadTask = $webClient.DownloadFileTaskAsync($vcxsrvUrl, $installerPath)
    while (!$downloadTask.IsCompleted) {
        Start-Sleep -Milliseconds 100
    }
    
    Write-Progress -Activity "Baixando VcXsrv" -Completed
    Write-Host "[✓] Download concluído!" -ForegroundColor Green
} catch {
    Write-Host "[✗] Erro no download: $_" -ForegroundColor Red
    exit 1
}

# Instalar VcXsrv
Write-Host "[*] Instalando VcXsrv..." -ForegroundColor Yellow

try {
    if ($Silent) {
        Start-Process -FilePath $installerPath -ArgumentList "/S" -Wait
    } else {
        Start-Process -FilePath $installerPath -Wait
    }
    Write-Host "[✓] VcXsrv instalado com sucesso!" -ForegroundColor Green
} catch {
    Write-Host "[✗] Erro na instalação: $_" -ForegroundColor Red
    exit 1
}

# Criar arquivo de configuração
Write-Host "[*] Criando configuração otimizada..." -ForegroundColor Yellow

$configPath = "$env:USERPROFILE\vcxsrv-wsl.xlaunch"
$configContent = @'
<?xml version="1.0" encoding="UTF-8"?>
<XLaunch WindowMode="MultiWindow" ClientMode="NoClient" LocalClient="False" Display="0" LocalProgram="xcalc" RemoteProgram="xterm" RemotePassword="" PrivateKey="" RemoteHost="" RemoteUser="" XDMCPHost="" XDMCPBroadcast="False" XDMCPIndirect="False" Clipboard="True" ClipboardPrimary="True" ExtraParams="" Wgl="True" DisableAC="True" XDMCPTerminate="False"/>
'@

$configContent | Out-File -FilePath $configPath -Encoding UTF8
Write-Host "[✓] Configuração criada em: $configPath" -ForegroundColor Green

# Alternativa: iniciar diretamente sem arquivo .xlaunch
$vcxsrvExe = "${env:ProgramFiles}\VcXsrv\vcxsrv.exe"
if (Test-Path $vcxsrvExe) {
    # Matar instâncias anteriores
    Get-Process vcxsrv -ErrorAction SilentlyContinue | Stop-Process -Force
    Start-Sleep -Seconds 1
    
    # Iniciar com parâmetros diretos
    Start-Process -FilePath $vcxsrvExe -ArgumentList "-multiwindow", "-clipboard", "-ac" -WindowStyle Hidden
    Write-Host "[✓] VcXsrv iniciado com parâmetros diretos!" -ForegroundColor Green
}

# Adicionar ao Firewall
Write-Host "[*] Configurando Firewall do Windows..." -ForegroundColor Yellow

try {
    New-NetFirewallRule -DisplayName "VcXsrv Windows X Server" `
        -Direction Inbound `
        -Program "${env:ProgramFiles}\VcXsrv\vcxsrv.exe" `
        -Action Allow `
        -Profile Any `
        -ErrorAction SilentlyContinue
    
    Write-Host "[✓] Regra de Firewall criada!" -ForegroundColor Green
} catch {
    Write-Host "[!] Aviso: Não foi possível criar regra de firewall automaticamente" -ForegroundColor Yellow
    Write-Host "    Por favor, permita VcXsrv manualmente no Windows Defender Firewall" -ForegroundColor Yellow
}

# Criar atalho na área de trabalho
Write-Host "[*] Criando atalho..." -ForegroundColor Yellow

$WshShell = New-Object -comObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut("$env:USERPROFILE\Desktop\VcXsrv for WSL.lnk")
$Shortcut.TargetPath = "${env:ProgramFiles}\VcXsrv\vcxsrv.exe"
$Shortcut.Arguments = "-multiwindow -clipboard -ac"
$Shortcut.IconLocation = "${env:ProgramFiles}\VcXsrv\vcxsrv.exe"
$Shortcut.Save()

Write-Host "[✓] Atalho criado na Área de Trabalho!" -ForegroundColor Green

# Iniciar VcXsrv
Write-Host ""
Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan
Write-Host "[✓] Instalação concluída!" -ForegroundColor Green
Write-Host ""
Write-Host "Iniciando VcXsrv automaticamente..." -ForegroundColor Yellow

# Usar execução direta ao invés de xlaunch
$vcxsrvExe = "${env:ProgramFiles}\VcXsrv\vcxsrv.exe"
if (Test-Path $vcxsrvExe) {
    Start-Process -FilePath $vcxsrvExe -ArgumentList "-multiwindow", "-clipboard", "-ac" -WindowStyle Hidden
} else {
    Write-Host "[!] VcXsrv.exe não encontrado no caminho esperado" -ForegroundColor Red
}

Write-Host "[✓] VcXsrv está rodando!" -ForegroundColor Green
Write-Host ""
Write-Host "Você pode fechar esta janela e voltar ao WSL." -ForegroundColor Cyan
Write-Host ""

# Limpar arquivos temporários
Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue

# Manter janela aberta se não for silent
if (!$Silent) {
    Write-Host "Pressione qualquer tecla para fechar..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}