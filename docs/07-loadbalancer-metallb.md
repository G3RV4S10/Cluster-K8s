# 7. Implementação de Load Balancer (MetalLB)

## Cenário e Decisão de Arquitetura
Em ambientes On-Premise (Bare Metal/VMware), não existe um Load Balancer nativo "as a Service" como na nuvem pública (AWS ELB, Google LB). Sem um addon, serviços do tipo `LoadBalancer` ficam eternamente em estado `Pending`.

Para este laboratório, utilizei o **MetalLB** em **Modo Layer 2**.

### Por que Layer 2 (ARP)?
O modo Layer 2 em vez de BGP pelas seguintes razões:
1.  **Compatibilidade Universal:** Funciona em qualquer rede Ethernet padrão sem exigir configurações em roteadores físicos.
2.  **Simplicidade:** Não exige ASN, peers BGP ou topologias de rede complexas (Spine-Leaf).
3.  **Funcionamento:** O nó líder "anuncia" o IP externo via ARP (Address Resolution Protocol) para a rede local, atraindo o tráfego para si.

> **Nota de Design:** Em Layer 2, todo o tráfego de um serviço passa por um único nó (o líder). Para a escala deste laboratório, isso não representa gargalo.

---

## 1. Pré-requisitos (Strict ARP)
O `kube-proxy` deve ser configurado com `strictARP: true` para permitir que o MetalLB manipule as respostas ARP corretamente.

```bash
kubectl get configmap kube-proxy -n kube-system -o yaml | \
sed -e "s/strictARP: false/strictARP: true/" | \
kubectl apply -f - -n kube-system
```

## 2. Instalação
Versão utilizada: v0.14.3 (Manifestos Nativos).

```Bash
curl -k -O [https://raw.githubusercontent.com/metallb/metallb/v0.14.3/config/manifests/metallb-native.yaml](https://raw.githubusercontent.com/metallb/metallb/v0.14.3/config/manifests/metallb-native.yaml)
kubectl apply -f metallb-native.yaml
```
## 3. Configuração do IP Pool
Definimos um range de IPs da rede física (192.xx.xx.0/24) que está fora do escopo DHCP, evitando conflitos de IP.

Faixa Alocada: 192.168.xx.xx - 192.168.xx.xx

Arquivo metallb-pool.yaml:

```YAML
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: ip-pool-laboratorio
  namespace: metallb-system
spec:
  addresses:
  - 192.168.255.200-192.168.255.210
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: l2-advertisement
  namespace: metallb-system
```

## 4. Teste de Validação
```Bash
# Deploy de teste
kubectl create deployment nginx-test --image=nginx
kubectl expose deployment nginx-test --port=80 --type=LoadBalancer
```

## Verificar atribuição de IP
```bash
kubectl get svc nginx-test
# Resultado Esperado: O serviço deve receber um IP do pool (ex: 192.168.255.200) e ser acessível via navegador na rede local.
```



<img width="1197" height="855" alt="image" src="https://github.com/user-attachments/assets/9d9919a9-1338-4366-8f54-a6d2529b0ab6" />

<img width="1207" height="834" alt="image" src="https://github.com/user-attachments/assets/a58b08d8-db09-48f2-b690-11efc3014f05" />


<img width="1235" height="368" alt="image" src="https://github.com/user-attachments/assets/600e0a6a-42ac-47c8-9cba-6fab64448f2a" />


<img width="1913" height="331" alt="image" src="https://github.com/user-attachments/assets/fdb7ec86-45da-4dbd-acb4-527e120a65a3" />

<img width="1918" height="461" alt="image" src="https://github.com/user-attachments/assets/4b069eaa-6180-4674-a972-c943b03666da" />



