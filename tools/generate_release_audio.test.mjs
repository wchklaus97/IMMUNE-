import assert from "node:assert/strict";
import test from "node:test";

import { encodePcm16Wav, synthesizeReleasePcm } from "./generate_release_audio.mjs";

test("release audio synthesis is deterministic and emits valid PCM WAV files", () => {
  const first = synthesizeReleasePcm();
  const second = synthesizeReleasePcm();
  assert.equal(first.size, 9);
  assert.deepEqual([...first.keys()], [...second.keys()]);
  for (const [path, buffer] of first) {
    assert.deepEqual(buffer, second.get(path), path);
    assert.equal(buffer.subarray(0, 4).toString("ascii"), "RIFF", path);
    assert.equal(buffer.subarray(8, 12).toString("ascii"), "WAVE", path);
    assert.equal(buffer.readUInt32LE(24), 44_100, path);
    assert.ok(buffer.length > 7_000, path);
  }
});

test("WAV encoder rejects mismatched or unsupported channel layouts", () => {
  assert.throws(() => encodePcm16Wav([]), /one or two channels/u);
  assert.throws(() => encodePcm16Wav([new Float64Array(2), new Float64Array(3)]), /matching frame counts/u);
  assert.throws(
    () => encodePcm16Wav([new Float64Array(2), new Float64Array(2), new Float64Array(2)]),
    /one or two channels/u,
  );
});
