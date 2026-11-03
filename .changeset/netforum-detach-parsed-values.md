---
"@memberjunction/connector-netforum-enterprise": patch
---

Copy each value the connector parses out of an xWeb response, so a kept value no longer keeps the whole response in memory.

The connector reads XML with regular expressions. In V8, a capture or substring of 13 or more characters points into the string it came from. So one kept value kept its whole response:

- **GetQuery pages.** The engine keeps the record IDs of an entity map until the map ends, and samples of unmapped columns until the run ends. Each kept ID or sample kept its page. On a production tenant, a page of 200 rows of a wide object is about 7 MB, and these pages added up to more than 2 GB during one sync.
- **GetQueryDefinition responses.** The connector caches the parsed definition of each object for its whole life, so each definition kept its response.

`ParseRowColumns` and `ParseSoapScalar` now return copies (`DetachText`). The copy costs about 140 ns per value.
