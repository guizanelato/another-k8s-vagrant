# Infraestrutura: Kubernetes

## Sobre o Kubernetes

<colocar aqui uma descrição sobre a arquitetura do k8s>

## Requisitos de hardware

Para a instalação do Kubernetes, utilizaremos do método oficial através do binário `kubeadm`.

Em seu [site](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/) oficial nos é recomendado que cada máquina do cluster possua ao menos:

- 2GB de RAM disponível
- 2 vCPUs no mínimo

Em nosso exemplo local utilizaremos:

- 2 máquinas de gerenciamento
- 2 máquinas de trabalho
- 1 Load Balancer 

Como o Load Balancer não faz parte do cluster, ele pode receber uma configuração menor (1vcpu, 512mb RAM). As demais máquinas seguem o padrão.

Nesse sentido, para simular o cluster localmente precisaremos aproximadamente de 8.5GB de RAM disponíveis na máquina host.

## Requisitos de software

Optamos por utilizar um cluster de Kubernetes local, através do uso de 
máquinas virtuais. 

Para otimizar o processo de instalação e configuração, utilizamos a ferramenta
[Vagrant](https://vagrantup.com) para gerenciar as imagens de linux
(no caso optamos pelo uso da distribuição  Debian 10), e no que se refere  a etapa de preparação do cluster, criamos alguns scripts de automação em shell para resolver os pré requisitos.

## Subindo sua infraestrutura local

Com o vagrant instalado, e feito o clone deste repositório, acesse:

```
cd diretorio/do/repositorio
vagrant up
```

Aguarde alguns minutos pois o vagrant irá:

1. realizar o download da imagem do linux debian 10
2. instalar e configurar o linux
3. criar e configurar as interfaces de rede
4. executar o script de automação em shell


### Instalando o Control Plane do Kubernetes 

Após finalizada a instalação, será necessário configurar o control plane no cluster.
Iniciaremos com a máquina `manager-01`:

``` 
vagrant ssh manager-01
``` 

Depois de acessar a máquina execute o seguinte comando:

```
sudo kubeadm init --config files/kubeadm-config.yml' --upload-certs
```

O `kubeadm` irá preparar o nó manager-01 para ser um nó de gerenciamento do Kubernetes. Após realizada a instalação algo como esta saída será apresentada:

```
Your Kubernetes control-plane has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
https://kubernetes.io/docs/concepts/cluster-administration/addons/

You can now join any number of the control-plane node running the following command on each as root:

kubeadm join 172.20.12.100:6443 --token 2vjyq3.aaepezlc9szigtcp \
--discovery-token-ca-cert-hash sha256:fabea16da44390b45c1749e6fb4949ced6c82a1abd97cebe46db9bb175fa8566 \
--control-plane --certificate-key f936242f98d7d56a3b48963555eea669020716f81788414edf84044addaa7814

Please note that the certificate-key gives access to cluster sensitive data, keep it secret!
As a safeguard, uploaded-certs will be deleted in two hours; If necessary, you can use 
"kubeadm init phase upload-certs --upload-certs" to reload certs afterward.

Then you can join any number of worker nodes by running the following on each as root:

kubeadm join 172.20.12.100:6443 --token 2vjyq3.aaepezlc9szigtcp \
--discovery-token-ca-cert-hash sha256:fabea16da44390b45c1749e6fb4949ced6c82a1abd97cebe46db9bb175fa856
```

> É recomendado que você abra outra sessão de terminal para preservar essa saída
pois ela contém os comandos de ingresso de outros nós para o seu clustes.

Depois desse setup inicial, copie o arquivo de configuração de acesso do kubernetes para a pasta do usuário vagrant: 

```
sudo mkdir -p /home/vagrant/.kube
cp /etc/kubernetes/admin.conf /home/vagrant/.kube/config
```

Assim você poderá executar comandos no cluster através do `kubectl` com seu usuário padrão do vagrant:

```
kubectl get nodes
```

E será apresentado algo parecido com:

```
NAME     STATUS    ROLES   AGE    VERSION
master1  NotReady  master  4m51s  v1.20.1
```

#### Configurando a rede do cluster


Para que os nós e seus objetos se comuniquem entre si, utilizaremos do [calico](https://docs.projectcalico.org/about/about-calico) para gerenciar a rede.

O arquivo de configuração já está no provision deste repositório, na máquina manager-01 no diretório `/home/vagrant/files/calico.yaml`.

Basta aplicar esta configuração que o kubernetes automaticamente realizará a sua implementação:

```
kubectl apply -f /home/vagrant/files/calico.yaml
``` 


### Configurando outros nós de gerenciamento

Conforme indicado anteriormente, a nossa infraestrutura é comporta de 2 nós de gerenciamento e dois nós de trabalho. Para completar a configuração dos outros nós, o `kubeadm` nos permite utilizar alguns comandos que facilitam o ingresso. 

Aproveitando o comando apresentado logo após executar o `kubeadm --init` temos o seguinte comando:

```
kubeadm join 172.20.12.100:6443 --token m2bj3h.fjf2tjccajgldqi2 \
--discovery-token-ca-cert-hash sha256:534305ca1b14a916c59f3d413f75158a6479a607ab97e9daf1212603c1683491 \
--control-plane --certificate-key c15d7c091fbbef93b3665b30d16e587fb37c1481f301bc11dc05cb27442c8181 
```

Saia do manager-01 digitando o comando `exit` de forma consecutiva ou aperte CRTL + D. Acesse o manager-02 com o comando:

``` 
vagrant ssh manager-02
```

Execute o comando que o `kubeadm` indicou, adicionando o parâmetro `--apiserver-advertise-address=172.20.12.20` ao final:

```
kubeadm join 172.20.12.100:6443 --token m2bj3h.fjf2tjccajgldqi2 \
  --discovery-token-ca-cert-hash sha256:534305ca1b14a916c59f3d413f75158a6479a607ab97e9daf1212603c1683491 \
  --control-plane --certificate-key c15d7c091fbbef93b3665b30d16e587fb37c1481f301bc11dc05cb27442c8181 \ 
  --apiserver-advertise-address=172.20.12.20
```

Ao final desse processo, teremos o segundo nó de gerenciamento configurado. Caso houver outro nó para configurar, basta acessá-lo e repetir estes mesmos passos alterando ip para o ip correspondente ao nó. 

### Configurando nós de trabalho


A primeira saída do `kubeadm` também nos indicou o comando para adicionar nós de trabalho: 

`kubeadm join 172.20.12.100:6443 --token 2vjyq3.aaepezlc9szigtcp \
--discovery-token-ca-cert-hash sha256:fabea16da44390b45c1749e6fb4949ced6c82a1abd97cebe46db9bb175fa856
```
Basta acessar os nós `worker-01` e `worker-02` e realizar o mesmo procedimento que foi feito na configuração de nós de gerenciamento:

```
#worker-01
#na máquina host
vagrant ssh worker-01
```


```
sudo kubeadm join 172.20.12.100:6443 --token 2vjyq3.aaepezlc9szigtcp \
  --discovery-token-ca-cert-hash sha256:fabea16da44390b45c1749e6fb4949ced6c82a1abd97cebe46db9bb175fa856  \
  --apiserver-advertive-address=172.20.12.60
```

```
#worker-02
#na máquina host
vagrant ssh worker-02

```
sudo kubeadm join 172.20.12.100:6443 --token 2vjyq3.aaepezlc9szigtcp \
  --discovery-token-ca-cert-hash sha256:fabea16da44390b45c1749e6fb4949ced6c82a1abd97cebe46db9bb175fa856  \
  --apiserver-advertive-address=172.20.12.70
```

Pronto, desta forma o seu cluster de kubernetes está pronto. 


### Inspecionando o seu cluster

Retorne a máquina `manager-01` e execute :

```
kubectl get nodes
```

A saída deverá ser algo como:

```
NAME         STATUS   ROLES                  AGE    VERSION
manager-01   Ready    control-plane,master   178m   v1.20.5
manager-02   Ready    control-plane,master   168m   v1.20.5
worker-01    Ready    <none>                 151m   v1.20.5
worker-02    Ready    <none>                 141m   v1.20.5
```


 


