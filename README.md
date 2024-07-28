# Open edX Redwood tutor build

- client contact: Brenton Kreiger, +1 (401) 808-9575, brenton.kreiger@eiabridges.org
- consultant contact: Lawrence McDaniel +1 (617) 834-6172, lpm0073@gmail.com, https://lawrencemcdaniel.com
- start date: 22-jul-2024

Migration from Koa native build to tutor redwood.

Original source server:

```bash
Host bedu-prod
  HostName eiaeducation.org
  User ubuntu
  IdentityFile ~/.ssh/bedu_key_3.3.pem
  IdentitiesOnly yes
```

Target server:

```bash
Host bedu
  HostName 52.5.202.56
  User ubuntu
  IdentityFile ~/.ssh/eia-openedx-redwood.pem
  IdentitiesOnly yes
```

AWS S3 Source data:

- s3://bridgeedu/backups/openedx-mysql-20240724T060001.tgz
- s3://bridgeedu/backups/mongo-dump-20240724T060001.tgz

AWS IAM User: arn:aws:iam::120088116466:user/lpm0073


## EC2 AMI

(subscription required)
ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-20230328

## ubuntu packages

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install python3 python3-pip libyaml-dev python3-venv
# sudo add-apt-repository ppa:deadsnakes/ppa -y
```

## Docker installation

https://docs.docker.com/engine/install/ubuntu/

### Add Docker's official GPG key:

```bash
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
```

### Install Docker CE

```bash
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose
sudo apt update
sudo usermod -a -G docker ubuntu
logout
sudo docker run hello-world
docker-compose version
```

## python virtual environment

```bash
python3 -m venv venv
source venv/bin/activate
pip install setuptools
pip install "tutor[full]==12.2.0"
tutor local quickstart
```

## install aws cli

```bash
sudo snap install aws-cli --classic
```
