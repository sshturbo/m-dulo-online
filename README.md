# m-dulo-online
Script para os online do painel web pro 

# Instalação
Para instalar o Modulos do online, siga estas etapas:

```bash
bash <(wget -qO- https://raw.githubusercontent.com/sshturbo/m-dulo-online/main/install.sh) https://seu domínio.com/online.php
```

### Verificar se está instalado e executado com sucesso só executar o comando.

```bash
sudo systemctl status online.service
```


### Para poder tá parando os módulos e só executar o comando.

```bash
sudo systemctl stop online.service
```

```bash
sudo systemctl disable online.service
```

```bash
sudo systemctl daemon-reload
```
 

### Para poder ta iniciando os módulos e so executar o comando.

```bash
sudo systemctl enable online.service
```
```bash
sudo systemctl start online.service
```