-- SQL Project - Data Cleaning
/*
I noticed that the original database schema was not well designed. To address this, I'll rebuild 
the database with a properly defined schema that includes primary keys, foreign keys, and appropriate constraints.
*/
    
CREATE TABLE campaigns (
    campaign_id CHAR(6) NOT NULL,
    campaign_name VARCHAR(100) NOT NULL,
    channel VARCHAR(50) NOT NULL,
    budget DECIMAL(10,2) NOT NULL,

    PRIMARY KEY (campaign_id)
);
/*
Here I changed the signup_date datatype from text to Date type
*/
CREATE TABLE customers (
    customer_id CHAR(10) NOT NULL,
    age TINYINT UNSIGNED NOT NULL,
    region VARCHAR(50) NOT NULL,
    signup_date DATE NOT NULL,
    acquisition_channel VARCHAR(50) NOT NULL,
    acquisition_campaign_id CHAR(6) NULL,

    PRIMARY KEY (customer_id),

    CONSTRAINT fk_customer_campaign
        FOREIGN KEY (acquisition_campaign_id)
        REFERENCES campaigns(campaign_id)
);

CREATE TABLE transactions (
    transaction_id CHAR(10) NOT NULL,
    customer_id CHAR(10) NOT NULL,
    campaign_id CHAR(6) NULL,
    transaction_date DATE NOT NULL,
    order_amount DECIMAL(10,2) NOT NULL,

    PRIMARY KEY (transaction_id),

    CONSTRAINT fk_transaction_customer
        FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id),

    CONSTRAINT fk_transaction_campaign
        FOREIGN KEY (campaign_id)
        REFERENCES campaigns(campaign_id)
);

/*
The next thing i did was to import the data from the raw table into their new and cleaned corresponding schema
*/

INSERT INTO campaigns (
    campaign_id,
    campaign_name,
    channel,
    budget
)
SELECT
    campaign_id,
    campaign_name,
    channel,
    budget
FROM campaigns_raw;

/*
Some customers were acquired organically and therefore have no associated campaign.

The raw dataset stored these missing values as empty strings (''), which are
not appropriate for relational databases. NULLIF() converts empty strings into
proper SQL NULL values. 
*/
INSERT INTO customers (
    customer_id,
    age,
    region,
    signup_date,
    acquisition_channel,
    acquisition_campaign_id
)
SELECT
    customer_id,
    age,
    region,
    signup_date,
    acquisition_channel,
    NULLIF(acquisition_campaign_id, '')
FROM customers_raw;

INSERT INTO transactions (
    transaction_id,
    customer_id,
    campaign_id,
    transaction_date,
    order_amount
)
SELECT
    transaction_id,
    customer_id,
    NULLIF(campaign_id, ''),
    transaction_date,
    order_amount
FROM transactions_raw;

-- Validate data intergrity.
-- 1. check for duplicate customers in the customers table
-- 2. Verified there were no orphaned campaign IDs.(Although i've already enforced referential integrity)
-- 3. check if any record is completely empty.
-- 4. Check for zero/negative transactions.

-- I checked for duplicate customers in the customers table
SELECT customer_id, COUNT(*) customer_count
FROM customers
GROUP BY customer_id
HAVING customer_count > 1;

-- I Verified that there were no orphaned campaign IDs
SELECT t.campaign_id, c.campaign_name
FROM transactions t
LEFT JOIN campaigns c
	ON	t.campaign_id = c.campaign_id
WHERE t.campaign_id IS NOT NULL
AND c.campaign_id IS NULL;


-- I checked to find out if there were any empty entity(rows) from the campaigns table
SELECT COUNT(*) AS empty_records
FROM campaigns
WHERE campaign_id IS NULL
  AND campaign_name IS NULL
  AND channel IS NULL
  AND budget IS NULL;
  
-- i checked for negative transactions
SELECT *
FROM transactions
WHERE order_amount <= 0;

/*
-- FINAL SCHEMA

campaigns
---------
campaign_id (PK)
campaign_name
channel
budget

customers
---------
customer_id (PK)
age
region
signup_date
acquisition_channel
acquisition_campaign_id (FK → campaigns.campaign_id)

transactions
------------
transaction_id (PK)
customer_id (FK → customers.customer_id)
campaign_id (FK → campaigns.campaign_id)
transaction_date
order_amount
*/

/*
Assumptions

- Every customer must have a valid customer_id.
- Every transaction belongs to an existing customer.
- Campaign IDs are optional because some purchases were organic.
*/

