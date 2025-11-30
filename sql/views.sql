USE bank_marketing;

CREATE OR REPLACE VIEW vw_campaign_performance AS
SELECT
    c.campaign_id,
    c.code,
    c.name,
    COUNT(ct.contact_id) AS total_contacts,
    SUM(ct.subscribed) AS total_subscriptions,
    ROUND(SUM(ct.subscribed) / COUNT(ct.contact_id) * 100, 2) AS conversion_rate_pct
FROM campaigns c
JOIN contacts ct ON c.campaign_id = ct.campaign_id
GROUP BY c.campaign_id, c.code, c.name;

CREATE OR REPLACE VIEW vw_client_profile AS
SELECT
    cl.client_id,
    cl.age,
    cl.job,
    cl.marital,
    cl.education,
    cl.default_flag,
    cl.housing_flag,
    cl.loan_flag,
    COUNT(ct.contact_id) AS total_contacts,
    SUM(ct.subscribed) AS total_subscriptions,
    ROUND(
        IF(COUNT(ct.contact_id) = 0, 0,
            SUM(ct.subscribed) / COUNT(ct.contact_id) * 100
        ), 2
    ) AS conversion_rate_pct
FROM clients cl
LEFT JOIN contacts ct ON ct.client_id = cl.client_id
GROUP BY cl.client_id;

CREATE OR REPLACE VIEW vw_poutcome_summary AS
SELECT
    poutcome,
    COUNT(*) AS total_contacts,
    SUM(subscribed) AS total_subscriptions,
    ROUND(SUM(subscribed) / COUNT(*) * 100, 2) AS conversion_rate_pct,
    AVG(call_duration) AS avg_call_duration
FROM contacts
GROUP BY poutcome;

SELECT * FROM vw_campaign_performance;

