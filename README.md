# K3s Debian Image

The default Rancher K3s Docker image is distroless and includes none of the standard userspace. This makes using it with thirdparty plugins (eg. CNIs) challenging. This repository contains a compatible image that is instead based on debian-slim.