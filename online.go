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
        fmt.Println("Uso: programa <URL>")
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

    output, err := exec.Command("sh", "-c", "ps aux | grep priv | grep Ss").Output()
    if err != nil {
        return "", err
    }

    scanner := bufio.NewScanner(strings.NewReader(string(output)))
    for scanner.Scan() {
        line := scanner.Text()
        if !strings.Contains(line, "priv") {
            continue
        }
        columns := strings.Fields(line)
        if len(columns) >= 12 {
            username := columns[11] // Alterado para pegar o usuário da coluna 10
            // Adicione apenas o nome de usuário à lista, ignorando outros caracteres
            username = strings.TrimSpace(username)
            if !strings.Contains(username, "-c") { // Verifica se o usuário contém "-c"
                userList = append(userList, username)
            }
        }
    }
    if err := scanner.Err(); err != nil {
        return "", err
    }

    // Verifica se o arquivo do OpenVPN existe antes de tentar recuperar os usuários
    if _, err := exec.LookPath("grep"); err == nil {
        if _, err := exec.Command("grep", "-q", "^[a-zA-Z0-9_-]+,[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+:[0-9]+", "/etc/openvpn/openvpn-status.log").Output(); err == nil {
            openVPNOutput, err := exec.Command("grep", "-Eo", "^[a-zA-Z0-9_-]+,[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+:[0-9]+", "/etc/openvpn/openvpn-status.log").Output()
            if err != nil {
                return "", err
            }
            openVPNUsers := strings.Split(strings.TrimSpace(string(openVPNOutput)), "\n")
            for _, user := range openVPNUsers {
                // Adicione apenas o nome de usuário à lista, ignorando outros caracteres
                user = strings.TrimSpace(user)
                if !strings.Contains(user, "-c") { // Verifica se o usuário contém "-c"
                    userList = append(userList, user)
                }
            }
        }
    }

    return strings.Join(userList, ","), nil
}

func sendPostRequest(url, userList string) error {
    // Crie um buffer com os dados a serem enviados no corpo da requisição
    requestBody := []byte("users=" + userList)
    body := bytes.NewBuffer(requestBody)

    // Faça uma requisição POST para a URL especificada com os dados do corpo
    _, err := http.Post(url, "application/x-www-form-urlencoded", body)
    if err != nil {
        return err
    }

    fmt.Printf("Enviando lista de usuários %s para %s\n", userList, url)
    return nil
}
