## Security Policy

### Supported versions

This document describes operational security guidance for deployments of
`gost-multinode` starting from **v1.0.0**.

### Reporting a vulnerability

- Do **not** publicly disclose security issues before coordinating with the
  maintainer.
- Please open a private issue or contact the maintainer via the GitHub profile
  associated with:
  - Maintainer: **HassanAgh**

Provide as much detail as possible:

- A clear description of the issue and potential impact.
- Steps to reproduce (if applicable).
- Affected configuration and environment details.

### Operational security guidelines

- Prefer **SSH key authentication** over password authentication for the
  relay+ssh connection between foreign nodes and the Iran relay.
- Restrict access to the Iran relay port:
  - Use firewalls, security groups, or other network controls.
  - Where possible, only allow IPs of foreign nodes to reach the relay.
- Protect configuration files that contain secrets:
  - `/opt/gost-multinode/config/iran.conf`
  - `/opt/gost-multinode/config/foreign/*.conf`
  - Ensure these files are only readable by `root`.
- Regularly rotate passwords and SSH keys used for the relay.
- Monitor `systemd` logs for unusual activity:
  - `journalctl -u gost-iran.service`
  - `journalctl -u 'gost-foreign@*.service'`

### Out of scope

`gost-multinode` does **not** ship or manage:

- Host-level firewalls (iptables, nftables, UFW, etc.).
- Operating system hardening.
- Gost binary updates beyond calling the official installer.

These should be handled by the system administrator according to their own
security policies and compliance requirements.

