# Securing SSH with Fail2ban

When exposing your SSH port to the internet, it is highly recommended to use SSH Keys and disable password authentication. However, if you **need** to retain password authentication to log in from any random computer, you **must** install a brute-force protection system like `fail2ban`.

## What is Fail2ban?
`fail2ban` scans log files (like `/var/log/auth.log`) and bans IPs that show malicious signs, such as too many password failures. It updates system firewall rules (iptables/ufw) to reject new connections from those IP addresses for a configurable amount of time.

---

## 1. Installation

Update your package lists and install `fail2ban`:

```bash
sudo apt update
sudo apt install fail2ban -y
```

Once installed, the service starts automatically.

---

## 2. Configuration

Fail2ban comes with a default configuration file (`/etc/fail2ban/jail.conf`). **Never edit this file directly**, as it might be overwritten during package updates. Instead, create a local copy called `jail.local`:

```bash
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
```

Now, open `jail.local` in your preferred editor:

```bash
sudo nano /etc/fail2ban/jail.local
```

### Recommended Settings for SSH
Search for the `[sshd]` section and make sure it looks like this (or add these overrides):

```ini
[sshd]
enabled = true
port    = 22 # raspberry pi ssh access port 
logpath = %(sshd_log)s
backend = %(sshd_backend)s
maxretry = 5
findtime = 10m
bantime  = 1h # Ban the IP for 1 hour (use '1d' for 1 day, '-1' for permanent)
```

Save the file and exit (`CTRL+O`, `ENTER`, `CTRL+X` in nano).

---

## 3. Apply Changes

Restart the Fail2ban service to apply the new rules:

```bash
sudo systemctl restart fail2ban
```

Enable the service to start automatically on system boot:

```bash
sudo systemctl enable fail2ban
```

---

## 4. Useful Commands

Here are some commands you might need for daily management:

**Check the overall status of fail2ban:**
```bash
sudo fail2ban-client status
```

**Check the status of the SSH jail (shows currently banned IPs):**
```bash
sudo fail2ban-client status sshd
```

**Unban an IP address (if you accidentally lock yourself out):**
```bash
sudo fail2ban-client set sshd unbanip 192.168.1.50
```

**Ban an IP address manually:**
```bash
sudo fail2ban-client set sshd banip 192.168.1.50
```
