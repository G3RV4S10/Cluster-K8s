
# Adicionando Worker Nodes ao Cluster

Após o Control Plane estar operacional (Status `Ready`), podemos escalar o cluster adicionando os nós de trabalho.

## Pré-requisitos nos Workers
Certifique-se de que os passos dos documentos `01`, `02` e `03` foram executados em cada worker:
1. Swap desligada.
2. Módulos de Kernel (`overlay`, `br_netfilter`) carregados.
3. Containerd instalado e configurado com `SystemdCgroup = true`.
4. Pacotes `kubeadm`, `kubelet`, `kubectl` instalados.

## Execução do Join
No nó **Master**, se você perdeu o token gerado no init, crie um novo:
```bash
kubeadm token create --print-join-command
No Worker Node, execute o comando gerado (como root ou com sudo):

sudo kubeadm join 192.168.255.80:6443 --token <TOKEN> --discovery-token-ca-cert-hash sha256:<HASH>
```


## Configuração SSH (Opcional mas Recomendado). Para facilitar a gestão sem depender do console do hypervisor (VMware/VirtualBox), configure chaves SSH do Master para os Workers. Assim pode-se logar a partir do master em qualquer um dos worker's e vice-versa

# No Master
ssh-keygen -t rsa
ssh-copy-id user@worker-01
ssh-copy-id user@worker-02
ssh-copy-id user@worker-03

---
