FROM alpine:3.19.0 

ENV HELM_VERSION v3.13.3
ENV KUBEVAL_VERSION=v0.16.1
# kubectl_version is not used... installs latest stable
ENV KUBECTL_VERSION=v1.29.0
ENV KUSTOMIZE_VERSION=5.3.0
ENV KAPP_VERSION=v0.59.2

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

# Install kapp
RUN wget -nv -O- https://github.com/vmware-tanzu/carvel-kapp/releases/download/${KAPP_VERSION}/kapp-linux-amd64 > /usr/local/bin/kapp && chmod +x /usr/local/bin/kapp

# Install vht Vault Helper Tools
RUN wget -q https://github.com/ilijamt/vht/releases/download/v0.4.3/vht_linux_x86_64.tar.gz && tar xf vht_linux_x86_64.tar.gz && mv vht /usr/local/bin && rm vht_linux_x86_64.tar.gz

# Install Vault + Terraform + Consul-Template
COPY --from=hashicorp/terraform:latest /bin/terraform /bin/terraform
COPY --from=hashicorp/vault:latest /bin/vault /bin/vault
COPY --from=hashicorp/consul-template:alpine /bin/consul-template /bin/consul-template

# Install yq
COPY --from=mikefarah/yq /usr/bin/yq /bin/yq

# Install istioctl
# COPY --from=istio/istioctl:1.6.4-distroless /usr/local/bin/istioctl /bin/istioctl
