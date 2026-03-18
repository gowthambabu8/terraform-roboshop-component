#!bin/bash
dnf install ansible -y

component=$1
environment=$2
app_version=$3
cd /home/ec2-user/
git clone https://github.com/gowthambabu8/roboshop-ansible-roles-tf.git
cd roboshop-ansible-roles-tf
git pull
ansible-playbook -e component=$component -e environment=$environment -e app_version=$app_version roboshop.yaml
