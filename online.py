#!/usr/bin/env python
# -*- coding: utf-8 -*-
import subprocess
import re
import time
import sys

# Importação condicional para requests
try:
    import requests
except ImportError:
    print("A biblioteca 'requests' não está instalada. Instale-a com 'pip install requests'.")
    sys.exit(1)

# Compatibilidade com Python 2 e 3 para 'input' e 'print'
try:
    input = raw_input
except NameError:
    pass

def get_connected_users():
    # Comando modificado para ser compatível com Python 2 e 3
    process = subprocess.Popen(['ps', 'aux'], stdout=subprocess.PIPE)
    output, _ = process.communicate()
    # Decodificar para UTF-8 em Python 3
    if sys.version_info[0] >= 3:
        output = output.decode('utf-8')

    users = set()
    for line in output.split('\n'):
        if 'priv' in line and 'Ss' in line:
            columns = line.split()
            if len(columns) > 11:
                users.add(columns[11])

    try:
        with open('/etc/openvpn/openvpn-status.log', 'r') as file:
            for line in file:
                match = re.match(r"^[a-zA-Z0-9_-]+,[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:[0-9]+", line)
                if match:
                    users.add(line.split(',')[0])
    except IOError:  # IOError cobre FileNotFoundError em Python 2 e é suficiente para ambos
        pass

    print("Usuários conectados: " + ', '.join(users))
    return ','.join(users)

def send_users_to_server(user_list, url):
    print("Enviando para o URL: " + url)
    response = requests.post(url, data={'users': user_list})
    print("Resposta do servidor: " + str(response.status_code))

def start_loop(url):
    while True:
        user_list = get_connected_users()
        send_users_to_server(user_list, url)
        time.sleep(3)

if __name__ == "__main__":
    url = sys.argv[1] if len(sys.argv) > 1 else "https://example.com/"
    print("Iniciando o loop com a URL: " + url)
    start_loop(url)

