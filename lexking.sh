#!/bin/bash
# lex-king-installer.sh
# Instalador completo LEX KING - Sem PowerShell, sem complicação!

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Banner épico
show_banner() {
    clear
    echo -e "${YELLOW}╔═══════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║${GREEN}     LEX KING ALL-IN-ONE INSTALLER    ${YELLOW}║${NC}"
    echo -e "${YELLOW}╚═══════════════════════════════════════╝${NC}"
    echo -e "${CYAN}        Não é só sobre letrinhas...      ${NC}"
    echo -e "${CYAN}         É sobre CRIAR coisas!           ${NC}"
    echo
}

# Função de progresso
progress() {
    local current=$1
    local total=$2
    local width=40
    local percentage=$((current * 100 / total))
    local completed=$((width * current / total))
    
    printf "\r["
    printf "%${completed}s" | tr ' ' '='
    printf "%$((width - completed))s" | tr ' ' '-'
    printf "] %d%%" $percentage
}

# 1. Verificar e instalar cmatrix
install_cmatrix() {
    if ! command -v cmatrix &> /dev/null; then
        echo -e "${YELLOW}Instalando cmatrix para o Leo...${NC}"
        sudo apt-get update -qq && sudo apt-get install -y cmatrix -qq
    fi
}

# 2. Instalar dependências básicas
install_basic_deps() {
    echo -e "${BLUE}Instalando dependências básicas...${NC}"
    
    PACKAGES="wget curl git x11-apps mesa-utils"
    sudo apt-get update
    sudo apt-get install -y $PACKAGES
}

# 3. Instalar VcXsrv (sem PowerShell!)
install_vcxsrv() {
    echo -e "${BLUE}Verificando VcXsrv...${NC}"
    
    if cmd.exe /c "if exist \"C:\\Program Files\\VcXsrv\\vcxsrv.exe\" (echo yes)" 2>/dev/null | grep -q "yes"; then
        echo -e "${GREEN}✓ VcXsrv já instalado!${NC}"
        
        # Iniciar
        cmd.exe /c "taskkill /F /IM vcxsrv.exe" 2>/dev/null
        sleep 1
        cmd.exe /c "\"C:\\Program Files\\VcXsrv\\vcxsrv.exe\" -multiwindow -clipboard -ac" 2>/dev/null &
        echo -e "${GREEN}✓ VcXsrv iniciado!${NC}"
    else
        echo -e "${YELLOW}VcXsrv não encontrado!${NC}"
        echo
        echo "Por favor, instale manualmente:"
        echo "1. Baixe: https://sourceforge.net/projects/vcxsrv/"
        echo "2. Instale normalmente"
        echo "3. Execute com: -multiwindow -clipboard -ac"
        echo
        read -p "Pressione Enter quando o VcXsrv estiver instalado e rodando..."
    fi
    
    # Configurar DISPLAY
    export DISPLAY=$(cat /etc/resolv.conf | grep nameserver | awk '{print $2}'):0.0
    echo "export DISPLAY=\$(cat /etc/resolv.conf | grep nameserver | awk '{print \$2}'):0.0" >> ~/.bashrc
}

# 4. Instalar PCSX2
install_pcsx2() {
    echo -e "${BLUE}Instalando PCSX2...${NC}"
    
    # Instalar dependências do PCSX2
    sudo apt-get install -y \
        libgtk-3-0 libsdl2-2.0-0 libaio1 \
        libsoundtouch1 libportaudio2 \
        libgl1-mesa-glx libglu1-mesa
    
    # Baixar AppImage
    mkdir -p ~/pcsx2
    cd ~/pcsx2
    
    if [ ! -f "pcsx2.AppImage" ]; then
        echo "Baixando PCSX2..."
        wget -q --show-progress \
            "https://github.com/PCSX2/pcsx2/releases/download/v1.7.5474/pcsx2-v1.7.5474-linux-appimage-x64-Qt.AppImage" \
            -O pcsx2.AppImage
        chmod +x pcsx2.AppImage
    fi
    
    # Criar link
    sudo ln -sf "$HOME/pcsx2/pcsx2.AppImage" /usr/local/bin/pcsx2
    
    echo -e "${GREEN}✓ PCSX2 instalado!${NC}"
}

# 5. Criar estrutura de pastas
create_folders() {
    echo -e "${BLUE}Criando estrutura de pastas...${NC}"
    
    mkdir -p ~/pcsx2-games
    mkdir -p ~/pcsx2-bios
    mkdir -p ~/.config/PCSX2
    
    echo -e "${GREEN}✓ Pastas criadas!${NC}"
}

# 6. Criar launcher
create_launcher() {
    cat > ~/lex-king-launcher.sh << 'EOF'
#!/bin/bash
# LEX KING LAUNCHER

# Cores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Banner com cmatrix
clear
if command -v cmatrix &> /dev/null; then
    echo -e "${YELLOW}Letrinhas amarelas pro Leo...${NC}"
    timeout 3 cmatrix -b -a -C yellow
fi

clear