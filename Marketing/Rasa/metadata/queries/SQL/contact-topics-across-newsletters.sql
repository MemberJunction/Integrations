-- A person's interests across every newsletter, one row per contact and topic, with the email.
-- Clicks are summed, the strongest per-newsletter weight is kept and the click window is widened,
-- the same way rasa.io merges a contact's topics across an account's newsletters.
SELECT
    t.contact_id AS ContactID,
    c.email AS Email,
    t.topic AS Topic,
    SUM(t.num_clicks) AS Clicks,
    MAX(t.weight) AS Weight,
    COUNT(DISTINCT t.newsletter_id) AS Newsletters,
    MIN(t.first_click) AS FirstClick,
    MAX(t.last_click) AS LastClick
FROM {{ IntegrationSchema | default('rasa') | sqlIdentifier }}.Newsletter_Contact_Topic t
INNER JOIN {{ IntegrationSchema | default('rasa') | sqlIdentifier }}.Contact c ON c.id = t.contact_id
GROUP BY t.contact_id, c.email, t.topic
