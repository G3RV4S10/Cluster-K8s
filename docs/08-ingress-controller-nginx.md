# 8. Implementação de Ingress Controller (NGINX)

## Cenário e Decisão de Arquitetura
Com o MetalLB funcionando (Capítulo 07), conseguimos expor serviços usando IPs da rede física (Layer 4). No entanto, esse modelo possui limitações de escalabilidade:
1.  **Esgotamento de IPs:** Cada serviço exposto consome um IP exclusivo do pool do MetalLB.
2.  **Custo/Gestão:** Em ambientes reais, IPs públicos ou fixos são recursos escassos.
3.  **Roteamento Limitado:** O LoadBalancer nativo opera em Camada 4 (TCP/UDP), sem entender domínios ou caminhos HTTP.

A solução adotada é o **Ingress Controller (NGINX)** operando em **Camada 7 (Aplicação)**.

### Fluxo de Tráfego Implementado
1.  **MetalLB:** Entrega **um único IP** (ex: `192.168.255.32`) para o Ingress Controller.
2.  **Ingress NGINX:** Recebe todo o tráfego HTTP/HTTPS, lê o cabeçalho `Host` (ex: `site.empresa.local`) e roteia para o pod correto.

---

## 1. Instalação (Bare Metal)
Utilizamos a versão oficial compatível com Bare Metal (On-Premise), que já traz as configurações de segurança e permissões necessárias.

**Versão:** v1.10.0 (Community Edition)

``` bash
# Aplica o manifesto oficial
kubectl apply -f [https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.10.0/deploy/static/provider/baremetal/deploy.yaml](https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.10.0/deploy/static/provider/baremetal/deploy.yaml)

# Monitoramento da instalação
kubectl get pods -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx --watch
```
## 2. Integração com MetalLB
Por padrão, o manifesto Bare Metal cria um serviço do tipo NodePort (expondo em portas altas como 30xxx). Para ambientes corporativos, queremos que o Ingress tenha um IP fixo e padrão (Portas 80/443).

Realizamos um Patch no serviço para alterar seu tipo para LoadBalancer, forçando o MetalLB a atribuir um IP do pool.

```Bash
kubectl patch svc ingress-nginx-controller -n ingress-nginx \
  -p '{"spec": {"type": "LoadBalancer"}}'

# Validação
kubectl get svc -n ingress-nginx
# Resultado Esperado: O EXTERNAL-IP deve exibir um endereço válido do pool configurado no MetalLB (diferente do IP usado em testes anteriores).
```

## 3. Configuração de Roteamento (Ingress Resource)
Para testar o roteamento baseado em nomes (Name-Based Virtual Hosting), criamos uma regra apontando o domínio fictício meu-site.local para o serviço Nginx já existente.

Arquivo: ingress-regras.yaml
``` yaml
YAML
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ingress-meu-site
  annotations:
    # Rewrite target garante que a aplicação receba a rota na raiz
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
  - host: meu-site.local   # Definição do Domínio
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: nginx-service-lb  # Nome do Service backend (criado no cap. 07.md)
            port:
              number: 80
```

Aplicação:

```Bash
kubectl apply -f ingress-regras.yaml
```

## 4. Validação e Testes (Host Header)
Como o domínio meu-site.local não existe no DNS real da rede, simulamos a resolução de nomes injetando o cabeçalho HTTP ou alterando o arquivo hosts.

Teste via cURL (Simulação)
```Bash
# Substitua O_IP_DO_INGRESS pelo IP obtido no passo 2
curl -H "Host: meu-site.local" [http://192.168.255.32](http://192.168.255.32)
```
Teste via Navegador (Hosts File)
Adicionar a entrada no arquivo /etc/hosts (Linux/Mac) ou C:\Windows\System32\drivers\etc\hosts (Windows):

192.168.255.32  meu-site.local
Ao acessar http://meu-site.local no navegador, a página padrão do Nginx ("Welcome to nginx!") deve ser exibida, confirmando que o tráfego passou pelo Ingress e foi roteado corretamente.
