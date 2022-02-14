FROM alpine:latest

LABEL MAINTAINER="Jonathan Farias <jonathan.developer10@gmail.com>"

WORKDIR /terraform

RUN apk --update --no-cache add bash wget zip git

RUN wget https://releases.hashicorp.com/terraform/1.1.3/terraform_1.1.3_linux_amd64.zip && unzip terraform_1.1.3_linux_amd64.zip && mv terraform /usr/bin/terraform && rm terraform_1.1.3_linux_amd64.zip




COPY . .

