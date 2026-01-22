# Instalação dos binários. Separado do "Init" para ficar modular.

## Instalação das Ferramentas Kubernetes (Kubeadm, Kubelet, Kubectl)

## Configuração do Repositório
link: https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/

```bash
sudo apt-get install -y apt-transport-https ca-certificates curl gpg

# Baixar chave pública (v1.35)
# Uso de -k para ignorar verificação SSL estrita do proxy se necessário
curl -fsSL -k [https://pkgs.k8s.io/core:/stable:/v1.35/deb/Release.key](https://pkgs.k8s.io/core:/stable:/v1.35/deb/Release.key) | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg --yes

# Adicionar source list
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] [https://pkgs.k8s.io/core:/stable:/v1.35/deb/](https://pkgs.k8s.io/core:/stable:/v1.35/deb/) /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
```

### Instalação dos pacotes
```bash
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl

# "Trava" a versão para evitar updates automáticos que quebram o cluster
sudo apt-mark hold kubelet kubeadm kubectl

