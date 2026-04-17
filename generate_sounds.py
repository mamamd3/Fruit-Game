import wave
import math
import struct
import random
import os

SAMPLE_RATE = 44100

def save_wav(filename, samples):
    os.makedirs(os.path.dirname(filename), exist_ok=True)
    with wave.open(filename, 'w') as wav_file:
        wav_file.setnchannels(1)
        wav_file.setsampwidth(2)
        wav_file.setframerate(SAMPLE_RATE)
        for sample in samples:
            # Clamp sample to [-1.0, 1.0]
            s = max(-1.0, min(1.0, sample))
            wav_file.writeframes(struct.pack('h', int(s * 32767.0)))

def generate_shoot():
    samples = []
    duration = 0.15
    for i in range(int(SAMPLE_RATE * duration)):
        t = i / SAMPLE_RATE
        # Envelope: fast attack, exponential decay
        env = math.exp(-t * 20)
        # Pitch drop
        freq = 800 - 4000 * t
        freq = max(100, freq)
        # Square wave
        val = 1.0 if math.sin(2 * math.pi * freq * t) > 0 else -1.0
        samples.append(val * env * 0.3)
    return samples

def generate_jump():
    samples = []
    duration = 0.2
    for i in range(int(SAMPLE_RATE * duration)):
        t = i / SAMPLE_RATE
        env = 1.0 - (t / duration)
        freq = 300 + 1000 * t
        val = 1.0 if math.sin(2 * math.pi * freq * t) > 0 else -1.0
        samples.append(val * env * 0.3)
    return samples

def generate_hit():
    samples = []
    duration = 0.1
    for i in range(int(SAMPLE_RATE * duration)):
        t = i / SAMPLE_RATE
        env = math.exp(-t * 30)
        val = random.uniform(-1.0, 1.0)
        samples.append(val * env * 0.4)
    return samples

def generate_death():
    samples = []
    duration = 0.8
    for i in range(int(SAMPLE_RATE * duration)):
        t = i / SAMPLE_RATE
        env = 1.0 - (t / duration)
        freq = 200 - 150 * t
        freq = max(20, freq)
        # Noise mixed with saw
        val = (t * freq % 1.0) * 2.0 - 1.0
        noise = random.uniform(-1.0, 1.0) * 0.5
        samples.append((val + noise) * env * 0.4)
    return samples

def generate_ui_click():
    samples = []
    duration = 0.05
    for i in range(int(SAMPLE_RATE * duration)):
        t = i / SAMPLE_RATE
        env = 1.0 - (t / duration)
        freq = 600
        val = math.sin(2 * math.pi * freq * t)
        samples.append(val * env * 0.4)
    return samples

def generate_melee():
    samples = []
    duration = 0.15
    for i in range(int(SAMPLE_RATE * duration)):
        t = i / SAMPLE_RATE
        env = math.sin(t / duration * math.pi)
        val = random.uniform(-1.0, 1.0)
        # Lowpass filter effect simulated by just using lower frequency noise or smoothing, we just do white noise + envelope
        samples.append(val * env * 0.3)
    return samples

def generate_bgm():
    # Simple 4-bar loop, 120 BPM, 4/4 time. 1 beat = 0.5s. Bar = 2.0s. Loop = 8.0s
    samples = []
    duration = 8.0
    bpm = 120
    beat_time = 60.0 / bpm
    
    notes = [
        # Bar 1
        (440.0, 0.0, 0.25), (440.0, 0.5, 0.25), (523.25, 1.0, 0.25), (587.33, 1.5, 0.25),
        # Bar 2
        (659.25, 2.0, 0.5), (587.33, 2.5, 0.5), (523.25, 3.0, 0.25), (440.0, 3.5, 0.25),
        # Bar 3
        (349.23, 4.0, 0.25), (349.23, 4.5, 0.25), (440.0, 5.0, 0.25), (523.25, 5.5, 0.25),
        # Bar 4
        (587.33, 6.0, 0.5), (659.25, 6.5, 0.5), (523.25, 7.0, 0.5), (440.0, 7.5, 0.5)
    ]
    
    bass_notes = [
        (220.0, 0.0, 1.0), (174.61, 2.0, 1.0), (130.81, 4.0, 1.0), (146.83, 6.0, 1.0)
    ]
    
    for i in range(int(SAMPLE_RATE * duration)):
        t = i / SAMPLE_RATE
        val = 0.0
        
        # Melody
        for freq, start, length in notes:
            if start <= t < start + length:
                local_t = t - start
                env = math.exp(-local_t * 5)
                # Triangle wave
                osc = 2.0 * abs(2.0 * (local_t * freq - math.floor(local_t * freq + 0.5))) - 1.0
                val += osc * env * 0.15
        
        # Bass
        for freq, start, length in bass_notes:
            if start <= t < start + length:
                local_t = t - start
                env = 1.0 if local_t < length * 0.9 else 0.0
                # Square wave
                osc = 1.0 if math.sin(2 * math.pi * freq * local_t) > 0 else -1.0
                val += osc * env * 0.1
                
        # Drums (kick and hihat)
        kick_interval = 0.5
        hihat_interval = 0.25
        
        kick_t = t % kick_interval
        if kick_t < 0.1:
            val += math.sin(2 * math.pi * (100 - 800 * kick_t) * kick_t) * math.exp(-kick_t * 30) * 0.3
            
        hihat_t = t % hihat_interval
        if hihat_t < 0.05:
            val += random.uniform(-1.0, 1.0) * math.exp(-hihat_t * 50) * 0.05
            
        samples.append(val)
        
    return samples

if __name__ == "__main__":
    out_dir = "assets/audio"
    print(f"Generating sounds in {out_dir}...")
    save_wav(f"{out_dir}/shoot.wav", generate_shoot())
    save_wav(f"{out_dir}/jump.wav", generate_jump())
    save_wav(f"{out_dir}/hit.wav", generate_hit())
    save_wav(f"{out_dir}/death.wav", generate_death())
    save_wav(f"{out_dir}/ui_click.wav", generate_ui_click())
    save_wav(f"{out_dir}/melee.wav", generate_melee())
    save_wav(f"{out_dir}/bgm.wav", generate_bgm())
    print("Done!")
