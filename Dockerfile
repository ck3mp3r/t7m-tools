FROM hashicorp/terraform:0.12.28 as build
# get the official terraform image, we're copying the binary into the other image below.

FROM alpine:latest as final

ARG HELM_VERSION=2.16.7
ARG KUBECTL_VERSION=1.18.0
ARG AWS_IAM_AUTH_VERSION=0.5.0

# Install helm
ENV BASE_URL="https://get.helm.sh"
ENV TAR_FILE="helm-v${HELM_VERSION}-linux-amd64.tar.gz"
RUN apk add --update --no-cache curl ca-certificates bash && \
    curl -L ${BASE_URL}/${TAR_FILE} |tar xvz && \
    mv linux-amd64/helm /usr/bin/helm && \
    chmod +x /usr/bin/helm && \
    rm -rf linux-amd64 && \
    apk del curl && \
    rm -f /var/cache/apk/*

# Install kubectl
RUN apk add --update --no-cache curl && \
    curl -LO https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl && \
    mv kubectl /usr/bin/kubectl && \
    chmod +x /usr/bin/kubectl

# Install aws-iam-authenticator
RUN curl -LO https://github.com/kubernetes-sigs/aws-iam-authenticator/releases/download/v${AWS_IAM_AUTH_VERSION}/aws-iam-authenticator_${AWS_IAM_AUTH_VERSION}_linux_amd64 && \
    mv aws-iam-authenticator_${AWS_IAM_AUTH_VERSION}_linux_amd64 /usr/bin/aws-iam-authenticator && \
    chmod +x /usr/bin/aws-iam-authenticator

# installing other prerequisites
RUN apk add --no-cache --update docker git openssh jq python3 py3-pip && \
      pip3 install --upgrade pip awscli 

# now we copy the binary from the hashicorp container into our final container
COPY --from=build ["/bin/terraform", "/bin/terraform"]
COPY tf.sh /bin/tf

ENV AWS_SDK_LOAD_CONFIG=1

WORKDIR /workspaces

# bash entrypoint set as default
ENTRYPOINT ["/bin/ash"]
