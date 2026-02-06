## gost-multinode

Status: **Stable**  
Release: **v1.0.0**  
Maintainer: **HassanAgh**

Multi-node relay setup for [Gost](https://github.com/go-gost/gost), designed for
deployments where an **Iran node** acts as a central relay for multiple **foreign
nodes**.

- Iran node: one `gost-iran.service` running inside Iran, exposing a relay+ssh
  listener.
- Foreign nodes: many `gost-foreign@<name>.service` instances outside Iran,
  connecting back to the Iran relay and exposing local ports.

---

## Features

- Simple interactive manager (`gost-manager`) to:
  - Install/update Gost
  - Configure the Iran relay node
  - Add/update multiple foreign nodes
  - Start/restart all related systemd services
  - Clean uninstall of gost-multinode (manager and units)
- Separation of concerns:
  - `lib/iran.sh` for Iran node logic
  - `lib/foreign.sh` for foreign node logic
- Authentication:
  - Username/password
  - SSH private key (per-node configurable)
- Config-driven:
  - Iran config: `/opt/gost-multinode/config/iran.conf`
  - Foreign configs: `/opt/gost-multinode/config/foreign/<name>.conf`
- Systemd integration:
  - `gost-iran.service` – Iran relay
  - `gost-foreign@.service` – one instance per foreign node
  - Restart policies and basic hardening
- Idempotent installer and manager:
  - Safe to run multiple times

---

## Installation

Run as `root` (or via `sudo`) on both Iran and foreign nodes:

```bash
curl -fsSL https://raw.githubusercontent.com/hassanagharkakli/gost-multinode/main/install.sh | bash
```

After installation:

```bash
gost-manager
```

`gost-manager` must be run as root, as it configures `systemd` units and writes
configuration files under `/opt/gost-multinode`.

---

## Iran node workflow

On the Iran node:

1. Run `gost-manager`.
2. Choose:
   - `2) Configure Iran relay node`
3. Provide:
   - Relay port (listening port on the Iran node)
   - Relay username
   - Authentication mode:
     - Password (stored in `iran.conf`)
     - SSH private key (path to key on the Iran node)
   - Optional IP allowlist (comma-separated IP/CIDR values)
4. Then choose:
   - `3) Start / restart Iran relay service`

This enables and starts `gost-iran.service`, which reads
`/opt/gost-multinode/config/iran.conf` and launches Gost with a `relay+ssh`
listener.

---

## Foreign node workflow

On each foreign node:

1. Run `gost-manager`.
2. Choose:
   - `4) Add or update a foreign node configuration`
3. Provide:
   - Foreign node name (used as the `%i` instance name in `gost-foreign@.service`)
   - Iran relay IP/hostname
   - Iran relay port
   - Relay username
   - Authentication mode:
     - Password (must match Iran node)
     - SSH private key (path to key on the foreign node)
   - One or more `local_port -> iran_port` mappings
4. Then choose:
   - `5) Start / restart all foreign node services`

This enables and starts `gost-foreign@<name>.service` for each config file in
`/opt/gost-multinode/config/foreign`.

---

## Configuration format

### Iran config (`/opt/gost-multinode/config/iran.conf`)

Example (password-based):

```bash
PORT=2222
USER=myrelay
AUTH_MODE=password
PASS=changeme
ALLOWLIST=1.2.3.4,5.6.7.8
```

Example (SSH key-based):

```bash
PORT=2222
USER=myrelay
AUTH_MODE=key
KEY_FILE=/root/.ssh/id_rsa
```

### Foreign config (`/opt/gost-multinode/config/foreign/<name>.conf`)

```bash
NAME=eu-1
IRAN=IRAN_PUBLIC_IP_OR_HOST
PORT=2222
USER=myrelay
AUTH_MODE=password      # or: AUTH_MODE=key
PASS=changeme           # if AUTH_MODE=password
KEY_FILE=/root/.ssh/id_rsa   # if AUTH_MODE=key

MAP=8080:8080
MAP=8443:8443
```

Each `MAP` line defines `LOCAL_PORT:IRAN_PORT`.

---

## Systemd units

- `systemd/gost-iran.service`
  - Reads `iran.conf` and runs:
    - Password mode:
      - `gost -L relay+ssh://USER:PASS@:PORT?bind=true`
    - SSH key mode:
      - `gost -L relay+ssh://USER@:PORT?bind=true&privateKey=KEY_FILE`
- `systemd/gost-foreign@.service`
  - Reads `/opt/gost-multinode/config/foreign/%i.conf`
  - For each `MAP=LOCAL:REMOTE`:
    - Adds `-L rtcp://:LOCAL/:REMOTE`
  - Connects to the Iran relay with:
    - Password mode:
      - `-F relay+ssh://USER:PASS@IRAN:PORT`
    - SSH key mode:
      - `-F relay+ssh://USER@IRAN:PORT?privateKey=KEY_FILE`

Both units:

- Use `Restart=on-failure` and `RestartSec=3`
- Depend on `network-online.target`
- Include basic hardening options such as `NoNewPrivileges=yes`

---

## Security notes

- Consider using **SSH keys** instead of passwords where possible.
- Restrict reachability of the Iran relay port:
  - Use firewall rules, security groups, or IP allowlists.
- Keep `/opt/gost-multinode/config/iran.conf` and
  `/opt/gost-multinode/config/foreign/*.conf` readable only by root:
  - The installer and manager apply restrictive permissions by default.
- Secrets (passwords, key paths) are never echoed back to the terminal, but
  note that:
  - With password-based URLs, passwords appear in process command lines and
    systemd logs; prefer SSH keys if this is a concern.

---

## Uninstall

Run:

```bash
gost-manager
```

Then choose:

- `7) Uninstall gost-multinode (manager and services)`

This stops and disables related services, removes `/opt/gost-multinode`, and
deletes the `/usr/bin/gost-manager` symlink. The Gost binary itself is not
removed.

---

## License and maintenance

- Maintainer: **HassanAgh**
- Repository: `https://github.com/hassanagharkakli/gost-multinode`

See the repository for license details and contribution guidelines.

