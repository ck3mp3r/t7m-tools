FROM hashicorp/terraform:1.1.4 as tf
# get the official terraform image, we're copying the binary into the other image below.

FROM alpine:latest as build

ARG HELM3_VERSION=3.7.2
ARG KUBECTL_VERSION=1.23.0
ARG AWS_IAM_AUTH_VERSION=0.5.0

# Install helm
ENV BASE_URL="https://get.helm.sh"
ENV TAR_FILE="helm-v${HELM3_VERSION}-linux-amd64.tar.gz"
RUN apk add --update --no-cache curl ca-certificates bash && \
  curl -L ${BASE_URL}/${TAR_FILE} |tar xvz && \
  mv linux-amd64/helm /usr/bin/helm && \
  chmod +x /usr/bin/helm && \
  rm -rf linux-amd64 && \
  rm -f /var/cache/apk/*

# Install kubectl
RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl && \
  mv kubectl /usr/bin/kubectl && \
  chmod +x /usr/bin/kubectl

# Install aws-iam-authenticator
RUN curl -LO https://github.com/kubernetes-sigs/aws-iam-authenticator/releases/download/v${AWS_IAM_AUTH_VERSION}/aws-iam-authenticator_${AWS_IAM_AUTH_VERSION}_linux_amd64 && \
  mv aws-iam-authenticator_${AWS_IAM_AUTH_VERSION}_linux_amd64 /usr/bin/aws-iam-authenticator && \
  chmod +x /usr/bin/aws-iam-authenticator

FROM alpine:latest as final

# install aws cli with prerequisite glibc compatibility for alpine. Documentation here: https://github.com/sgerrand/alpine-pkg-glibc
ENV GLIBC_VER=2.31-r0

RUN apk --no-cache add \
  git \
  binutils \
  curl \
  && curl -sL https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub -o /etc/apk/keys/sgerrand.rsa.pub \
  && curl -sLO https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VER}/glibc-${GLIBC_VER}.apk \
  && curl -sLO https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VER}/glibc-bin-${GLIBC_VER}.apk \
  && apk add --no-cache \
  glibc-${GLIBC_VER}.apk \
  glibc-bin-${GLIBC_VER}.apk \
  && curl -sL https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o awscliv2.zip \
  && unzip awscliv2.zip \
  && aws/install \
  && rm -rf \
  awscliv2.zip \
  aws \
  /usr/local/aws-cli/v2/*/dist/aws_completer \
  /usr/local/aws-cli/v2/*/dist/awscli/data/ac.index \
  /usr/local/aws-cli/v2/*/dist/awscli/examples \
  && apk --no-cache del \
  binutils \
  curl \
  && rm glibc-${GLIBC_VER}.apk \
  && rm glibc-bin-${GLIBC_VER}.apk

# installing other prerequisites
RUN apk --no-cache add bash git groff less curl jq python3 py3-pip docker unzip \
  && rm -rf /var/cache/apk/*

# now we copy the binaries from the relevant containers into our final container
COPY --from=tf ["/bin/terraform", "/bin/terraform"]
COPY --from=build ["/usr/bin/kubectl", "/usr/bin/kubectl"]
COPY --from=build ["/usr/bin/helm", "/usr/bin/helm"]
COPY --from=build ["/usr/bin/aws-iam-authenticator", "/usr/bin/aws-iam-authenticator"]

COPY scripts/tf.sh /bin/tf
COPY scripts/aws-profile.sh /bin/aws-profile

ENV AWS_SDK_LOAD_CONFIG=1

WORKDIR /workspaces

# bash entrypoint set as default
ENTRYPOINT ["/bin/bash"]
