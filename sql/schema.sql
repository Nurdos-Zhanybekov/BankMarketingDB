USE bank_marketing;

CREATE TABLE clients (
  client_id     BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  age           TINYINT UNSIGNED NOT NULL,
  job           VARCHAR(64) NOT NULL,
  marital       VARCHAR(64) NOT NULL,
  education     VARCHAR(64) NOT NULL,
  default_flag  ENUM('no','yes','unknown') NOT NULL,
  housing_flag  ENUM('no','yes','unknown') NOT NULL,
  loan_flag     ENUM('no','yes','unknown') NOT NULL,
  balance       DECIMAL(14,2) NOT NULL DEFAULT 0,
  created_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE campaigns (
  campaign_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  code        VARCHAR(64)  NOT NULL UNIQUE,
  name        VARCHAR(128) NOT NULL,
  start_date  DATE NOT NULL,
  end_date    DATE,
  notes       TEXT
) ENGINE=InnoDB;

CREATE TABLE econ_indicators (
  econ_id         BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  period_start    DATE NOT NULL,
  emp_var_rate    DECIMAL(5,2)  NOT NULL,
  cons_price_idx  DECIMAL(6,3) NOT NULL,
  cons_conf_idx   DECIMAL(6,3) NOT NULL,
  euribor3m        DECIMAL(6,3) NOT NULL,
  nr_employed      DECIMAL(10,2) NOT NULL,
  UNIQUE KEY uk_econ_period (period_start)
) ENGINE=InnoDB;

CREATE TABLE contacts (
  contact_id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  client_id               BIGINT UNSIGNED NOT NULL,
  campaign_id             INT UNSIGNED NOT NULL,
  econ_id                 BIGINT UNSIGNED,
  contact_type            ENUM('cellular','telephone') NOT NULL,
  contact_month           CHAR(3) NOT NULL,
  day_of_week             ENUM('mon','tue','wed','thu','fri') NOT NULL,
  call_duration           INT UNSIGNED NOT NULL,
  campaign_contacts_count INT UNSIGNED NOT NULL,
  pdays                   INT NOT NULL,
  previous                INT NOT NULL,
  poutcome                ENUM('failure','nonexistent','success') NOT NULL,
  subscribed              BOOLEAN NOT NULL,
  created_at              DATE NOT NULL
) ENGINE=InnoDB;


CREATE TABLE previous_outcomes (
  prev_id       INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  client_id     BIGINT UNSIGNED NOT NULL,
  prev_contacts INT UNSIGNED NOT NULL,
  last_poutcome ENUM('failure','nonexistent','success') NOT NULL,
  last_pdays    INT NOT NULL,
  CONSTRAINT fk_prev_client
    FOREIGN KEY (client_id) REFERENCES clients(client_id)
) ENGINE=InnoDB;

ALTER TABLE contacts
  ADD CONSTRAINT fk_contacts_client
    FOREIGN KEY (client_id) REFERENCES clients(client_id),
  ADD CONSTRAINT fk_contacts_campaign
    FOREIGN KEY (campaign_id) REFERENCES campaigns(campaign_id),
  ADD CONSTRAINT fk_contacts_econ
    FOREIGN KEY (econ_id) REFERENCES econ_indicators(econ_id);


CREATE TABLE raw_bank (
  age              INT,
  job              VARCHAR(64),
  marital          VARCHAR(64),
  education        VARCHAR(64),
  default_flag     VARCHAR(16),
  housing_flag     VARCHAR(16),
  loan_flag        VARCHAR(16),
  contact_type     VARCHAR(16),
  contact_month    VARCHAR(10),
  day_of_week      VARCHAR(10),
  call_duration    INT,
  campaign_count   INT,
  pdays            INT,
  previous         INT,
  poutcome         VARCHAR(32),
  emp_var_rate     DECIMAL(5,2),
  cons_price_idx   DECIMAL(6,3),
  cons_conf_idx    DECIMAL(6,3),
  euribor3m        DECIMAL(6,3),
  nr_employed      DECIMAL(10,2),
  subscribed_raw   VARCHAR(10)
);

UPDATE raw_bank SET default_flag = 'unknown'
WHERE default_flag IS NULL OR default_flag = '' OR default_flag = ' ';

UPDATE raw_bank SET housing_flag = 'unknown'
WHERE housing_flag IS NULL OR housing_flag = '' OR housing_flag = ' ';

UPDATE raw_bank SET loan_flag = 'unknown'
WHERE loan_flag IS NULL OR loan_flag = '' OR loan_flag = ' ';

UPDATE raw_bank SET contact_type = 'cellular'
WHERE contact_type IS NULL OR contact_type = '' OR contact_type NOT IN ('cellular','telephone');

UPDATE raw_bank SET contact_month = 'unknown'
WHERE contact_month IS NULL OR contact_month = '';

UPDATE raw_bank SET day_of_week = 'mon'
WHERE day_of_week IS NULL OR day_of_week NOT IN ('mon','tue','wed','thu','fri');

UPDATE raw_bank SET poutcome = 'nonexistent'
WHERE poutcome IS NULL OR poutcome = '' OR poutcome = ' ';

UPDATE raw_bank SET pdays = 999 WHERE pdays IS NULL OR pdays < 0;
UPDATE raw_bank SET previous = 0 WHERE previous IS NULL;
UPDATE raw_bank SET campaign_count = 0 WHERE campaign_count IS NULL;

UPDATE raw_bank SET subscribed_raw = 'no'
WHERE subscribed_raw IS NULL OR subscribed_raw = '';

UPDATE raw_bank SET emp_var_rate = 0       WHERE emp_var_rate IS NULL;
UPDATE raw_bank SET cons_price_idx = 0     WHERE cons_price_idx IS NULL;
UPDATE raw_bank SET cons_conf_idx = 0      WHERE cons_conf_idx IS NULL;
UPDATE raw_bank SET euribor3m = 0          WHERE euribor3m IS NULL;
UPDATE raw_bank SET nr_employed = 0        WHERE nr_employed IS NULL;
UPDATE raw_bank SET call_duration = 0
WHERE call_duration IS NULL OR call_duration = '' OR call_duration < 0;


INSERT INTO campaigns (code, name, start_date)
VALUES ('CAMP_001', 'Bank Telemarketing Campaign', '2010-01-01');

INSERT INTO clients (
  age, job, marital, education,
  default_flag, housing_flag, loan_flag, balance
)
SELECT DISTINCT
  age, job, marital, education,
  default_flag, housing_flag, loan_flag,
  0.00
FROM raw_bank;

INSERT INTO econ_indicators (
  period_start,
  emp_var_rate,
  cons_price_idx,
  cons_conf_idx,
  euribor3m,
  nr_employed
)
SELECT DISTINCT
  '2010-01-01',
  emp_var_rate,
  cons_price_idx,
  cons_conf_idx,
  euribor3m,
  nr_employed
FROM raw_bank;

INSERT INTO contacts (
  client_id,
  campaign_id,
  econ_id,
  contact_type,
  contact_month,
  day_of_week,
  call_duration,
  campaign_contacts_count,
  pdays,
  previous,
  poutcome,
  subscribed,
  created_at
)
SELECT
  c.client_id,
  1,
  e.econ_id,
  contact_type,
  LOWER(SUBSTRING(contact_month,1,3)),
  day_of_week,
  call_duration,
  campaign_count,
  pdays,
  previous,
  poutcome,
  (subscribed_raw = 'yes'),
  '2010-01-01'
FROM raw_bank r
JOIN clients c
  ON c.age = r.age AND c.job = r.job AND c.marital = r.marital
 AND c.education = r.education
 AND c.default_flag = r.default_flag
 AND c.housing_flag = r.housing_flag
 AND c.loan_flag = r.loan_flag
JOIN econ_indicators e
  ON e.emp_var_rate = r.emp_var_rate
 AND e.cons_price_idx = r.cons_price_idx
 AND e.cons_conf_idx = r.cons_conf_idx
 AND e.euribor3m = r.euribor3m
 AND e.nr_employed = r.nr_employed;

INSERT INTO previous_outcomes (
  client_id,
  prev_contacts,
  last_poutcome,
  last_pdays
)
SELECT
  c.client_id,
  previous,
  poutcome,
  pdays
FROM raw_bank r
JOIN clients c
  ON c.age = r.age AND c.job = r.job AND c.marital = r.marital
 AND c.education = r.education
 AND c.default_flag = r.default_flag
 AND c.housing_flag = r.housing_flag
 AND c.loan_flag = r.loan_flag
WHERE previous > 0;







