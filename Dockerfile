FROM alpine:3.24.2

ENV HELM_VERSION=v3.22.0
ENV KUBEVAL_VERSION=v0.16.1
ENV KUBECTL_VERSION=v1.37.1
ENV KUSTOMIZE_VERSION=5.8.1
ENV KAPP_VERSION=v0.65.4
ENV VHT_VERSION=0.6.0
ENV HELM_DIFF_VERSION=v3.15.15
ENV HELM_2TO3_VERSION=v0.11.0

WORKDIR /

# Enable SSL
RUN apk add --no-cache ca-certificates wget curl tar jq git bash perl-utils gettext-envsubst

# Install kubectl
ENV HOME=/
RUN curl -fsSL "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl" -o /tmp/kubectl \
    && curl -fsSL "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl.sha256" -o /tmp/kubectl.sha256 \
    && echo "$(cat /tmp/kubectl.sha256)  /tmp/kubectl" | sha256sum -c - \
    && chmod +x /tmp/kubectl \
    && mv /tmp/kubectl /usr/local/bin/kubectl \
    && rm /tmp/kubectl.sha256

# Install Helm
ENV FILENAME=helm-${HELM_VERSION}-linux-amd64.tar.gz
ENV HELM_URL=https://get.helm.sh/${FILENAME}

RUN curl -fsSL "${HELM_URL}" -o "/tmp/${FILENAME}" \
    && curl -fsSL "${HELM_URL}.sha256sum" -o "/tmp/${FILENAME}.sha256sum" \
    && (cd /tmp && sha256sum -c "${FILENAME}.sha256sum") \
    && tar -xzf "/tmp/${FILENAME}" -C /tmp \
    && mv /tmp/linux-amd64/helm /bin/helm \
    && rm -rf /tmp/linux-amd64 "/tmp/${FILENAME}" "/tmp/${FILENAME}.sha256sum"

# Install Helm plugins
RUN helm plugin install https://github.com/databus23/helm-diff --version "${HELM_DIFF_VERSION}" \
    && helm plugin install https://github.com/helm/helm-2to3 --version "${HELM_2TO3_VERSION}"

# Install kustomize
RUN curl -fsSL "https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv${KUSTOMIZE_VERSION}/kustomize_v${KUSTOMIZE_VERSION}_linux_amd64.tar.gz" -o /tmp/kustomize.tar.gz \
    && tar -xzf /tmp/kustomize.tar.gz -C /usr/local/bin kustomize \
    && rm /tmp/kustomize.tar.gz

# Install kubeval
RUN curl -fsSL "https://github.com/instrumenta/kubeval/releases/download/${KUBEVAL_VERSION}/kubeval-linux-amd64.tar.gz" -o /tmp/kubeval.tar.gz \
    && tar -xzf /tmp/kubeval.tar.gz -C /usr/local/bin kubeval \
    && rm /tmp/kubeval.tar.gz

# Install kapp
RUN curl -fsSL "https://github.com/carvel-dev/kapp/releases/download/${KAPP_VERSION}/kapp-linux-amd64" -o /usr/local/bin/kapp \
    && chmod +x /usr/local/bin/kapp

# Install vht Vault Helper Tools
RUN curl -fsSL "https://github.com/ilijamt/vht/releases/download/v${VHT_VERSION}/vht_${VHT_VERSION}_linux_amd64.tar.gz" -o /tmp/vht.tar.gz \
    && tar -xzf /tmp/vht.tar.gz -C /usr/local/bin vht \
    && rm /tmp/vht.tar.gz

# Install Vault + Terraform + Consul-Template
COPY --from=hashicorp/terraform:1.16.4 /bin/terraform /bin/terraform
COPY --from=hashicorp/vault:2.1.1 /bin/vault /bin/vault
COPY --from=hashicorp/consul-template:0.43.0 /bin/consul-template /bin/consul-template

# Install yq
COPY --from=mikefarah/yq:4.54.1 /usr/bin/yq /bin/yq
