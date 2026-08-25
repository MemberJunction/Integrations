---
"@memberjunction/connector-business-central": patch
---

Fix `mjVersionRange` so the connector can be installed on MemberJunction 6.x.

`package.json` advertised MJ 6.x on all five peers (`>=5.43.0 <7.0.0`) while `mj-app.json` still capped at
`>=5.43.0 <6.0.0`. MJ reads the manifest to gate `mjdev app register`, so the connector was rejected on a
6.x host — reported as outside `>=5.43.0 <6.0.0` — even though its package said it was compatible. Not the
prerelease trap: MJ coerces the host to its base tuple before evaluating, so `6.1.0-edge.2` is judged as
`6.1.0`, which is legitimately outside the old cap.

The manifest value was a symptom. `scripts/sync-manifest-versions.mjs` **derived** the ceiling from the
range's minimum as `major+1` rather than reading the declared ceiling:

```js
const range = `>=${min[0]} <${Number(min[1]) + 1}.0.0`;
```

That is correct only while every connector's ceiling happens to be min-major+1, which held for 54 of 55.
Business Central was the one connector whose peers had actually been widened, so the script rewrote its
manifest back to `<6.0.0` on every release — meaning a hand-edit of `mj-app.json` would not have survived
the next publish.

The sync now copies the peer range verbatim when it states an explicit ceiling, and falls back to the old
derivation (with a warning) for ranges that state none. A new gate,
`scripts/lint-manifest-version-range.mjs`, fails CI when the two disagree, so the class cannot return
silently — it runs in `pr.yml` and as `npm run lint:version-range`.

Fixes #208.
