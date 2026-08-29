# IMMUNE six-family human playtest

This campaign collects real, anonymous, local-only player evidence for the six
base-cell families. Automation already proves that the demo loads and that the
combat loop can complete. This campaign asks the questions automation cannot:
Are the families distinct, are controls and combat readable, does the jelly art
communicate clearly, and would a player choose to replay?

## Evidence boundary

- Raw reports stay under ignored local `outputs/` folders.
- The offline form makes no network requests and does not auto-save answers.
- Reports use anonymous `tester-` codes and require adult confirmation.
- Names, email addresses, phone numbers, account names, and contact details are
  forbidden.
- The aggregate removes participant codes, device text, GPU text, and all
  free-text answers. It contains numeric counts and ratings only.
- A minimum sample does not prove accessibility, fun, or low-end hardware
  performance. A facilitator must review local notes and hardware coverage.

## Campaign contract

- Shared mission: `MISSION-01`
- Families: T, B, M, N, A, D
- Minimum initial sample: 3 complete participants
- Recommended sample: 6 complete participants
- Design: each participant plays all six families
- Order control: deterministic cyclic rotation from the anonymous participant
  code
- Exact provenance: every participant must use the same version and build
  commit

The six numeric tester codes `tester-01` through `tester-06` start on a
different family. Continue with `tester-07` only after the first rotation is
assigned.

## Prepare a kit

Use the commit that produced the artifact, not the current documentation HEAD.
For the remotely verified v0.4.0 artifact in Actions run `33255697919`:

```sh
npm run create:playtest-kit -- \
  --participant=tester-01 \
  --build-commit=5021665c73862f9aa8a2e7adf514c86841f4c4e5 \
  --out=outputs/human-playtest-kits/tester-01-build-5021665
```

The output contains:

- `index.html`: bilingual offline form
- `report.json`: prefilled blank report
- `manifest.json`: exact build and assigned family order
- `README.md`: tester and facilitator instructions

The generator refuses to overwrite an existing kit so participant drafts are
not destroyed accidentally.

## Run one session

1. Give the participant one exact game artifact and their assigned kit.
2. Confirm that the artifact matches the manifest commit.
3. Ask the participant not to enter names or contact details.
4. Let the participant play each family in the assigned order.
5. Explain only the normal controls. Avoid coaching family strategy after play
   begins.
6. Ask the participant to try the duty switch where available.
7. Use Download draft before any break.
8. Use Export completed report after all six sessions.
9. Store the downloaded JSON under
   `outputs/playtests/human/raw/<build-commit>/`.

## Validate reports

Validate every completed file separately:

```sh
node tools/validate_human_playtest.mjs \
  outputs/playtests/human/raw/5021665/tester-01-six-family-playtest-complete.json
```

The validator rejects incomplete sessions, placeholders, unknown families,
mixed missions, malformed build provenance, PII keys, and email addresses
hidden in free text.

## Aggregate a campaign

```sh
npm run aggregate:playtests -- \
  --dir=outputs/playtests/human/raw/5021665 \
  --out=outputs/playtests/human/aggregate-5021665.json \
  --minimum-participants=3 \
  --require-minimum
```

`--require-minimum` exits non-zero when fewer than three valid participants are
present, but still writes an `insufficient-sample` aggregate for inspection.
Duplicate participant codes or mixed builds fail without producing a combined
claim.

## Facilitator review

Before making a product decision, inspect the local raw reports for:

- repeated confusion about the same control, duty, phase, or HUD element;
- any family with repeated role or jelly-visual ratings below 3;
- defects reproduced by more than one participant;
- whether both Traditional Chinese and English were exercised;
- at least one real Windows integrated-GPU result;
- at least one controller result if controller support is a release claim; and
- motion, contrast, text-size, or input-access needs that the current form does
  not represent.

Do not commit raw reports. If a decision summary is needed in the repository,
write it from the anonymous numeric aggregate and remove any copied free text.
