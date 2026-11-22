# OpenRadlr Helm chart

Runs an OpenRadlr server (game server, browser client and routes in one image)
on Kubernetes. For Docker Compose and the background on every setting, see
[docs/deploy.md](../../../docs/deploy.md).

```bash
helm install openradlr oci://ghcr.io/lethonium/charts/openradlr --version <release> \
  -n openradlr --create-namespace -f my-values.yaml
# or from a checkout: helm install openradlr deploy/helm/openradlr ...
helm test openradlr -n openradlr   # GET /healthz through the Service
```

## What it creates

- A Deployment with **one** pod (`Recreate`): worlds live in memory and Strava
  logins in SQLite, so there is no replica setting. Every upgrade or restart
  drops the riders who are on, like `make update`.
- A PersistentVolumeClaim for `/app/data` (Strava logins, ride statistics),
  kept on `helm uninstall` (`helm.sh/resource-policy: keep`). Back it up.
- A ConfigMap with the server settings, a Secret for Strava (when set), a
  Service, and optionally an Ingress and a Prometheus `ServiceMonitor`.

The pod runs as the image's non-root user (10001) with a read-only root
filesystem and no capabilities, matching `docker-compose.yml`.

## Example values

```yaml
publicUrl: https://ride.example.org      # also limits game connections to this origin

config:                                  # any variable from .env.example
  OPENRADLR_SERVER_NAME: Leon's Ride Club
  OPENRADLR_ROUTE_FILE: /app/routes/rolling-hills.json
  OPENRADLR_MAX_PLAYERS: 50
  OPENRADLR_TRUST_PROXY: true            # the ingress is the only way in
  OPENRADLR_ALLOW_SIMULATED_TRAINER: false

secrets:
  existingSecret: openradlr              # keys OPENRADLR_STRAVA_CLIENT_ID,
                                         # OPENRADLR_STRAVA_CLIENT_SECRET, OPENRADLR_SECRET_KEY

ingress:
  enabled: true
  className: nginx
  annotations:
    # Game connections are WebSockets that stay open for a whole ride.
    nginx.ingress.kubernetes.io/proxy-read-timeout: "3600"
    nginx.ingress.kubernetes.io/proxy-send-timeout: "3600"
  hosts:
    - host: ride.example.org
      paths:
        - path: /
          pathType: Prefix
  tls:                                   # Web Bluetooth needs https://
    - secretName: openradlr-tls
      hosts: [ride.example.org]
```

Create the Secret yourself, e.g.:

```bash
kubectl -n openradlr create secret generic openradlr \
  --from-literal=OPENRADLR_STRAVA_CLIENT_ID=... \
  --from-literal=OPENRADLR_STRAVA_CLIENT_SECRET=... \
  --from-literal=OPENRADLR_SECRET_KEY="$(openssl rand -hex 32)"
```

## Notes

- **Image:** `ghcr.io/lethonium/openradlr-server`, tag = the chart's
  `appVersion` unless `image.tag` or `image.digest` is set. `edge` follows
  `main`. Your own build works too: `docker build -t <registry>/openradlr-server:<tag> .`
  at the repository root, then set `image.repository` and `image.tag`.
- **Routes:** the image contains `routes/`. Add more with `extraRoutes`
  (file name → JSON, mounted next to the bundled ones; a ConfigMap holds about
  1 MiB) or mount a volume over `/app/routes` with `extraVolumes`.
- **Client IPs:** `OPENRADLR_TRUST_PROXY=true` (the default here) takes them
  from `X-Forwarded-For`, which the per-IP connection limit relies on. Turn it
  off if the pod can be reached without the ingress, e.g. through a
  `LoadBalancer` Service.
- **Metrics:** `/internal/metrics` on the service port. With the Prometheus
  Operator set `metrics.serviceMonitor.enabled=true`; with annotation-based
  discovery (the community Prometheus chart) annotate the Service instead:
  ```yaml
  service:
    annotations:
      prometheus.io/scrape: "true"
      prometheus.io/path: /internal/metrics
      prometheus.io/port: "8080"
  ```
  With the ingress path `/` the endpoint is public too; block `/internal` at
  your controller if that matters.
- **Landing page:** not part of this chart (it is a separate static image,
  see `landing/`).

All values are documented in [values.yaml](values.yaml).
