# IMMUNE v0.4.0 local Steam build candidate

Built: 2026-09-01

This record describes the local repository candidate containing this file. It
is not a Steam upload, a public release, or Valve approval. The build used the
official signed Godot `4.7.2.stable.official.ed1daf0bf` editor and matching
export templates. Steam staging used synthetic identifiers, retained
`preview=1`, and performed no login or upload.

## SHA-256 and byte size

| Artifact | Bytes | SHA-256 |
| --- | ---: | --- |
| `IMMUNE-windows.exe` | 109245952 | `198e8e41c131937abf58676e18de522a6612a96885309512609036ec994c2832` |
| `IMMUNE-windows.pck` | 76176380 | `c10f2eb6ae75b3925a226713e8e55e3121cb50717338958bc75b01460a984608` |
| `IMMUNE-linux.x86_64` | 73519416 | `d9f79ab89b5ae369aeed11c6052d402e8218cd503bf85b4a235f9c30c46a7c63` |
| `IMMUNE-linux.pck` | 76176380 | `c10f2eb6ae75b3925a226713e8e55e3121cb50717338958bc75b01460a984608` |
| `IMMUNE-macOS.zip` | 135046555 | `eba5f706dde86d3bab073073402b9fa2b25dd917e688daf052819b14897d71c4` |
| `web/index.html` | 5438 | `ff78c5c3538f35628febd6a35c98c3f9648b568f190cb5986d7db49c36fe3594` |
| `web/index.js` | 279815 | `33c94cb3175f3333b82e2a3be5e8e86f77986f0aa2042b1631f6367a4e5bb6ba` |
| `web/index.pck` | 76176380 | `c10f2eb6ae75b3925a226713e8e55e3121cb50717338958bc75b01460a984608` |
| `web/index.wasm` | 39514754 | `fc74679e3b97f76878947fcd4fbe1268cbfa6188182a2e33bbc3f5dc9bfa57d0` |
| `web/index.audio.worklet.js` | 7298 | `5b476a9c9ce642c0ee4256436d1bc31d9c38f868aca0f9a8e2a57c18d2dec2a3` |
| `web/index.audio.position.worklet.js` | 2973 | `be33985bc7160d6bf9646f259cd86b259cd67b02ccb297ee5c44f8ac84327bc8` |

## Verified locally

- Four export presets and every required artifact pass
  `validate_release_contract.mjs`.
- Windows is an x86-64 PE executable; Linux is an x86-64 ELF executable; Web
  contains a valid WebAssembly module.
- The macOS ZIP expands to a universal arm64+x86_64 app with bundle identifier
  `com.wchklaus97.immune`, version `0.4.0`, an ICNS icon, a valid ad-hoc
  signature, and `RELEASE_SMOKE_OK platform=macOS nodes=200`.
- Exported-Web QA passes the full research/mission/combat/duty/Pause flow at
  120.003 mean / 106.383 p05 FPS on Metal and 13.469 / 9.940 under the explicit
  4x CPU + SwiftShader compatibility profile. The latter is not a real
  lower-end-hardware benchmark.
- Synthetic Steam staging expands/copies all three native depots, rejects
  links and unsafe ZIP paths, records checksums for 13 content files, renders
  preview VDFs, and reports `upload_performed=false`.

## Not yet verified or authorized

- The exact candidate has not run natively on Windows or Linux. Their headers,
  sidecars, sizes, checksums, and staging permissions pass locally; launch
  evidence requires those operating systems or an authorized remote CI push.
- The macOS app is ad-hoc signed, not Developer ID signed or notarized.
- No real Steam App/depot IDs, Steamworks SDK, account credentials, upload,
  private-branch install, review submission, or public release were used.
