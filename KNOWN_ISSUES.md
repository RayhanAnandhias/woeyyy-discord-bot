# Known Issues

This document tracks known limitations, historical investigations, and environment-specific behaviors.

---

### [RESOLVED] Audio Hitching on Solitary Acoustic Piano Intros (e.g. Ms.OOJA - 「Hidamari」)

#### Symptoms
During the intro (seconds 0–5) of tracks featuring isolated, high-transient instruments separated by silence or sparse decay (specifically tested with **Ms.OOJA - 「Hidamari」**), audible hitching, pops, and stuttering occurred on every solitary piano note attack (at ~0.38s, ~1.50s, ~2.60s, ~3.32s, ~4.44s).

Interestingly:
- The issue occurred on **Windows (Local host)** and **Oracle Cloud VM (Linux)**.
- The issue **did NOT occur on AWS Linux VMs**.
- Dense tracks with continuous instrumentation (drums, bass, continuous vocals) never experienced this issue.

#### Root Cause Identified
Through empirical audio pipeline isolation (`direct_ffmpeg.wav` vs `step4_opus.wav` vs `ffmpeg_libopus_decoded.wav`), the issue was isolated directly to **`discord.py`'s Opus encoder on Windows**:

1. **Legacy `libopus 1.3.1` Transient Analysis Bug**:
   On Windows, `discord.py` automatically loaded an ancient binary bundled inside the package: `discord\bin\libopus-0.x64.dll` (`libopus 1.3.1-18-g923bebde-dirty-fixed`, released in 2019).
   In Opus 1.3.1, the psychoacoustic transient detector had a known flaw on solitary acoustic attacks following silence:
   - At Frame 130 (~2.60s piano attack), input amplitude was **15,147**.
   - `libopus 1.3.1` crushed the attack down to **3,899** (a 75% drop!).
   - In Frame 131, the energy compensation violently exploded to **21,879** (a +44% overshoot surge!).
   - This sudden envelope crushing and overshoot surge produced an audible click/pop/hitch on every piano attack.

2. **Why AWS Linux Was Unaffected**:
   AWS deployments used the host Linux distribution's system `libopus.so.0` (modern version >= 1.4/1.5+), which features the completely overhauled transient detection and psychoacoustic engine that preserves solitary note attacks faithfully.

#### Resolution
- **Bundled Modern `libopus 1.6.1` Across Platforms**: Placed official precompiled `libopus 1.6.1` binaries in the project's `bin/` directory:
  - `bin/libopus-0.x64.dll` (Windows x64)
  - `bin/libopus-linux-x64.so` (Linux x86_64, e.g. Oracle Cloud AMD/Intel instances)
  - `bin/libopus-linux-arm64.so` (Linux aarch64, e.g. Oracle Cloud Ampere A1 ARM instances)
  - `bin/libopus-osx-arm64.dylib` (macOS Apple Silicon M1/M2/M3/M4)
  - `bin/libopus-osx-x64.dylib` (macOS Intel)
- **Eager & Prioritized Loading in `engine/discord_bot.py`**:
  `ensure_opus_loaded()` detects the host OS and CPU architecture, prioritizes the appropriate bundled modern binary in `bin/`, and verifies the loaded version $\ge 1.4$. If the system package is the legacy 1.3.1 build (common on Ubuntu 20.04/22.04 LTS), it automatically upgrades to 1.6.1.
- **Verification**: Under Opus 1.6.1, Frame 130/131 attacks match the input within 4% amplitude (15,147 in $\rightarrow$ 15,857 out) with zero overshoot surge, producing clean, smooth, hitch-free playback.
