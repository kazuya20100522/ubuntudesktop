class PCMPlayer extends AudioWorkletProcessor {
  constructor() {
    super();
    this.channels = 2;

    // 48kHz × 0.15秒 × 2ch = 14400 サンプル
    this.maxBuffer = 48000 * 0.15 * this.channels;
    this.buffer = new Float32Array(0);

    this.port.onmessage = (event) => {
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
    const outputL = outputs[0][0];
    const outputR = outputs[0][1];
    const frameSize = outputL.length;

    if (this.buffer.length >= frameSize * this.channels) {
      for (let i = 0; i < frameSize; i++) {
        const base = i * this.channels;
        outputL[i] = this.buffer[base];
        outputR[i] = this.buffer[base + 1];
      }
      this.buffer = this.buffer.subarray(frameSize * this.channels);
    } else {
      outputL.fill(0);
      outputR.fill(0);
    }

    return true;
  }
}

registerProcessor("pcm-player", PCMPlayer);
