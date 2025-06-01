# 🎸 LEX KING Guitar Hero PS2 System

**THE CODE REIGNS HERE**

Sistema completo para jogar Guitar Hero e outros jogos PS2 no Windows 10 via WSL.

## 📋 Requisitos

- Windows 10 (1903 ou superior)
- WSL habilitado com Ubuntu
- ~10GB de espaço livre
- GPU com suporte OpenGL (NVIDIA recomendado)

## 🚀 Instalação Rápida

```bash
git clone https://github.com/slashline15/guitar-hero.git
cd guitar-hero
chmod +x setup-pcsx2.sh
./setup-pcsx2.sh
```

## 📁 Scripts Incluídos

- `setup-pcsx2.sh` - Instalador principal
- `install-vcxsrv.ps1` - Instalador do X Server para Windows
- `download-bios.sh` - Gerenciador de BIOS
- `game-downloader.sh` - Sistema de jogos
- `check-requirements.sh` - Verificador de requisitos

## ⚖️ Aviso Legal

### BIOS PS2
- As BIOS são propriedade da Sony e protegidas por copyright
- Você deve extrair as BIOS do seu próprio console PS2
- Este sistema facilita apenas o gerenciamento de BIOS que você já possui legalmente

### Jogos
- Baixe apenas backups de jogos que você possui fisicamente
- O download de jogos protegidos por copyright sem possuir o original é ilegal
- Use este sistema apenas para fazer backup de sua própria coleção

### Responsabilidade
- Este software é fornecido "como está", sem garantias
- Os autores não se responsabilizam pelo uso indevido
- Use por sua própria conta e risco

## 🎮 Uso

Após a instalação, execute:

```bash
pcsx2-manager
```

### Menu Principal:
1. **🎮 Iniciar PCSX2** - Abre o emulador
2. **🎸 Quick Play Guitar Hero** - Inicia jogos Guitar Hero diretamente
3. **📀 Gerenciar BIOS** - Importar/verificar BIOS
4. **🎯 Baixar Jogos** - Gerenciar biblioteca de jogos
5. **📊 Status do Sistema** - Verificar instalação

## 🔧 Solução de Problemas

### VcXsrv não conecta
1. Certifique-se que o VcXsrv está rodando
2. Desabilite o Windows Firewall temporariamente
3. Execute VcXsrv com "Disable access control" marcado

### PCSX2 não abre
1. Verifique se as BIOS estão instaladas
2. Instale `libfuse2`: `sudo apt install libfuse2`
3. Teste com: `pcsx2 --help`

### Performance ruim
1. Use modo Hardware (pressione F9 no jogo)
2. Ative os speedhacks no PCSX2
3. Reduza a resolução interna

## 🤝 Contribuindo

Pull requests são bem-vindos! Para mudanças grandes, abra uma issue primeiro.

## 📜 Licença

Este projeto está licenciado sob a MIT License.

---

**LEX KING - THE CODE REIGNS HERE**

*Rock on! 🎸*