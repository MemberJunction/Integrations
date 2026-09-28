---
"@memberjunction/connector-bill-com": patch
---

Record the field lengths BILL enforces on writes. The catalog extractor read only each object's response DTO, and BILL's response DTOs leave `maxLength` off fields its create and update request DTOs bound. As a result, `customers.name` was recorded at the 255 default while BILL accepts 100. The extractor now also reads the create and update request DTOs and keeps the smallest bound. That changes `customers.name` 255→100, `customers.companyName` 255→250, `customers.accountNumber` 255→100 and `invoices.invoiceNumber` 255→100. The new `V202609271412__bill-com__Metadata.sql` migration applies the four lengths to installed catalogs, so apps that check lengths against this metadata reject an over-long value before sending it.
