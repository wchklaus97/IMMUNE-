#!/usr/bin/env node

import { createHash } from "node:crypto";
import { spawnSync } from "node:child_process";
import { mkdir, readFile, writeFile } from "node:fs/promises";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const ROOT = dirname(dirname(fileURLToPath(import.meta.url)));
const SAMPLE_RATE = 44_100;
const TAU = Math.PI * 2;
const MUSIC_SECONDS = 8;
const AUDIO_ROOT = join(ROOT, "godot/immune/audio");

export const EXPECTED_AUDIO_HASHES = {
  "music/immune_pulse.ogg": "1daba74fd27ac64db650cda112689ac5b5a9ea4776a5d56b0f71b6d5474de3a4",
  "sfx/core_hit.wav": "41ae39ffb58e7fe3e1117cccb9d6e3c99afc790e0335b8d1e98e4f36cc81c5fe",
  "sfx/defeat.wav": "ed52b15f1e95df443c13a02ca183d8d83d6b046b0ffd86bfcbc9ade2b01bf06a",
  "sfx/duty.wav": "b17e5aedf0a2629b4b90fbc3f1e22111983fce75f8bf276f69e88a9b968acbbe",
  "sfx/hit.wav": "fc53b90d36baf9fb1a16c4f9695a025fd54c4670e6cd0fbeacbde9d24949405a",
  "sfx/phase.wav": "881510d74cb039475d0fcd0e943201eb11c4d597f2b0a3f08b62969f1d631d66",
  "sfx/shot.wav": "1c653efcd6c960650ed7332f33aabfe83baf02f76401287ac67ac70b04c6237c",
  "sfx/ui.wav": "2a0c5878e276e1f8be32e3ae3991913ceefce8787e9e0fd02bd767ceedd427e5",
  "sfx/victory.wav": "d62dc33fa149114e75052ef6c11f77356a783510ee17c08d68bcc91b3340e963",
};

const SFX_SPECS = {
  "sfx/shot.wav": { seconds: 0.08, seed: 11, synth: synthShot },
  "sfx/hit.wav": { seconds: 0.12, seed: 23, synth: synthHit },
  "sfx/core_hit.wav": { seconds: 0.22, seed: 37, synth: synthCoreHit },
  "sfx/phase.wav": { seconds: 0.365, seed: 41, synth: synthPhase },
  "sfx/duty.wav": { seconds: 0.18, seed: 53, synth: synthDuty },
  "sfx/victory.wav": { seconds: 0.75, seed: 67, synth: synthVictory },
  "sfx/defeat.wav": { seconds: 0.8, seed: 79, synth: synthDefeat },
  "sfx/ui.wav": { seconds: 0.09, seed: 83, synth: synthUi },
};

function clamp(value, low = -1, high = 1) {
  return Math.min(high, Math.max(low, value));
}

function hashNoise(index, seed) {
  let value = (index + Math.imul(seed, 374_761_393)) | 0;
  value = Math.imul(value ^ (value >>> 13), 1_274_126_177);
  value ^= value >>> 16;
  return ((value >>> 0) / 4_294_967_295) * 2 - 1;
}

function edgeFade(t, duration, fadeSeconds = 0.004) {
  return clamp(Math.min(t / fadeSeconds, (duration - t) / fadeSeconds), 0, 1);
}

function chirp(t, startHz, endHz, duration, phase = 0) {
  const sweep = (endHz - startHz) / duration;
  return Math.sin(TAU * (startHz * t + 0.5 * sweep * t * t) + phase);
}

function noteEnvelope(t, start, duration, attack = 0.008, decay = 7) {
  const local = t - start;
  if (local < 0 || local >= duration) return 0;
  return Math.min(1, local / attack) * Math.exp(-decay * local / duration);
}

function synthShot(t, duration, index, seed) {
  const env = Math.exp(-32 * t) * edgeFade(t, duration, 0.0025);
  return env * (0.72 * chirp(t, 1_080, 310, duration) + 0.18 * hashNoise(index, seed));
}

function synthHit(t, duration, index, seed) {
  const env = Math.exp(-22 * t) * edgeFade(t, duration);
  return env * (
    0.58 * chirp(t, 190, 72, duration)
    + 0.24 * Math.sin(TAU * 95 * t)
    + 0.16 * hashNoise(index, seed)
  );
}

function synthCoreHit(t, duration, index, seed) {
  const env = Math.exp(-12 * t) * edgeFade(t, duration);
  const body = 0.58 * chirp(t, 125, 48, duration) + 0.22 * Math.sin(TAU * 62.5 * t);
  const crack = 0.16 * hashNoise(index, seed) * Math.exp(-45 * t);
  return env * body + crack * edgeFade(t, duration, 0.002);
}

function synthPhase(t, duration) {
  const env = Math.sin(Math.PI * t / duration) ** 0.7;
  return env * (
    0.45 * chirp(t, 210, 1_180, duration)
    + 0.24 * chirp(t, 420, 1_760, duration, Math.PI / 3)
    + 0.12 * Math.sin(TAU * 90 * t)
  );
}

function synthDuty(t, duration) {
  const env = edgeFade(t, duration) * Math.exp(-7 * t);
  const second = noteEnvelope(t, 0.075, 0.105, 0.005, 4);
  return 0.58 * env * Math.sin(TAU * 392 * t) + 0.45 * second * Math.sin(TAU * 659.25 * t);
}

function synthVictory(t, duration) {
  const notes = [523.25, 659.25, 783.99, 1_046.5];
  let sample = 0;
  for (let i = 0; i < notes.length; i += 1) {
    const start = i * 0.135;
    const env = noteEnvelope(t, start, duration - start, 0.006, 3.8);
    sample += env * (0.34 * Math.sin(TAU * notes[i] * (t - start))
      + 0.1 * Math.sin(TAU * notes[i] * 2 * (t - start)));
  }
  return sample * edgeFade(t, duration);
}

function synthDefeat(t, duration) {
  const notes = [329.63, 277.18, 220, 164.81];
  let sample = 0;
  for (let i = 0; i < notes.length; i += 1) {
    const start = i * 0.16;
    const env = noteEnvelope(t, start, duration - start, 0.012, 2.8);
    sample += env * (0.32 * Math.sin(TAU * notes[i] * (t - start))
      + 0.09 * Math.sin(TAU * notes[i] * 0.5 * (t - start)));
  }
  return sample * edgeFade(t, duration, 0.008);
}

function synthUi(t, duration) {
  const env = Math.exp(-38 * t) * edgeFade(t, duration, 0.0025);
  return env * (0.65 * Math.sin(TAU * 880 * t) + 0.18 * Math.sin(TAU * 1_320 * t));
}

function normalize(channels, peakTarget = 0.86) {
  let peak = 0;
  for (const channel of channels) {
    for (const value of channel) peak = Math.max(peak, Math.abs(value));
  }
  const gain = peak > peakTarget ? peakTarget / peak : 1;
  return channels.map((channel) => channel.map((value) => clamp(value * gain)));
}

function synthesizeMono({ seconds, seed, synth }) {
  const frames = Math.round(seconds * SAMPLE_RATE);
  const samples = new Float64Array(frames);
  for (let index = 0; index < frames; index += 1) {
    samples[index] = synth(index / SAMPLE_RATE, seconds, index, seed);
  }
  return normalize([samples]);
}

function synthesizeMusic() {
  const frames = MUSIC_SECONDS * SAMPLE_RATE;
  const left = new Float64Array(frames);
  const right = new Float64Array(frames);
  const melody = [220, 275, 330, 440, 330, 275, 247.5, 330, 220, 330, 440, 550, 440, 330, 275, 247.5];
  for (let index = 0; index < frames; index += 1) {
    const t = index / SAMPLE_RATE;
    const beatPhase = t % 0.5;
    const beatIndex = Math.floor(t / 0.5) % melody.length;
    const pulse = Math.exp(-8 * (t % 1)) * Math.sin(TAU * 55 * t);
    const attack = Math.min(1, beatPhase / 0.012);
    const pluckEnv = attack * Math.exp(-7.5 * beatPhase);
    const pluck = pluckEnv * Math.sin(TAU * melody[beatIndex] * t);
    const breathing = 0.72 + 0.28 * Math.sin(TAU * 0.125 * t - Math.PI / 2);
    const padL = breathing * (0.16 * Math.sin(TAU * 110 * t) + 0.08 * Math.sin(TAU * 165 * t + 0.4));
    const padR = breathing * (0.16 * Math.sin(TAU * 110 * t + 0.16) + 0.08 * Math.sin(TAU * 220 * t + 0.75));
    left[index] = padL + 0.17 * pulse + 0.19 * pluck;
    right[index] = padR + 0.15 * pulse + 0.19 * pluck;
  }
  left[frames - 1] = left[0];
  right[frames - 1] = right[0];
  return normalize([left, right], 0.8);
}

export function encodePcm16Wav(channels, sampleRate = SAMPLE_RATE) {
  if (!Array.isArray(channels) || channels.length < 1 || channels.length > 2) {
    throw new Error("WAV requires one or two channels");
  }
  const frames = channels[0].length;
  if (!channels.every((channel) => channel.length === frames)) {
    throw new Error("WAV channels must have matching frame counts");
  }
  const blockAlign = channels.length * 2;
  const dataBytes = frames * blockAlign;
  const buffer = Buffer.alloc(44 + dataBytes);
  buffer.write("RIFF", 0, "ascii");
  buffer.writeUInt32LE(36 + dataBytes, 4);
  buffer.write("WAVEfmt ", 8, "ascii");
  buffer.writeUInt32LE(16, 16);
  buffer.writeUInt16LE(1, 20);
  buffer.writeUInt16LE(channels.length, 22);
  buffer.writeUInt32LE(sampleRate, 24);
  buffer.writeUInt32LE(sampleRate * blockAlign, 28);
  buffer.writeUInt16LE(blockAlign, 32);
  buffer.writeUInt16LE(16, 34);
  buffer.write("data", 36, "ascii");
  buffer.writeUInt32LE(dataBytes, 40);
  let cursor = 44;
  for (let frame = 0; frame < frames; frame += 1) {
    for (const channel of channels) {
      const value = clamp(channel[frame]);
      buffer.writeInt16LE(Math.round(value * (value < 0 ? 32_768 : 32_767)), cursor);
      cursor += 2;
    }
  }
  return buffer;
}

export function synthesizeReleasePcm() {
  const assets = new Map();
  for (const [path, spec] of Object.entries(SFX_SPECS)) {
    assets.set(path, encodePcm16Wav(synthesizeMono(spec)));
  }
  assets.set("music/immune_pulse.source.wav", encodePcm16Wav(synthesizeMusic()));
  return assets;
}

function sha256(buffer) {
  return createHash("sha256").update(buffer).digest("hex");
}

async function writeAssets() {
  const generated = synthesizeReleasePcm();
  for (const [path, buffer] of generated) {
    if (path.endsWith(".source.wav")) continue;
    const target = join(AUDIO_ROOT, path);
    await mkdir(dirname(target), { recursive: true });
    await writeFile(target, buffer);
  }
  const musicSource = generated.get("music/immune_pulse.source.wav");
  const musicTarget = join(AUDIO_ROOT, "music/immune_pulse.ogg");
  const encoders = spawnSync("ffmpeg", ["-hide_banner", "-encoders"], {
    encoding: "utf8",
    maxBuffer: 8 * 1024 * 1024,
  });
  if (encoders.status !== 0) throw new Error("ffmpeg is required to encode release music");
  const encoderListing = `${encoders.stdout ?? ""}\n${encoders.stderr ?? ""}`;
  const encoder = /\blibvorbis\b/u.test(encoderListing) ? "libvorbis" : /\bvorbis\b/u.test(encoderListing) ? "vorbis" : "";
  if (!encoder) throw new Error("ffmpeg has no Vorbis encoder; refusing to create a mislabeled release track");
  const encoderOptions = encoder === "vorbis" ? ["-strict", "experimental"] : [];
  const ffmpeg = spawnSync("ffmpeg", [
    "-v", "error", "-y", "-f", "wav", "-i", "pipe:0",
    "-map_metadata", "-1", "-fflags", "+bitexact", "-flags:a", "+bitexact",
    "-c:a", encoder, ...encoderOptions, "-q:a", "5", "-serial_offset", "0", musicTarget,
  ], { input: musicSource, encoding: null, maxBuffer: 8 * 1024 * 1024 });
  if (ffmpeg.status !== 0) {
    throw new Error(`ffmpeg failed to encode release music: ${ffmpeg.stderr?.toString("utf8") ?? "unknown error"}`);
  }
  const results = {};
  for (const path of Object.keys(EXPECTED_AUDIO_HASHES)) {
    results[path] = sha256(await readFile(join(AUDIO_ROOT, path)));
  }
  return { results, musicSourceSha256: sha256(musicSource) };
}

async function checkAssets() {
  const errors = [];
  for (const [path, expected] of Object.entries(EXPECTED_AUDIO_HASHES)) {
    const actual = sha256(await readFile(join(AUDIO_ROOT, path)));
    if (actual !== expected) errors.push(`${path}: expected ${expected}, got ${actual}`);
  }
  if (errors.length) throw new Error(`RELEASE_AUDIO_DRIFT\n- ${errors.join("\n- ")}`);
  return Object.keys(EXPECTED_AUDIO_HASHES).length;
}

async function main() {
  const args = process.argv.slice(2);
  if (args.length !== 1 || !["--write", "--check"].includes(args[0])) {
    throw new Error("Usage: node tools/generate_release_audio.mjs --write|--check");
  }
  if (args[0] === "--write") {
    const report = await writeAssets();
    console.log(`RELEASE_AUDIO_WRITTEN assets=${Object.keys(report.results).length} source_sha256=${report.musicSourceSha256}`);
    for (const [path, digest] of Object.entries(report.results)) console.log(`${digest}  ${path}`);
  } else {
    console.log(`RELEASE_AUDIO_OK assets=${await checkAssets()}`);
  }
}

if (process.argv[1] && fileURLToPath(import.meta.url) === resolve(process.argv[1])) {
  main().catch((error) => {
    console.error(error instanceof Error ? error.message : String(error));
    process.exitCode = 1;
  });
}
