---
"@memberjunction/connector-asana": patch
---

fix(asana): a parent deleted in Asana no longer stops the whole Tasks or Subtasks fetch.

Tasks (`/tasks?project={gid}`) and Subtasks (`/tasks/{gid}/subtasks`) are fetched per synced parent. A task or project deleted in Asana stays in the synced tables, so its children call returns 404 on every run. The base fetch loop treated that as a persistent error and abandoned the object at that batch. On one tenant that left every subtask after one deleted task unsynced, every night ("Fetch for 'Subtasks' stopped at batch 54 … HTTP 404"). A 404 on a parent-scoped GET is now read as an empty page, with a warning naming the parent. A 404 on a single record or an unscoped list still fails as before.
