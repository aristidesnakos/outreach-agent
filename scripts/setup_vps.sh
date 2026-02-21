#!/bin/bash
# Lead Outreach Agent - Hetzner CAX11 Setup
# Run as root on fresh Ubuntu 24.04 ARM

set -euo pipefail

echo "=== Lead Outreach Agent VPS Setup ==="

# System updates
apt-get update && apt-get upgrade -y

# Install dependencies
apt-get install -y \
    curl git jq sqlite3 \
    build-essential pkg-config libssl-dev

# Create service user
useradd -m -s /bin/bash zeroclaw || true

# Install Rust (for ZeroClaw)
su - zeroclaw -c 'curl --proto "=https" --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y'

# Install ZeroClaw
su - zeroclaw -c 'source ~/.cargo/env && cargo install zeroclaw'

# Create directories
su - zeroclaw -c 'mkdir -p ~/.zeroclaw/workspace/skills'

# Firewall
apt-get install -y ufw
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw --force enable

# Systemd service
cat > /etc/systemd/system/zeroclaw.service << 'EOF'
[Unit]
Description=ZeroClaw Lead Outreach Agent
After=network.target

[Service]
Type=simple
User=zeroclaw
WorkingDirectory=/home/zeroclaw
ExecStart=/home/zeroclaw/.cargo/bin/zeroclaw daemon
Restart=always
RestartSec=10
Environment=HOME=/home/zeroclaw

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable zeroclaw

echo ""
echo "=== Setup Complete ==="
echo "Next:"
echo "1. scp config.toml zeroclaw@host:~/.zeroclaw/"
echo "2. scp -r workspace zeroclaw@host:~/.zeroclaw/"
echo "3. scp .env zeroclaw@host:~/.zeroclaw/"
echo "4. ssh zeroclaw@host 'zeroclaw onboard'"
echo "5. systemctl start zeroclaw"
