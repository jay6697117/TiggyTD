import math
import wave
import struct
import os
import random

# 配置输出路径
PROJECT_ROOT = os.path.dirname(os.path.abspath(__file__))
BGM_DIR = os.path.join(PROJECT_ROOT, "src", "assets", "audio", "bgm")
SFX_DIR = os.path.join(PROJECT_ROOT, "src", "assets", "audio", "sfx")

os.makedirs(BGM_DIR, exist_ok=True)
os.makedirs(SFX_DIR, exist_ok=True)

# 音频合成核心
def generate_wav(filepath, duration, wave_func, sample_rate=44100):
    n_samples = int(sample_rate * duration)
    with wave.open(filepath, 'w') as f:
        f.setnchannels(1)  # 单声道
        f.setsampwidth(2)  # 16-bit
        f.setframerate(sample_rate)

        frames = bytearray()
        for i in range(n_samples):
            t = i / sample_rate
            value = wave_func(t)

            # Anti-popping (淡入淡出封套)
            env = 1.0
            if t < 0.01: env = t / 0.01
            if duration - t < 0.02: env = max(0, (duration - t) / 0.02)

            value *= env
            value = max(-1.0, min(1.0, value))
            sample = int(value * 32767.0)
            frames.extend(struct.pack('<h', sample))

        f.writeframes(frames)
    print(f"✅ Generated: {filepath}")

# ----- 波形生成器 (8-bit 风格) -----

def square_wave(freq, t):
    return 0.5 if math.sin(2 * math.pi * freq * t) > 0 else -0.5

def noise():
    return random.uniform(-1.0, 1.0)

def arp(t, notes, speed):
    idx = int(t * speed) % len(notes)
    freq = 440.0 * (2.0 ** ((notes[idx] - 69) / 12.0))
    return square_wave(freq, t)

# ----- SFX 逻辑 -----

sfx_list = {
    "hit_normal.wav": (0.1, lambda t: noise() * math.exp(-30*t)),
    "hit_crit.wav": (0.3, lambda t: (noise() + square_wave(50, t)) * math.exp(-15*t)),
    "base_damage.wav": (0.8, lambda t: (square_wave(200 - 150*t, t) * 0.5 + noise()*0.5) * math.exp(-3*t)),
    "boss_appear.wav": (2.0, lambda t: math.sin(2 * math.pi * 50 * t) * min(1, t/0.5) * math.exp(-0.5*t) + noise()*0.1),
    "boss_death.wav": (2.5, lambda t: noise() * (1 - t/2.5)**2),
    "skill_apex_roar.wav": (0.8, lambda t: square_wave(60 + math.sin(t*30)*20, t) * math.exp(-3*t)),
    "skill_natures_call.wav": (1.0, lambda t: math.sin(2*math.pi * (400 + max(0, 1000 - t*1000)) * t) * math.exp(-2*t)),
    "skill_era_judgement.wav": (1.5, lambda t: square_wave(2000 * math.exp(-4*t), t) * math.exp(-2*t)),
    "ui_click.wav": (0.05, lambda t: square_wave(1200, t) * math.exp(-50*t)),
    "ui_buy.wav": (0.2, lambda t: math.sin(2*math.pi * (600 if t < 0.1 else 800) * t)),
    "gold_gain.wav": (0.15, lambda t: square_wave(1000 if t<0.05 else 1500, t) * math.exp(-10*t)),
    "tower_place.wav": (0.1, lambda t: (square_wave(100, t) + noise()*0.5) * math.exp(-20*t)),
    "tower_upgrade.wav": (0.4, lambda t: math.sin(2*math.pi * (440 + int(t*10)*100) * t) * math.exp(-5*t)),
    "skill_ready.wav": (0.4, lambda t: math.sin(2*math.pi*880*t) * math.exp(-10*t)),
    "enemy_death.wav": (0.2, lambda t: noise() * math.exp(-15*t)),
    "synergy_activate.wav": (0.8, lambda t: square_wave(220 + t*500, t) * math.exp(-2*t)),
    "wave_start.wav": (1.5, lambda t: square_wave(440 + math.sin(2*math.pi*4*t)*100, t) * math.exp(-t)),
    "level_up.wav": (0.8, lambda t: arp(t, [60, 64, 67, 72], 10) * math.exp(-t)),
}

# ----- BGM 逻辑 (较长，带简单循环) -----

bgm_list = {
    # 菜单：欢快 C大调和弦分解
    "menu.wav": (4.0, lambda t: (arp(t, [60, 64, 67, 72, 60, 64, 67, 72], 4) * 0.3)),
    # 建造：简单的节拍 (低频鼓点 + 中频方波)
    "build.wav": (2.0, lambda t: (square_wave(100, t) if (t*4)%1 < 0.2 else 0) * 0.4 + (square_wave(440, t) if (t*8)%1 < 0.5 else 0) * 0.1),
    # 战斗：快速小调下行
    "battle.wav": (2.0, lambda t: arp(t, [72, 68, 65, 60, 71, 67, 63, 59], 8) * 0.3),
    # Boss：沉重极速方波低音 + 噪音鼓
    "boss.wav": (2.0, lambda t: square_wave(50, t) * 0.5 + (noise() * 0.4 if (t*8)%1 < 0.3 else 0)),
    # 胜利：激昂的进行曲上升
    "victory.wav": (3.0, lambda t: arp(t, [60, 60, 67, 67, 72, 72, 76, 76], 4) * min(1, 3 - t) * 0.4),
    # 失败：下行减速
    "defeat.wav": (3.0, lambda t: arp(t, [72, 67, 63, 60, 55, 51, 48, 43], 3/(1+t)) * min(1, 3-t) * 0.4),
}

print("🎶 开始生成 TiggyTD 的复古 8-bit 音效和音乐...")

for f_name, (dur, func) in sfx_list.items():
    generate_wav(os.path.join(SFX_DIR, f_name), dur, func)

for f_name, (dur, func) in bgm_list.items():
    generate_wav(os.path.join(BGM_DIR, f_name), dur, func)

print("🎉 全部 24 个音频文件生成完毕！完全零外部依赖的代码魔法！")
