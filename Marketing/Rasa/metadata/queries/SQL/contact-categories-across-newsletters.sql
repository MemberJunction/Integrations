-- A person's interests across every newsletter at the category level (broader than topics),
-- one row per contact and category, with the email. Merged the same way as the topic query.
SELECT
    t.contact_id AS ContactID,
    c.email AS Email,
    t.topic AS Category,
    SUM(t.num_clicks) AS Clicks,
    MAX(t.weight) AS Weight,
    COUNT(DISTINCT t.newsletter_id) AS Newsletters,
    MIN(t.first_click) AS FirstClick,
    MAX(t.last_click) AS LastClick
FROM {{ IntegrationSchema | default('rasa') | sqlIdentifier }}.Newsletter_Contact_Category t
INNER JOIN {{ IntegrationSchema | default('rasa') | sqlIdentifier }}.Contact c ON c.id = t.contact_id
GROUP BY t.contact_id, c.email, t.topic
