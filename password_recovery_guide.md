## Configurazione dell'account Google (Gmail SMTP)
Per abilitare l'invio delle email tramite il server SMTP di Gmail senza costi e senza che finiscano in spam:

1. Accedi al tuo account Google (`robe.ingenito@gmail.com`).
2. Vai su **Sicurezza** nelle impostazioni dell'account.
3. Abilita la **Verifica in due passaggi** (se non l'hai già fatta).
4. Cerca **Password per le app** (App Passwords) nella barra di ricerca delle impostazioni dell'account Google.
5. Crea una nuova password per le app, nominala (es. `Cashly`) e copia il codice di **16 caratteri** generato (senza spazi).

---

## Configurazione dell'Ambiente e Docker

### 1. File `.env` e `.env-template`
Aggiungi le seguenti variabili d'ambiente nel tuo file `.env` compilando la password per le app generata da Google:

```ini
# Configurazione SMTP diretta con Gmail (Risolve lo spam per @gmail.com)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=robe.ingenito@gmail.com
SMTP_PASSWORD=i_tuoi_16_caratteri_senza_spazi
SMTP_FROM_EMAIL=robe.ingenito@gmail.com
SMTP_FROM_NAME=Cashly
```
