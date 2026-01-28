#!/bin/bash
set -e

# ================================================:
# VARIÁVEIS (Igual ao Worker-node p consistência) |
# ================================================:
# Este .sh serve para "Automatizar" as configurações inicias para o nó de worker-node

K8S_VERSION="1.35"
PROXY_URL="http://xx.xx.xx.xx:80"

GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${GREEN}>>> Iniciando Setup do Worker Node Kubernetes v$K8S_VERSION ${NC}"

# 1. Preparação do OS
echo -e "${GREEN}>>> [1/4] Desativando Swap e Carregando Módulos...${NC}"
swapoff -a
sed -i '/ swap / s/^\\(.*\\)$/#\\1/g' /etc/fstab

cat <<EOF | tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
modprobe overlay
modprobe br_netfilter

cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
sysctl --system

#3. Container Runtime (Containerd)
echo -e "${GREEN}>>> [2/4] Instalando e Configurando Containerd...${NC}"
apt update
apt install -y ca-certificates curl gnupg
install -m 0755 -d /etc/apt/keyrings
curl -fsSL -k https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg --yes
chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

apt update
apt install -y containerd.io

# Systemd Cgroup Fix
mkdir -p /etc/containerd
containerd config default | tee /etc/containerd/config.toml > /dev/null
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml
systemctl restart containerd

#Setando proxy
export http_proxy=$PROXY_URL
export https_proxy=$PROXY_URL
# O no_proxy é menos crítico no worker antes do join, mas bom ter
export no_proxy=127.0.0.1,localhost,xxx.xxx.0.0/xx,xx.xx.0.0/12

# 2. Configurar APT Proxy
cat <<EOF | tee /etc/apt/apt.conf.d/99proxy
Acquire::http::Proxy "$PROXY_URL/";
Acquire::https::Proxy "$PROXY_URL/";
Acquire::https::Verify-Peer "false";
Acquire::https::Verify-Host "false";
EOF

# 4. Instalar Kubernetes Binaries
echo -e "${GREEN}>>> [3/4] Instalando Kubeadm, Kubelet e Kubectl...${NC}"
apt install -y apt-transport-https
curl -fsSL -k https://pkgs.k8s.io/core:/stable:/v$K8S_VERSION/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg --yes
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v$K8S_VERSION/deb/ /" | tee /etc/apt/sources.list.d/kubernetes.list

apt update
apt install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

#chmod +x script.sh
#root@control-plane:~# kubeadm token create --print-join-command
#kubeadm join xxx.xxx.xx:6443 --token 5vnwkw.kk0pglh40em1kaa6 --discovery........etc

echo -e "${GREEN}>>> [4/4] WORKER PRONTO!${NC}"
echo "-----------------------------------------------------------------------"
echo "Agora, cole o comando 'kubeadm join' gerado no Master aqui no worker"
echo "Exemplo: sudo kubeadm join xx.xx.xx:6443 --token .."
echo "-----------------------------------------------------------------------"
