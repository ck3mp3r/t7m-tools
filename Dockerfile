FROM hashicorp/terraform:1.1.8 as tf
# get the official terraform image, we're copying the binary into the other image below.

FROM python:3.9-alpine as installer

RUN set -ex; \
    apk add --no-cache \
    git unzip groff \
    build-base libffi-dev cmake

ENV AWS_CLI_VERSION=2.5.4
RUN set -eux; \
    mkdir /aws; \
    git clone --single-branch --depth 1 -b ${AWS_CLI_VERSION} https://github.com/aws/aws-cli.git /aws; \
    cd /aws; \
    sed -i'' 's/PyInstaller.*/PyInstaller==4.10/g' requirements-build.txt; \
    python -m venv venv; \
    . venv/bin/activate; \
    ./scripts/installers/make-exe

RUN set -ex; \
    unzip /aws/dist/awscli-exe.zip; \
    ./aws/install --bin-dir /aws-cli-bin; \
    /aws-cli-bin/aws --version

FROM alpine:latest as build

ARG HELM3_VERSION=3.8.1
ARG KUBECTL_VERSION=1.23.5
ARG AWS_IAM_AUTH_VERSION=0.5.0

# Install helm
ENV BASE_URL="https://get.helm.sh"
RUN ARCH=$(case "aarch64" in (`arch`) echo arm64 ;; (*) echo amd64; esac) && \
  apk add --update --no-cache curl ca-certificates bash && \
  curl -L ${BASE_URL}/helm-v${HELM3_VERSION}-linux-${ARCH}.tar.gz |tar xvz && \
  mv linux-${ARCH}/helm /usr/bin/helm && \
  chmod +x /usr/bin/helm && \
  rm -rf linux-${ARCH} && \
  rm -f /var/cache/apk/*

# Install kubectl
RUN ARCH=$(case "aarch64" in (`arch`) echo arm64 ;; (*) echo amd64; esac) && \
  curl -LO https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/$ARCH/kubectl && \
  mv kubectl /usr/bin/kubectl && \
  chmod +x /usr/bin/kubectl

# Install aws-iam-authenticator
RUN ARCH=$(case "aarch64" in (`arch`) echo arm64 ;; (*) echo amd64; esac) && \
  curl -LO https://github.com/kubernetes-sigs/aws-iam-authenticator/releases/download/v${AWS_IAM_AUTH_VERSION}/aws-iam-authenticator_${AWS_IAM_AUTH_VERSION}_linux_$ARCH && \
  mv aws-iam-authenticator_${AWS_IAM_AUTH_VERSION}_linux_$ARCH /usr/bin/aws-iam-authenticator && \
  chmod +x /usr/bin/aws-iam-authenticator

FROM alpine:latest as final

# installing other prerequisites
RUN apk --no-cache add bash git groff less curl jq python3 py3-pip docker unzip \
  && rm -rf /var/cache/apk/*

# now we copy the binaries from the relevant containers into our final container
COPY --from=tf ["/bin/terraform", "/bin/terraform"]
COPY --from=build ["/usr/bin/kubectl", "/usr/bin/kubectl"]
COPY --from=build ["/usr/bin/helm", "/usr/bin/helm"]
COPY --from=build ["/usr/bin/aws-iam-authenticator", "/usr/bin/aws-iam-authenticator"]
COPY --from=installer ["/usr/local/aws-cli/", "/usr/local/aws-cli/"]
COPY --from=installer ["/aws-cli-bin/", "/usr/local/bin/"]

COPY scripts/tf.sh /bin/tf
COPY scripts/aws-profile.sh /bin/aws-profile

ENV AWS_SDK_LOAD_CONFIG=1

WORKDIR /workspaces

# bash entrypoint set as default
ENTRYPOINT ["/bin/bash"]
