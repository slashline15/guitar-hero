#!/bin/bash
# check-requirements.sh
# Verifica todos os requisitos antes da instalação
# LEX KING - THE CODE REIGNS HERE

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Verificando requisitos do sistema...${NC}"
echo

# Verificar WSL
check_wsl() {
    echo -n "WSL: "
    if grep -qi microsoft /proc/version; then
        echo -e "${GREEN}✓${NC} Detectado"
        
        # Tentar detectar versão
        if [ -f /proc/sys/fs/binfmt_misc/WSLInterop ]; then
            echo -e "  Versão: WSL 2"
        else
            echo -e "  Versão: WSL 1"
        fi
    else
        echo -e "${RED}✗${NC} Não detectado"
        return 1
    fi
}

# Verificar Windows 10
check_windows() {
    echo -n "Windows: "
    if command -v cmd.exe &>/dev/null; then
        WIN_VER=$(cmd.exe /c ver 2>/dev/null | grep -oP '\d+\.\d+\.\d+' | head -1)
        echo -e "${GREEN}✓${NC} $WIN_VER"
    else
        echo -e "${YELLOW}!${NC} Não foi possível detectar versão"
    fi
}

# Verificar X Server
check_xserver() {
    echo -n "X Server: "
    
    # Verificar VcXsrv instalado
    if powershell.exe -Command "Test-Path 'C:\\Program Files\\VcXsrv\\vcxsrv.exe'" 2>/dev/null | grep -q "True"; then
        echo -e "${GREEN}✓${NC} VcXsrv instalado"
        
        # Verificar se está rodando
        if timeout 2 xset q &>/dev/null 2>&1; then
            echo -e "  Status: ${GREEN}Rodando${NC}"
        else
            echo -e "  Status: ${YELLOW}Não está rodando${NC}"
        fi
    else
        echo -e "${RED}✗${NC} VcXsrv não instalado"
    fi
}

# Verificar GPU
check_gpu() {
    echo -n "GPU: "
    
    # Tentar nvidia-smi primeiro
    if command -v nvidia-smi &>/dev/null; then
        GPU_NAME=$(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null | head -1)
        echo -e "${GREEN}✓${NC} NVIDIA $GPU_NAME"
    elif command -v glxinfo &>/dev/null; then
        GPU_INFO=$(glxinfo 2>/dev/null | grep "OpenGL renderer" | cut -d: -f2)
        echo -e "${GREEN}✓${NC}$GPU_INFO"
    else
        echo -e "${YELLOW}!${NC} Não foi possível detectar"
    fi
}

# Verificar espaço em disco
check_disk_space() {
    echo -n "Espaço em disco: "
    
    AVAILABLE=$(df -BG "$HOME" | awk 'NR==2 {print $4}' | sed 's/G//')
    if [ "$AVAILABLE" -ge 10 ]; then
        echo -e "${GREEN}✓${NC} ${AVAILABLE}GB disponível"
    else
        echo -e "${YELLOW}!${NC} ${AVAILABLE}GB disponível (recomendado: 10GB+)"
    fi
}

# Verificar pacotes essenciais
check_packages() {
    echo "Pacotes essenciais:"
    
    ESSENTIAL_PACKAGES=(
        "git"
        "wget"
        "curl"
        "python3"
    )
    
    local missing=0
    for pkg in "${ESSENTIAL_PACKAGES[@]}"; do
        echo -n "  $pkg: "
        if dpkg -l | grep -q "^ii  $pkg"; then
            echo -e "${GREEN}✓${NC}"
        else
            echo -e "${RED}✗${NC}"
            ((missing++))
        fi
    done
    
    return $missing
}

# Verificar conectividade
check_connectivity() {
    echo -n "Conectividade Internet: "
    
    if wget -q --spider https://github.com 2>/dev/null; then
        echo -e "${GREEN}✓${NC} OK"
    else
        echo -e "${RED}✗${NC} Sem conexão"
        return 1
    fi
}

# Resumo
echo "═══════════════════════════════════════"
check_wsl || exit 1
check_windows
check_xserver
check_gpu
check_disk_space
check_connectivity || exit 1
echo "═══════════════════════════════════════"
check_packages
echo "═══════════════════════════════════════"

# Resultado final
echo
if [ $? -eq 0 ]; then
    echo -e "${GREEN}Sistema pronto para instalação!${NC}"
    exit 0
else
    echo -e "${YELLOW}Alguns requisitos estão faltando.${NC}"
    echo "Execute 'sudo apt update && sudo apt install git wget curl python3' primeiro."
    exit 1
fi