-- Each contact's topics in each newsletter, with the contact's email and the newsletter's name.
-- contact_id is the rasa.io contact id: the same id in Contact, Newsletter Contact and the topic tables.
SELECT
    t.newsletter_id AS NewsletterID,
    n.name AS Newsletter,
    t.contact_id AS ContactID,
    c.email AS Email,
    t.topic AS Topic,
    t.num_clicks AS Clicks,
    t.weight AS Weight,
    t.first_click AS FirstClick,
    t.last_click AS LastClick,
    t.effective_date AS EffectiveDate
FROM {{ IntegrationSchema | default('rasa') | sqlIdentifier }}.Newsletter_Contact_Topic t
INNER JOIN {{ IntegrationSchema | default('rasa') | sqlIdentifier }}.Contact c ON c.id = t.contact_id
LEFT JOIN {{ IntegrationSchema | default('rasa') | sqlIdentifier }}.Newsletter n ON n.id = t.newsletter_id
