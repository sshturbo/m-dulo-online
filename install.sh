#!/bin/bash

# Verifica se o script está sendo executado como root
if [[ $EUID -ne 0 ]]; then
    echo "Este script deve ser executado como root"
    exit 1
fi

# Função para centralizar texto
print_centered() {
    term_width=$(tput cols)
    text="$1"
    padding=$(( (term_width - ${#text}) / 2 ))
    printf "%${padding}s" '' # Adiciona espaços antes do texto
    echo "$text"
}

# Função para simular uma barra de progresso
progress_bar() {
    local total_steps=$1
    local current_step=0

    echo -n "Progresso: ["
    while [ $current_step -lt $total_steps ]; do
        echo -n "#"
        ((current_step++))
        sleep 0.1
    done
    echo "] Completo!"
}

# Verifica se a URL foi passada como argumento
if [ $# -ne 1 ]; then
    echo "Uso: $0 <URL>"
    exit 1
fi

# URL passada como argumento
url=$1


# Instalar o supervisor

apt install supervisor -y &>/dev/null

# Diretório onde os arquivos serão baixados
download_dir="/opt/myapp/online"

# Criar o diretório se não existir
mkdir -p "$download_dir"

# Baixar os arquivos online.go e online.conf
wget -O "$download_dir/online.go" https://raw.githubusercontent.com/sshturbo/m-dulo-online/main/online.go &>/dev/null

# Adicionar a URL ao arquivo online.conf
echo "[program:Online]" >> "$download_dir/online.conf"
echo "command=/opt/myapp/online/online $url" >> "$download_dir/online.conf"
echo "directory=/opt/myapp/online" >> "$download_dir/online.conf"
echo "autostart=true" >> "$download_dir/online.conf"
echo "autorestart=true" >> "$download_dir/online.conf"
echo "stderr_logfile=/var/log/online.err.log" >> "$download_dir/online.conf"
echo "stdout_logfile=/var/log/online.out.log" >> "$download_dir/online.conf"


go build -o /opt/myapp/online/online /opt/myapp/online/online.go

# Copiar o arquivo online.conf para /etc/supervisor/conf.d
if [ -f "/opt/myapp/online/online.conf" ]; then
    print_centered "Copiando online.conf para /etc/supervisor/conf.d..."
    sudo cp /opt/myapp/online/online.conf /etc/supervisor/conf.d/
    sudo chown root:root /etc/supervisor/conf.d/online.conf
    sudo chmod 644 /etc/supervisor/conf.d/online.conf
    print_centered "Arquivo copiado com sucesso."
else
    print_centered "Arquivo online.conf não encontrado. Verifique se o arquivo existe no repositório."
fi

# Atualizar a configuração do Supervisor
sudo supervisorctl update &>/dev/null

# Iniciar o serviço
print_centered "Iniciando o modulos do painel..."
sudo supervisorctl start Online &>/dev/null

progress_bar 10

print_centered "Modulos do Online instalado com sucesso!"
