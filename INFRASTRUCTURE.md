# 🛠️ Configurazione del Server Host (Raspberry Pi / Ubuntu)

Questo documento descrive le configurazioni di base del sistema operativo host (si presume una distribuzione basata su Ubuntu o Raspberry Pi OS) e della rete necessarie per far funzionare correttamente l'ambiente Docker e la pipeline CI/CD.

## 🔗 Configurazione Rete: Indirizzo IP Statico

Per garantire che i servizi Docker siano sempre accessibili allo stesso indirizzo di rete, è essenziale configurare un IP statico. Su Ubuntu Server, questo si fa tramite Netplan.

1.  **Aprire il file di configurazione di Netplan:**

    ```sh
    sudo nano /etc/netplan/50-cloud-init.yaml
    ```

2.  **Incollare e Adattare la Configurazione:**
    Sostituire gli indirizzi IP (`addresses`, `via`) con i valori appropriati per la propria rete locale.

    ```yml
    network:
      version: 2
      ethernets:
        eth0:
          dhcp4: no
          addresses:
            - 192.168.1.20/24   # Indirizzo IP statico del tuo Raspberry Pi
          routes:
            - to: default
              via: 192.168.1.1   # Gateway del router (ad esempio, indirizzo IP del tuo router Vodafone)
          nameservers:
            addresses:
              - 1.1.1.1         # DNS di Cloudflare
              - 8.8.8.8         # DNS di Google
    ```

3.  **Applicare le Modifiche:**

    ```sh
    sudo netplan apply
    ```

## 🌐 Accesso Remoto e DNS (Cloudflare Tunnel)

L'accesso remoto sicuro ai servizi ospitati sul server avviene tramite **Cloudflare Tunnel** (gestito dal servizio `cloudflared` in Docker).

* **Nessun DDNS o Port Forwarding necessario:** Non è più necessario configurare servizi di Dynamic DNS (come NO-IP) o aprire porte sul router domestico (porte 80/443).
* **Funzionamento:** Il container `cloudflared` stabilisce una connessione sicura in uscita verso la rete di Cloudflare. Il traffico in entrata viene instradato in modo sicuro tramite il tunnel ai singoli servizi in esecuzione nella rete Docker `common-network`.
* **Configurazione:** Per maggiori informazioni sulla configurazione delle rotte e dei sottodomini, consulta [cloudflare_guide.md](file:///C:/Users/roberto/Documents/GitHub/server-raspberry-pi/cloudflare_guide.md).

## 🤖 GitHub Actions Self-Hosted Runner

Per abilitare il Continuous Deployment (CI/CD) direttamente sul server host (Raspberry Pi), è stato configurato un **Self-Hosted Runner** di GitHub Actions.

* **Scopo:** Il runner è responsabile di eseguire il workflow di deployment (`deploy.yml`) che include il pull del codice, la ricostruzione e l'avvio dei container Docker.

* **Documentazione Ufficiale:** Per istruzioni dettagliate su come installare e configurare il runner sul tuo Raspberry Pi, consulta:
    [How to configure GitHub Actions Self-Hosted Runner](https://docs.github.com/en/actions/how-tos/manage-runners/self-hosted-runners/add-runners#adding-a-self-hosted-runner-to-a-repository)


