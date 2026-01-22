# Instalação e configuração do containerd (Todos os nós)

## 1. Instalação do Container Runtime (containerd)
O Kubernetes requer um motor de container compatível com CRI (Container Runtime Interface).
```bash
# Adicionar repositório Docker oficial da distro utilizada, no meu caso foi o Debian 13(Trixie)
# Segue link da documentação oficial para adição do repositório e Instalação do containerd. OBS: fazer instalação somente do containerd: https://docs.docker.com/engine/install/debian/ 

# 1. Adicionar repositório Docker
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL -k [https://download.docker.com/linux/debian/gpg](https://download.docker.com/linux/debian/gpg) | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] [https://download.docker.com/linux/debian](https://download.docker.com/linux/debian) \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# 2. Instalar containerd
sudo apt update
sudo apt install -y containerd.io

```

# 2. Configuração do Cgroups Driver (Ponto Crítico/Obrigatório)

Por default, o containerd vem configurado com cgroupfs (ou config vazia). O Kubernetes (Kubelet) usa systemd para gerenciar recursos. Essa discrepância/divergência/diferença impede o cluster de subir ou caso suba ficará instável. O que faremos é fazer com que o containerd trabalhe com o systemd
```bash
# Cria o diretório 
sudo mkdir -p /etc/containerd
#Gera as config defalt e encaminha p/ config.toml 
containerd config default | sudo tee /etc/containerd/config.toml

# Forçar SystemdCgroup = true
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml
#P/ validação execute o comando abaixo e confirme se está true;
grep SystemdCgroup /etc/containerd/config.toml
# Feedback esperado
[root@control-plane ~]# grep SystemdCgroup /etc/containerd/config.toml
            SystemdCgroup = true

#Reinicia o containerd
sudo systemctl restart containerd

```

OBS: A documentação oficial ensina a configurar o Kubelet, mas assume que já tenhamos configurado o runtime. Se não fizer esse passo no containerd:
O kubeadm init detecta o socket.
O Kubelet tenta subir usando systemd.
O Containerd responde usando cgroupfs.
Resultado: Erro de driver e falha no boot do nó.

Ajustando o containerd primeiro (como feito acima), o kubeadm(proximo passo) detecta automaticamente o driver systemd e configura o kubelet sozinho.



