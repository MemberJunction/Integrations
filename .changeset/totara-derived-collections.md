---
"@memberjunction/connector-totara": minor
---

Five derived child objects explode the embedded JSON arrays into first-class tables — `Enrolled User Roles`, `Enrolled User Groups`, `User Custom Fields`, `Course Content Modules`, `Cohort Member Users` — fed from the parent object's own fetch as the data comes in (zero additional vendor calls when maps run in order; automatic fallback walk otherwise). Also `Configuration.dropFields`: `preferences` (Moodle UI widget state) and `courseformatoptions` (course theming) stop being fetched — configuration, not data.
