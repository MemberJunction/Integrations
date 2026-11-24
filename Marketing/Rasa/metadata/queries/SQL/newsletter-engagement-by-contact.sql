-- Opens and clicks per contact and newsletter, with the email from Contact (an event's own email
-- can be empty). Clicks with confidence 0 looked automated to rasa.io and are left out.
SELECT
    a.newsletter_id AS NewsletterID,
    n.name AS Newsletter,
    a.contact_id AS ContactID,
    c.email AS Email,
    SUM(CASE WHEN a.action_type = 'open' THEN 1 ELSE 0 END) AS Opens,
    SUM(CASE WHEN a.action_type = 'click' AND a.confidence <> 0 THEN 1 ELSE 0 END) AS Clicks,
    MIN(a.created) AS FirstActivity,
    MAX(a.created) AS LastActivity
FROM {{ IntegrationSchema | default('rasa') | sqlIdentifier }}.Newsletter_Action a
INNER JOIN {{ IntegrationSchema | default('rasa') | sqlIdentifier }}.Contact c ON c.id = a.contact_id
LEFT JOIN {{ IntegrationSchema | default('rasa') | sqlIdentifier }}.Newsletter n ON n.id = a.newsletter_id
GROUP BY a.newsletter_id, n.name, a.contact_id, c.email
