---
"@memberjunction/connector-netforum-enterprise": patch
---

NetForum: one record that xWeb cannot write as XML no longer stops a read or removes the object's joined columns.

- **The fault.** A value with a control character (for example 0x02) makes xWeb answer GetQuery with HTTP 500: `' ', hexadecimal value 0x02, is an invalid character.` Every read faults on the page that holds the record. On a live tenant, a full read of `Individual` stopped at page 138 of about 280 on every try.
- **Not a verdict on the column list.** The fault taught nothing, so the connector marked the object's full column list `unsendable` in `.nf-learned.json`. From the next run, the object was read with its own-table columns only, without any joined column. This fault is now never learned against the list.
- **Read around the record.** On this fault, the connector finds the first record of the page that xWeb cannot write: it sends the same request with a smaller `@TOP` (a binary search, about log2 of the page size requests), then the key of the next record from a request that names only the key and the WHERE clause's columns. It returns the readable rows before the record, warns `RECORD_UNREADABLE` with the record's key, and the next page starts after that key.
- **The read ends incomplete.** When the read reaches its last page, the next call throws an error that lists the skipped keys, so the engine holds the watermark and does not treat a skipped record as deleted. A read stops after 5 such records, because each costs a few faults against xWeb's daily limit. Remove the character from the listed records in netFORUM.
- **Upgrade note.** An object that this fault already marked `unsendable` stays on its own-table list until its entry is removed from `.nf-learned.json`.
