# Pré-requisitos do Sistema Operacional

## 🔧 Especificações da VM
- **OS:** Debian 13 (Trixie)
- **CPU:** 4 vCPU
- **RAM:** 8 GB
- **Disco:** 64 GB (Particionamento Btrfs)

## 1. Configuração de Rede e Proxy
Como o ambiente é corporativo no meu caso, as variáveis de ambiente são críticas para que o `kubeadm` e o `crictl` funcionem.

```bash
# Setar proxy na variável de ambiente (se aplicável). OBS: Verifique como setar seu proxy
export http_proxy=[http://xx.xx.xx.xx](http://xx.xx.xx.xx):xx
export https_proxy=[http://xx.xx.xx.xx](http://xx.xx.xx.xx):xx

# CRÍTICO: No Proxy
# Garante que o tráfego do Cluster (Pod Network, Service Network) não saia pelo Gateway
export no_proxy=127.0.0.1,localhost,192.168.0.0/16,10.90.0.0/12,192.168.255.80
```

## 2. Configuração de Kernel e Swap (Todos os nós)

```bash
# 1. Desativar Swap
sudo swapoff -a
sudo sed -i '/ swap / s/^\\(.*\\)$/#\\1/g' /etc/fstab

# 2. Carregar Módulos (Overlay e Netfilter)
# O K8s necessita de módulos específicos para roteamento de pacotes e OverlayFS.
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

# overlay: Habilita o OverlayFS, essencial para o filesystem de camadas dos containers. Sem ele, containers não iniciam.
# br_netfilter: Permite que o tráfego em bridges passe pelo iptables. Fundamental para Services, NetworkPolicies e CNI. Sem ele, Pods "se veem" mas não comunicam.

sudo modprobe overlay
sudo modprobe br_netfilter

# 3. Parâmetros Sysctl (Bridged Traffic/Rede)
# Permite que o kernel do Linux roteie tráfego de bridge (IPv4 e IPv6).
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system
```
