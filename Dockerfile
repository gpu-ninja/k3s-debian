FROM debian:bookworm-slim

RUN apt update \
  && apt install -y \
    curl gnupg2 \
    # Required for k3s.
    ca-certificates busybox \
    # For Rook/Ceph.
    udev lvm2

# For NVIDIA GPU support.
RUN curl -fsL https://nvidia.github.io/nvidia-container-runtime/gpgkey | gpg --dearmor -o /etc/apt/trusted.gpg.d/nvidia.gpg \
  && curl -fL -o /etc/apt/sources.list.d/nvidia-container-runtime.list https://nvidia.github.io/nvidia-container-runtime/ubuntu22.04/nvidia-container-runtime.list \
  && apt update \
  && apt install -y \
    nvidia-container-toolkit-base

ARG TARGETARCH
ARG KUBE_VERSION
RUN if [ "$TARGETARCH" = "amd64" ]; then \
      curl -L -o /bin/k3s https://github.com/k3s-io/k3s/releases/download/${KUBE_VERSION}%2Bk3s1/k3s; \
    else \
      curl -L -o /bin/k3s https://github.com/k3s-io/k3s/releases/download/${KUBE_VERSION}%2Bk3s1/k3s-$TARGETARCH; \
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

# K3D requires busybox to be the default shell.
RUN ln -sf /bin/busybox /bin/sh

# Enable CDI.
COPY config.toml.tmpl /var/lib/rancher/k3s/agent/etc/containerd/config.toml.tmpl

VOLUME /var/lib/kubelet
VOLUME /var/lib/rancher/k3s
VOLUME /var/lib/cni
VOLUME /var/log

ENV CRI_CONFIG_FILE="/var/lib/rancher/k3s/agent/etc/crictl.yaml"
ENTRYPOINT ["/bin/k3s"]
CMD ["agent"]
