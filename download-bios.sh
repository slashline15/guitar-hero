#!/bin/bash
# download-bios.sh
# Download automático de BIOS PS2
# LEX KING - THE CODE REIGNS HERE

set -e

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Diretórios
BIOS_DIR="$HOME/pcsx2-bios"
TEMP_DIR="/tmp/ps2-bios-download"
GITHUB_REPO="https://github.com/slashline15/guitar-hero.git"

# Banner
show_banner() {
    clear
    echo -e "${CYAN}╔═══════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║      PS2 BIOS Auto-Downloader         ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════╝${NC}"
    echo -e "${CYAN} -                                      - ${NC}"
    echo -e "${GREEN}          ----------------------          ${NC}"
    echo -e "${GREEN}              L E X   K I N G             ${NC}"
    echo -e "${GREEN}          ----------------------          ${NC}"
    echo -e "${GREEN}          THE CODE REIGNS HERE            ${NC}"
    echo -e "${CYAN} -                                      - ${NC}"
    echo
}

# Função de log
log() {
    echo -e "${GREEN}[$(date '+%H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERRO]${NC} $1"
    exit 1
}

warning() {
    echo -e "${YELLOW}[AVISO]${NC} $1"
}

# Lista de BIOS necessárias com checksums
declare -A BIOS_FILES=(
    ["SCPH10000.bin"]="28922c703cc7d2cf856f177f2985b3a9"
    ["SCPH30004R.bin"]="28aa539d1a11e7b43c0b6f8a7af0e420"
    ["SCPH39001.bin"]="27bc22e6e319c01fb32da6e3ed1a5eda"
    ["SCPH70012.bin"]="3e3e030b0f35a8a873fb2b50f11c6594"
)

# Verificar BIOS existentes
check_existing_bios() {
    log "Verificando BIOS existentes..."
    
    mkdir -p "$BIOS_DIR"
    local found=0
    
    for bios in "${!BIOS_FILES[@]}"; do
        if [ -f "$BIOS_DIR/$bios" ]; then
            echo -e "  ${GREEN}✓${NC} $bios já existe"
            ((found++))
        else
            echo -e "  ${RED}✗${NC} $bios não encontrada"
        fi
    done
    
    if [ $found -eq ${#BIOS_FILES[@]} ]; then
        log "Todas as BIOS já estão instaladas!"
        read -p "Deseja baixar novamente? (s/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Ss]$ ]]; then
            exit 0
        fi
    fi
}

# Baixar do repositório GitHub
download_from_github() {
    log "Clonando repositório..."
    
    # Criar diretório temporário
    rm -rf "$TEMP_DIR"
    mkdir -p "$TEMP_DIR"
    
    # Clonar apenas a pasta de BIOS (sparse checkout)
    cd "$TEMP_DIR"
    git clone --depth 1 --filter=blob:none --sparse "$GITHUB_REPO" .
    git sparse-checkout set bios
    
    if [ -d "bios" ]; then
        log "BIOS encontradas no repositório!"
        return 0
    else
        return 1
    fi
}

# Download alternativo via torrent
download_via_torrent() {
    log "Preparando download via torrent..."
    
    # Verificar se transmission-cli está instalado
    if ! command -v transmission-cli &> /dev/null; then
        warning "Transmission não instalado. Instalando..."
        sudo apt-get update && sudo apt-get install -y transmission-cli
    fi
    
    # Magnet link para BIOS PS2 (exemplo)
    local magnet="magnet:?xt=urn:btih:EXAMPLE_HASH&dn=PS2_BIOS_PACK"
    
    echo -e "${YELLOW}Nota: Por questões legais, você precisa possuir um PS2 para usar estas BIOS${NC}"
    read -p "Continuar com download? (s/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        transmission-cli "$magnet" -w "$TEMP_DIR" --finish-script "echo Download concluído!"
    fi
}

# Download direto de URLs
download_direct() {
    log "Baixando BIOS diretamente..."
    
    # URLs de backup (você deve adicionar URLs válidas aqui)
    declare -A BIOS_URLS=(
        ["SCPH10000.bin"]="https://example.com/bios/SCPH10000.bin"
        ["SCPH30004R.bin"]="https://example.com/bios/SCPH30004R.bin"
        ["SCPH39001.bin"]="https://example.com/bios/SCPH39001.bin"
        ["SCPH70012.bin"]="https://example.com/bios/SCPH70012.bin"
    )
    
    mkdir -p "$TEMP_DIR"
    cd "$TEMP_DIR"
    
    for bios in "${!BIOS_URLS[@]}"; do
        if [ ! -f "$BIOS_DIR/$bios" ]; then
            log "Baixando $bios..."
            wget -q --show-progress "${BIOS_URLS[$bios]}" -O "$bios" || warning "Falha ao baixar $bios"
        fi
    done
}

# Verificar integridade das BIOS
verify_bios() {
    log "Verificando integridade das BIOS..."
    
    local valid=0
    for bios in "${!BIOS_FILES[@]}"; do
        if [ -f "$TEMP_DIR/$bios" ]; then
            local md5=$(md5sum "$TEMP_DIR/$bios" | awk '{print $1}')
            if [ "$md5" == "${BIOS_FILES[$bios]}" ]; then
                echo -e "  ${GREEN}✓${NC} $bios - Checksum válido"
                ((valid++))
            else
                echo -e "  ${RED}✗${NC} $bios - Checksum inválido"
                rm -f "$TEMP_DIR/$bios"
            fi
        fi
    done
    
    return $((${#BIOS_FILES[@]} - valid))
}

# Instalar BIOS
install_bios() {
    log "Instalando BIOS..."
    
    local installed=0
    for bios in "${!BIOS_FILES[@]}"; do
        if [ -f "$TEMP_DIR/$bios" ]; then
            cp "$TEMP_DIR/$bios" "$BIOS_DIR/"
            echo -e "  ${GREEN}✓${NC} $bios instalada"
            ((installed++))
        elif [ -f "$TEMP_DIR/bios/$bios" ]; then
            cp "$TEMP_DIR/bios/$bios" "$BIOS_DIR/"
            echo -e "  ${GREEN}✓${NC} $bios instalada"
            ((installed++))
        fi
    done
    
    if [ $installed -gt 0 ]; then
        log "$installed BIOS instaladas com sucesso!"
    else
        error "Nenhuma BIOS foi instalada!"
    fi
}

# Menu de opções
show_menu() {
    echo -e "${BLUE}Escolha o método de download:${NC}"
    echo
    echo "1) Download do repositório GitHub (Recomendado)"
    echo "2) Download direto de URLs"
    echo "3) Download via torrent"
    echo "4) Tenho as BIOS, apenas verificar"
    echo "5) Sair"
    echo
}

# Função principal
main() {
    show_banner
    check_existing_bios
    
    while true; do
        show_menu
        read -p "Opção: " choice
        
        case $choice in
            1)
                if download_from_github; then
                    verify_bios || warning "Algumas BIOS falharam na verificação"
                    install_bios
                    break
                else
                    error "Falha ao baixar do GitHub"
                fi
                ;;
            2)
                download_direct
                verify_bios || warning "Algumas BIOS falharam na verificação"
                install_bios
                break
                ;;
            3)
                download_via_torrent
                verify_bios || warning "Algumas BIOS falharam na verificação"
                install_bios
                break
                ;;
            4)
                if [ -d "$BIOS_DIR" ]; then
                    cd "$BIOS_DIR"
                    for bios in *.bin *.BIN *.rom *.ROM; do
                        [ -f "$bios" ] && echo -e "  ${GREEN}✓${NC} $bios"
                    done
                fi
                break
                ;;
            5)
                exit 0
                ;;
            *)
                warning "Opção inválida!"
                ;;
        esac
    done
    
    # Limpar arquivos temporários
    rm -rf "$TEMP_DIR"
    
    echo
    echo -e "${GREEN}╔═══════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║        BIOS Prontas para Uso!         ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════╝${NC}"
    echo
}

# Executar se chamado diretamente
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    main "$@"
fi