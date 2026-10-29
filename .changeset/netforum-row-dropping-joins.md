---
"@memberjunction/connector-netforum-enterprise": patch
---

NetForum: the full column list leaves out joins that would DROP records.

A list definition states each join's kind (`<lsf_from_join_type>`: `Join` or `Left Join`), and xWeb joins a table only when the list names one of its columns. A live tenant's Individual INNER-joins `ce_course_participant`, `np_constituent` and `co_email_optout`, and its Organization INNER-joins `co_related_association` behind a LEFT join. Naming any of their columns, or any of their Extender columns, keeps only the records that have a match there. Both objects' full lists returned 0 rows with no WHERE at all, while netFORUM holds 55,988 individuals and 7,152 organizations, and the incremental reads stopped finding new people.

- `<lsf_from_join_type>` is parsed (`NFFromTable.JoinType`), and each column records the from-table it is listed under (`NFDefinedColumn.FromTable`). An Extender column's `mdc_table_name` is its `_ext` table, but naming it brings in the enclosing join.
- `RowFilteringJoins` keeps an INNER join only when it is a lookup: the joined table's own `<prefix>_key` equated with a column of a table always present (the main table, or another such lookup), such as `co_customer` by `cst_key` or `ev_event` by `evt_key`. Any other INNER join, and anything joined through one, has its columns left out of the full list, except this read's own key, ordering key and watermark. The read says so: a `ROW_FILTERING_JOINS_LEFT_OUT` warning, logged once per object.
- A definition that states no join kind is read as before.

Measured on the live xWeb, with no WHERE:

| Object | Today's full list | List with those joins left out |
|---|---|---|
| Individual | 0 rows | full page |
| Organization | 0 rows | full page |

Since 2026-09-25, Individual returned a full page of new records and Organization returned 18.
