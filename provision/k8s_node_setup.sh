IP=$(hostname -I | cut -d" " -f2)
sudo su  <<EOF
#0: change do root

#1: set ip-tables legacy mode

 update-alternatives --set iptables /usr/sbin/iptables-legacy
 update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy
 update-alternatives --set arptables /usr/sbin/arptables-legacy
 update-alternatives --set ebtables /usr/sbin/ebtables-legacy

#2: install dependencies
 apt update
 apt install -y apt-transport-https ca-certificates curl gnupg2 software-properties-common vim 

#3: configure respositories

curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -

echo 'deb https://apt.kubernetes.io/ kubernetes-xenial main' > /etc/apt/sources.list.d/kubernetes.list

 curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg


echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null


# install 
 apt-get update
 apt-get install -y docker-ce docker-ce-cli containerd.io kubelet kubeadm kubectl
 apt-mark hold kubelet kubeadm kubectl 

 cat <<EOFL | tee /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "journald"
}
EOFL
 systemctl restart docker

 echo "KUBELET_EXTRA_ARGS='--node-ip=$IP'" > /etc/default/kubelet

 sed -Ei 's/(.*swap.*)/#\1/g' /etc/fstab
 swapoff -a

EOF



