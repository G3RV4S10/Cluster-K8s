# Kubernetes Cluster – Arquitetura de Control Plane e Worker Nodes

## 📌 Visão Geral
Este repositório documenta a criação de um **cluster Kubernetes** composto por **1 Control Plane** e **3 Worker Nodes**, com foco em **boas práticas de arquitetura**, **decisões técnicas justificadas** e **padrões próximos de ambiente corporativo/SRE**.

O objetivo não é apenas "subir um cluster", mas **projetar uma infraestrutura consistente**, observável e preparada para crescimento controlado.

---

## 🏗️ Arquitetura do Cluster

- **1× Control Plane**
  - API Server
  - Scheduler
  - Controller Manager
  - etcd

- **3× Worker Nodes**
  - containerd
  - kubelet
  - workloads (pods)

Todos os nós utilizam **Debian Linux** como sistema operacional base.

---

## Estratégia de Particionamento

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


### Por que **não** criar `/home`?
- Nós Kubernetes não são estações de trabalho
- Não há usuários interativos
- Nenhum dado persistente de aplicação deve residir localmente

---

## Decisões Técnicas Importantes

### Swap
- Swap **não é utilizada**
- Kubernetes exige swap desativada por padrão
- Evita comportamento imprevisível de memória


### /usr separado
- Sistemas modernos (systemd) não se beneficiam
- Pode causar problemas no boot
- Mantido junto com `/`

---

## 📂 Uso de Btrfs

O **Btrfs** foi escolhido por:
- Suporte a subvolumes
- Snapshots seletivos
- Compressão transparente
- Facilidade de rollback

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
- [ ] Hardening básico de segurança
- [ ] Monitoramento (Prometheus + Grafana)
- [ ] Backup do etcd
- [ ] Networking (CNI) - Calico 
- [ ] Documentação de troubleshooting

---

## 📎 Observação Final

Todas as decisões aqui documentadas são **intencionais**, **justificadas** e alinhadas com cenários reais de operação.

> Infraestrutura não é sobre instalar — é sobre **sustentar**.

