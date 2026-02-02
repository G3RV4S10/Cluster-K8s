# Kubernetes Cluster – Arquitetura de Control Plane e Worker Nodes

## Documentação "Hard Way"....


![Status](https://img.shields.io/badge/Status-Operational-success?style=flat-square) 
![Kubernetes](https://img.shields.io/badge/Kubernetes-v1.35.0-blue?style=flat-square) 
![OS](https://img.shields.io/badge/OS-Debian_13_(Trixie)-red?style=flat-square)

## 📌 Visão Geral
Este repositório documenta a criação de um **cluster Kubernetes** composto por **1 Control Plane** e **3 Worker Nodes**, com foco em **boas práticas de arquitetura**, **decisões técnicas justificadas** e **padrões próximos de ambiente corporativo/SRE**.

O objetivo não é apenas "subir um cluster", mas **projetar uma infraestrutura consistente**, observável e preparada para crescimento controlado.

A implementação segue a filosofia "Hard Way" (via `kubeadm`), enfrentando cenários reais de restrição de rede (Proxy Corporativo) e customizações de kernel.

---

## 📚 Navegação da Documentação Técnica
O detalhamento passo-a-passo da implementação encontra-se na pasta `/docs`:

1. [**Pré-requisitos de Sistema**](docs/01-pre-requisitos-rede-os.md) - *Kernel 6.12, Swap, Proxy e Sysctl.*
2. [**Container Runtime**](docs/02-container-runtime.md) - *Containerd com Systemd Cgroup (Correção Crítica).*
3. [**Instalação de Pacotes**](docs/03-kubernetes-install.md) - *Kubeadm, Kubelet e Kubectl.*
4. [**Cluster Bootstrap**](docs/04-cluster-bootstrap.md) - *Inicialização do Control Plane.*
5. [**Rede e CNI (Calico)**](docs/05-rede-cni-calico.md) - *Solução de problemas de Path CNI no Debian.*
6. [**Worker Nodes**](docs/06-adicionando-workers.md) - *Join e validação.*
7. [**MetalLB - Load Balancer**](docs/07-loadbalancer-metallb.md) - *In progress.*

---

## 🏗️ Arquitetura do Cluster

- **1× Control Plane** (API Server, Scheduler, Controller Manager, etcd)
- **3× Worker Nodes** (Workloads(pods), Kubelet, Containerd)
- **Rede:** Project Calico (Tigera Operator)
- **OS:** Debian Linux 13 (Trixie)

Todos os nós utilizam **Debian Linux** como sistema operacional base.

---

## 🛠️ Desafios de Engenharia Superados

Durante a implementação, decisões específicas foram tomadas para garantir estabilidade em ambiente virtualizado corporativo:

### 1. Alinhamento de Cgroups (Systemd)
O `containerd` padrão utiliza `cgroupfs`, enquanto o Kubernetes requer `systemd`. A discrepância causa falha silenciosa no Kubelet.
* **Solução:** Forçar `SystemdCgroup = true` no `config.toml` do containerd.

### 2. Integração de Rede (CNI Path)
O Debian 13 e o Calico possuem divergência no diretório de binários CNI (`/usr/lib/cni` vs `/opt/cni/bin`), causando falha nos pods `calico-node`.
* **Solução:** Download manual dos plugins CNI v1.3.0 e replicação dos binários para ambos os diretórios de sistema.

### 3. Proxy Transparente
Configuração de variáveis `no_proxy` granulares para garantir que o tráfego do Pod CIDR (`192.168.0.0/16`) e Service CIDR não colida com o gateway corporativo.

---

## Estratégia de Particionamento & Storage
O particionamento utiliza **Btrfs** para evitar indisponibilidade e facilitar snapshots.

O particionamento foi pensado para:
- Evitar indisponibilidade por disco cheio
- Isolar crescimento de logs e containers
- Facilitar troubleshooting
- Manter simplicidade sem sacrificar boas práticas

### 🔐 Control Plane – Layout de Disco

| Ponto de Montagem | Tamanho | FS     | Justificativa |
|------------------|---------|--------|---------------|
| /boot            | 528 MB  | ext4   | Boot estável e compatível |
| /                | 25 GB   | btrfs  | Sistema base e binários |
| /var             | 43.2 GB | btrfs  | Logs, containers, kubelet e etcd |

### Decisões de Filesystem
* **Btrfs:** Escolhido por suporte a subvolumes e snapshots.
- Suporte a subvolumes
- Snapshots seletivos
- Compressão transparente
- Facilidade de rollback
* **Sem `/home` separado, Por que **não** criar `/home`?:** 
- Nós Kubernetes não são estações de trabalho
- Não há usuários interativos
- Nenhum dado persistente de aplicação deve residir localmente

### /usr separado
- Sistemas modernos (systemd) não se beneficiam
- Pode causar problemas no boot
- Mantido junto com `/`
---

## Decisões Técnicas Importantes
### Swap - Totalmente desabilitado (requisitos do kubelet)
- Swap **não é utilizada**
- Kubernetes exige swap desativada por padrão
- Evita comportamento imprevisível de memória

---

### Subvolumes recomendados em `/var`

```
/var/log
/var/lib/containerd
/var/lib/kubelet
/var/lib/etcd   # apenas no control plane
```

### Atenção: etcd e Copy-on-Write

O etcd é extremamente sensível a latência de disco.

➡ **Copy-on-Write é desativado para o diretório do etcd**:

```bash
chattr +C /var/lib/etcd
```

Essa prática reduz risco de degradação de performance e corrupção de dados.

---

## Opções de Montagem (Mount Options)

Recomendadas para `/` e `/var`:

```
noatime,compress=zstd
```

Benefícios:
- Menor I/O
- Logs mais leves
- Melhor desempenho geral

---

## Objetivo do Projeto

Este projeto serve como:
- Laboratório avançado de Kubernetes
- Base para estudos de DevOps / SRE
- Portfólio técnico documentado
- Referência de boas práticas de infraestrutura

---

## Próximos Passos

- [x] Inicialização do cluster com kubeadm
- [x] Networking (CNI) - Calico (Configurado e Operacional)
- [ ] Networking (CNI) - Canal - Explorar futuramente - Junção do Flannel e Calico
- [x] Documentação de troubleshooting (CNI e Runtime)
- [ ] Hardening básico de segurança
- [ ] Monitoramento (Prometheus + Grafana)
- [ ] Backup do etcd
- [ ] Documentação de troubleshooting


---

#### Observação Final

Todas as decisões aqui documentadas são **intencionais**, **justificadas** e alinhadas com cenários reais de operação.

> Infraestrutura não é sobre instalar — é sobre **sustentar**.

---
📎 Licença
MIT License - Copyright (c) 2026 Gervasio
