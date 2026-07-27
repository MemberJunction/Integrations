# @memberjunction/connector-schema-merge

## 1.0.1

### Patch Changes

- c4c826e: Harden the declared-vs-sampled field merge on two fronts that could silently drop or under-size data:

  - **Carry a proven sampled PK onto an otherwise-keyless object (I1).** When a connector object declares columns but no primary key, MJ's sampler can still statistically prove one — but the merge previously kept the declared field unchanged except its width, dropping that PK signal, so the object stayed keyless and never synced. The merge now adopts the sampled `IsPrimaryKey` onto the declared field **only when the object declares no PK of its own** (a real declared PK always wins; no second PK is ever added). This is the one gap that could drop an entity from sync entirely.
  - **Give a tight declared width guess headroom (I2).** A capped sample reads a bounded number of rows, so its widest value is a floor, not the truth. Measured widths already round up to the next standard tier (…2048, 4000) so a slightly-longer unsampled value fits (this dropped 99 PheedLoop members: `about` measured 2348, a real bio was 2595). Now a **declared** width that sits _below the sample's own headroom tier_ — a sign it's a tight metadata guess rather than an authoritative describe width — is bumped to that tier too. A declared width that comfortably clears the sample's headroom (a real describe-API width, e.g. Salesforce/Fonteva) is still kept EXACT. Widths never shrink.
