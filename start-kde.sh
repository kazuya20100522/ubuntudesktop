#!/bin/bash

# ===== Audio (PulseAudio + Virtual Sink) =====
pulseaudio --kill 2>/dev/null || true
pulseaudio --start --exit-idle-time=-1

# 仮想シンク作成（存在してもエラーにしない）
pactl load-module module-null-sink sink_name=virtual_sink sink_properties=device.description=VirtualSink 2>/dev/null || true

# デフォルト出力を仮想シンクに
pactl set-default-sink virtual_sink 2>/dev/null || true

# ===== KDE 専用 HOME =====
export HOME=/home/codespace/.kde
mkdir -p $HOME
mkdir -p $HOME/.vnc

# ===== PulseAudio は KDE で起動しない =====
unset PULSE_RUNTIME_PATH
unset PULSE_STATE_PATH

# ===== 旧セッション完全終了 =====
echo "[*] Killing old VNC / Desktop sessions..."

vncserver -kill :1 2>/dev/null

pkill -f Xtigervnc 2>/dev/null
pkill -f x0vncserver 2>/dev/null

pkill -f websockify 2>/dev/null
pkill -f novnc 2>/dev/null

pkill -f startplasma-x11 2>/dev/null
pkill -f startxfce4 2>/dev/null
pkill -f xfce4-session 2>/dev/null
pkill -f plasmashell 2>/dev/null

pkill -f dbus-launch 2>/dev/null
pkill -f dbus-daemon 2>/dev/null

fuser -k 5901/tcp 2>/dev/null
fuser -k 6080/tcp 2>/dev/null

echo "[*] Cleanup complete."

# ===== KDE 日本語化 =====
export LANG=ja_JP.UTF-8
export LC_ALL=ja_JP.UTF-8
export LANGUAGE=ja_JP:ja

mkdir -p $HOME/.config
cat > $HOME/.config/plasma-localerc <<EOF
[Formats]
LANG=ja_JP.UTF-8

[Translations]
LANGUAGE=ja_JP:ja
EOF

# ===== VNC xstartup =====
cat > $HOME/.vnc/xstartup <<'EOF'
#!/bin/bash
export LANG=ja_JP.UTF-8
export LC_ALL=ja_JP.UTF-8
export LANGUAGE=ja_JP:ja
exec dbus-launch --exit-with-session startplasma-x11
EOF
chmod +x $HOME/.vnc/xstartup

# ===== VNC 起動 =====
vncserver :1 -geometry 1366x768 -depth 24 -localhost no

# ===== noVNC 起動 =====
nohup websockify --web=/usr/share/novnc/ 6080 localhost:5901 &

echo "KDE started on http://localhost:6080"
