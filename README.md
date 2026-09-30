# helm-docker

An Alpine-based toolkit for Kubernetes deployment pipelines in GitLab CI/CD.
Originally based on [devth/helm](https://hub.docker.com/r/devth/helm/).

## Included tools

Tool and image versions are pinned in the [Dockerfile](Dockerfile); system
packages are installed from the selected Alpine release.

- `helm` (Helm 3, preserving compatibility with existing pipelines)
- `kubectl`
- `kustomize`
- `kapp`
- `kubeval`
- `terraform`
- `vault`
- `consul-template`
- `vht` (Vault Helper Tools)
- `envsubst`, `jq`, and `yq`
- `bash`, `git`, `curl`, `wget`, `tar`, and `perl-utils`

Helm plugins:

- [helm-diff](https://github.com/databus23/helm-diff)
- [helm-2to3](https://github.com/helm/helm-2to3) (deprecated upstream; retained
  for legacy Helm 2 migrations)

`kubeval` is retained at its last published release. It is no longer actively
maintained and its default schemas may not cover recent Kubernetes versions.

`gcloud`, `cattlectl`, and `istioctl` are not included. Terraform providers are
not preinstalled; use `terraform init -input=false` to install the providers
declared by your project.

## GitLab CI/CD usage

```yaml
deploy:
  image:
    name: ghcr.io/expertzentrale/helm-docker:latest
    entrypoint: [""]
  stage: deploy
  script:
    - helm version --short
    - kubectl version --client
    - helm upgrade --install my-app ./chart --namespace my-app --create-namespace
```

Provide cluster credentials through your pipeline's protected CI/CD variables
or GitLab Kubernetes integration. Choose a `kubectl` version within one minor
version of your Kubernetes API server.

The image targets Linux AMD64. For reproducible pipelines, use a published
release tag or image digest instead of `latest`.

## Images and releases

The [GitHub Actions workflow](.github/workflows/docker-publish.yml) publishes
`ghcr.io/expertzentrale/helm-docker`:

- `latest` is rebuilt from `master` on pushes and the daily schedule.
- Git tags matching `v*.*.*` are published as matching image tags.

To release an update, change the pinned versions in the Dockerfile, build and
test the image, then commit the changes and push a new version tag. Release
tags identify the complete toolkit, not just the Helm version.

## Local build

```bash
docker build --platform linux/amd64 -t helm-docker .
docker run --rm helm-docker sh -ec 'helm version --short; kubectl version --client; helm plugin list'
```
