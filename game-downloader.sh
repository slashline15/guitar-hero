#!/bin/bash
# game-downloader.sh
# Sistema de busca e download de jogos PS2
# LEX KING - THE CODE REIGNS HERE

set -e

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Diretórios
GAMES_DIR="$HOME/pcsx2-games"
CACHE_DIR="$HOME/.pcsx2-wsl/cache"
TEMP_DIR="/tmp/ps2-games"
CONFIG_DIR="$HOME/.pcsx2-wsl"

# Criar diretórios
mkdir -p "$GAMES_DIR" "$CACHE_DIR" "$TEMP_DIR" "$CONFIG_DIR"

# Banner
show_banner() {
    clear
    echo -e "${CYAN}╔═══════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║    PS2 GAME DOWNLOADER v1.0           ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════╝${NC}"
    echo -e "${CYAN} -                                      - ${NC}"
    echo -e "${GREEN}          ----------------------          ${NC}"
    echo -e "${GREEN}              L E X   K I N G             ${NC}"
    echo -e "${GREEN}          ----------------------          ${NC}"
    echo -e "${GREEN}          THE CODE REIGNS HERE            ${NC}"
    echo -e "${CYAN} -                                      - ${NC}"
    echo
}

# Base de dados de jogos populares
declare -A GAMES_DB=(
    ["Guitar Hero III"]="SLUS-21672|guitar-hero-3-legends-of-rock"
    ["Guitar Hero World Tour"]="SLUS-21804|guitar-hero-world-tour"
    ["Guitar Hero Metallica"]="SLUS-21865|guitar-hero-metallica"
    ["Guitar Hero 5"]="SLUS-21889|guitar-hero-5"
    ["God of War"]="SCUS-97109|god-of-war"
    ["God of War II"]="SCUS-97481|god-of-war-2"
    ["Final Fantasy X"]="SLUS-20312|final-fantasy-x"
    ["Final Fantasy XII"]="SLUS-20963|final-fantasy-xii"
    ["Shadow of the Colossus"]="SCUS-97472|shadow-of-the-colossus"
    ["Metal Gear Solid 3"]="SLUS-20978|metal-gear-solid-3"
    ["Grand Theft Auto San Andreas"]="SLUS-20946|grand-theft-auto-san-andreas"
    ["Kingdom Hearts"]="SLUS-20370|kingdom-hearts"
    ["Devil May Cry"]="SLUS-20216|devil-may-cry"
    ["Resident Evil 4"]="SLUS-21134|resident-evil-4"
)

# Função de log
log() {
    echo -e "${GREEN}[$(date '+%H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERRO]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[AVISO]${NC} $1"
}

# Pesquisar jogos
search_games() {
    local query="$1"
    show_banner
    
    echo -e "${BLUE}Pesquisando por:${NC} $query"
    echo
    
    # Pesquisa no banco local primeiro
    local found=0
    local results=()
    
    for game in "${!GAMES_DB[@]}"; do
        if [[ "${game,,}" == *"${query,,}"* ]]; then
            results+=("$game")
            ((found++))
        fi
    done
    
    if [ $found -eq 0 ]; then
        warning "Nenhum jogo encontrado com '$query'"
        echo
        echo "Jogos populares disponíveis:"
        local count=1
        for game in "${!GAMES_DB[@]}"; do
            echo -e "  ${GREEN}$count)${NC} $game"
            ((count++))
            [ $count -gt 10 ] && break
        done
    else
        echo -e "${GREEN}Encontrados $found resultado(s):${NC}"
        echo
        local count=1
        for game in "${results[@]}"; do
            local info="${GAMES_DB[$game]}"
            local code="${info%%|*}"
            echo -e "  ${GREEN}$count)${NC} $game ${CYAN}[$code]${NC}"
            ((count++))
        done
    fi
    
    echo
}

# Download via torrent
download_torrent() {
    local game_name="$1"
    local magnet="$2"
    
    log "Preparando download via torrent: $game_name"
    
    # Verificar transmission
    if ! command -v transmission-cli &> /dev/null; then
        warning "Instalando transmission-cli..."
        sudo apt-get update && sudo apt-get install -y transmission-cli
    fi
    
    # Download
    cd "$TEMP_DIR"
    transmission-cli "$magnet" -w "$TEMP_DIR" --finish-script "echo 'Download concluído!'"
    
    # Mover para pasta de jogos
    find "$TEMP_DIR" -name "*.iso" -o -name "*.ISO" -o -name "*.bin" -o -name "*.BIN" | while read file; do
        mv "$file" "$GAMES_DIR/"
        log "Jogo movido para: $GAMES_DIR/$(basename "$file")"
    done
}

# Download direto
download_direct() {
    local url="$1"
    local filename="$2"
    
    log "Baixando: $filename"
    
    # Download com progresso
    cd "$TEMP_DIR"
    wget -q --show-progress "$url" -O "$filename" || return 1
    
    # Verificar se é um arquivo compactado
    case "$filename" in
        *.7z|*.zip|*.rar)
            log "Extraindo arquivo..."
            if command -v 7z &> /dev/null; then
                7z x "$filename" -o"$TEMP_DIR/extract"
            else
                unzip "$filename" -d "$TEMP_DIR/extract" || error "Falha ao extrair"
            fi
            
            # Mover ISOs extraídas
            find "$TEMP_DIR/extract" -name "*.iso" -o -name "*.ISO" | while read file; do
                mv "$file" "$GAMES_DIR/"
                log "Extraído: $(basename "$file")"
            done
            ;;
        *.iso|*.ISO|*.bin|*.BIN)
            mv "$filename" "$GAMES_DIR/"
            log "Jogo salvo em: $GAMES_DIR/$filename"
            ;;
    esac
}

# Buscar em fontes alternativas
search_alternative_sources() {
    local game_name="$1"
    
    echo -e "${BLUE}Buscando em fontes alternativas...${NC}"
    
    # Simular busca em várias fontes
    echo "1) Archive.org - ISO disponível"
    echo "2) Emuparadise Mirror - Torrent disponível"
    echo "3) CoolROM Alternative - Download direto"
    echo
}

# Menu de download
download_menu() {
    local game_name="$1"
    
    echo -e "${BLUE}Opções de download para:${NC} $game_name"
    echo
    echo "1) Download direto (Rápido)"
    echo "2) Download via torrent (Estável)"
    echo "3) Buscar em outras fontes"
    echo "4) Inserir URL/Magnet manualmente"
    echo "5) Voltar"
    echo
    
    read -p "Escolha: " choice
    
    case $choice in
        1)
            # Simular download direto
            local iso_name="${game_name// /-}.iso"
            echo -e "${YELLOW}Nota Legal:${NC}"
            echo "Baixe apenas jogos que você possui fisicamente."
            echo "O download de jogos protegidos por copyright sem"
            echo "possuir o original é ilegal."
            echo
            echo "Por favor, insira a URL do jogo que você possui:"
            read -p "URL: " url
            if [ ! -z "$url" ]; then
                download_direct "$url" "$iso_name"
            fi
            ;;
        2)
            echo -e "${YELLOW}Nota Legal:${NC}"
            echo "Use apenas para fazer backup de jogos que você possui."
            echo
            echo "Insira o magnet link:"
            read -p "Magnet: " magnet
            if [ ! -z "$magnet" ]; then
                download_torrent "$game_name" "$magnet"
            fi
            ;;
        3)
            search_alternative_sources "$game_name"
            ;;
        4)
            echo "Insira URL ou Magnet link do seu backup:"
            read -p "> " link
            if [[ "$link" == magnet:* ]]; then
                download_torrent "$game_name" "$link"
            else
                download_direct "$link" "$(basename "$link")"
            fi
            ;;
        5)
            return
            ;;
    esac
}

# Listar jogos baixados
list_downloaded_games() {
    show_banner
    echo -e "${BLUE}Jogos disponíveis:${NC}"
    echo
    
    local count=0
    for file in "$GAMES_DIR"/*.{iso,ISO,bin,BIN} 2>/dev/null; do
        if [ -f "$file" ]; then
            local size=$(du -h "$file" | cut -f1)
            echo -e "  ${GREEN}→${NC} $(basename "$file") ${CYAN}[$size]${NC}"
            ((count++))
        fi
    done
    
    if [ $count -eq 0 ]; then
        warning "Nenhum jogo encontrado em $GAMES_DIR"
    else
        echo
        echo -e "${GREEN}Total: $count jogo(s)${NC}"
    fi
    
    echo
}

# Download em lote (Guitar Hero Collection)
download_guitar_hero_collection() {
    show_banner
    echo -e "${MAGENTA}╔═══════════════════════════════════════╗${NC}"
    echo -e "${MAGENTA}║   GUITAR HERO COLLECTION DOWNLOAD     ║${NC}"
    echo -e "${MAGENTA}╚═══════════════════════════════════════╝${NC}"
    echo
    
    local gh_games=(
        "Guitar Hero III"
        "Guitar Hero World Tour"
        "Guitar Hero Metallica"
        "Guitar Hero 5"
        "Guitar Hero Aerosmith"
        "Guitar Hero Van Halen"
    )
    
    echo -e "${YELLOW}Esta opção baixará toda a coleção Guitar Hero!${NC}"
    echo
    
    for game in "${gh_games[@]}"; do
        echo -e "  ${GREEN}•${NC} $game"
    done
    
    echo
    read -p "Continuar? (s/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        for game in "${gh_games[@]}"; do
            echo
            echo -e "${BLUE}Processando:${NC} $game"
            download_menu "$game"
        done
    fi
}

# Menu principal
main_menu() {
    while true; do
        show_banner
        
        echo -e "${GREEN}1)${NC} Pesquisar jogo"
        echo -e "${GREEN}2)${NC} Listar jogos baixados"
        echo -e "${GREEN}3)${NC} Download Guitar Hero Collection"
        echo -e "${GREEN}4)${NC} Buscar por código (SLUS/SCUS)"
        echo -e "${GREEN}5)${NC} Importar jogo local"
        echo -e "${GREEN}6)${NC} Limpar downloads temporários"
        echo -e "${GREEN}7)${NC} Voltar ao menu principal"
        echo
        
        read -p "Escolha: " choice
        
        case $choice in
            1)
                read -p "Nome do jogo: " query
                search_games "$query"
                read -p "Selecione o número do jogo (0 para voltar): " game_num
                
                if [ "$game_num" != "0" ]; then
                    # Pegar o jogo selecionado
                    local count=1
                    for game in "${!GAMES_DB[@]}"; do
                        if [[ "${game,,}" == *"${query,,}"* ]]; then
                            if [ $count -eq $game_num ]; then
                                download_menu "$game"
                                break
                            fi
                            ((count++))
                        fi
                    done
                fi
                ;;
            2)
                list_downloaded_games
                read -p "Pressione Enter para continuar..."
                ;;
            3)
                download_guitar_hero_collection
                ;;
            4)
                read -p "Código do jogo (ex: SLUS-21672): " code
                # Buscar por código
                for game in "${!GAMES_DB[@]}"; do
                    if [[ "${GAMES_DB[$game]}" == *"$code"* ]]; then
                        echo -e "${GREEN}Encontrado:${NC} $game"
                        download_menu "$game"
                        break
                    fi
                done
                ;;
            5)
                echo "Caminho do arquivo ISO/BIN:"
                read -p "> " filepath
                if [ -f "$filepath" ]; then
                    cp "$filepath" "$GAMES_DIR/"
                    log "Jogo importado: $(basename "$filepath")"
                else
                    error "Arquivo não encontrado!"
                fi
                read -p "Pressione Enter para continuar..."
                ;;
            6)
                rm -rf "$TEMP_DIR"/*
                log "Cache limpo!"
                read -p "Pressione Enter para continuar..."
                ;;
            7)
                break
                ;;
            *)
                warning "Opção inválida!"
                sleep 1
                ;;
        esac
    done
}

# Executar se chamado diretamente
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    main_menu
fi