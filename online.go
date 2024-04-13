package main

import (
	"bufio"
	"bytes"
	"fmt"
	"net/http"
	"os"
	"os/exec"
	"strings"
	"time"
)

func main() {
	if len(os.Args) != 2 {
		fmt.Println("Uso: ./programa <URL>")
		return
	}
	url := os.Args[1]
	startLoop(url)
}

func startLoop(url string) {
	for {
		userList, err := getUsers()
		if err != nil {
			fmt.Println("Erro ao obter a lista de usuários:", err)
			time.Sleep(3 * time.Second)
			continue
		}

		if err := sendPostRequest(url, userList); err != nil {
			fmt.Println("Erro ao enviar POST request:", err)
		}

		time.Sleep(3 * time.Second)
	}
}

func getUsers() (string, error) {
	var userList []string

	// Obtém usuários do sistema
	output, err := exec.Command("sh", "-c", "ps aux | grep priv | grep Ss").Output()
	if err != nil {
		return "", err
	}
	scanner := bufio.NewScanner(strings.NewReader(string(output)))
	for scanner.Scan() {
		line := scanner.Text()
		columns := strings.Fields(line)
		if len(columns) >= 12 {
			// Encontra o índice do padrão "sshd:"
			index := -1
			for i, col := range columns {
				if col == "sshd:" {
					index = i
					break
				}
			}
			// Se o padrão "sshd:" for encontrado, adicione o nome de usuário à lista
			if index != -1 && index+1 < len(columns) {
				username := columns[index+1]
				userList = append(userList, username)
			}
		}
	}
	if err := scanner.Err(); err != nil {
		return "", err
	}

	// Se o arquivo openvpn-status.log existir, adicione os usuários do OpenVPN
	if _, err := os.Stat("/etc/openvpn/openvpn-status.log"); err == nil {
		openVPNOutput, err := exec.Command("sh", "-c", "cat /etc/openvpn/openvpn-status.log | grep -Eo '^[a-zA-Z0-9_-]+,[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+:[0-9]+' | awk -F, '{print $1}'").Output()
		if err != nil {
			return "", err
		}
		openVPNUsers := strings.Split(strings.TrimSpace(string(openVPNOutput)), "\n")
		for _, user := range openVPNUsers {
			userList = append(userList, user)
		}
	}

	return strings.Join(userList, ","), nil
}

func sendPostRequest(url, userList string) error {
	// Fazer uma requisição POST para a URL especificada
	requestBody := []byte("users=" + userList)
	resp, err := http.Post(url, "application/x-www-form-urlencoded", bytes.NewBuffer(requestBody))
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	fmt.Printf("Enviando lista de usuários %s para %s\n", userList, url)
	return nil
}
