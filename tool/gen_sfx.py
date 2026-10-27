"""Regenerates assets/sfx/*.wav (pure Python, no dependencies). Run from the project root: python tool/gen_sfx.py"""
import math, random, struct, wave, os

SR = 22050
random.seed(7)

def synth(segs):
    out = []
    for f0, f1, dur, kind, vol in segs:
        n, ph = int(SR * dur), 0.0
        for i in range(n):
            t = i / n
            ph += 2 * math.pi * (f0 + (f1 - f0) * t) / SR
            if kind == 'sine': s = math.sin(ph)
            elif kind == 'square': s = 0.5 if math.sin(ph) > 0 else -0.5
            elif kind == 'saw': s = 2 * ((ph / (2 * math.pi)) % 1) - 1
            else: s = random.uniform(-1, 1)
            out.append(s * vol * (1 - t) ** 1.5 * min(1, i / (SR * 0.005)))
    return out

def mix(a, b):
    n = max(len(a), len(b))
    a += [0] * (n - len(a)); b += [0] * (n - len(b))
    return [x + y for x, y in zip(a, b)]

def save(name, samples):
    with wave.open(f'assets/sfx/{name}.wav', 'wb') as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes(b''.join(struct.pack('<h', int(max(-1, min(1, s)) * 32000)) for s in samples))

SOUNDS = {
    'bid':   synth([(660, 880, .09, 'square', .25)]),
    'fold':  synth([(300, 150, .18, 'sine', .4)]),
    'gavel': mix(synth([(110, 60, .3, 'sine', .8)]), synth([(0, 0, .08, 'noise', .5)])),
    'win':   synth([(523, 523, .1, 'sine', .4), (659, 659, .1, 'sine', .4), (784, 784, .1, 'sine', .4), (1047, 1047, .25, 'sine', .45)]),
    'curse': mix(synth([(320, 60, .7, 'saw', .35)]), synth([(340, 70, .7, 'saw', .3)])),
    'coin':  synth([(1318, 1318, .07, 'sine', .4), (1760, 1760, .18, 'sine', .4)]),
    'taunt': synth([(150, 110, .25, 'saw', .35)]),
    'charm': synth([(800, 1800, .3, 'sine', .35)]),
    'lose':  synth([(392, 392, .2, 'sine', .4), (311, 311, .2, 'sine', .4), (233, 233, .5, 'sine', .45)]),
}
os.makedirs('assets/sfx', exist_ok=True)
for k, v in SOUNDS.items(): save(k, v)
print('wrote', ', '.join(SOUNDS))
