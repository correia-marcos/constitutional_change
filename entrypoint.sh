#!/usr/bin/env bash
set -euo pipefail

USER_NAME="${USER:-rstudio}"
PASS="${PASSWORD:-rstudio}"
JUPYTER_PORT="${JUPYTER_PORT:-8888}"
JUPYTER_TOKEN="${JUPYTER_TOKEN:-}"
PRUNE_R_KERNELS="${PRUNE_R_KERNELS:-true}"

# Ensure user exists
if ! id -u "$USER_NAME" >/dev/null 2>&1; then
  useradd -m -s /bin/bash "$USER_NAME"
  usermod -aG staff "$USER_NAME" || true
fi
echo "${USER_NAME}:${PASS}" | chpasswd

# Writable renv cache
mkdir -p /opt/renv/cache
chown -R "${USER_NAME}":staff /opt/renv/cache

echo "[entrypoint] args: $*"

case "${1:-}" in
  run)
    shift
    if [ "$#" -eq 0 ]; then
      echo "Usage: run <script1.R> [script2.R ...]"
      exit 1
    fi
    for script in "$@"; do
      echo "[entrypoint] Running R script: ${script}"
      Rscript "${script}"
    done
    ;;
  bash)
    echo "[entrypoint] Opening bash shell…"
    exec bash
    ;;
  jupyter|jupyter-lab|lab)
    if [ "${PRUNE_R_KERNELS}" = "true" ]; then
      echo "[entrypoint] Removing any R kernelspecs to enforce Python-only…"
      rm -rf /usr/local/share/jupyter/kernels/ir || true
      rm -rf /home/${USER_NAME}/.local/share/jupyter/kernels/ir || true
      rm -rf /root/.local/share/jupyter/kernels/ir || true
    fi
    echo "[entrypoint] Starting JupyterLab on :${JUPYTER_PORT} (Python-only)…"
    exec jupyter lab \
      --ip=0.0.0.0 \
      --port="${JUPYTER_PORT}" \
      --no-browser \
      --NotebookApp.token="${JUPYTER_TOKEN}" \
      --NotebookApp.allow_origin="*" \
      --NotebookApp.notebook_dir="/paper"
    ;;
  rserver|"")
    echo "[entrypoint] Starting RStudio Server…"
    exec rserver \
      --www-port=8787 \
      --server-user="${USER_NAME}" \
      --auth-none=0 \
      --server-daemonize=0
    ;;
  *)
    echo "[entrypoint] Exec: $*"
    exec "$@"
    ;;
esac
