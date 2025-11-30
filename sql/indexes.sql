CREATE INDEX idx_clients_job     ON clients(job);
CREATE INDEX idx_clients_marital ON clients(marital);
CREATE INDEX idx_clients_age     ON clients(age);

CREATE INDEX idx_contacts_client      ON contacts(client_id);
CREATE INDEX idx_contacts_campaign    ON contacts(campaign_id);
CREATE INDEX idx_contacts_subscribed  ON contacts(subscribed, campaign_id);
CREATE INDEX idx_contacts_month_dow   ON contacts(contact_month, day_of_week);

CREATE INDEX idx_prev_client ON previous_outcomes(client_id);

SHOW INDEXES FROM clients;
SHOW INDEXES FROM contacts;
SHOW INDEXES FROM econ_indicators;
SHOW INDEXES FROM previous_outcomes;
SHOW INDEXES FROM campaigns;