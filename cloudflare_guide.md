# Configuration on Cloudflare Zero Trust Dashboard

Since you use the tunnel in remote mode (managed via `--token TOKEN`), routing and subdomain configuration takes place directly from the Cloudflare web panel.

## Steps to follow:

1. Access [Cloudflare Zero Trust](https://one.dash.cloudflare.com/).
2. Go to **Networks** ➔ **Tunnels**.
3. Select your tunnel and click on **Configure**.
4. Go to the **Public Hostname** tab and add the routes for your services.

## Map of Subdomains and Docker Services

Configure the following hostname rules to match subdomains to their internal containers in the `common-network` Docker network:

| Public Hostname (Subdomain)       | Path (Optional)    | Service Type | URL (Container Name)                 | Notes                           |
| :-------------------------------- | :----------------- | :----------- | :----------------------------------- | :------------------------------ |
| `robertoingenito.com`             | `/robots.txt`      | HTTP         | `http://static-files:80`             | robots.txt management (SEO)     |
| `robertoingenito.com`             | `/sitemap.xml`     | HTTP         | `http://static-files:80`             | sitemap.xml management (SEO)    |
| `robertoingenito.com`             | _Empty_            | HTTP         | `http://portfolio-app:80`            | Main Portfolio                  |
| `cashly.robertoingenito.com`      | `/cashly-api*`     | HTTP         | `http://cashly-back-end:80`          | Cashly API Backend              |
| `cashly.robertoingenito.com`      | `/swagger*`        | HTTP         | `http://cashly-back-end:80`          | API Documentation               |
| `cashly.robertoingenito.com`      | _Empty_            | HTTP         | `http://cashly-front-end:80`         | Cashly Frontend                 |
| `mr-white.robertoingenito.com`    | `/mr-white-api*`   | HTTP         | `http://mr-white-back-end:80`        | WebSockets Backend              |
| `mr-white.robertoingenito.com`    | _Empty_            | HTTP         | `http://mr-white-front-end:3000`     | Mr. White Frontend              |
| `cloud.robertoingenito.com`       | _Empty_            | HTTP         | `http://nextcloud-app:80`            | Nextcloud Storage               |
| `timesheet.robertoingenito.com`   | _Empty_            | HTTP         | `http://fortil-excel-timesheet:3000` | Timesheet utility               |
| `calcolatori.robertoingenito.com` | _Empty_            | HTTP         | `http://static-files:80`             | Static utility pages            |
| `lafa.robertoingenito.com`        | `/lafa-tools-api*` | HTTP         | `http://lafa-tools-back-end:8080`    | LAFA Tools API Backend          |
| `lafa.robertoingenito.com`        | `/swagger*`        | HTTP         | `http://lafa-tools-back-end:8080`    | LAFA API Documentation          |
| `lafa.robertoingenito.com`        | _Empty_            | HTTP         | `http://lafa-tools-front-end:80`     | LAFA Tools Frontend             |
| `docmost.robertoingenito.com`     | _Empty_            | HTTP         | `http://docmost:3000`                | Wiki and documentation (Docmost)|
| `appflowy.robertoingenito.com`    | _Empty_            | HTTP         | `http://appflowy-nginx:80`           | Workspace collaborativo (AppFlowy)|

> [!IMPORTANT]
> **ORDER OF RECORDS (ROUTES) ON CLOUDFLARE**
> 
> The order in which routes are positioned in Cloudflare is fundamental. Cloudflare evaluates rules from top to bottom:
>
> 1. Routes with a specific path (such as `/robots.txt`, `/sitemap.xml`, `/cashly-api*` or `/swagger*`) **must be placed ABOVE** the generic route with an empty path (`Empty`).
> 2. If the route with an `Empty` path (which points to the frontend) is placed above the others, Cloudflare will capture all traffic directed to that subdomain and send it to the frontend, ignoring subsequent rules for APIs, Swagger, or SEO files.

> [!NOTE]
> For rules with a path (e.g. `/cashly-api*`), Cloudflare will automatically forward the path to the container. This keeps the API and frontend on the same subdomain, eliminating CORS issues.

> [!IMPORTANT]
> **ENABLE WEBSOCKETS FOR REAL-TIME ROUTING**
> 
> Services like **Docmost** and **AppFlowy** (for real-time collaboration and synchronization) and **Mr. White** (via SignalR) rely strictly on persistent WebSocket connections.
> For each of these subdomains, in the Cloudflare Zero Trust web console:
>
> 1. Enter route editing mode (`Public Hostname`).
> 2. Expand the **Additional application settings** section.
> 3. Click on **HTTP Settings**.
> 4. Activate the **Websockets** switch (set it to _Enabled_). If not enabled, the application interface will start but it will not be able to establish a real-time connection and will not synchronize notes.

> [!TIP]
> If your repositories will be private on GitHub (and thus GHCR images will require authentication to be downloaded), remember to:
>
> 1. Log in to your server via shell with: `docker login ghcr.io -u YOUR_USERNAME -p YOUR_GITHUB_TOKEN`
> 2. Uncomment the volume line in the `watchtower` service to mount the server's Docker configuration:
>    ```yaml
>    volumes:
>      - /var/run/docker.sock:/var/run/docker.sock
>      - ~/.docker/config.json:/config.json
>    ```
>    This way Watchtower will automatically use your credentials to update private apps.

---

## 📈 SEO Management and Google Search Console

An [Nginx](static-files/nginx.conf) server has been configured in centralized mode to serve SEO indexing files exclusively for the main portfolio `robertoingenito.com` and exclude all other subdomains.

### File Structure on the Server

SEO files are located in the `./seos/` folder of the repository:

- **`seos/default/robots.txt`**: Generic file that prevents indexing (`Disallow: /`). It is served to all explicitly unconfigured subdomains (e.g. `calcolatori.`, `cashly.`, `cloud.`).
- **`seos/robertoingenito.com/robots.txt` & `sitemap.xml`**: Allow indexing and indicate the main portfolio sitemap to Googlebot.

### Activation Procedure:

1. **Cloudflare Routes**: Make sure to configure the routes for `/robots.txt` and `/sitemap.xml` for `robertoingenito.com` directing them to `http://static-files:80` (placing them **above** the generic portfolio route).
2. **Domain Verification on GSC**: Add the **Domain** property for `robertoingenito.com` in Google Search Console.
3. **Submit the Sitemap**: In the Search Console panel for `robertoingenito.com`, go to **Sitemaps** and submit the URL `https://robertoingenito.com/sitemap.xml`.
