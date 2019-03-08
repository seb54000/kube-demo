#!/bin/bash


if [ -z "$1" ]; then
	echo "Usage : init=cluster.sh <cluster=name>"
else
	CLUSTER_NAME="$1"
fi

echo "This script has been tested only on 16.04.1-Ubuntu"
echo "Root password would be asked for sudo commands"

FILE="$HOME/.aws/config"     
if [ -f $FILE ]; then
   AWS_EXIST=1
else
	echo "We need an AWS IAM admin role access key"
	echo "Please enter aws_access_key :"
	read AWS_ACCESS_KEY
	echo "Please enter aws_secret_key :"
	read -s AWS_SECRET_KEY
fi

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

sudo apt-get install -y docker-ce docker-ce-cli containerd.io

sudo groupadd docker
sudo usermod -aG docker $USER

sudo systemctl enable docker



echo "================"
echo "Install AWS cli and configure credentials"
echo "================"

curl -O https://bootstrap.pypa.io/get-pip.py
python get-pip.py --user
pip install awscli --upgrade --user

# install aws CLI completion
COMPLETER_DIR=$(which aws_completer)
echo export PATH=${COMPLETER_DIR}:\$PATH >> ~/.bashrc
echo complete -C \'${COMPLETER_DIR}\' aws >> ~/.bashrc
source ~/.bashrc

if [ -z "$AWS_EXIST" ]; then
	mkdir -p ~/.aws
	echo "[default]" > ~/.aws/config
	echo "region = eu-west-3" >> ~/.aws/config

	echo "[default]" > ~/.aws/credentials
	echo "aws_access_key_id = ${AWS_ACCESS_KEY}" >> ~/.aws/credentials
	echo "aws_secret_access_key = ${AWS_SECRET_KEY}" >> ~/.aws/credentials
fi

echo "================"
echo "Install aws-iam-authenticator"
echo "================"

curl -o aws-iam-authenticator https://amazon-eks.s3-us-west-2.amazonaws.com/1.11.5/2018-12-06/bin/linux/amd64/aws-iam-authenticator
chmod +x ./aws-iam-authenticator
sudo mv ./aws-iam-authenticator /usr/bin/aws-iam-authenticator 
sudo chown root:root /usr/bin/aws-iam-authenticator


echo "================"
echo "Ensure the ELB Service Role exists"
echo "================"

aws iam get-role --role-name "AWSServiceRoleForElasticLoadBalancing" || aws iam create-service-linked-role --aws-service-name "elasticloadbalancing.amazonaws.com"


echo "================"
echo "Create EKS cluster"
echo "================"

curl --silent --location "https://github.com/weaveworks/eksctl/releases/download/latest_release/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv -v /tmp/eksctl /usr/local/bin
eksctl create cluster --name=${CLUSTER_NAME} --nodes=3 --node-ami=auto



echo "================"
echo "Install kubectl and verify cluster access"
echo "================"

sudo apt-get install -y apt-transport-https
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

