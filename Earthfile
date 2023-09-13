VERSION 0.7
FROM debian:bookworm-slim
WORKDIR /app

docker-all:
  BUILD --platform=linux/amd64 --platform=linux/arm64 +docker

docker:
  FROM debian:bookworm-slim
  ARG TARGETARCH
  RUN apt update \
    && apt install -y \
      curl gnupg2 \
      # Required for k3s.
      ca-certificates busybox \
      # Rook/Ceph.
      udev lvm2

  # NVIDIA GPU support.
  RUN curl -fsL https://nvidia.github.io/nvidia-container-runtime/gpgkey | gpg --dearmor -o /etc/apt/trusted.gpg.d/nvidia.gpg \
    && curl -fL -o /etc/apt/sources.list.d/nvidia-container-runtime.list https://nvidia.github.io/nvidia-container-runtime/ubuntu22.04/nvidia-container-runtime.list \
    && apt update \
    && apt install -y \
      nvidia-container-toolkit-base

  # K3D requires busybox to be the default shell.
  RUN ln -sf /bin/busybox /bin/sh

  ARG VERSION
  RUN if [ "${TARGETARCH}" = "amd64" ]; then \
      curl -L -o /bin/k3s https://github.com/k3s-io/k3s/releases/download/${VERSION}%2Bk3s1/k3s; \
    else \
      curl -L -o /bin/k3s https://github.com/k3s-io/k3s/releases/download/${VERSION}%2Bk3s1/k3s-${TARGETARCH}; \
    fi && chmod +x /bin/k3s

  RUN ln -s /bin/k3s /bin/containerd \
    && ln -s /bin/k3s /bin/crictl \
    && ln -s /bin/k3s /bin/ctr \
    && ln -s /bin/k3s /bin/k3s-agent \
    && ln -s /bin/k3s /bin/k3s-certificate \
    && ln -s /bin/k3s /bin/k3s-completion \
    && ln -s /bin/k3s /bin/k3s-etcd-snapshot \
    && ln -s /bin/k3s /bin/k3s-secrets-encrypt \
    && ln -s /bin/k3s /bin/k3s-server \
    && ln -s /bin/k3s /bin/k3s-token \
    && ln -s /bin/k3s /bin/kubectl

  # Enable CDI.
  COPY config.toml.tmpl /var/lib/rancher/k3s/agent/etc/containerd/config.toml.tmpl

  VOLUME /var/lib/kubelet
  VOLUME /var/lib/rancher/k3s
  VOLUME /var/lib/cni
  VOLUME /var/log

  ENV CRI_CONFIG_FILE="/var/lib/rancher/k3s/agent/etc/crictl.yaml"
  ENTRYPOINT ["/bin/k3s"]
  CMD ["agent"]
  SAVE IMAGE --push ghcr.io/gpu-ninja/k3s-debian:${VERSION}
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
  ARG VERSION
  RUN curl -fsSLO https://github.com/k3s-io/k3s/releases/download/${VERSION}%2Bk3s1/k3s-images.txt
  COPY images.yaml.tmpl .
  ARG IMGARCH=amd64
  RUN mkdir -p /dist
  RUN yq e ".spec.images = [\"ghcr.io/gpu-ninja/k3s-debian:${VERSION}\"]" images.yaml.tmpl > images.yaml \
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