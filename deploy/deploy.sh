#!/bin/bash
set -e

# ─────────────────────────────────────────────
# Usage: ./deploy.sh <install_dir>
# Example: ./deploy.sh /root/easytier-linux-x86_64
# ─────────────────────────────────────────────

INSTALL_DIR="${1}"

if [ -z "${INSTALL_DIR}" ]; then
    echo "[ERROR] Please provide an install directory as the first argument."
    echo "Usage: $0 <install_dir>"
    exit 1
fi

EASYTIER_VERSION="v2.6.3"
EASYTIER_ZIP="easytier-linux-x86_64-${EASYTIER_VERSION}.zip"
EASYTIER_URL="https://github.com/EasyTier/EasyTier/releases/download/${EASYTIER_VERSION}/${EASYTIER_ZIP}"
SERVICE_NAME="easytier"
SERVICE_FILE_SRC="$(dirname "$(realpath "$0")")/easytier.service"
SERVICE_FILE_DST="/etc/systemd/system/${SERVICE_NAME}.service"

echo "============================================"
echo "  Deploy Script: Docker + EasyTier"
echo "  Install Dir : ${INSTALL_DIR}"
echo "  EasyTier Ver: ${EASYTIER_VERSION}"
echo "============================================"

# ─── 0. Root check ───────────────────────────
if [ "$(id -u)" -ne 0 ]; then
    echo "[ERROR] This script must be run as root."
    exit 1
fi

# ─── 1. Update apt & install prerequisites ───
echo ""
echo "[1/4] Updating package list and installing prerequisites..."
apt-get update -y
apt-get install -y curl unzip ca-certificates gnupg lsb-release

# ─── 2. Install Docker ───────────────────────
echo ""
echo "[2/4] Installing Docker..."

if command -v docker &>/dev/null; then
    echo "      Docker is already installed ($(docker --version)). Skipping."
else
    # Add Docker's official GPG key
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
        | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg

    # Add the Docker repository
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu \
$(lsb_release -cs) stable" \
        | tee /etc/apt/sources.list.d/docker.list > /dev/null

    apt-get update -y
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    systemctl enable docker
    systemctl start docker
    echo "      Docker installed and started successfully."
fi

# ─── 3. Download & install EasyTier ──────────
echo ""
echo "[3/4] Downloading EasyTier ${EASYTIER_VERSION}..."

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

curl -fL "${EASYTIER_URL}" -o "${TMP_DIR}/${EASYTIER_ZIP}"

echo "      Extracting to ${INSTALL_DIR} ..."
mkdir -p "${INSTALL_DIR}"
unzip -o "${TMP_DIR}/${EASYTIER_ZIP}" -d "${INSTALL_DIR}"
chmod +x "${INSTALL_DIR}"/easytier-* 2>/dev/null || true

echo "      EasyTier extracted to ${INSTALL_DIR}"

# ─── 4. Install & enable systemd service ─────
echo ""
echo "[4/4] Installing systemd service..."

if [ ! -f "${SERVICE_FILE_SRC}" ]; then
    echo "[ERROR] Service file not found: ${SERVICE_FILE_SRC}"
    exit 1
fi

cp "${SERVICE_FILE_SRC}" "${SERVICE_FILE_DST}"
chmod 644 "${SERVICE_FILE_DST}"

# ─── 5. 自动配置 UFW 防火墙 ─────
echo "=== 自动配置 UFW 防火墙 ==="
ufw reset
ufw enable


ufw allow 22/tcp
ufw allow 11010

ufw allow from 10.126.126.0/24 to any port 3000 proto tcp
ufw allow from 10.126.126.0/24 to any port 7878 proto tcp
ufw allow from 10.126.126.0/24 to any port 7800 proto tcp

ufw reload

echo -e "\n=== 配置完成，当前状态 ==="
ufw status

systemctl daemon-reload
systemctl enable "${SERVICE_NAME}"
systemctl restart "${SERVICE_NAME}"

echo ""
echo "============================================"
echo "  Deployment complete!"
echo "  Service status:"
systemctl status "${SERVICE_NAME}" --no-pager || true
echo "============================================"
