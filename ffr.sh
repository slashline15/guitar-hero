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
    echo