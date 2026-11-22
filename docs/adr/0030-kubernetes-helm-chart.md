# 0030 — Ship a Helm chart and a published image

## Context

Docker Compose is the supported way to run a server. Running it on Kubernetes
meant translating `docker-compose.yml` by hand, and with no published image
every cluster had to build and host its own.

## Decision

The repository ships a Helm chart in `deploy/helm/openradlr/` and a workflow
that publishes the server image to `ghcr.io/<owner>/openradlr-server` for every
release tag (and `edge` for `main`), and the chart to
`oci://ghcr.io/<owner>/charts/openradlr`. The chart's `version` and
`appVersion` both follow `version.txt` (bumped by Release Please), so chart
0.3.0 runs image 0.3.0.

The chart runs exactly one pod with the `Recreate` strategy and has no replica
setting: worlds live in memory and Strava logins in SQLite on one volume, so
two pods would split riders into separate worlds and race on the database.
Server settings are passed through as a `config` map of the same environment
variables as `.env.example`, so new settings need no chart change.

## Consequences

Kubernetes users get a supported install path; Compose stays the default and
documented first. Upgrades drop connected riders like `make update`, without
the rider guard. The chart is linted and rendered in CI (`make helm-lint`) but
not installed into a cluster there. Chart-only fixes ship with the next app
release, since the two versions move together.
