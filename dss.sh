#!/bin/bash
# lex-king-intro.sh
# Uma introdução épica ao sistema LEX KING
# Para mostrar que não é só sobre letrinhas amarelas...

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
NC='\033[0m'

# Função de digitação
type_text() {
    local text="$1"
    local delay="${2:-0.05}"
    
    for (( i=0; i<${#text}; i++ )); do
        echo -n "${text:$i:1}"
        sleep $delay
    done
    echo
}

# Instalar cmatrix se não tiver
if ! command -v cmatrix &> /dev/null; then
    echo "Instalando cmatrix..."
    sudo apt-get update -qq && sudo apt-get install -y cmatrix -qq
fi

clear

# Intro épica
echo -e "${YELLOW}"
type_text "Leo..." 0.1
sleep 1
type_text "Você disse que eu passo madrugadas vendo letrinhas amarelas caindo?" 0.05
sleep 1
echo -e "${NC}"

# Mostrar cmatrix
if command -v cmatrix &> /dev/null; then
    echo -e "${GREEN}Então toma aqui suas letrinhas amarelas...${NC}"
    sleep 2
    timeout 5 cmatrix -b -a -C yellow
fi

clear

# Revelação
echo -e "${CYAN}"
type_text "Mas sabe de uma coisa?" 0.08
sleep 1
echo
type_text "Não se trata só de ver chuvas de letrinhas..." 0.06
sleep 1
echo -e "${NC}"

# Buildup
echo -e "${GREEN}"
type_text "Se trata de..." 0.1
sleep 1
echo -e "${NC}"

# Explosão de cores
for i in {1..3}; do
    echo -e "${RED}C${GREEN}R${YELLOW}I${BLUE}A${MAGENTA}R${NC}"
    sleep 0.2
    clear
    sleep 0.1
done

# Banner principal
echo -e "${WHITE}SE TRATA DE ${GREEN}C R I A R${WHITE} COISAS!${NC}"
echo
sleep 2

# ASCII Art Guitar
echo -e "${YELLOW}"
cat << 'EOF'
     .  o ..                  
     o . o o.o                
          ...oo               
            __[]__            
         __|_o_o_o\__         
         \  GUITAR  /         
          \   HERO /          
           \______/           
            |   |             
            |   |             
            |___|             
EOF
echo -e "${NC}"

sleep 2
