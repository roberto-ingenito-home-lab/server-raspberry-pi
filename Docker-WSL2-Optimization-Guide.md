# Pulizia e Ottimizzazione Spazio Docker su WSL2

Questa guida spiega come analizzare lo spazio occupato da Docker, come pulirlo in sicurezza e come ridurre le dimensioni reali del file `.vhdx` su Windows.

## 1. Analisi dello Spazio

Prima di procedere, identifica cosa occupa spazio con:

```bash
docker system df
```

## 2. Pulizia

### A. Svuotare la Build Cache (Sicuro)

La cache di build può accumulare decine di GB. Eliminarla non tocca né i container né le immagini finali:

```bash
docker builder prune -a
```

### B. Eliminare i Volumi inutilizzati

Rimuove solo i volumi che non sono montati in **nessun** container (nemmeno quelli fermi):

```bash
docker volume prune
```

### C. Eliminare Immagini non utilizzate

Per eliminare solo le immagini che non sono associate ad alcun container (nemmeno a quelli fermi):

```bash
docker image prune -a
```

_Nota: Se un container è fermo (Stopped), la sua immagine è considerata "in uso" e non verrà rimossa._

## 3. Compattazione del disco WSL2 (ext4.vhdx)

Anche dopo la pulizia, Windows non recupera lo spazio automaticamente. È necessario compattare il file del disco virtuale.

1. **Chiudi Docker Desktop** (Tasto destro sull'icona -> Quit).
2. **Spegni WSL** dal terminale:
   ```bash
   wsl --shutdown
   ```
3. Apri il terminale come Amministratore e digita `diskpart`.
4. Esegui i seguenti comandi uno alla volta (sostituisci `<username>` con il tuo nome utente di Windows):
   - ```bash
     select vdisk file="C:\Users\<username>\AppData\Local\Docker\wsl\disk\docker_data.vhdx"
     ```
   - ```bash
     attach vdisk readonly
     ```
   - ```bash
     compact vdisk
     ```
   - ```bash
     detach vdisk
     ```
   - ```bash
     exit
     ```

# Troubleshooting

Se il file `.vhdx` non si restringe nonostante la pulizia e il `compact`, significa che i blocchi orfani sono bloccati all'interno del motore di Docker.

**Procedura di sblocco:**

1. Assicurati che Docker Desktop sia avviato.
2. Esegui il "trim" forzato entrando nel namespace del sistema ospite:
   ```bash
   docker run --rm --privileged --pid=host alpine nsenter -t 1 -m -u -n -i fstrim -av
   ```
3. Una volta terminato, chiudi Docker e spegni WSL:
   ```bash
   wsl --shutdown
   ```
4. Procedi con la compattazione finale tramite `diskpart`
