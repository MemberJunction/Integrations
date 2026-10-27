-- rasa.io Connector v3.0.0 — retire the v1 API surface.
--
-- rasa.io directed integrations to its v2 API only (the customer now generates a v2 client ID + secret in the
-- rasa.io dashboard; the v1 username/password/API-key exchange is no longer implemented). This migration removes
-- the 18 IntegrationObject rows that read or wrote v1 endpoints, and disables the 12 Actions that targeted them.
-- The v3 seed delta adds the new v2 objects and Actions; see MIGRATION-v3.md.
--
-- Deleting by hardcoded ID (the IDs seeded by V202608011359), so this is a no-op on a database that never had
-- them and cannot touch the v2 rows. IntegrationObjectField is deleted first: it is the only table with an FK
-- to IntegrationObject (IntegrationObjectID and RelatedIntegrationObjectID).
--
-- Destination tables created by these objects are NOT dropped, and no synced data is deleted.
-- Actions are DISABLED, not deleted, so execution-log and agent references to them stay valid.
--
-- Retired IntegrationObjects:
--   0E7CC444-2569-4BFC-8B17-77CB11A30D9F  Community              /v1/communities
--   871F3818-D7A4-4100-A097-92DB65BCA7A1  Section                /v1/sections/{community_identifier}
--   38E5B6C4-0202-4377-9654-8CC1E1DF6E9A  Person                 /v1/persons
--   B1EE6B66-225E-4EF7-972D-22ECEE24A6FA  Deleted Person         /v1/persons/deleted
--   7C004F8F-3966-4302-89D1-7564C925E3BF  Person Action          /v1/persons/{id}/actions
--   ABAF75DB-5AD4-465C-989C-17BFFA9C6820  Person Topic           /v1/persons/{id}/topics
--   3A995F1E-DE81-4CE5-ABFA-B7E0948FA586  Person Send            /v1/persons/{id}/sends
--   2D5C2E70-15DA-478D-A95D-20ACB615FC0B  Person Attribute       /v1/persons/{id}/attributes
--   ACF8EC58-AB5D-44C2-84F0-4F5215040BAD  Post                   /v1/posts
--   CCC0AAB0-40AD-434A-BCC5-0ED0FF1025DA  Content Pool Item      /v1/content-pool
--   B7C49A5C-D09D-4590-A6E9-756C22741BA9  Insight Action         /v1/insights/actions
--   D1EC400C-8B50-4DB5-811E-C26598E1C1B0  Insight Topic          /v1/insights/topics
--   7A4756AD-B078-4D60-8EA4-8F5D7AFC1872  Analytics Activity     /v1/analytics/activities
--   C7E53001-D997-4B48-8891-3DE21C51DBAD  Analytics Article      /v1/analytics/articles
--   6CB72608-4804-4C71-A493-76815C751E98  Analytics Image        /v1/analytics/images
--   7113621D-9405-401C-BFEA-AB143DD240B3  Analytics Topic        /v1/analytics/topics
--   DAFD40E6-558D-4D51-81CA-872165F6214E  Lead Post              (write-only) /v1/lead-posts
--   DFC4B9E5-3D64-4B46-A1F3-FD746FB65031  Insight Topic Score    /v1/insights/topics
--
-- Disabled Actions:
--   DD07C385-C998-4B6E-BE34-5C3C5D1972DF  Rasa.io - Get Person
--   002BD7D0-7F30-401F-83D3-8C5C652149C0  Rasa.io - Search Person
--   D89EC8E2-1384-40A0-8B8B-87AFDEC547A7  Rasa.io - List Person
--   88D4D813-4208-44F9-AE60-09F36E694860  Rasa.io - Get Post
--   DD46EDA9-8C92-4331-9E75-F8582A21BCCD  Rasa.io - Search Post
--   5436D85E-E2A2-4C56-A503-9C3574AB4E5E  Rasa.io - List Post
--   A06C4837-3CA9-446A-B670-DDC971648927  Rasa.io - Get Insight Action
--   FE15D2AA-8CE1-4B90-A3E5-01F5CFAB7E17  Rasa.io - Search Insight Action
--   B7358517-DBAF-440D-925B-A1E855832898  Rasa.io - List Insight Action
--   7CF75CCD-4DB4-4A8F-8C99-12B5900219BD  Rasa.io - Get Insight Topic
--   6F638653-F270-4D7A-9573-49D29513E89F  Rasa.io - Search Insight Topic
--   FF768FA6-7B07-4C5B-A0C3-8A9D67B40BA0  Rasa.io - List Insight Topic

DELETE FROM [__mj].[IntegrationObjectField]
WHERE IntegrationObjectID IN (
        '0E7CC444-2569-4BFC-8B17-77CB11A30D9F',
        '871F3818-D7A4-4100-A097-92DB65BCA7A1',
        '38E5B6C4-0202-4377-9654-8CC1E1DF6E9A',
        'B1EE6B66-225E-4EF7-972D-22ECEE24A6FA',
        '7C004F8F-3966-4302-89D1-7564C925E3BF',
        'ABAF75DB-5AD4-465C-989C-17BFFA9C6820',
        '3A995F1E-DE81-4CE5-ABFA-B7E0948FA586',
        '2D5C2E70-15DA-478D-A95D-20ACB615FC0B',
        'ACF8EC58-AB5D-44C2-84F0-4F5215040BAD',
        'CCC0AAB0-40AD-434A-BCC5-0ED0FF1025DA',
        'B7C49A5C-D09D-4590-A6E9-756C22741BA9',
        'D1EC400C-8B50-4DB5-811E-C26598E1C1B0',
        '7A4756AD-B078-4D60-8EA4-8F5D7AFC1872',
        'C7E53001-D997-4B48-8891-3DE21C51DBAD',
        '6CB72608-4804-4C71-A493-76815C751E98',
        '7113621D-9405-401C-BFEA-AB143DD240B3',
        'DAFD40E6-558D-4D51-81CA-872165F6214E',
        'DFC4B9E5-3D64-4B46-A1F3-FD746FB65031')
   OR RelatedIntegrationObjectID IN (
        '0E7CC444-2569-4BFC-8B17-77CB11A30D9F',
        '871F3818-D7A4-4100-A097-92DB65BCA7A1',
        '38E5B6C4-0202-4377-9654-8CC1E1DF6E9A',
        'B1EE6B66-225E-4EF7-972D-22ECEE24A6FA',
        '7C004F8F-3966-4302-89D1-7564C925E3BF',
        'ABAF75DB-5AD4-465C-989C-17BFFA9C6820',
        '3A995F1E-DE81-4CE5-ABFA-B7E0948FA586',
        '2D5C2E70-15DA-478D-A95D-20ACB615FC0B',
        'ACF8EC58-AB5D-44C2-84F0-4F5215040BAD',
        'CCC0AAB0-40AD-434A-BCC5-0ED0FF1025DA',
        'B7C49A5C-D09D-4590-A6E9-756C22741BA9',
        'D1EC400C-8B50-4DB5-811E-C26598E1C1B0',
        '7A4756AD-B078-4D60-8EA4-8F5D7AFC1872',
        'C7E53001-D997-4B48-8891-3DE21C51DBAD',
        '6CB72608-4804-4C71-A493-76815C751E98',
        '7113621D-9405-401C-BFEA-AB143DD240B3',
        'DAFD40E6-558D-4D51-81CA-872165F6214E',
        'DFC4B9E5-3D64-4B46-A1F3-FD746FB65031');

DELETE FROM [__mj].[IntegrationObject]
WHERE ID IN (
        '0E7CC444-2569-4BFC-8B17-77CB11A30D9F',
        '871F3818-D7A4-4100-A097-92DB65BCA7A1',
        '38E5B6C4-0202-4377-9654-8CC1E1DF6E9A',
        'B1EE6B66-225E-4EF7-972D-22ECEE24A6FA',
        '7C004F8F-3966-4302-89D1-7564C925E3BF',
        'ABAF75DB-5AD4-465C-989C-17BFFA9C6820',
        '3A995F1E-DE81-4CE5-ABFA-B7E0948FA586',
        '2D5C2E70-15DA-478D-A95D-20ACB615FC0B',
        'ACF8EC58-AB5D-44C2-84F0-4F5215040BAD',
        'CCC0AAB0-40AD-434A-BCC5-0ED0FF1025DA',
        'B7C49A5C-D09D-4590-A6E9-756C22741BA9',
        'D1EC400C-8B50-4DB5-811E-C26598E1C1B0',
        '7A4756AD-B078-4D60-8EA4-8F5D7AFC1872',
        'C7E53001-D997-4B48-8891-3DE21C51DBAD',
        '6CB72608-4804-4C71-A493-76815C751E98',
        '7113621D-9405-401C-BFEA-AB143DD240B3',
        'DAFD40E6-558D-4D51-81CA-872165F6214E',
        'DFC4B9E5-3D64-4B46-A1F3-FD746FB65031');

UPDATE [__mj].[Action]
SET Status = 'Disabled'
WHERE ID IN (
        'DD07C385-C998-4B6E-BE34-5C3C5D1972DF',
        '002BD7D0-7F30-401F-83D3-8C5C652149C0',
        'D89EC8E2-1384-40A0-8B8B-87AFDEC547A7',
        '88D4D813-4208-44F9-AE60-09F36E694860',
        'DD46EDA9-8C92-4331-9E75-F8582A21BCCD',
        '5436D85E-E2A2-4C56-A503-9C3574AB4E5E',
        'A06C4837-3CA9-446A-B670-DDC971648927',
        'FE15D2AA-8CE1-4B90-A3E5-01F5CFAB7E17',
        'B7358517-DBAF-440D-925B-A1E855832898',
        '7CF75CCD-4DB4-4A8F-8C99-12B5900219BD',
        '6F638653-F270-4D7A-9573-49D29513E89F',
        'FF768FA6-7B07-4C5B-A0C3-8A9D67B40BA0');
