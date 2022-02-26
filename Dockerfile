FROM alpine:latest

LABEL MAINTAINER="Jonathan Farias <jonathan.developer10@gmail.com>"

WORKDIR /home/Bluechat-CD/terraform/

RUN apk --update --no-cache add wget unzip bash git

RUN wget https://releases.hashicorp.com/terraform/1.1.2/terraform_1.1.2_linux_amd64.zip && unzip terraform_1.1.2_linux_amd64.zip && mv terraform /usr/bin/ && rm terraform_1.1.2_linux_amd64.zip

RUN wget -O helm.tgz https://get.helm.sh/helm-v3.8.0-linux-amd64.tar.gz && tar -vzxf helm.tgz && mv linux-amd64/helm /usr/bin/ && rm -rf helm.tgz linux-amd64

COPY manifests/ /home/Bluechat-CD/manifests/

COPY terraform/ /home/Bluechat-CD/terraform/

RUN chmod +x helm_repo.sh && ./helm_repo.sh

