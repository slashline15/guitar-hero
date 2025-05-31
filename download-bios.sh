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
    log "Verificando repositório..."
    
    # Criar diretório temporário
    rm -rf "$TEMP_DIR"
    mkdir -p "$TEMP_DIR"
    
    # Clonar repositório completo (mais simples e confiável)
    cd "$TEMP_DIR"
    git clone --depth 1 "$GITHUB_REPO" . || {
        warning "Falha ao clonar repositório"
        return 1
    }
    
    # Procurar BIOS em várias possíveis localizações
    for dir in bios BIOS Bios roms ROMS Roms files; do
        if [ -d "$dir" ]; then
            log "Pasta '$dir' encontrada no repositório"
            # Procurar arquivos de BIOS
            find "$dir" -name "*.bin" -o -name "*.BIN" -o -name "*.rom" -o -name "*.ROM" | while read file; do
                basename=$(basename "$file")
                if [[ -n "${BIOS_FILES[$basename]}" ]]; then
                    cp "$file" "$TEMP_DIR/"
                    log "BIOS encontrada: $basename"
                fi
            done
        fi
    done
    
    # Verificar se encontrou alguma BIOS
    local found=0
    for bios in "${!BIOS_FILES[@]}"; do
        [ -f "$TEMP_DIR/$bios" ] && ((found++))
    done
    
    if [ $found -eq 0 ]; then
        warning "Nenhuma BIOS encontrada no repositório"
        return 1
    else
        log "$found BIOS encontrada(s)"
        return 0
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
    log "Download direto desabilitado por questões legais"
    warning "Por favor, obtenha as BIOS de suas próprias fontes legais"
    echo
    echo "Arquivos necessários:"
    for bios in "${!BIOS_FILES[@]}"; do
        echo "  - $bios (MD5: ${BIOS_FILES[$bios]})"
    done
    echo
    echo "Coloque os arquivos em: $BIOS_DIR"
    read -p "Pressione Enter para continuar..."
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
    echo "2) Importar BIOS local"
    echo "3) Verificar BIOS existentes"
    echo "4) Informações sobre BIOS"
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
                    warning "Falha ao baixar do GitHub"
                    echo "Tente a opção 2 para importar BIOS locais"
                fi
                ;;
            2)
                import_local_bios
                check_existing_bios
                ;;
            3)
                if [ -d "$BIOS_DIR" ]; then
                    cd "$BIOS_DIR"
                    for bios in *.bin *.BIN *.rom *.ROM; do
                        [ -f "$bios" ] && echo -e "  ${GREEN}✓${NC} $bios"
                    done
                fi
                read -p "Pressione Enter para continuar..."
                ;;
            4)
                echo -e "${BLUE}Informações sobre BIOS PS2:${NC}"
                echo
                echo "As BIOS são necessárias para emular o PS2."
                echo "Você deve extraí-las do seu próprio console PS2."
                echo
                echo "BIOS recomendadas:"
                for bios in "${!BIOS_FILES[@]}"; do
                    echo "  - $bios"
                done
                echo
                read -p "Pressione Enter para continuar..."
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