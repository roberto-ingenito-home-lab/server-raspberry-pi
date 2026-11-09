# 🛠️ Host Server Configuration (Raspberry Pi / Ubuntu)

This document describes the basic configurations of the host operating system (assuming an Ubuntu or Raspberry Pi OS based distribution) and the network required to properly run the Docker environment and the CI/CD pipeline.

## 🔗 Network Configuration: Static IP Address

To ensure that Docker services are always accessible at the same network address, it is essential to configure a static IP. On Ubuntu Server, this is done via Netplan.

1.  **Open the Netplan configuration file:**

    ```sh
    sudo nano /etc/netplan/50-cloud-init.yaml
    ```

2.  **Paste and Adapt the Configuration:**
    Replace the IP addresses (`addresses`, `via`) with the appropriate values for your local network.

    ```yml
    network:
      version: 2
      ethernets:
        eth0:
          dhcp4: no
          addresses:
            - 192.168.1.100/24 # Static IP address of your Raspberry Pi
          routes:
            - to: default
              via: 192.168.1.1 # Router gateway
          nameservers:
            addresses:
              - 1.1.1.1 # Cloudflare DNS
              - 8.8.8.8 # Google DNS
    ```

3.  **Apply the Changes:**

    ```sh
    sudo netplan apply
    ```

## 🌐 Remote Access and DNS (Cloudflare Tunnel)

Secure remote access to services hosted on the server is achieved through **Cloudflare Tunnel** (managed by the `cloudflared` service in Docker).

- **How it works:** The `cloudflared` container establishes a secure outbound connection to the Cloudflare network. Inbound traffic is securely routed through the tunnel to the individual services running in the `common-network` Docker network.
- **Configuration:** For more information on configuring routes and subdomains, see [cloudflare_guide.md](cloudflare_guide.md).
