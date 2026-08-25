---
'@memberjunction/connector-pheedloop': patch
---

Guard the UnboundedText migration's sessions_information INSERT on (IntegrationObjectID, Name) — the columns UQ_IntegrationObjectField_Name actually covers — instead of on ID. Where discovery reached the object before the migration ran, the field already existed under a different ID: the ID guard passed, the INSERT violated the constraint, and the migration failed. Because migrations apply in version order and stop at the first failure, the later corrective migration could never be reached on exactly the instances that needed it. Fixed in both dialects.
