#!/usr/bin/env python3
"""Generate USBChime built-in sounds as 16-bit mono WAV files (44100 Hz).
Pure stdlib — no dependencies. Output: Resources/sounds/*.wav
"""
import math
import os
import struct
import wave

SR = 44100
OUT_DIR = os.path.join(os.path.dirname(__file__), "..", "Sources", "Resources")


def synth(samples):
    """samples: list of floats in [-1, 1] → 16-bit mono WAV bytes."""
    frames = bytearray()
    for s in samples:
        v = max(-1.0, min(1.0, s))
        frames += struct.pack("<h", int(v * 32767))
    return bytes(frames)


def tone(freq, dur, amp=0.5, attack=0.008, release=0.05):
    """A single sine tone with click-free attack/release envelopes."""
    n = int(SR * dur)
    out = []
    for i in range(n):
        t = i / SR
        env = 1.0
        if t < attack:
            env = t / attack
        if t > dur - release:
            env = max(0.0, (dur - t) / release)
        out.append(amp * env * math.sin(2 * math.pi * freq * t))
    return out


def mix(*tracks):
    """Overlay tracks sample-aligned with linear fade between segments."""
    length = max(len(t) for t in tracks)
    out = [0.0] * length
    for track in tracks:
        for i, v in enumerate(track):
            out[i] += v
    return out


def concat(*tracks):
    out = []
    for t in tracks:
        out.extend(t)
    return out


def pad(track, seconds):
    return [0.0] * int(SR * seconds) + track


def normalize(track, peak=0.9):
    m = max(abs(v) for v in track) or 1.0
    k = peak / m
    return [v * k for v in track]


def write_wav(name, samples):
    os.makedirs(OUT_DIR, exist_ok=True)
    path = os.path.join(OUT_DIR, name)
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(synth(samples))
    print(f"  {name}  ({len(samples)/SR:.2f}s)")


def main():
    # Windows connect: two quick rising notes (E5 → A5), slight overlap
    connect = normalize(
        mix(
            pad(tone(659.25, 0.16, amp=0.55), 0.01),   # E5
            pad(tone(880.0, 0.22, amp=0.60), 0.13),    # A5
        ),
        peak=0.85,
    )
    write_wav("windows_connect.wav", connect)

    # Windows disconnect: the reverse — falling notes (A5 → E5)
    disconnect = normalize(
        mix(
            pad(tone(880.0, 0.22, amp=0.60), 0.01),    # A5
            pad(tone(659.25, 0.16, amp=0.55), 0.14),   # E5
        ),
        peak=0.85,
    )
    write_wav("windows_disconnect.wav", disconnect)

    # Soft chime: gentle rising C6 → E6, slower, quieter
    soft = normalize(
        mix(
            pad(tone(1046.5, 0.25, amp=0.35), 0.02),   # C6
            pad(tone(1318.5, 0.35, amp=0.38), 0.18),   # E6
        ),
        peak=0.55,
    )
    write_wav("soft.wav", soft)

    # Pop: one short bright thump
    pop = normalize(tone(950.0, 0.09, amp=0.5, attack=0.004, release=0.06), peak=0.7)
    write_wav("pop.wav", pop)

    # Blip: two quick high beeps (like a sonar ping)
    blip = normalize(
        concat(
            tone(1567.98, 0.07, amp=0.45, attack=0.004, release=0.04),  # G6
            pad(tone(1567.98, 0.07, amp=0.45, attack=0.004, release=0.04), 0.05),
        ),
        peak=0.6,
    )
    write_wav("blip.wav", blip)


if __name__ == "__main__":
    main()
