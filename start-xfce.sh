#!/bin/bash

# ===== XFCE 専用 HOME =====
# ★ これを削除（PulseAudio が壊れる）
# export PULSE_RUNTIME_PATH=/run/user/1000/pulse
# export PULSE_STATE_PATH=/home/codespace/.config/pulse

export HOME=/home/codespace/.xfce
mkdir -p $HOME
mkdir -p $HOME/.vnc

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

# ===== XFCE 日本語化 =====
export LANG=ja_JP.UTF-8
export LC_ALL=ja_JP.UTF-8
export LANGUAGE=ja_JP:ja

mkdir -p $HOME/.config/xfce4/xfconf/xfce-perchannel-xml
cat > $HOME/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xsettings" version="1.0">
  <property name="Net" type="empty">
    <property name="LocaleName" type="string" value="ja_JP.UTF-8"/>
  </property>
</channel>
EOF

# ===== VNC xstartup =====
cat > $HOME/.vnc/xstartup <<'EOF'
#!/bin/bash
export LANG=ja_JP.UTF-8
export LC_ALL=ja_JP.UTF-8
export LANGUAGE=ja_JP:ja

# ===== Audio (PulseAudio + Virtual Sink) =====
pulseaudio --kill 2>/dev/null || true
pulseaudio --start --exit-idle-time=-1

# 仮想シンク作成（存在してもエラーにしない）
pactl load-module module-null-sink sink_name=virtual_sink sink_properties=device.description=VirtualSink 2>/dev/null || true

# デフォルト出力を仮想シンクに
pactl set-default-sink virtual_sink 2>/dev/null || true

exec dbus-launch --exit-with-session startxfce4
EOF
chmod +x $HOME/.vnc/xstartup

# ===== VNC 起動 =====
vncserver :1 -geometry 1366x768 -depth 24 -localhost no

# ===== noVNC 起動 =====
nohup websockify --web=/usr/share/novnc/ 6080 localhost:5901 &

echo "XFCE4 started on http://localhost:6080"
