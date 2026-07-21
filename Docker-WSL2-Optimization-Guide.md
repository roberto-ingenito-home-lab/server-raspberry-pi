# Docker Space Cleanup and Optimization on WSL2

This guide explains how to analyze the space used by Docker, how to clean it safely, and how to reduce the actual size of the `.vhdx` file on Windows.

## 1. Space Analysis

Before proceeding, identify what is taking up space with:

```bash
docker system df
```

## 2. Cleanup

### A. Clear the Build Cache (Safe)

The build cache can accumulate tens of GBs. Deleting it does not affect containers or final images:

```bash
docker builder prune -a
```

### B. Delete unused Volumes

Removes only volumes that are not mounted in **any** container (not even stopped ones):

```bash
docker volume prune
```

### C. Delete unused Images

To delete only images that are not associated with any container (not even stopped ones):

```bash
docker image prune -a
```

_Note: If a container is stopped, its image is considered "in use" and will not be removed._

## 3. WSL2 disk compaction (ext4.vhdx)

Even after cleanup, Windows does not recover space automatically. It is necessary to compact the virtual disk file.

1. **Close Docker Desktop** (Right-click on the icon -> Quit).
2. **Shut down WSL** from the terminal:
   ```bash
   wsl --shutdown
   ```
3. Open the terminal as Administrator and type `diskpart`.
4. Run the following commands one at a time (replace `<username>` with your Windows username):
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

If the `.vhdx` file does not shrink despite the cleanup and `compact`, it means that orphan blocks are stuck inside the Docker engine.

**Unblock procedure:**

1. Ensure Docker Desktop is running.
2. Run a forced "trim" by entering the host system namespace:
   ```bash
   docker run --rm --privileged --pid=host alpine nsenter -t 1 -m -u -n -i fstrim -av
   ```
3. Once finished, close Docker and shut down WSL:
   ```bash
   wsl --shutdown
   ```
4. Proceed with the final compaction via `diskpart`
