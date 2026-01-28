class PCMPlayer extends AudioWorkletProcessor {
  constructor() {
    super();
    this.buffer = new Float32Array(0);

    // ★ 300ms 分のバッファ（安定性UP）
    this.maxBuffer = 14400;

    this.port.onmessage = (event) => {
      // ★ ffmpeg が f32le を出すのでそのまま Float32 として受ける
      const float32 = new Float32Array(event.data);

      const totalLen = this.buffer.length + float32.length;
      if (totalLen <= this.maxBuffer) {
        const newBuffer = new Float32Array(totalLen);
        newBuffer.set(this.buffer, 0);
        newBuffer.set(float32, this.buffer.length);
        this.buffer = newBuffer;
      } else {
        const newBuffer = new Float32Array(this.maxBuffer);
        const start = totalLen - this.maxBuffer;
        const merged = new Float32Array(totalLen);
        merged.set(this.buffer, 0);
        merged.set(float32, this.buffer.length);
        newBuffer.set(merged.slice(start));
        this.buffer = newBuffer;
      }
    };
  }

  process(inputs, outputs) {
    const output = outputs[0][0];

    if (this.buffer.length >= output.length) {
      output.set(this.buffer.subarray(0, output.length));
      this.buffer = this.buffer.subarray(output.length);
    } else {
      output.fill(0);
    }

    return true;
  }
}

registerProcessor("pcm-player", PCMPlayer);