import WebSocket, { WebSocketServer } from "ws";
import http from "http";
import { spawn } from "child_process";
import fs from "fs";
import path from "path";
import url from "url";

const __dirname = path.dirname(url.fileURLToPath(import.meta.url));

// ---- HTTP サーバ ----
const server = http.createServer((req, res) => {

  const serve = (file, type) => {
    const filePath = path.join(__dirname, file);
    const data = fs.readFileSync(filePath);
    res.writeHead(200, { "Content-Type": type });
    res.end(data);
  };

  if (req.url === "/pcm") return serve("pcm.html", "text/html");
  if (req.url === "/pcm-worklet") return serve("pcm-worklet.html", "text/html");
  if (req.url === "/webrtc") return serve("webrtc.html", "text/html");
  if (req.url === "/worklet.js") return serve("worklet.js", "application/javascript");

  res.writeHead(404);
  res.end("Not found");
});

// ---- PCM 用 WebSocket ----
const wssPcm = new WebSocketServer({ noServer: true });
let pcmClients = [];

wssPcm.on("connection", (ws) => {
  console.log("PCM client connected");
  ws._socket.setNoDelay(true);
  pcmClients.push(ws);

  ws.on("close", () => {
    pcmClients = pcmClients.filter(c => c !== ws);
  });
});

// ---- HTTP Upgrade ----
server.on("upgrade", (req, socket, head) => {
  socket.setNoDelay(true);
  if (req.url === "/pcm-ws") {
    wssPcm.handleUpgrade(req, socket, head, (ws) => {
      wssPcm.emit("connection", ws, req);
    });
  } else {
    socket.destroy();
  }
});

// ---- ffmpeg → PCM（高音質 Float32） ----
const ffmpeg = spawn("ffmpeg", [
  "-flags", "low_delay",
  "-f", "pulse",
  "-i", "virtual_sink.monitor",
  "-ac", "2",
  "-ar", "48000",
  "-f", "f32le",        // ★ 32bit float
  "-flush_packets", "1",
  "-max_delay", "0",
  "pipe:1"
]);

// ---- WebSocket 送信（大きめチャンクで安定） ----
ffmpeg.stdout.on("data", (chunk) => {
  const size = 16384; // ★ 高音質向け
  for (let i = 0; i < chunk.length; i += size) {
    const slice = chunk.subarray(i, i + size);
    for (const ws of pcmClients) {
      if (ws.readyState === WebSocket.OPEN) {
        ws.send(slice);
      }
    }
  }
});

ffmpeg.stderr.on("data", (data) => {
  console.log("ffmpeg:", data.toString());
});

server.listen(9000, () => {
  console.log("Compare server running on port 9000");
  console.log("PCM page        : /pcm");
  console.log("PCM Worklet page: /pcm-worklet");
  console.log("WebRTC page     : /webrtc");
});