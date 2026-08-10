---
name: manage-docker-services
description: Manage independently deployed Docker Compose services on either sachi or amane. Use for adding, enabling, updating, starting, stopping, disabling, or safely removing a service while selecting the correct host-specific Docker root and ZFS dataset root, validating Compose, preserving persistent state, and handling Traefik networking.
---

# Manage Docker Services

Use one shared workflow for both supported hosts. Derive paths from the target host profile; never hard-code one host's root into operations for the other.

## Resolve target profile

Determine `target_host` from the request. If omitted, use `hostname -s` only when it returns a supported host; otherwise ask for the target. When working over SSH, run all discovery, file changes, and lifecycle commands on `target_host`.

| `target_host` | `docker_root` | `dataset_root` |
| --- | --- | --- |
| `sachi` | `/pool/main/docker` | `main/docker/available` |
| `amane` | `/pool/tank/docker` | `tank/encrypted/docker/available` |

Derive all remaining values after selecting the profile:

```text
service_dir  = <docker_root>/available/<service>
enabled_link = <docker_root>/enabled/<service>
dataset      = <dataset_root>/<service>
```

Before mutation, verify the remote/local short hostname equals `target_host`, both `<docker_root>/available` and `<docker_root>/enabled` exist, and the service slug matches `^[A-Za-z0-9][A-Za-z0-9._-]*$`. Stop on an unsupported host or profile mismatch.

Treat each `service_dir` as an independent Compose project. Never operate from `docker_root` as an aggregate project. Treat `enabled_link` as activation metadata, not as a Compose working directory.

## Inspect

1. Inspect `service_dir`, `enabled_link`, and `dataset` using the selected profile.
2. Reject an unexpected symlink or path resolving outside `docker_root`.
3. Locate `docker-compose.yaml` or `docker-compose.yml`.
4. Change to `service_dir` before every Compose command.
5. Validate with `docker compose config --quiet`; never print rendered config because it can expose secrets.
6. Inspect only this project with `docker compose ps` and targeted logs.

## Add

1. Confirm `service_dir`, `enabled_link`, and `dataset` do not exist. If the project exists, use the update workflow.
2. Run `sudo -n docker-service-init <service>` on `target_host`. This immutable host helper uses the selected host's configured roots, creates exactly one child ZFS dataset, assigns initial ownership, refuses existing datasets, and rolls back failed initialization.
3. Verify the created path and dataset match `service_dir` and `dataset`. Never substitute direct `mkdir`, `zfs create`, `chown`, or password-based sudo.
4. Create Compose and protected environment/config files inside `service_dir`. Put writable application state under `./persist/<component>` and use bind mounts instead of anonymous volumes.
5. For HTTP proxying, attach only proxy-facing containers to external network `g_proxy`. Keep databases and workers on private project networks. Follow a nearby project on the same target host for Traefik router, hostname, TLS, and middleware conventions.
6. Run `docker compose config --quiet` and fix every error.
7. Create a relative activation link: `ln -s ../available/<service> <enabled_link>`.
8. Run `docker compose pull` for image-based services or `docker compose build` for local builds, then `docker compose up -d` or `docker compose up -d --build`.
9. Verify status, health, recent targeted logs, and routed endpoint when applicable.

On failure after provisioning, stop containers and remove only an activation link created by this operation. Preserve the dataset for diagnosis; never destroy it as rollback.

## Update

1. Preserve `persist/`, environment files, and unrelated changes.
2. Edit only `service_dir` for the selected host.
3. Run `docker compose config --quiet`.
4. Pull or build as appropriate, then run `docker compose up -d` or `docker compose up -d --build`.
5. Use `--remove-orphans` only after confirming obsolete Compose services should disappear.
6. Verify status, health, logs, and routing. Traefik watches Docker labels dynamically; do not restart it for ordinary label changes.

## Disable or remove

Interpret unqualified removal as reversible decommissioning: remove runtime resources and activation while retaining service files and state.

1. Resolve the target profile again and show the exact `service_dir`, `enabled_link`, and `dataset`. Report whether `persist/` exists.
2. From `service_dir`, run `docker compose down` without `-v`.
3. Remove `enabled_link` only when it is a symlink resolving exactly to `service_dir`. Never recursively remove the enabled path.
4. Verify the project has no remaining containers and the activation link is absent.
5. Retain `service_dir`, `dataset`, and `persist/`; report that the removal is reversible.

If the user explicitly requests irreversible deletion, verify the exact dataset using `zfs list <dataset>` and stop. No approved dataset-removal helper exists on either host. Never run `zfs destroy`, recursive destroy, rename, rollback, or unmount; leave dataset deletion to the user.

## Safety

- Never request, read, or pipe a password. Use only `sudo -n docker-service-init` for privileged provisioning.
- Never expose or summarize credentials from Compose or environment files.
- Never use `docker compose down -v` unless volume deletion is explicitly requested.
- Never delete or recursively change ownership of `persist/`; containers may use special UIDs.
- Reuse shared `/pool` paths only after checking ownership, permissions, and read/write requirements. Prefer `:ro` where possible.
- Never expose the Docker socket to a new container without explicit need.
- Never start a legacy Compose Traefik stack. Native `traefik.service` serves both hosts.
- Avoid restarting unrelated services. Diagnose `g_proxy` membership and labels before considering a Traefik restart.
