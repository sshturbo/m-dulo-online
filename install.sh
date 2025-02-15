#!/bin/bash

# ===============================
# Configurações e Variáveis Globais
# ===============================
APP_DIR="/opt/myapp/online"
DEPENDENCIES=("unzip")
VERSION="1.0.0"
FILE_URL="https://github.com/sshturbo/m-dulo-online/releases/download/$VERSION"
ARCH=$(uname -m)
SERVICE_FILE_NAME="online.service"
SERVICE_FILE="/etc/systemd/system/online.service" 

# Determinar arquitetura e nome do arquivo para download
case $ARCH in
x86_64)
    FILE_NAME="online-amd64.zip"
    DOCKER_ARCH="x86_64"
    EXEC_BINARY="/opt/myapp/online/online-amd64"  
    ;;
aarch64)
    FILE_NAME="online-arm64.zip"
    DOCKER_ARCH="aarch64"
    EXEC_BINARY="/opt/myapp/online/online-arm64"
    ;;
*)
    echo "Arquitetura $ARCH não suportada."
    exit 1
    ;;
esac

# ===============================
# Funções Utilitárias
# ===============================
print_centered() {
    printf "\e[33m%s\e[0m\n" "$1"
}

progress_bar() {
    local total_steps=$1
    for ((i = 0; i < total_steps; i++)); do
        echo -n "#"
        sleep 0.1
    done
    echo " COMPLETO!"
}

run_with_spinner() {
    local command="$1"
    local message="$2"
    echo -n "$message"
    $command &>/tmp/command_output.log &
    local pid=$!
    while kill -0 $pid 2>/dev/null; do
        echo -n "."
        sleep 1
    done
    wait $pid
    if [ $? -ne 0 ]; then
        echo " ERRO!"
        cat /tmp/command_output.log
        exit 1
    else
        echo " FEITO!"
    fi
}

install_if_missing() {
    local package=$1
    if ! command -v $package &>/dev/null; then
        run_with_spinner "apt-get install -y $package" "INSTALANDO $package"
    else
        print_centered "$package JÁ ESTÁ INSTALADO."
    fi
}

# ===============================
# Validações Iniciais
# ===============================
if [[ $EUID -ne 0 ]]; then
    echo "Este script deve ser executado como root."
    exit 1
fi

# Verifica se a URL foi passada como argumento
if [ $# -ne 1 ]; then
    echo "Uso: $0 <URL>"
    exit 1
fi

# URL passada como argumento
URL=$1

# Instalar dependências
for dep in "${DEPENDENCIES[@]}"; do
    install_if_missing $dep
done


# ===============================
# Configuração da Aplicação
# ===============================
# Configurar diretório da aplicação
if [ -d "$APP_DIR" ]; then
    print_centered "DIRETÓRIO $APP_DIR JÁ EXISTE. EXCLUINDO ANTIGO..."
    if systemctl list-units --full -all | grep -Fq "$SERVICE_FILE_NAME"; then
        run_with_spinner "systemctl stop $SERVICE_FILE_NAME" "PARANDO SERVIÇO"
        run_with_spinner "systemctl disable $SERVICE_FILE_NAME" "DESABILITANDO SERVIÇO"
    else
        print_centered "SERVIÇO $SERVICE_FILE_NAME NÃO ENCONTRADO."
    fi
    run_with_spinner "rm -rf $APP_DIR" "EXCLUINDO DIRETÓRIO"
else
    print_centered "DIRETÓRIO $APP_DIR NÃO EXISTE. NADA A EXCLUIR."
fi
mkdir -p $APP_DIR

# Baixar e configurar o módulo
print_centered "BAIXANDO $FILE_NAME..."
run_with_spinner "wget --timeout=30 -O $APP_DIR/$FILE_NAME $FILE_URL/$FILE_NAME" "BAIXANDO ARQUIVO"

print_centered "EXTRAINDO ARQUIVOS..."
run_with_spinner "unzip $APP_DIR/$FILE_NAME -d $APP_DIR" "EXTRAINDO ARQUIVOS"
run_with_spinner "rm $APP_DIR/$FILE_NAME" "REMOVENDO ARQUIVO ZIP"
progress_bar 5

chmod -R 775 $APP_DIR

# Configurar serviço systemd
if [ -f "$APP_DIR/$SERVICE_FILE_NAME" ]; then
    cp "$APP_DIR/$SERVICE_FILE_NAME" /etc/systemd/system/
    chmod 644 $SERVICE_FILE
    sed -i "s|^ExecStart=.*|ExecStart=$EXEC_BINARY $URL|" "$SERVICE_FILE"
    if [ $? -ne 0 ]; then
        echo "Erro ao atualizar o arquivo de serviço com a URL."
        exit 1
    fi
    systemctl daemon-reload
    systemctl enable $SERVICE_FILE_NAME
    systemctl start $SERVICE_FILE_NAME
    print_centered "SERVIÇO $SERVICE_FILE_NAME CONFIGURADO E INICIADO COM SUCESSO!"
else
    print_centered "Erro: Arquivo de serviço não encontrado."
    exit 1
fi

progress_bar 10
print_centered "MÓDULO INSTALADO E CONFIGURADO COM SUCESSO!"