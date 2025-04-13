# Developer Guide

Welcome to the `ansible_homelab_kubernetes` project! This guide explains how to get started as a contributor, with an emphasis on Ansible best practices, linting, formatting, and CI.

---

## 🚀 Project Overview

This repository automates the setup of a homelab Kubernetes cluster using Ansible. It includes roles for:

- K3s control plane and workers
- NFS server and dynamic provisioning
- Traefik ingress, dashboards, Prometheus/Grafana monitoring
- ML components like MLflow, Argo Workflows, and Seldon Core

---

## ⚙️ Tooling Setup

All linting and formatting tools are managed via [pipx](https://pipx.pypa.io/), which installs each tool in an isolated environment.

### Prerequisites

- Python 3.9+
- `pipx` installed and available in your PATH

```bash
python3 -m pip install --user pipx
python3 -m pipx ensurepath
exec $SHELL -l
```

### Install Required Tools

```bash
pipx install pre-commit
pipx install ansible-lint
pipx install yamllint
pipx install yamlfmt
```

---

## ✅ Linting and Formatting Standards

This project uses the following quality tools:

| Tool         | Purpose                         | Config File               |
|--------------|----------------------------------|---------------------------|
| yamllint     | YAML syntax, spacing, style     | `.yamllint`               |
| ansible-lint | Enforces Ansible best practices | `.pre-commit-config.yaml` |
| yamlfmt      | YAML auto-formatter             | `.yamlfmt.yaml`           |
| pre-commit   | Runs all linters in one step    | `.pre-commit-config.yaml` |

Run everything locally with:

```bash
pre-commit run --all-files
```

Or format YAML only with:

```bash
find . -type f \( -name "*.yml" -o -name "*.yaml" \) -exec yamlfmt -w {} \;
```

---

## 🔁 GitHub Actions CI

Every push and pull request to `main` runs lint checks via GitHub Actions:

- ✅ Validates YAML format
- ✅ Enforces Ansible lint rules
- ✅ Runs `pre-commit` hooks across the repo

CI is defined in:

```
.github/workflows/lint.yml
```

Add this badge to your `README.md`:

```markdown
![Lint Status](https://github.com/jtayl222/ansible_homelab_kubernetes/actions/workflows/lint.yml/badge.svg)
```

---

## 👩‍💻 Contribution Guidelines

Before committing any changes:

1. Run `pre-commit run --all-files`
2. Fix any lint or format issues
3. Ensure your playbooks pass syntax checks:

```bash
ansible-playbook install_010_site.yml --syntax-check
```

4. Follow Ansible best practices:
   - Use roles and `defaults/main.yml` for tunables
   - Avoid `shell:` unless required (use `command:` instead)
   - Include `name:` on every task
   - Keep lines ≤120 characters

---

## 📚 Reference Docs

- [ansible-lint rules](https://ansible-lint.readthedocs.io/)
- [yamllint rules](https://yamllint.readthedocs.io/)
- [pipx installation](https://pipx.pypa.io/stable/)

---

## 🙌 Thanks

Thank you for helping maintain clean, reproducible, and high-quality infrastructure automation!
