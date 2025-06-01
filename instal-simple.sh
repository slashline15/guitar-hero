#!/bin/bash
# install-vcxsrv-simple.sh
# Versão simplificada para instalar VcXsrv

echo "==================================="
echo "   Instalador VcXsrv Simplificado  "
echo "       LEX KING EDITION            "
echo "==================================="
echo

# Verificar se VcXsrv já está instalado
if cmd.exe /c "if exist \"C:\\Program Files\\VcXsrv\\vcxsrv.exe\" (echo yes)" 2>/dev/null | grep -q "yes"; then
    echo "✓ VcXsrv já está instalado!"
    
    # Iniciar VcXsrv
    echo "Iniciando VcXsrv..."
    cmd.exe /c "\"C:\\Program Files\\VcXsrv\\vcxsrv.exe\" -multiwindow -clipboard -ac" 2>/dev/null &
    
    echo "✓ VcXsrv iniciado!"
else
    echo "VcXsrv não está instalado."
    echo
    echo "Opções:"
    echo "1) Baixar e instalar automaticamente"
    echo "2) Instruções para instalação manual"
    echo
    read -p "Escolha (1/2): " choice
    
    if [ "$choice" = "1" ]; then
        echo "Baixando VcXsrv..."
        
        # Criar pasta temporária
        TEMP_DIR="/tmp/vcxsrv-install"
        mkdir -p "$TEMP_DIR"
        
        # Baixar instalador
        wget -q --show-progress "https://sourceforge.net/projects/vcxsrv/files/latest/download" -O "$TEMP_DIR/vcxsrv-installer.exe"
        
        if [ -f "$TEMP_DIR/vcxsrv-installer.exe" ]; then
            echo "Download concluído!"
            echo "Abrindo instalador no Windows..."
            
            # Abrir instalador
            cmd.exe /c "$(wslpath -w "$TEMP_DIR/vcxsrv-installer.exe")" &
            
            echo
            echo "Complete a instalação e pressione Enter quando terminar..."
            read
            
            # Iniciar VcXsrv
            echo "Iniciando VcXsrv..."
            cmd.exe /c "\"C:\\Program Files\\VcXsrv\\vcxsrv.exe\" -multiwindow -clipboard -ac" 2>/dev/null &
            
            echo "✓ Instalação concluída!"
        else
            echo "Erro no download!"
        fi
    else
        echo
        echo "=== Instalação Manual ==="