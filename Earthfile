VERSION 0.7
FROM debian:bookworm-slim
WORKDIR /app

docker-all:
  BUILD --platform=linux/amd64 --platform=linux/arm64 +docker

docker:
  ARG TARGETPLATFORM
  ARG KUBE_VERSION
  FROM DOCKERFILE --platform=$TARGETPLATFORM --build-arg KUBE_VERSION=${KUBE_VERSION} -f +docker-context/Dockerfile +docker-context/*
  SAVE IMAGE --push ghcr.io/gpu-ninja/k3s-debian:${KUBE_VERSION}
  SAVE IMAGE --push ghcr.io/gpu-ninja/k3s-debian:latest

docker-context:
  COPY Dockerfile .
  COPY config.toml.tmpl .
  SAVE ARTIFACT Dockerfile
  SAVE ARTIFACT config.toml.tmpl

save-images-all:
  COPY (+save-images/dist/* --IMGARCH=amd64) /dist/
  COPY (+save-images/dist/* --IMGARCH=arm64) /dist/
  RUN cd /dist && find . -type f ! -name 'checksums.txt' -print0 | sort -z | xargs -0 sha256sum >> checksums.txt
  SAVE ARTIFACT /dist/k3s-debian-amd64.tar.zst AS LOCAL dist/k3s-debian-amd64.tar.zst
  SAVE ARTIFACT /dist/k3s-debian-arm64.tar.zst AS LOCAL dist/k3s-debian-arm64.tar.zst
  SAVE ARTIFACT /dist/k3s-images-amd64.tar.zst AS LOCAL dist/k3s-images-amd64.tar.zst
  SAVE ARTIFACT /dist/k3s-images-arm64.tar.zst AS LOCAL dist/k3s-images-arm64.tar.zst
  SAVE ARTIFACT /dist/checksums.txt AS LOCAL dist/checksums.txt

save-images:
  FROM +tools
  ARG KUBE_VERSION
  RUN curl -fsSLO https://github.com/k3s-io/k3s/releases/download/${KUBE_VERSION}%2Bk3s1/k3s-images.txt
  COPY images.yaml.tmpl .
  ARG IMGARCH=amd64
  RUN mkdir -p /dist
  RUN yq e ".spec.images = [\"ghcr.io/gpu-ninja/k3s-debian:${KUBE_VERSION}\"]" images.yaml.tmpl > images.yaml \
    && airgapify --no-progress --platform=linux/${IMGARCH} -f images.yaml -o /dist/k3s-debian-${IMGARCH}.tar.zst
  RUN yq e '.spec.images = (load_str("k3s-images.txt") | trim | split("\n"))' images.yaml.tmpl > images.yaml \
    && airgapify --no-progress --platform=linux/${IMGARCH} -f images.yaml -o /dist/k3s-images-${IMGARCH}.tar.zst
  SAVE ARTIFACT /dist/k3s-debian-${IMGARCH}.tar.zst /dist/k3s-debian-${IMGARCH}.tar.zst AS LOCAL dist/k3s-debian-${IMGARCH}.tar.zst
  SAVE ARTIFACT /dist/k3s-images-${IMGARCH}.tar.zst /dist/k3s-images-${IMGARCH}.tar.zst AS LOCAL dist/k3s-images-${IMGARCH}.tar.zst

tools:
  ARG TARGETARCH
  RUN apt update && apt install -y netselect-apt \
    && (cd /etc/apt; netselect-apt bookworm) \
    && rm -f /etc/apt/sources.list.d/debian.sources \
    && apt update
  RUN apt install -y ca-certificates curl
  ARG YQ_VERSION=v4.35.1
  RUN curl -fsSL -o /usr/local/bin/yq https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_${TARGETARCH} \
    && chmod +x /usr/local/bin/yq
  ARG AIRGAPIFY_VERSION=v0.4.0
  RUN curl -fsSL -o /usr/local/bin/airgapify https://github.com/gpu-ninja/airgapify/releases/download/${AIRGAPIFY_VERSION}/airgapify-linux-${TARGETARCH} \
    && chmod +x /usr/local/bin/airgapify