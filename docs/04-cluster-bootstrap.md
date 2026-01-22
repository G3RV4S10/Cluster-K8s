# Aqui entra o log de execução real e os avisos coletados.

## Inicialização do Cluster (Control Plane)

Este passo inicializa o plano de controle. Deve ser executado **apenas no nó master**.

## Execução do Kubeadm Init
Substitua `IP_DA_SUA_VM_MASTER` pelo IP fixo da interface principal (ex: 192.168.255.80).

```bash
sudo kubeadm init \
  --pod-network-cidr=192.168.0.0/16 \
  --apiserver-advertise-address=192.168.255.80
--pod-network-cidr=192.168.0.0/16: Necessário para o plugin de rede Calico.

--apiserver-advertise-address: Garante que o API Server anuncie o IP correto e não o localhost.
```

--pod-network-cidr=192.168.0.0/16: Necessário para o plugin de rede Calico.

--apiserver-advertise-address: Garante que o API Server anuncie o IP correto e não o localhost.

Logs de Execução e Avisos Importantes
Durante a execução, observe os avisos de Preflight:

[WARNING HTTPProxyCIDR]: connection to "192.168.0.0/16" uses proxy... Ação: Certifique-se de que os CIDRs de Pod e Service estão no no_proxy.

[WARNING ContainerRuntimeVersion]: ...Falling back to using cgroupDriver from kubelet config... Ação: Informativo sobre depreciação futura (v1.36), mas seguro na versão atual com a configuração de systemd aplicada.


Pós-Instalação (Acesso ao Cluster)
Para começar a usar o cluster com seu usuário regular:

```Bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
Próximos Passos
Salvar o comando kubeadm join exibido ao final do log.

Instalar o CNI (Calico) para que os nós fiquem Ready.

Ingressar os Worker Nodes.
```