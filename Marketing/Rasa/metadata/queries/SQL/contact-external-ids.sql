-- Each contact's IDs in other systems (for example a CRM or AMS), with the email, so rasa.io
-- contacts can be matched to records elsewhere by ID as well as by email.
SELECT
    x.contact_id AS ContactID,
    c.email AS Email,
    x.system AS ExternalSystem,
    x.identifier AS ExternalID,
    x.system_identifier AS ExternalSystemIdentifier
FROM {{ IntegrationSchema | default('rasa') | sqlIdentifier }}.Contact_External_Identifier x
INNER JOIN {{ IntegrationSchema | default('rasa') | sqlIdentifier }}.Contact c ON c.id = x.contact_id
