---
'@memberjunction/connector-openwater': patch
---

Page a detail walk's door by the DOOR object's rules, not the child's

`PaginateLeaf` decides whether to page from `obj.SupportsPagination && obj.PaginationType !== 'None'`.
The door fetch passed the **child** object, and a walked child declares neither — its APIPath is
literally "(embedded in /v2/Applications/{applicationId} …)". So the door request went out with no
`pageIndex`/`pageSize` and the vendor answered with its default page. Every detail walk was capped
at one page of parents, while honestly reporting `HasMore: false`, because it really had consumed
every parent it was given. It was given ten.

Measured on a live tenant with 1,976 Applications:

| object | result | target |
| --- | --- | --- |
| ApplicationRoundSubmission | 10 records from 10 parents, `hasMore:false` | 1,935 |
| ApplicationFile | 0 records from 10 parents (`ZERO_LEAVES`) | 4,001 |
| ApplicationWinnerType | 74 — correct | 89 |

ApplicationWinnerType was right only because its door, `/v2/Programs`, has 5 rows and fits inside a
single default page — which is what made the cap look like a per-object extraction problem rather
than one shared defect.

The door object is now resolved from the catalog by `AccessPath.door` and its pagination governs the
door request. When the door has no catalog row we fall back to the child, so a misdeclared AccessPath
behaves as it did before rather than throwing mid-sync.
