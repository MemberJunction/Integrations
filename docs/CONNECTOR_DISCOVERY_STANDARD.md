# Connector discovery standard — the sample-union

> Applies to every **describe-endpoint** connector (one that extends `BaseRESTIntegrationConnector`
> and returns a *declared* field catalog — cache-driven `IntrospectSchema`, or `DiscoverObjects` +
> `DiscoverFields` over seeded metadata). It does **not** apply to schema-less / live-discovery
> connectors (FileFeed, RelationalDB, MJtoMJ, or any connector that already overrides
> `IntrospectSchema` to describe/stream from the live source).

## The rule

Describe-endpoint connectors MUST union their declared catalog with a bounded, read-only streaming
data-sample by overriding their **OWN** `IntrospectSchema`:

1. call `super.IntrospectSchema(...)` to get the declared catalog;
2. for each object, augment its fields via MJ's own **`DiscoverFieldsViaFetch`** sampler; and
3. union the two with the shared pure helper **`mergeDeclaredWithSampledFields`**.

The connector adds **no discovery, merge, or sync logic of its own** — it only *wires* MJ's existing
`DiscoverFieldsViaFetch` sampler into `IntrospectSchema`. MJ upstream owns everything real:
measurement, type inference, PK statistics, persistence, the width/PK reconcile overlay, and sync.

```ts
public override async IntrospectSchema(companyIntegration, contextUser): Promise<SourceSchemaInfo> {
  const schema = await super.IntrospectSchema(companyIntegration, contextUser); // declared catalog
  await runBounded(schema.Objects, 8, async (obj) => {                          // bounded, parallel
    try {
      const sampled = await this.DiscoverFieldsViaFetch(companyIntegration, obj.ExternalName, contextUser);
      obj.Fields = mergeDeclaredWithSampledFields(obj.Fields, sampled);
    } catch { /* keep declared fields for this object — sampling never breaks introspection */ }
  });
  return schema;
}
```

## Hard prohibitions

- **DO NOT introduce a shared base class or re-parent connectors** for this. Connectors keep
  `extends BaseRESTIntegrationConnector` exactly as-is. The merge is a **pure shared helper only**
  (`@memberjunction/connector-schema-merge`), never inheritance.
- **NEVER override `DiscoverFields` to call `DiscoverFieldsViaFetch` / `DiscoverFieldsViaStream`.**
  `DiscoverFieldsViaFetch` falls back to `DiscoverFields`, so that wiring is an **infinite recursion
  trap**. Leave `DiscoverFields` unchanged; the sampler is wired only into `IntrospectSchema`.

## The helper is pure glue — fixed, minimal rules

`mergeDeclaredWithSampledFields(declared, sampled)` is a plain function (no class). It re-implements
none of MJ's behaviour. It does exactly:

- **Union by field name.**
- **Name in BOTH** → keep the DECLARED field object unchanged **except** adopt MJ's measured
  `MaxLength` when the sample measured one (the declared catalog carries no real width). No width
  math / max() / shrink rules, **no PK logic, no type inference** — MJ's sampler set those and MJ's
  Persist/reconcile overlay owns width-shrink protection and PK preservation.
- **Name ONLY in the sample** → append it as-is (a custom column MJ discovered, with MJ's own
  type / width / PK-stats), mapped onto the `SourceFieldInfo` shape.
- **Deterministic** — declared order preserved; custom columns appended in sample order.

## Sampling shape

One bounded, read-only pass per object, run in parallel across objects (a small promise-pool;
`BaseRESTIntegrationConnector.RunBounded` is private, so the override carries a tiny local pool).
Any per-object failure keeps that object's declared fields.

## Verification (every new/changed connector, on a real data sample)

- measured widths present (no `nvarchar(255)` overflow / `STRING_OVERFLOW_SKIPPED`);
- custom columns present **before** the first sync;
- PK stable;
- re-discovery monotonic (running discovery again does not thrash the catalog).
