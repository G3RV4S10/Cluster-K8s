# Instalação da Rede (CNI - Calico) e Troubleshooting Avançado

A rede é o componente que tira os nós do estado `NotReady`. Utilizamos o **Project Calico** via Tigera Operator devido à sua robustez e suporte a Network Policies.

> **Nota de Arquitetura:** O CIDR configurado no `kubeadm init` (`192.168.0.0/16`) deve corresponder à configuração padrão do Calico.

## 1. Instalação Padrão (Tentativa Inicial)
Em ambientes sem restrições, a instalação segue o manifesto oficial:

```bash
# Instalar o Tigera Operator
kubectl create -f [https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/tigera-operator.yaml](https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/tigera-operator.yaml)

# Instalar os Custom Resources (Define o CIDR e configs do CNI)
kubectl create -f [https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/custom-resources.yaml](https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/custom-resources.yaml)
```


### Troubleshooting Crítico: Erro de "CNI Plugin Not Found", tive este problema e resolvi documentar também;
### Cenário: Após a instalação, os pods calico-node e csi-node-driver entram em CrashLoopBackOff ou ficam presos em ContainerCreating.

### Diagnóstico: Analisando os logs (kubectl describe pod -n calico-system ...), identifica-se que o kubelet está procurando os binários de rede (como loopback, bridge) no diretório /usr/lib/cni, mas o pacote padrão ou a extração manual muitas vezes os coloca em /opt/cni/bin. Solução Definitiva (The Hard Way): Baixar os plugins CNI standard manualmente e garantir que eles existam em ambos os diretórios esperados pelo Debian 13.


```bash

# Passo 1: Baixar os Plugins CNI
# Baixar a versão v1.3.0 (compatível com k8s v1.35)
curl -L -k [https://github.com/containernetworking/plugins/releases/download/v1.3.0/cni-plugins-linux-amd64-v1.3.0.tgz](https://github.com/containernetworking/plugins/releases/download/v1.3.0/cni-plugins-linux-amd64-v1.3.0.tgz) -o cni-plugins.tgz
Passo 2: Extração e Correção de Path

# 1. Criar e extrair para o diretório padrão da indústria
sudo mkdir -p /opt/cni/bin
sudo tar -xzvf cni-plugins.tgz -C /opt/cni/bin

# 2. O Pulo do Gato: Replicar para o diretório que o Debian/Kubelet está buscando
sudo mkdir -p /usr/lib/cni
sudo cp -r /opt/cni/bin/* /usr/lib/cni/

Passo 3: Reiniciar Workloads
Force o Kubernetes a recriar os pods para que eles detectem os binários novos.

# Reiniciar serviços do nó (opcional, mas recomendado)
sudo systemctl restart containerd
sudo systemctl restart kubelet

# Deletar os pods travados para forçar recriação
kubectl delete pod -n calico-system --all

Validação Final
Aguarde alguns segundos e verifique se todos os componentes do sistema estão Running.


kubectl get pods -n calico-system
Saída Esperada:

NAME                                      READY   STATUS    RESTARTS   AGE
calico-kube-controllers-wd5c8...          1/1     Running   0          2m
calico-node-vnjr2                         1/1     Running   0          2m
calico-typha-667c9...                     1/1     Running   0          2m
csi-node-driver-pbzg6                     2/2     Running   0          2m
Por final, verificar se o nó master(Control-plane) está pronto:

kubectl get nodes
# STATUS deve ser 'Ready'

---