#!/usr/bin/env bash
set -e

echo "[*] Installing KDE Plasma (Minimal)..."

# ==== Update =======================================================
sudo apt-get update -y

# ==== Install packages (KDE Minimal) ==============================
sudo apt-get install -y --no-install-recommends \
  kde-plasma-desktop \
  tigervnc-standalone-server tigervnc-common tigervnc-tools \
  novnc websockify \
  dbus-x11 x11-xserver-utils \
  pulseaudio \
  ibus ibus-mozc \
  language-pack-ja language-pack-gnome-ja \
  fonts-ipafont fonts-ipafont-gothic fonts-ipafont-mincho \
  wget tar xz-utils bzip2 git

# ==== Locale =======================================================
sudo locale-gen ja_JP.UTF-8
sudo update-locale LANG=ja_JP.UTF-8

export LANG=ja_JP.UTF-8
export LC_ALL=ja_JP.UTF-8
export LANGUAGE=ja_JP:ja

# ==== Input Method (IBus) ==========================================
export GTK_IM_MODULE=ibus
export QT_IM_MODULE=ibus
export XMODIFIERS=@im=ibus

mkdir -p ~/.config/autostart
cat > ~/.config/autostart/ibus.desktop <<'EOF'
[Desktop Entry]
Type=Application
Exec=ibus-daemon -drx
Name=IBus
EOF

# ==== VNC Setup ====================================================
VNC_DIR="$HOME/.vnc"
mkdir -p "$VNC_DIR"

# パスワードを自動生成（固定: vncpass）
echo "vncpass" | vncpasswd -f > "$VNC_DIR/passwd"
chmod 600 "$VNC_DIR/passwd"

cat > "$VNC_DIR/xstartup" <<'EOF'
#!/bin/bash
export LANG=ja_JP.UTF-8
export LC_ALL=ja_JP.UTF-8
export LANGUAGE=ja_JP:ja

export GTK_IM_MODULE=ibus
export QT_IM_MODULE=ibus
export XMODIFIERS=@im=ibus

exec dbus-launch --exit-with-session startplasma-x11
EOF
chmod +x "$VNC_DIR/xstartup"

# ==== Cleanup old sessions ========================================
vncserver -kill :1 2>/dev/null || true
pkill Xtigervnc 2>/dev/null || true
pkill websockify 2>/dev/null || true

# ==== Wait until port 6080 is free ================================
while ss -tlnp | grep -q ":6080"; do
  echo "[*] Waiting for port 6080 to be free..."
  sleep 1
done

# ==== Update noVNC to latest ======================================
if [ ! -d "/usr/share/novnc/.git" ]; then
    sudo rm -rf /usr/share/novnc
    sudo git clone --depth 1 https://github.com/novnc/noVNC /usr/share/novnc
fi

# ==== Start VNC (TigerVNC) ========================================
echo "[*] Starting TigerVNC for KDE (:1)..."
vncserver :1 -geometry 1280x720 -depth 24 -localhost no

sleep 3

# ==== Start noVNC (websockify) ====================================
echo "[*] Starting noVNC (6080)..."
nohup websockify --web=/usr/share/novnc/ \
  6080 localhost:5901 \
  > /tmp/novnc.log 2>&1 &

# ==== Audio ========================================================
pulseaudio --kill 2>/dev/null || true
pulseaudio --start --exit-idle-time=-1

# ==== Done =========================================================
echo "=============================================================="
echo " ✔ noVNC  : http://localhost:6080/"
echo " ✔ Password: vncpass"
echo " ✔ Desktop: KDE Plasma (Minimal / Japanese)"
echo "=============================================================="
