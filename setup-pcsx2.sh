#!/bin/bash
# setup-pcsx2.sh
# Script principal de instalação PCSX2 para Guitar Hero
# LEX KING - THE CODE REIGNS HERE

set -euo pipefail

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Variáveis globais
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.pcsx2-wsl"
LOG_FILE="$CONFIG_DIR/install.log"
GITHUB_REPO="https://github.com/slashline15/guitar-hero.git"

# Criar diretórios
mkdir -p "$CONFIG_DIR"

# Banner principal
show_banner() {
    clear
    echo -e "${CYAN}╔═══════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║  PCSX2 PRA JOGAR GUITAR HERO 3 v1.0   ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════╝${NC}"
    echo -e "${CYAN} -                                      - ${NC}"
    echo -e "${GREEN}          ----------------------          ${NC}"
    echo -e "${GREEN}              L E X   K I N G             ${NC}"
    echo -e "${GREEN}          ----------------------          ${NC}"
    echo -e "${GREEN}          THE CODE REIGNS HERE            ${NC}"
    echo -e "${CYAN} -                                      - ${NC}"
    echo
}

# Logging
log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERRO]${NC} $1" | tee -a "$LOG_FILE"
    exit 1
}

warning() {
    echo -e "${YELLOW}[AVISO]${NC} $1" | tee -a "$LOG_FILE"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

# Verificar WSL
check_wsl() {
    log "Verificando ambiente WSL..."
    
    if ! grep -qi microsoft /proc/version; then
        error "Este script deve ser executado dentro do WSL!"
    fi
    
    # Detectar versão do WSL
    if command -v wsl.exe &> /dev/null; then
        WSL_VERSION=$(wsl.exe -l -v 2>/dev/null | grep -E "Ubuntu|$WSL_DISTRO_NAME" | awk '{print $4}' | tr -d '\r')
        info "WSL versão detectada: ${WSL_VERSION:-1}"
    else
        WSL_VERSION="1"
    fi
    
    echo "WSL_VERSION=$WSL_VERSION" > "$CONFIG_DIR/config"
}

# Baixar scripts do GitHub
download_scripts() {
    log "Baixando scripts auxiliares do GitHub..."
    
    # Se já estamos no diretório do repositório, não precisamos clonar
    if [ -f "$SCRIPT_DIR/download-bios.sh" ] && [ -f "$SCRIPT_DIR/game-downloader.sh" ]; then
        info "Scripts já presentes localmente"
        return 0
    fi
    
    # Clonar repositório
    cd /tmp
    rm -rf guitar-hero-temp
    git clone --depth 1 "$GITHUB_REPO" guitar-hero-temp || error "Falha ao clonar repositório"
    
    # Copiar scripts necessários
    cp guitar-hero-temp/*.sh "$SCRIPT_DIR/" 2>/dev/null || true
    cp guitar-hero-temp/*.ps1 "$SCRIPT_DIR/" 2>/dev/null || true
    
    # Tornar executáveis
    chmod +x "$SCRIPT_DIR"/*.sh
    
    # Limpar
    rm -rf guitar-hero-temp
    
    log "Scripts baixados com sucesso!"
}

# Instalar VcXsrv no Windows
install_vcxsrv() {
    log "Verificando VcXsrv no Windows..."
    
    # Verificar se já está instalado
    if powershell.exe -Command "Test-Path 'C:\\Program Files\\VcXsrv\\vcxsrv.exe'" 2>/dev/null | grep -q "True"; then
        info "VcXsrv já está instalado!"
        
        # Verificar se está rodando
        if ! timeout 2 xset q &>/dev/null 2>&1; then
            warning "VcXsrv não está rodando. Iniciando..."
            
            # Tentar iniciar VcXsrv
            powershell.exe -Command "Start-Process 'C:\\Program Files\\VcXsrv\\xlaunch.exe' -ArgumentList '-run', '$env:USERPROFILE\\vcxsrv-wsl.xlaunch'" 2>/dev/null &
            
            sleep 3
        fi
    else
        warning "VcXsrv não encontrado. Instalando..."
        
        # Executar script PowerShell
        if [ -f "$SCRIPT_DIR/install-vcxsrv.ps1" ]; then
            info "Abrindo instalador do VcXsrv no Windows..."
            powershell.exe -ExecutionPolicy Bypass -File "$(wslpath -w "$SCRIPT_DIR/install-vcxsrv.ps1")" -Silent
        else
            error "Script install-vcxsrv.ps1 não encontrado!"
        fi
    fi
    
    # Configurar DISPLAY
    export DISPLAY=$(cat /etc/resolv.conf | grep nameserver | awk '{print $2}'):0.0
    
    # Adicionar ao .bashrc apenas se não existir
    if ! grep -qF 'export DISPLAY=' ~/.bashrc; then
        echo "export DISPLAY=\$(cat /etc/resolv.conf | grep nameserver | awk '{print \$2}'):0.0" >> ~/.bashrc
    fi
}

# Instalar dependências
install_dependencies() {
    log "Instalando dependências do sistema..."
    
    # Atualizar sistema
    sudo apt-get update
    
    # Lista de pacotes
    PACKAGES=(
        # Essenciais
        software-properties-common
        build-essential cmake git curl wget p7zip-full
        
        # Python
        python3 python3-pip python3-venv
        
        # FUSE para AppImage
        libfuse2
        
        # X11/GUI
        x11-apps x11-utils x11-xserver-utils
        libgtk-3-0 libgtk-3-dev
        
        # OpenGL/Mesa
        libgl1-mesa-dev libgl1-mesa-glx
        libglu1-mesa-dev mesa-utils
        
        # PCSX2 deps
        libwxgtk3.0-gtk3-dev libsdl2-dev
        libasound2-dev libpulse-dev
        libportaudio2 libsoundtouch-dev
        libaio-dev libpcap-dev
        
        # Ferramentas extras
        transmission-cli # Para downloads torrent
        jq # Para parsing JSON
        unrar # Para arquivos RAR (alternativa ao p7zip-rar)
    )
    
    for package in "${PACKAGES[@]}"; do
        if ! dpkg -l | grep -q "^ii  $package"; then
            info "Instalando $package..."
            sudo apt-get install -y "$package" || warning "Falha ao instalar $package"
        fi
    done
    
    # Tentar instalar p7zip-rar se disponível (opcional)
    if apt-cache show p7zip-rar &>/dev/null; then
        sudo apt-get install -y p7zip-rar || info "p7zip-rar não disponível, usando unrar"
    fi
    
    log "Dependências instaladas!"
}

# Instalar PCSX2
install_pcsx2() {
    log "Instalando PCSX2..."
    
    # Verificar se já está instalado
    if command -v pcsx2 &> /dev/null; then
        info "PCSX2 já está instalado!"
        return 0
    fi
    
    # Tentar via PPA primeiro
    info "Adicionando repositório PCSX2..."
    sudo add-apt-repository -y ppa:pcsx2-team/pcsx2-daily 2>/dev/null || {
        warning "PPA falhou. Usando método AppImage..."
        
        # Download AppImage
        mkdir -p "$HOME/pcsx2"
        cd "$HOME/pcsx2"
        
        log "Baixando PCSX2 AppImage..."
        wget -q --show-progress \
            https://github.com/PCSX2/pcsx2/releases/download/v1.7.5474/pcsx2-v1.7.5474-linux-appimage-x64-Qt.AppImage \
            -O pcsx2.AppImage
        
        chmod +x pcsx2.AppImage
        
        # Link simbólico
        sudo ln -sf "$HOME/pcsx2/pcsx2.AppImage" /usr/local/bin/pcsx2
        
        info "PCSX2 AppImage instalado!"
        return 0
    }
    
    # Instalar do PPA
    sudo apt-get update
    sudo apt-get install -y pcsx2
    
    log "PCSX2 instalado com sucesso!"
}

# Configurar PCSX2 para Guitar Hero
configure_pcsx2_guitar_hero() {
    log "Configurando PCSX2 para Guitar Hero..."
    
    # Criar diretórios
    mkdir -p "$HOME/.config/PCSX2/inis"
    mkdir -p "$HOME/pcsx2-games"
    mkdir -p "$HOME/pcsx2-bios"
    mkdir -p "$HOME/.config/PCSX2/memcards"
    
    # Configuração otimizada para Guitar Hero
    cat > "$HOME/.config/PCSX2/inis/PCSX2.ini" << 'EOF'
[Settings]
EnableSpeedHacks=enabled
EnableGameFixes=enabled
EnablePresets=enabled

[Speedhacks]
EECycleRate=2
VUCycleSteal=1
fastCDVD=enabled
IntcStat=enabled
WaitLoop=enabled
vuFlagHack=enabled
vuThread=enabled
vu1Instant=enabled

[Gamefixes]
FpuMulHack=enabled
FpuNegDivHack=enabled
XgKickHack=enabled
IpuWaitHack=enabled
EETimingHack=enabled
SkipMPEGHack=enabled

[GPU]
Renderer=OpenGL (Hardware)
AspectRatio=16:9
Windowed=enabled
DisableWindowResize=disabled
DefaultToNativeResolution=disabled
InternalResolution=3
EnableShadeBoost=disabled
ShadeBoostBrightness=50
ShadeBoostContrast=50
ShadeBoostSaturation=50
UseDebugDevice=disabled
UseBlitSwapChain=disabled

[Audio]
Interpolation=2
SynchMode=1
Latency=100
Volume=100

[Controllers]
# Configuração para controle de Guitar Hero será feita na primeira execução

[Folders]
Bios=$HOME/pcsx2-bios
Savestates=$HOME/.config/PCSX2/sstates
Snapshots=$HOME/.config/PCSX2/snaps
Logs=$HOME/.config/PCSX2/logs
MemoryCards=$HOME/.config/PCSX2/memcards
EOF
    
    info "Configuração otimizada criada!"
}

# Criar interface CLI principal
create_main_cli() {
    log "Criando interface CLI principal..."
    
    cat > "$CONFIG_DIR/pcsx2-manager.sh" << 'EOF'
#!/bin/bash
# pcsx2-manager.sh - Interface principal
# LEX KING - THE CODE REIGNS HERE

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Diretórios
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GAMES_DIR="$HOME/pcsx2-games"
BIOS_DIR="$HOME/pcsx2-bios"

# Banner
show_banner() {
    clear
    echo -e "${CYAN}╔═══════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║  PCSX2 PRA JOGAR GUITAR HERO 3 v1.0   ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════╝${NC}"
    echo -e "${CYAN} -                                      - ${NC}"
    echo -e "${GREEN}          ----------------------          ${NC}"
    echo -e "${GREEN}              L E X   K I N G             ${NC}"
    echo -e "${GREEN}          ----------------------          ${NC}"
    echo -e "${GREEN}          THE CODE REIGNS HERE            ${NC}"
    echo -e "${CYAN} -                                      - ${NC}"
    echo
}

# Iniciar PCSX2
start_pcsx2() {
    echo -e "${BLUE}Iniciando PCSX2...${NC}"
    
    # Configurar DISPLAY
    if [ -z "$DISPLAY" ]; then
        export DISPLAY=$(cat /etc/resolv.conf | grep nameserver | awk '{print $2}'):0.0
    fi
    
    # Verificar X Server
    if ! timeout 2 xset q &>/dev/null; then
        echo -e "${RED}X Server não detectado!${NC}"
        echo "Certifique-se que o VcXsrv está rodando no Windows."
        read -p "Tentar iniciar mesmo assim? (s/N): " -n 1 -r
        echo
        [[ ! $REPLY =~ ^[Ss]$ ]] && return
    fi
    
    if command -v pcsx2 &> /dev/null; then
        pcsx2 &
    elif [ -f "$HOME/pcsx2/pcsx2.AppImage" ]; then
        "$HOME/pcsx2/pcsx2.AppImage" &
    else
        echo -e "${RED}PCSX2 não encontrado!${NC}"
    fi
    
    echo -e "${GREEN}PCSX2 iniciado!${NC}"
    read -p "Pressione Enter para continuar..."
}

# Quick Play Guitar Hero
quick_play_guitar_hero() {
    show_banner
    echo -e "${MAGENTA}╔═══════════════════════════════════════╗${NC}"
    echo -e "${MAGENTA}║         QUICK PLAY GUITAR HERO        ║${NC}"
    echo -e "${MAGENTA}╚═══════════════════════════════════════╝${NC}"
    echo
    
    # Listar jogos Guitar Hero
    local gh_games=()
    for game in "$GAMES_DIR"/*[Gg]uitar*[Hh]ero*.{iso,ISO} 2>/dev/null; do
        [ -f "$game" ] && gh_games+=("$game")
    done
    
    if [ ${#gh_games[@]} -eq 0 ]; then
        echo -e "${RED}Nenhum jogo Guitar Hero encontrado!${NC}"
        echo
        echo "Use a opção 4 para baixar jogos."
        read -p "Pressione Enter para continuar..."
        return
    fi
    
    echo -e "${GREEN}Jogos Guitar Hero disponíveis:${NC}"
    local count=1
    for game in "${gh_games[@]}"; do
        echo -e "  ${GREEN}$count)${NC} $(basename "$game")"
        ((count++))
    done
    
    echo
    read -p "Escolha o jogo (1-$((count-1))): " choice
    
    if [[ $choice -ge 1 && $choice -lt $count ]]; then
        local selected="${gh_games[$((choice-1))]}"
        echo -e "${BLUE}Iniciando: $(basename "$selected")${NC}"
        
        export DISPLAY=$(cat /etc/resolv.conf | grep nameserver | awk '{print $2}'):0.0
        
        if command -v pcsx2 &> /dev/null; then
            pcsx2 "$selected" &
        elif [ -f "$HOME/pcsx2/pcsx2.AppImage" ]; then
            "$HOME/pcsx2/pcsx2.AppImage" "$selected" &
        fi
        
        echo -e "${GREEN}Jogo iniciado! Rock on! 🎸${NC}"
    fi
    
    read -p "Pressione Enter para continuar..."
}

# Status do sistema
system_status() {
    show_banner
    echo -e "${BLUE}STATUS DO SISTEMA${NC}"
    echo -e "${CYAN}═══════════════════════════════════════${NC}"
    echo
    
    # WSL
    echo -e "${YELLOW}WSL:${NC}"
    grep -qi microsoft /proc/version && echo -e "  ${GREEN}✓${NC} Rodando no WSL" || echo -e "  ${RED}✗${NC} Não está no WSL"
    
    # X Server
    echo -e "${YELLOW}X Server:${NC}"
    if timeout 2 xset q &>/dev/null; then
        echo -e "  ${GREEN}✓${NC} VcXsrv conectado"
    else
        echo -e "  ${RED}✗${NC} VcXsrv não conectado"
    fi
    
    # PCSX2
    echo -e "${YELLOW}PCSX2:${NC}"
    if command -v pcsx2 &> /dev/null || [ -f "$HOME/pcsx2/pcsx2.AppImage" ]; then
        echo -e "  ${GREEN}✓${NC} PCSX2 instalado"
    else
        echo -e "  ${RED}✗${NC} PCSX2 não encontrado"
    fi
    
    # BIOS
    echo -e "${YELLOW}BIOS PS2:${NC}"
    local bios_count=$(ls -1 "$BIOS_DIR"/*.{bin,BIN,rom,ROM} 2>/dev/null | wc -l)
    if [ $bios_count -gt 0 ]; then
        echo -e "  ${GREEN}✓${NC} $bios_count BIOS encontrada(s)"
    else
        echo -e "  ${RED}✗${NC} Nenhuma BIOS encontrada"
    fi
    
    # Jogos
    echo -e "${YELLOW}Jogos:${NC}"
    local games_count=$(ls -1 "$GAMES_DIR"/*.{iso,ISO,bin,BIN} 2>/dev/null | wc -l)
    local gh_count=$(ls -1 "$GAMES_DIR"/*[Gg]uitar*[Hh]ero*.{iso,ISO} 2>/dev/null | wc -l)
    echo -e "  ${GREEN}→${NC} Total: $games_count jogo(s)"
    echo -e "  ${GREEN}→${NC} Guitar Hero: $gh_count jogo(s)"
    
    # GPU
    echo -e "${YELLOW}GPU/OpenGL:${NC}"
    if command -v glxinfo &> /dev/null; then
        local renderer=$(glxinfo 2>/dev/null | grep "OpenGL renderer" | cut -d: -f2)
        echo -e "  ${GREEN}→${NC}$renderer"
    else
        echo -e "  ${YELLOW}!${NC} glxinfo não disponível"
    fi
    
    echo
    read -p "Pressione Enter para continuar..."
}

# Menu principal
while true; do
    show_banner
    
    echo -e "${GREEN}1)${NC} 🎮 Iniciar PCSX2"
    echo -e "${GREEN}2)${NC} 🎸 Quick Play Guitar Hero"
    echo -e "${GREEN}3)${NC} 📀 Gerenciar BIOS"
    echo -e "${GREEN}4)${NC} 🎯 Baixar Jogos"
    echo -e "${GREEN}5)${NC} 📊 Status do Sistema"
    echo -e "${GREEN}6)${NC} ⚙️  Configurações"
    echo -e "${GREEN}7)${NC} 📝 Instruções"
    echo -e "${GREEN}8)${NC} 🚪 Sair"
    echo
    echo -e "${CYAN}═══════════════════════════════════════${NC}"
    echo
    
    read -p "Escolha uma opção: " choice
    
    case $choice in
        1) start_pcsx2 ;;
        2) quick_play_guitar_hero ;;
        3)
            if [ -f "$(dirname "$0")/download-bios.sh" ]; then
                bash "$(dirname "$0")/download-bios.sh"
            else
                echo -e "${RED}Script download-bios.sh não encontrado!${NC}"
                read -p "Pressione Enter..."
            fi
            ;;
        4)
            if [ -f "$(dirname "$0")/game-downloader.sh" ]; then
                bash "$(dirname "$0")/game-downloader.sh"
            else
                echo -e "${RED}Script game-downloader.sh não encontrado!${NC}"
                read -p "Pressione Enter..."
            fi
            ;;
        5) system_status ;;
        6)
            echo -e "${YELLOW}Em desenvolvimento...${NC}"
            read -p "Pressione Enter..."
            ;;
        7)
            clear
            echo -e "${CYAN}INSTRUÇÕES DE USO${NC}"
            echo -e "${CYAN}═══════════════════════════════════════${NC}"
            echo
            echo "1. Certifique-se que o VcXsrv está rodando"
            echo "2. Baixe as BIOS usando a opção 3"
            echo "3. Baixe jogos usando a opção 4"
            echo "4. Use Quick Play para jogar Guitar Hero!"
            echo
            echo -e "${GREEN}Controles Guitar Hero:${NC}"
            echo "- Configure no PCSX2: Config > Controllers"
            echo "- Mapear guitarra USB ou teclado"
            echo
            echo -e "${GREEN}Dicas de Performance:${NC}"
            echo "- Use modo Hardware (F9 para alternar)"
            echo "- Ative os speedhacks no PCSX2"
            echo
            read -p "Pressione Enter..."
            ;;
        8)
            echo -e "${GREEN}Rock on! 🎸${NC}"
            echo -e "${CYAN}LEX KING - THE CODE REIGNS HERE${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Opção inválida!${NC}"
            sleep 1
            ;;
    esac
done
EOF
    
    chmod +x "$CONFIG_DIR/pcsx2-manager.sh"
    sudo ln -sf "$CONFIG_DIR/pcsx2-manager.sh" /usr/local/bin/pcsx2-manager
    
    # Copiar scripts auxiliares
    for script in download-bios.sh game-downloader.sh; do
        if [ -f "$SCRIPT_DIR/$script" ]; then
            cp "$SCRIPT_DIR/$script" "$CONFIG_DIR/"
            chmod +x "$CONFIG_DIR/$script"
        fi
    done
    
    log "Interface CLI criada!"
}

# Função principal
main() {
    show_banner
    log "Iniciando instalação LEX KING Edition..."
    
    # Etapas de instalação
    check_wsl
    download_scripts
    install_vcxsrv
    install_dependencies
    install_pcsx2
    configure_pcsx2_guitar_hero
    create_main_cli
    
    # BIOS
    echo
    read -p "Deseja baixar as BIOS agora? (S/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Ss]$ ]] || [ -z "$REPLY" ]; then
        if [ -f "$CONFIG_DIR/download-bios.sh" ]; then
            bash "$CONFIG_DIR/download-bios.sh"
        fi
    fi
    
    # Finalização
    clear
    show_banner
    echo -e "${GREEN}╔═══════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║       INSTALAÇÃO CONCLUÍDA! 🎸        ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════╝${NC}"
    echo
    echo -e "${YELLOW}Para iniciar, execute:${NC}"
    echo -e "  ${GREEN}pcsx2-manager${NC}"
    echo
    echo -e "${CYAN}Rock on! THE CODE REIGNS HERE!${NC}"
    echo
    log "Instalação concluída com sucesso!"
}

# Executar
main "$@"