# ubuntudesktop

pulseaudio --start
pactl load-module module-null-sink sink_name=virtual_sink format=float32le rate=48000 channels=1
pactl set-default-sink virtual_sink

cd /workspaces/ubuntudesktop/current
node compare-server.js

pactl load-module module-null-sink sink_name=virtual_sink format=float32le rate=48000 channels=1 sink_properties=device.description=VirtualSink


pactl load-module module-null-sink sink_name=virtual_sink format=float32le rate=48000 channels=2 sink_properties=device.description=VirtualSink
