---
'@memberjunction/connector-netforum-enterprise': patch
---

Withdraw the write from the five netFORUM Enterprise objects that declare no fields and can never
acquire a primary key.

A writable `IntegrationObject` with no `IsPrimaryKey` field derives a **keyless entity**. On Postgres,
MJ's save audit-wrapper then emits an empty record identifier and every save fails with
`syntax error at or near ","`, while fetch keeps succeeding — the object reads green and persists
nothing.

These five are a distinct case from the rest of the fleet: each declares **zero** fields and is marked
`Configuration.placeholder = true` with `schemaSource: "runtime-discovered (GetFacadeXMLSchema /
GetQueryDefinition)"`. The connector's other ten writable objects each declare hundreds of fields and a
proper key (`Individual.ind_cst_key`, `Invoice.inv_key`, `Organization.org_cst_key`, …).

**Runtime discovery cannot rescue them.** `NetForumConnector.ParseQueryDefinition` sets
`IsPrimaryKey: declared?.IsPrimaryKey ?? false` — a netFORUM column definition does not mark a primary
key, so a discovered field is *never* a key and an object with no declared key stays keyless forever.
There is nothing to stamp and nothing may be invented.

Evidence is the vendor's own public WSDL for the xWeb SOAP service (`netFORUMXML.asmx?WSDL`, namespace
`http://www.avectra.com/2005/`), read operation by operation.

| Object | Change | WSDL evidence |
| --- | --- | --- |
| `CustomerAction` | create withdrawn | `InsertCustomerAction(actionCustomerKey, action, actionTypeKey, source, actionDate, actionSubtypeList) -> guid`, but the declared read door `GetActionTypeList()` takes **no arguments** and returns the action **TYPE** list — not customer actions. Nothing written is ever read back, and no fields are declared to build a create body from. |
| `CommunicationPreference` | update withdrawn | `SetCustomerCommunicationPreferences(customerKey, ArrayOfMailingListSetting)` → **empty response**. One call carries a customer plus an *array* of settings — no single record, no returned identity. Already broken: `UpdateRecord` injects the external id via `PrimaryKeyFieldName()`, which reads declared fields only, so the envelope goes out with **no `customerKey` at all**. |
| `CEUCredit` | create withdrawn | `CeuApplyExternalCredits(individualKey, CeuCreditList)` → `ArrayOfCeuCreditResult` (each `{ceu_key, externalId, resultStatus, resultMessage}`). A bulk apply-many-to-one; keys come back inside an array, so there is no single created record for `BuildCreatedResult`. Its declared read door *is* the write method. |
| `AdvocacyData` | create withdrawn | `CreateAdvocacyData(oNode)` → **empty response**, no identifier at all. Already a hard failure today: `BuildCreatedResult` returns `Success:false` on an empty id rather than silently losing the record. Its declared read door is also the write method. |
| `FacadeObject` | write withdrawn | A generic meta-accessor, not a record type — the object *name* is a parameter: `GetFacadeObject(szObjectName, szObjectKey)`, `InsertFacadeObject(szObjectName, oNode)`, `UpdateFacadeObject(szObjectName, szObjectKey, oNode)`. One catalog row would stand for every netFORUM entity without a dedicated `WEB*` method at once, and `UpdateFacadeObject` needs an `szObjectKey` the connector cannot supply. |

Reads are unaffected on all five. `CustomerAction`'s insert does return a key, so it could be modelled
properly once a real read door for customer actions is established — that is object authoring, not a
key stamp, and is deliberately out of scope here.

Metadata and the delta migration move together in both dialects; the seed migration is untouched.
