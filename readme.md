# SSH Gateway
This projects aims to create a container to be used as an SSH Gateway with the smallest attack surface possible. Using Alpine Linux, we statically compile OpenSSH and all the dependencies and manually build a rootfs that is then imported into a completely empty container.
