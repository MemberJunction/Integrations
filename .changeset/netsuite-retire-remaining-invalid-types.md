---
"@memberjunction/connector-netsuite": patch
---

Retire the remaining twelve presupposed record types, so the catalog stops shipping objects that can never sync.

`V202609082300` retired the four whose failure was reproduced live. These twelve are the rest of the same set: the Declared catalog was authored by camel-collapsing NetSuite's UI labels into record-type slugs, and for these the collapse does not land on a real `record.Type` id — `class` (real: `classification`), `event` (`calendarevent`), `unitofmeasure` (`unitstype`), `taxcontrolaccount` (`taxacct`), `glauditnumberingsequence` (`glnumberingsequence`), `periodendjournalentry` (`periodendjournal`), `revenuerecognitionschedule` (`revrecschedule`), `revenuerecognitiontemplate` (`revrectemplate`), the three `otherchargefor*item` variants (`othercharge*item`), and `changeorder`, for which no standard record carries the id at all. SuiteQL answers `SELECT * FROM <slug>` with HTTP 400 `Invalid search type: <slug>`, so each ships Active, is auto-mapped, and spends a request, an error and a retry ladder per run, forever.

They are `Status = Disabled` in the metadata and in a delta migration (`V202609122100`, SQL Server and PostgreSQL) keyed by seeded ID, so installed tenants keep the rows and pick the change up on upgrade. Nothing is deleted or remapped: discovery unions the Declared floor with the account's live metadata-catalog and passes unknown slugs through verbatim, so every tenant already surfaces the real record type on its own, and a remap would put two objects over one table.

Genuine record types that merely fail on feature-gated accounts (`costcategory`, `department`, `expensereport`, `generaltoken`, `issue` — `Record 'x' was not found`, which the connector reports as `OBJECT_UNAVAILABLE`) stay Active, and a test pins that.
