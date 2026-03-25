#!bin/bash
dnf install ansible -y

component=$1
env=$2
app_version=$3
domain_name=$4

cd /home/ec2-user/
git clone https://github.com/gowthambabu8/roboshop-ansible-roles-tf.git
cd roboshop-ansible-roles-tf
git pull
ansible-playbook -e component=$component -e env=$env -e app_version=$app_version -e domain_name=$domain_name roboshop.yaml
