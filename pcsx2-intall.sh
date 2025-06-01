#!/bin/bash

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Diretórios
GAMES_DIR="$HOME/pcsx2-games"
BIOS_DIR="$HOME/pcsx2-bios"
CONFIG_DIR="$HOME/.config/PCSX2"

# Função para exibir menu principal
show_menu() {
    clear
    echo -e "${CYAN}╔═══════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║      PCSX2 WSL Manager v1.0          ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════╝${NC}"
    echo
    echo -e "${GREEN}1)${NC} Iniciar PCSX2"
    echo -e "${GREEN}2)${NC} Listar jogos disponíveis"
    echo -e "${GREEN}3)${NC} Verificar BIOS"
    echo -e "${GREEN}4)${NC} Testar configuração gráfica"
    echo -e "${GREEN}5)${NC} Configurar X Server"
    echo -e "${GREEN}6)${NC} Abrir pasta de jogos"
    echo -e "${GREEN}7)${NC} Verificar status do sistema"
    echo -e "${GREEN}8)${NC} Instruções de uso"
    echo -e "${GREEN}9)${NC} Sair"
    echo
}

# Função para iniciar PCSX2
start_pcsx2() {
    echo -e "${BLUE}Iniciando PCSX2...${NC}"
    
    if [ -z "$DISPLAY" ]; then
        export DISPLAY=$(cat /etc/resolv.conf | grep nameserver | awk '{print $2}'):0.0
    fi
    
    if command -v pcsx2 &> /dev/null; then
        pcsx2 &
        echo -e "${GREEN}PCSX2 iniciado!${NC}"
    elif [ -f "$HOME/pcsx2/pcsx2.AppImage" ]; then
        "$HOME/pcsx2/pcsx2.AppImage" &
        echo -e "${GREEN}PCSX2 AppImage iniciado!${NC}"
    else
        echo -e "${RED}PCSX2 não encontrado!${NC}"
    fi
    
    read -p "Pressione Enter para continuar..."
}

# Função para listar jogos
list_games() {
    echo -e "${BLUE}Jogos disponíveis em $GAMES_DIR:${NC}"
    echo
    
    if [ -d "$GAMES_DIR" ]; then
        found=0
        for file in "$GAMES_DIR"/*.{iso,ISO,bin,BIN,img,IMG,mdf,MDF} 2>/dev/null; do
            if [ -f "$file" ]; then
                echo -e "${GREEN}→${NC} $(basename "$file")"
                found=1
            fi
        done
        
        if [ $found -eq 0 ]; then
            echo -e "${YELLOW}Nenhum jogo encontrado!${NC}"
            echo "Coloque seus jogos (ISO/BIN) em: $GAMES_DIR"
        fi
    else
        echo -e "${RED}Diretório de jogos não existe!${NC}"
        mkdir -p "$GAMES_DIR"
    fi
    
    echo
    read -p "Pressione Enter para continuar..."
}

# Função para verificar BIOS
check_bios() {
    echo -e "${BLUE}Verificando BIOS em $BIOS_DIR:${NC}"
    echo
    
    if [ -d "$BIOS_DIR" ]; then
        found=0
        for file in "$BIOS_DIR"/*.{bin,BIN,rom,ROM} 2>/dev/null; do
            if [ -f "$file" ]; then
                echo -e "${GREEN}→${NC} $(basename "$file")"
                found=1
            fi
        done
        
        if [ $found -eq 0 ]; then
            echo -e "${RED}Nenhuma BIOS encontrada!${NC}"
            echo
            echo "Você precisa colocar os arquivos BIOS do PS2 em: $BIOS_DIR"
            echo "Arquivos necessários:"
            echo "- SCPH10000.bin (PS2 BIOS)"
            echo "- SCPH30004R.bin (Europa)"
            echo "- SCPH39001.bin (USA)"
            echo "- ou outras BIOS compatíveis"
        fi
    else
        echo -e "${RED}Diretório de BIOS não existe!${NC}"
        mkdir -p "$BIOS_DIR"
    fi
    
    echo
    read -p "Pressione Enter para continuar..."
}

# Função para testar gráficos
test_graphics() {
    echo -e "${BLUE}Testando configuração gráfica...${NC}"
    echo
    
    # Verificar DISPLAY
    if [ -z "$DISPLAY" ]; then
        export DISPLAY=$(cat /etc/resolv.conf | grep nameserver | awk '{print $2}'):0.0
    fi
    
    echo "DISPLAY configurado para: $DISPLAY"
    
    # Testar X Server
    if command -v xeyes &> /dev/null; then
        echo -e "${YELLOW}Abrindo xeyes para teste...${NC}"
        echo "Se uma janela com olhos aparecer, o X Server está funcionando!"
        timeout 10 xeyes
    fi
    
    # Verificar OpenGL
    if command -v glxinfo &> /dev/null; then
        echo
        echo -e "${BLUE}Informações OpenGL:${NC}"
        glxinfo | grep -E "OpenGL renderer|OpenGL version" || echo -e "${RED}Erro ao obter info OpenGL${NC}"
    fi
    
    echo
    read -p "Pressione Enter para continuar..."
}

# Função para configurar X Server
configure_xserver() {
    echo -e "${BLUE}Instruções para configurar X Server:${NC}"
    echo
    echo "1. Baixe e instale o VcXsrv no Windows:"
    echo "   https://sourceforge.net/projects/vcxsrv/"
    echo
    echo "2. Execute o XLaunch (VcXsrv) com estas configurações:"
    echo "   - Display number: 0"
    echo "   - Start no client"
    echo "   - Disable access control (importante!)"
    echo
    echo "3. Permita o VcXsrv no Firewall do Windows"
    echo
    echo "4. O DISPLAY já está configurado para: $DISPLAY"
    echo
    read -p "Pressione Enter para continuar..."
}

# Função para abrir pasta de jogos
open_games_folder() {
    echo -e "${BLUE}Abrindo pasta de jogos...${NC}"
    
    # Converter caminho WSL para Windows
    WINDOWS_PATH=$(wslpath -w "$GAMES_DIR" 2>/dev/null || echo "$GAMES_DIR")
    
    if command -v explorer.exe &> /dev/null; then
        explorer.exe "$WINDOWS_PATH" &
        echo -e "${GREEN}Pasta aberta no Windows Explorer!${NC}"
    else
        echo "Caminho da pasta: $GAMES_DIR"
        echo "Caminho Windows: $WINDOWS_PATH"
    fi
    
    echo
    read -p "Pressione Enter para continuar..."
}

# Função para verificar status
check_status() {
    echo -e "${BLUE}Status do Sistema:${NC}"
    echo
    
    # WSL
    echo -e "${CYAN}WSL:${NC}"
    grep -qi microsoft /proc/version && echo -e "  ${GREEN}✓${NC} Rodando no WSL" || echo -e "  ${RED}✗${NC} Não está no WSL"
    
    # X Server
    echo -e "${CYAN}X Server:${NC}"
    if timeout 2 xset q &>/dev/null; then
        echo -e "  ${GREEN}✓${NC} X Server conectado"
    else
        echo -e "  ${RED}✗${NC} X Server não conectado"
    fi
    
    # PCSX2
    echo -e "${CYAN}PCSX2:${NC}"
    if command -v pcsx2 &> /dev/null || [ -f "$HOME/pcsx2/pcsx2.AppImage" ]; then
        echo -e "  ${GREEN}✓${NC} PCSX2 instalado"
    else
        echo -e "  ${RED}✗${NC} PCSX2 não encontrado"
    fi
    
    # BIOS
    echo -e "${CYAN}BIOS PS2:${NC}"
    if [ -d "$BIOS_DIR" ] && [ "$(ls -A $BIOS_DIR/*.{bin,BIN,rom,ROM} 2>/dev/null | wc -l)" -gt 0 ]; then
        echo -e "  ${GREEN}✓${NC} BIOS encontrada"
    else
        echo -e "  ${RED}✗${NC} BIOS não encontrada"
    fi
    
    # Jogos
    echo -e "${CYAN}Jogos:${NC}"
    if [ -d "$GAMES_DIR" ] && [ "$(ls -A $GAMES_DIR/*.{iso,ISO,bin,BIN} 2>/dev/null | wc -l)" -gt 0 ]; then
        COUNT=$(ls -A $GAMES_DIR/*.{iso,ISO,bin,BIN} 2>/dev/null | wc -l)
        echo -e "  ${GREEN}✓${NC} $COUNT jogo(s) encontrado(s)"
    else
        echo -e "  ${YELLOW}!${NC} Nenhum jogo encontrado"
    fi
    
    echo
    read -p "Pressione Enter para continuar..."
}

# Função para mostrar instruções
show_instructions() {
    clear
    echo -e "${CYAN}╔═══════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║        Instruções de Uso              ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════╝${NC}"
    echo
    echo -e "${GREEN}Configuração Inicial:${NC}"
    echo "1. Instale o VcXsrv no Windows (X Server)"
    echo "2. Execute o VcXsrv com 'Disable access control'"
    echo "3. Coloque as BIOS do PS2 em: $BIOS_DIR"
    echo "4. Coloque seus jogos (ISO/BIN) em: $GAMES_DIR"
    echo
    echo -e "${GREEN}Para jogar:${NC}"
    echo "1. Certifique-se que o VcXsrv está rodando"
    echo "2. Use a opção 1 para iniciar o PCSX2"
    echo "3. Configure o PCSX2 na primeira execução"
    echo "4. Carregue um jogo via menu File > Run ISO"
    echo
    echo -e "${GREEN}Dicas:${NC}"
    echo "- Use F9 para alternar entre modo software/hardware"
    echo "- Configure os controles em Config > Controllers"
    echo "- Ajuste as configurações gráficas para melhor performance"
    echo
    read -p "Pressione Enter para continuar..."
}

# Loop principal
while true; do
    show_menu
    read -p "Escolha uma opção: " choice
    
    case $choice in
        1) start_pcsx2 ;;
        2) list_games ;;
        3) check_bios ;;
        4) test_graphics ;;
        5) configure_xserver ;;
        6) open_games_folder ;;
        7) check_status ;;
        8) show_instructions ;;
        9) echo -e "${GREEN}Saindo...${NC}"; exit 0 ;;
        *) echo -e "${RED}Opção inválida!${NC}"; sleep 1 ;;
    esac
done
EOF
    
    chmod +x "$SCRIPT_DIR/pcsx2-cli.sh"
    
    # Criar link simbólico
    sudo ln -sf "$SCRIPT_DIR/pcsx2-cli.sh" /usr/local/bin/pcsx2-manager
    
    log "Interface CLI criada! Use 'pcsx2-manager' para iniciar"
}

# Função para instruções finais
show_final_instructions() {
    clear
    echo -e "${GREEN}╔═══════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║    Instalação Concluída!              ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════╝${NC}"
    echo
    echo -e "${YELLOW}Próximos passos:${NC}"
    echo
    echo "1. ${BLUE}Instale o VcXsrv no Windows:${NC}"
    echo "   https://sourceforge.net/projects/vcxsrv/"
    echo
    echo "2. ${BLUE}Execute o VcXsrv (XLaunch) com estas configurações:${NC}"
    echo "   - Multiple windows"
    echo "   - Display number: 0"
    echo "   - Start no client"
    echo "   - ${RED}Disable access control${NC} (marque esta opção!)"
    echo
    echo "3. ${BLUE}Baixe as BIOS do PS2 e coloque em:${NC}"
    echo "   $HOME/pcsx2-bios/"
    echo
    echo "4. ${BLUE}Coloque seus jogos (ISO/BIN) em:${NC}"
    echo "   $HOME/pcsx2-games/"
    echo
    echo "5. ${BLUE}Execute o gerenciador:${NC}"
    echo "   ${GREEN}pcsx2-manager${NC}"
    echo
    echo -e "${YELLOW}Logs da instalação salvos em:${NC} $LOG_FILE"
    echo
}

# Função principal
main() {
    clear
    echo -e "${CYAN}╔═══════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║   PCSX2 WSL Setup Script v1.0         ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════╝${NC}"
    echo
    
    log "Iniciando instalação..."
    
    # Executar todas as etapas
    check_wsl
    check_python
    setup_xserver
    install_dependencies
    setup_nvidia
    install_pcsx2
    configure_pcsx2
    create_cli
    
    # Mostrar instruções finais
    show_final_instructions
    
    log "Instalação concluída com sucesso!"
}

# Executar script principal
main "$@"