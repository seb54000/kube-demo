#!/bin/bash


echo "This script has been tested only on 16.04.1-Ubuntu"
echo "Root password would be asked for sudo commands"

echo "================"
echo "Install AWS cli "
echo "================"

if aws --version;then
	echo "awscli already installed"
else
	curl "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" -o "awscli-bundle.zip"
	unzip awscli-bundle.zip
	sudo ./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws

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
echo "Everything is OK"
echo "================"


aws --version
aws-iam-authenticator --version
kubectl --version