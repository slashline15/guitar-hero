#!/bin/bash
# debug-install.sh
# Diagnóstico do problema de instalação

echo "=== DEBUG LEX KING SYSTEM ==="
echo

# Verificar WSL
echo "1. Verificando WSL:"
if grep -qi microsoft /proc/version; then
    echo "  ✓ WSL detectado"
    cat /proc/version | grep -o "Microsoft.*" | head -1
else
    echo "  ✗ WSL não detectado"
fi

echo
echo "2. Verificando PowerShell:"

# PS5
if command -v powershell.exe &>/dev/null; then
    echo "  ✓ PowerShell 5 encontrado"
    powershell.exe -Command "echo '    Versao: ' + \$PSVersionTable.PSVersion"
else
    echo "  ✗ PowerShell 5 não encontrado"
fi

# PS7
if command -v pwsh.exe &>/dev/null; then
    echo "  ✓ PowerShell 7 encontrado"
    pwsh.exe -Command "echo '    Versao: ' + \$PSVersionTable.PSVersion"
else
    echo "  ✗ PowerShell 7 não encontrado"
fi

echo
echo "3. Verificando VcXsrv:"
if cmd.exe /c "if exist \"C:\\Program Files\\VcXsrv\\vcxsrv.exe\" (echo yes) else (echo no)" 2>/dev/null | grep -q "yes"; then
    echo "  ✓ VcXsrv instalado"
else
    echo "  ✗ VcXsrv não instalado"
fi

echo
echo "4. Verificando DISPLAY:"
if [ -n "$DISPLAY" ]; then
    echo "  ✓ DISPLAY configurado: $DISPLAY"
else
    echo "  ✗ DISPLAY não configurado"
    export DISPLAY=$(cat /etc/resolv.conf | grep nameserver | awk '{print $2}'):0.0
    echo "    Configurado agora para: $DISPLAY"
fi

echo
echo "5. Testando X Server:"
if timeout 2 xset q &>/dev/null; then
    echo "  ✓ X Server conectado"
else
    echo "  ✗ X Server não conectado"
fi

echo
echo "6. Verificando scripts:"
for script in setup-pcsx2.sh install-vcxsrv.ps1 download-bios.sh game-downloader.sh; do
    if [ -f "$script" ]; then
        echo "  ✓ $script encontrado"
    else
        echo "  ✗ $script não encontrado"
    fi
done

echo
echo "=== RECOMENDAÇÕES ==="

# Se PS7 não estiver instalado
if ! command -v pwsh.exe &>/dev/null; then
    echo "- Instale o PowerShell 7 no Windows:"
    echo "  https://github.com/PowerShell/PowerShell/releases"
fi

# Se VcXsrv não estiver instalado
if ! cmd.exe /c "if exist \"C:\\Program Files\\VcXsrv\\vcxsrv.exe\" (echo yes) else (echo no)" 2>/dev/null | grep -q "yes"; then
    echo "- Baixe e instale o VcXsrv manualmente:"
    echo "  https://sourceforge.net/projects/vcxsrv/"
    echo "  Execute com: vcxsrv.exe -multiwindow -clipboard -ac"
fi

echo
echo "=== TESTE RÁPIDO ==="
echo "Executando o PowerShell com o script..."
echo

# Tentar executar com diferentes métodos
if [ -f "install-vcxsrv.ps1" ]; then
    WIN_SCRIPT=$(wslpath -w "$PWD/install-vcxsrv.ps1")
    
    echo "Tentando com PowerShell 7..."
    if command -v pwsh.exe &>/dev/null; then
        pwsh.exe -NoProfile -ExecutionPolicy Bypass -Command "& '$WIN_SCRIPT'" 2>&1 | head -20
    fi
    
    echo
    echo "Tentando com PowerShell 5..."
    if command -v powershell.exe &>/dev/null; then
        powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "& '$WIN_SCRIPT'" 2>&1 | head -20
    fi
fi

echo
echo "=== FIM DO DEBUG ==="
echo "Se ainda houver problemas, copie esta saída e me mostre!"




