#!/bin/bash


if [ -z "$1" ]; then
	echo "Usage : init=cluster.sh <cluster=name> [cred-config] [use-cluster]"
else
	CLUSTER_NAME="$1"
fi

export CLUSTER_NAME=${CLUSTER_NAME}

echo "This script has been tested only on 16.04.1-Ubuntu"
echo "Root password would be asked for sudo commands"

FILE="$HOME/.aws/config"     
if [ $2 == "cred-config" ]; then
   CRED_CONFIG=1
   	echo "You want to change or reload your admin keys"
   	echo "We need an AWS IAM admin role access key"
	echo "Please enter aws_access_key :"
	read AWS_ACCESS_KEY
	echo "Please enter aws_secret_key :"
	read -s AWS_SECRET_KEY
elif [ -f $FILE ]; then
	AWS_EXIST=1
else
	echo "We need an AWS IAM admin role access key"
	echo "Please enter aws_access_key :"
	read AWS_ACCESS_KEY
	echo "Please enter aws_secret_key :"
	read -s AWS_SECRET_KEY
fi

if [ $2 == "use-cluster" ]; then
	USE_CLUSTER=1
fi

echo "================"
echo "Configure AWScli credentials"
echo "================"

	mkdir -p ~/.aws
	echo "[default]" > ~/.aws/config
	echo "region = eu-west-3" >> ~/.aws/config

if [ -z "$AWS_EXIST" ] || [ ! -z ${CRED_CONFIG} ]; then
	echo "[default]" > ~/.aws/credentials
	echo "aws_access_key_id = ${AWS_ACCESS_KEY}" >> ~/.aws/credentials
	echo "aws_secret_access_key = ${AWS_SECRET_KEY}" >> ~/.aws/credentials

	if [ ${CRED_CONFIG} -eq 1 ]; then
		echo "Your awsconfig cli credentials are changed, please use or relaunch the script with differetn options to use-cluster or nothing to create it"
		exit 0
	fi
fi

echo "================"
echo "Install AWS cli and configure credentials"
echo "================"

if aws --version;then
	echo "awscli already installed"
else
	curl -O https://bootstrap.pypa.io/get-pip.py
	python get-pip.py --user
	pip install awscli --upgrade --user

	# install aws CLI completion
	COMPLETER_DIR=$(which aws_completer)
	echo export PATH=${COMPLETER_DIR}:\$PATH >> ~/.bashrc
	echo complete -C \'${COMPLETER_DIR}\' aws >> ~/.bashrc
	source ~/.bashrc
fi

echo "================"
echo "Install aws-iam-authenticator"
echo "================"

if which aws-iam-authenticator;then
	echo "aws-iam-authenticator already installed"
else
	curl -o aws-iam-authenticator https://amazon-eks.s3-us-west-2.amazonaws.com/1.11.5/2018-12-06/bin/linux/amd64/aws-iam-authenticator
	chmod +x ./aws-iam-authenticator
	sudo mv ./aws-iam-authenticator /usr/bin/aws-iam-authenticator 
	sudo chown root:root /usr/bin/aws-iam-auechothenticator
fi

echo "================"
echo "Ensure the ELB Service Role exists"
echo "================"

aws iam get-role --role-name "AWSServiceRoleForElasticLoadBalancing" || aws iam create-service-linked-role --aws-service-name "elasticloadbalancing.amazonaws.com"


echo "================"
echo "Install kubectl"
echo "================"

if which kubectl;then
	echo "kubectl already installed"
else
	sudo apt-get install -y apt-transport-https
	curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
	echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list
	sudo apt-get update
	sudo apt-get install -y kubectl
	# Installing kubectl bash completion on Linux
	kubectl completion bash >> ~/.bashrc
	source ~/.bashrc
fi

echo "================"
echo "Create EKS cluster or use it"
echo "================"


if [ ! -z $USE_CLUSTER ];then
	echo "use cluster mode -- do not create via eksctl"
else
	curl --silent --location "https://github.com/weaveworks/eksctl/releases/download/latest_release/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
	sudo mv -v /tmp/eksctl /usr/local/bin
	eksctl create cluster --name=${CLUSTER_NAME} --nodes=3 --node-ami=auto
fi

export EKS_ENDPOINT=$(aws eks describe-cluster --name ${CLUSTER_NAME}  --query cluster.[endpoint] --output=text)
export EKS_CA_DATA=$(aws eks describe-cluster --name ${CLUSTER_NAME}  --query cluster.[certificateAuthority.data] --output text)
echo EKS_ENDPOINT=${EKS_ENDPOINT}

mkdir -p ${HOME}/.kube

cat <<EoF > ${HOME}/.kube/${CLUSTER_NAME}
  apiVersion: v1
  clusters:
  - cluster:
      server: ${EKS_ENDPOINT}
      certificate-authority-data: ${EKS_CA_DATA}
    name: ${CLUSTER_NAME}
  contexts:
  - context:
      cluster: ${CLUSTER_NAME}
      user: ${CLUSTER_NAME}
    name: ${CLUSTER_NAME}
  current-context: ${CLUSTER_NAME}
  kind: Config
  preferences: {}
  users:
  - name: ${CLUSTER_NAME}
    user:
      exec:
        apiVersion: client.authentication.k8s.io/v1alpha1
        command: aws-iam-authenticator
        args:
          - "token"
          - "-i"
          - "${CLUSTER_NAME}"
EoF

export KUBECONFIG=${HOME}/.kube/${CLUSTER_NAME}
echo "export KUBECONFIG=${KUBECONFIG}" >> ${HOME}/.bashrc


echo "================"
echo "Verify cluster access"
echo "================"

kubectl cluster-info
kubectl get no

echo "================"
echo "Everything is OK"
echo "If you want to delete cluster"
echo "eksctl delete cluster --name=${CLUSTER_NAME}"
echo "================"

