---
'@memberjunction/connector-netforum-enterprise': minor
---

**Discovery resolves the client's object set from the source, per the framework contract — it no longer unions a baked-in list.** 1.4.0 shipped this behind an opt-in flag that defaulted OFF, so discovery still reported the declared 34 out of the box; and when enabled it *added* to the declared catalog rather than reconciling with it. Both were wrong against `everything.txt` §2.

**Enumeration is unconditional.** `GetFacadeObjectList` takes an empty request and returns every facade the credential may see (878 on a live tenant against a declared catalog of 34). A connector whose source can list its objects must ask the source, every time. There is no flag and no cap: the previous justification — that each listed object would cost a `GetQueryDefinition` round trip — was simply false. `BaseRESTIntegrationConnector.IntrospectSchema` is cache-driven (`GetActiveIntegrationObjects` + `GetCachedFields`) and issues no network calls, so enumeration costs exactly one request.

**The object set is now a three-way reconciliation, not a union.** Per the contract: *"if you have metadata for Objects A,B,C, and the external system has C,D,E ... you basically exclude A,B for this client as potential entity maps"*.

- **In both** — kept, and overlaid attribute-by-attribute with **external-system priority**, the declaration as fallback. `GetFacadeObjectList` states a description and is silent on APIPath, watermark, primary key and write capability, so the description comes from the source and the rest from the declaration. The overlay is gated on the source's actual statement (`obj_description`), never on a synthesised label — otherwise a silent source overwrites a curated label with the bare object name.
- **Source only** — added. These are the client's custom and undeclared objects.
- **Declared only** — excluded. A declared object the source does not list is not this tenant's object.

That third rule fixes an observed failure. Ten of the declared 34 are not listed for the probe credential, and they are exactly the ten whose `GetQuery` returns 500, whose primary key was never determinable, and which `entity.skipped-no-pk` drops at materialisation. Carrying them forward produced catalog rows that could never be fetched. 1.3.5 recorded this for one of them ("MembershipBilling is not readable by the probe credential"); it is ten.

**Exclusion applies only when the source actually answered.** A failed, timed-out or ungranted `GetFacadeObjectList` returns the declared baseline untouched — absence of an answer is never absence of an object. Mutation-proved: excluding on a failed call fails two tests.

`DiscoveryIsAuthoritative` remains **false**. The enumeration is permission-scoped — 878 is what this credential may see, a floor rather than a ceiling — so absence still must not deactivate. Revisiting that is a separate, deliberate decision.
