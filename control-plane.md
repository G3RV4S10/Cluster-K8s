# Control-Plane
Utilizado; 
- VM Debian 13 (Trixie)
- 4vCpu
- 8vRam
- 64vDisk
- Rede (192.168.x.x/24)


Este documento descreve o processo de preparação e bootstrap do **Control Plane Kubernetes**
em um sistema **Debian GNU/Linux 13**, seguindo rigorosamente as **boas práticas recomendadas
pela documentação oficial do Kubernetes**, utilizando `kubeadm`.

Referência oficial:  
https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/

O objetivo é garantir:
- Estabilidade operacional
- Reprodutibilidade do ambiente
- Clareza nas decisões técnicas
- Aderência a padrões enterprise
---
## Pré-requisitos do Ambiente

- Sistema operacional: **Debian GNU/Linux 13**
- Arquitetura: amd64
- Acesso root ou sudo
- Conectividade com repositórios Kubernetes (via proxy, quando aplicável)
- Swap desabilitado
- Container runtime: **containerd**

---

## Configuração de Proxy (Ambiente Corporativo)

Este nó foi previamente configurado para operar atrás de proxy HTTP/HTTPS, garantindo:

- Acesso aos repositórios oficiais do Kubernetes
- Download de imagens de containers
- Funcionamento correto do kubelet e do container runtime

> Detalhes sensíveis de proxy não são versionados neste repositório por motivos de segurança.

# Preparando o control-plane
### Via CLI
### Setando proxy na VM, caso nao possua em seu ambiente corporativo, nao e necessario
export http_proxy=http://170.xx.xx.xx:xx \
export https_proxy=http://170.xx.xx.xx:xx
### IMPORTANTE: Defina no_proxy para que o cluster não tente sair pelo proxy para falar localmente
export no_proxy=127.0.0.1,localhost,192.168.x.x/24,10.96.x.x/12,10.244.x.x/16


---

## Instalação dos Componentes Kubernetes

A instalação seguiu **exatamente o procedimento recomendado pela documentação oficial**,
assegurando compatibilidade com versões estáveis do Kubernetes.

---

