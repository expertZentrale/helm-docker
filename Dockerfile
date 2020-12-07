FROM alpine:3.6 

ENV HELM_VERSION v3.4.1
ENV KUBEVAL_VERSION=0.15.0
ENV KUBECTL_VERSION=1.18.5
ENV KUSTOMIZE_VERSION=3.8.3
ENV KAPP_VERSION=v0.34.0

WORKDIR /

# Enable SSL
RUN apk --update add ca-certificates wget curl tar jq git bash perl-utils

# Install kubectl
ENV HOME /
RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl && chmod +x kubectl && mv kubectl /usr/local/bin

# Install Helm
ENV FILENAME helm-${HELM_VERSION}-linux-amd64.tar.gz
ENV HELM_URL https://get.helm.sh/${FILENAME}

RUN echo $HELM_URL

RUN curl -o /tmp/$FILENAME ${HELM_URL} \
  && tar -zxvf /tmp/${FILENAME} -C /tmp \
  && mv /tmp/linux-amd64/helm /bin/helm \
  && rm -rf /tmp

# Install envsubst [better than using 'sed' for yaml substitutions]
ENV BUILD_DEPS="gettext"  \
    RUNTIME_DEPS="libintl"

RUN set -x && \
    apk add --update $RUNTIME_DEPS && \
    apk add --virtual build_deps $BUILD_DEPS &&  \
    cp /usr/bin/envsubst /usr/local/bin/envsubst && \
    apk del build_deps

# Install Helm plugins
# workaround for an issue in updating the binary of `helm-diff`
ENV HELM_PLUGIN_DIR /.helm/plugins/helm-diff
# Plugin is downloaded to /tmp, which must exist
RUN mkdir /tmp 
RUN helm plugin install https://github.com/databus23/helm-diff && helm plugin install https://github.com/helm/helm-2to3 && rm -rf /tmp


# Install kustomize
RUN curl -sLf https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv${KUSTOMIZE_VERSION}/kustomize_v${KUSTOMIZE_VERSION}_linux_amd64.tar.gz -o kustomize.tar.gz\
    && tar xf kustomize.tar.gz \
    && mv kustomize /usr/local/bin \
    && chmod +x /usr/local/bin/kustomize \
    && rm kustomize.tar.gz

# Install kubeval
RUN wget -q https://github.com/instrumenta/kubeval/releases/download/${KUBEVAL_VERSION}/kubeval-linux-amd64.tar.gz && tar xf kubeval-linux-amd64.tar.gz && mv kubeval /usr/local/bin && rm kubeval-linux-amd64.tar.gz

# Install cattlectl
# RUN wget -q https://github.com/bitgrip/cattlectl/releases/download/v1.3.0/cattlectl-v1.3.0-linux.tar.gz && tar xf cattlectl-v1.3.0-linux.tar.gz && mv build/linux/cattlectl /usr/local/bin && rm cattlectl-v1.3.0-linux.tar.gz

# Install kapp
RUN wget -nv -O- https://github.com/k14s/kapp/releases/download/${KAPP_VERSION}/kapp-linux-amd64  > /usr/local/bin/kapp && chmod +x /usr/local/bin/kapp

# Install vht Vault Helper Tools

RUN wget -q https://github.com/ilijamt/vht/releases/download/v0.4.3/vht_linux_x86_64.tar.gz && tar xf vht_linux_x86_64.tar.gz && mv vht /usr/local/bin && rm vht_linux_x86_64.tar.gz

# Install Vault + Terraform + Consul-Template
COPY --from=hashicorp/terraform:latest /bin/terraform /bin/terraform
COPY --from=vault:latest /bin/vault /bin/vault
COPY --from=hashicorp/consul-template:alpine /bin/consul-template /bin/consul-template

# upgrade terraform 0.13
#RUN mkdir /terraform-plugins
#RUN wget -q https://releases.hashicorp.com/terraform-provider-rancher2/1.10.0/terraform-provider-rancher2_1.10.0_linux_amd64.zip && unzip terraform-provider-rancher2_1.10.0_linux_amd64.zip -d /terraform-plugins && rm terraform-provider-rancher2_1.10.0_linux_amd64.zip
#RUN wget -q https://releases.hashicorp.com/terraform-provider-kubernetes/1.11.2/terraform-provider-kubernetes_1.11.2_linux_amd64.zip && unzip terraform-provider-kubernetes_1.11.2_linux_amd64.zip -d /terraform-plugins && rm terraform-provider-kubernetes_1.11.2_linux_amd64.zip
#RUN wget -q https://releases.hashicorp.com/terraform-provider-vault/2.10.0/terraform-provider-vault_2.10.0_linux_amd64.zip && unzip terraform-provider-vault_2.10.0_linux_amd64.zip -d /terraform-plugins && rm terraform-provider-vault_2.10.0_linux_amd64.zip

# Install yq
COPY --from=mikefarah/yq /usr/bin/yq /bin/yq

# Install istioctl
# COPY --from=istio/istioctl:1.6.4-distroless /usr/local/bin/istioctl /bin/istioctl
