#!/bin/bash

CLUSTER_NAME="kube-tp"

echo "This script has been tested only on 16.04.1-Ubuntu"
echo "Root password would be asked for sudo commands"

echo "We need an AWS IAM admin role access key"
echo "Please enter aws_access_key :"
read AWS_ACCESS_KEY
echo "Please enter aws_secret_key :"
read -s AWS_SECRET_KEY

echo "================"
echo "Install Docker"
echo "================"

sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

sudo groupadd docker
sudo usermod -aG docker $USER

sudo systemctl enable docker



echo "================"
echo "Install AWS cli and configure credentials"
echo "================"

sudo apt install -y curl
curl -O https://bootstrap.pypa.io/get-pip.py
python get-pip.py --user
pip install awscli --upgrade --user

# install aws CLI completion
COMPLETER_DIR=$(which aws_completer)
echo export PATH=${COMPLETER_DIR}:\$PATH >> ~/.bashrc
echo complete -C \'${COMPLETER_DIR}\' aws >> ~/.bashrc
source ~/.bashrc


echo "[default]" > ~/.aws/config
echo "region = eu-west-3" >> ~/.aws/config


echo "[default]" > ~/.aws/credentials
echo "aws_access_key_id = ${AWS_ACCESS_KEY}" >> ~/.aws/credentials
echo "aws_secret_access_key = ${AWS_SECRET_KEY}" >> ~/.aws/credentials





echo "================"
echo "Create EKS cluster"
echo "================"

curl --silent --location "https://github.com/weaveworks/eksctl/releases/download/latest_release/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv -v /tmp/eksctl /usr/local/bin
eksctl create cluster --name=${CLUSTER_NAME} --nodes=3 --node-ami=auto



echo "================"
echo "Install kubectl and verify cluster access"
echo "================"

sudo apt-get update && sudo apt-get install -y apt-transport-https
sudo apt-get install -y curl
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubectl
# Installing kubectl bash completion on Linux
kubectl completion bash >> ~/.bashrc
source ~/.bashrc

kubectl cluster-info
kubectl get no

echo "================"
echo "Everything is OK"
echo "If you wnat to delete cluster"
echo "eksctl delete cluster --name=${CLUSTER_NAME}"
echo "================"

