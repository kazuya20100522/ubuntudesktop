class PCMPlayer extends AudioWorkletProcessor {
  constructor() {
    super();
    this.buffer = new Float32Array(0);

    // 300ms × 2ch
    this.maxBuffer = 48000 * 0.3 * 2;
    this.channels = 2;

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

    if (this.buffer.length >= frameSize * 2) {
      for (let i = 0; i < frameSize; i++) {
        outputL[i] = this.buffer[i * 2];
        outputR[i] = this.buffer[i * 2 + 1];
      }
      this.buffer = this.buffer.subarray(frameSize * 2);
    } else {
      outputL.fill(0);
      outputR.fill(0);
    }

    return true;
  }
}

registerProcessor("pcm-player", PCMPlayer);
