-- 1. Executive Performance
/*
-- 1.1 Which marketing campaigns generated the highest revenue?
-- 1.2 Which campaigns delivered the highest ROI?
-- 1.3 Which acquisition channels generated the most customers?
-- 1.4 Which acquisition channels generated the highest revenue?
*/

-- 1.1 Which marketing campaigns generated the highest revenue?
SELECT 
	c.campaign_name,
    c.campaign_id,
	SUM(order_amount) revenue
FROM campaigns c
INNER JOIN transactions t
ON c.campaign_id = t.campaign_id 
GROUP BY 
	c.campaign_id,
    c.campaign_name
ORDER BY revenue DESC;

-- 1.2 Which campaigns delivered the highest ROI?
SELECT 
	c.campaign_name,
    c.campaign_id,
    c.budget,
	SUM(order_amount) AS revenue,
    SUM(order_amount) - budget AS net_profit,
    ROUND(SUM(order_amount) / budget, 2) AS revenue_to_budget_ratio,
    ROUND((SUM(order_amount) - budget) / budget * 100, 2) AS roi_pct
FROM campaigns c
INNER JOIN transactions t
ON c.campaign_id = t.campaign_id 
GROUP BY 
	c.campaign_id,
    c.campaign_name,
    c.budget
ORDER BY revenue DESC;

-- 1.3 Which acquisition channels generated the most customers?
SELECT 
	acquisition_channel, 
	COUNT(*) AS total_customers
FROM customers
GROUP BY acquisition_channel
ORDER BY total_customers DESC;

-- 1.4 Which acquisition channels generated the highest revenue?
WITH customer_acquisition AS
(
SELECT 
    c.acquisition_channel,
    SUM(t.order_amount) AS revenue
FROM customers c
INNER JOIN transactions t
	ON	c.customer_id = t.customer_id
GROUP BY c.acquisition_channel
),
channel_budget as
(
SELECT 
	channel,
    SUM(budget) AS total_budget
FROM campaigns
GROUP BY channel
)
SELECT 
	ca.acquisition_channel AS channel,
    cb.total_budget,
    ca.revenue AS total_revenue,
    ca.revenue - cb.total_budget AS net_profit,
	ROUND(ca.revenue / cb.total_budget, 2) AS roi_ratio
FROM customer_acquisition ca
LEFT JOIN channel_budget cb
	ON ca.acquisition_channel = cb.channel
ORDER BY revenue DESC;


-- 2. Customer acquisation
/*
1. Which customer acquisition channels attracted the highest-value customers?
2. Which campaigns produce repeat buyers?
3. What percentage of customers were acquired organically versus through paid campaigns?
4. On average, how long does it take customers from each acquisition channel to make their first purchase?
*/

-- 2.1 Which customer acquisition channels attracted the highest-value customers?
SELECT 
	c.acquisition_channel,
    COUNT(t.transaction_id) total_transactions,
    ROUND(SUM(t.order_amount) / COUNT(DISTINCT c.customer_id), 2) AS revenue_per_customer
FROM customers c
LEFT JOIN transactions t
	ON c.customer_id = t.customer_id
GROUP BY c.acquisition_channel
ORDER BY revenue_per_customer DESC;

-- 2.2 Which campaigns produce repeat buyers?. 
/*
I later met with the stake holder to properly define who is a repeat buyer.
He defined a repeat buyer as one that has made transactions at two or more distinct months.
*/
WITH retained AS (
    SELECT 
        customer_id, 
        COUNT(DISTINCT DATE_FORMAT(transaction_date, '%Y-%m')) AS no_of_active_months
    FROM transactions
    GROUP BY customer_id
)
SELECT
    ca.campaign_name,
    -- 1. Total customers brought in by this campaign
    COUNT(c.customer_id) AS total_acquired_customers,
    
    -- 2. Out of those, how many became repeat buyers (retained)
    SUM(CASE WHEN r.no_of_active_months >= 2 THEN 1 ELSE 0 END) AS repeat_customers 
FROM customers c
INNER JOIN campaigns ca
    ON c.acquisition_campaign_id = ca.campaign_id
LEFT JOIN retained r
    ON c.customer_id = r.customer_id
GROUP BY ca.campaign_name
ORDER BY repeat_customers  DESC;


-- 2.3 What percentage of customers were acquired organically versus through paid campaigns?

WITH categorized_customers AS (
    SELECT 
        customer_id,
        -- Group channels into Paid vs. Organic based on the campaign ID
        CASE 
            WHEN acquisition_campaign_id IS NULL THEN 'Organic'
            ELSE 'Paid Campaign'
        END AS acquisition_type
    FROM customers
)
SELECT 
    acquisition_type,
    COUNT(*) AS customers_acquired,
    ROUND((COUNT(*) / SUM(COUNT(*)) OVER()) * 100, 2) AS total_percent
FROM categorized_customers
GROUP BY acquisition_type;

-- 2.4 On average, how long does it take customers from each acquisition channel to make their first purchase?
WITH purchase_time_gap AS
(
	SELECT 
		c.customer_id,
		c.acquisition_channel,
		c.signup_date,
		MIN(t.transaction_date) AS purchase_date,
		TIMESTAMPDIFF(DAY, c.signup_date, MIN(t.transaction_date)) AS time_gap
	FROM customers c
	JOIN transactions t
		ON c.customer_id = t.customer_id
	GROUP BY 
		c.customer_id,
        c.acquisition_channel,
        c.signup_date
)
SELECT
	acquisition_channel,
    COUNT(*) AS customers,
    ROUND(AVG(time_gap), 2) AS avg_days_to_first_purchase
FROM purchase_time_gap
GROUP BY acquisition_channel;

-- 3. Customer Segmentation
/*
3.1 Which age groups spend the most per customer?
3.2 Which regions generate the highest revenue?
3.3 Which customers have never purchased after signup?
3.4 Which regions have the highest average order value?
*/

/*
-- Which age groups generates the most revenue?
-- Which age group generated the most sales overall?
-- Which age group spends the most per order?
*/
WITH age_bracket AS
(
SELECT 
	customer_id,
    age,
    acquisition_channel,
    CASE
		WHEN age BETWEEN 18 AND 24  THEN 'Gen Z'
        WHEN age BETWEEN 25 AND 40  THEN 'Millennials'
        WHEN age BETWEEN 41 AND 56  THEN 'Gen X'
        ELSE 'Baby Boomers'
	END AS age_group
FROM customers
)
SELECT
	age_group,
    COUNT(*) transactions_total,
    COUNT(DISTINCT t.customer_id) AS customers_who_purchased,
    SUM(order_amount) AS revenue,
    ROUND(SUM(order_amount) / COUNT(DISTINCT t.customer_id), 2) revenue_per_customer,
    ROUND(AVG(order_amount), 2) AS avg_spend_per_order
FROM age_bracket a
JOIN transactions t
	ON a.customer_id = t.customer_id
GROUP BY age_group
ORDER BY revenue_per_customer DESC;

-- 3.2 Which regions generate the highest revenue?
SELECT 
	c.region,
    COUNT(DISTINCT t.customer_id) AS customer,
    ROUND(SUM(order_amount) / COUNT(DISTINCT t.customer_id), 2) AS region_revenue_per_customer,
    SUM(order_amount) AS revenue_per_region
FROM customers c
JOIN transactions t
	ON c.customer_id = t.customer_id
GROUP BY c.region
ORDER BY revenue_per_region DESC;

-- 3.3 Which customers have never purchased after signup?
SELECT c.customer_id
FROM customers c
LEFT JOIN transactions t
	ON c.customer_id = t.customer_id
WHERE t.customer_id IS NULL;

-- 3.4 Which regions have the highest average order value?
SELECT 
	c.region,
    COUNT(DISTINCT t.customer_id) AS customer,
    ROUND(AVG(order_amount), 2) AS AVG_order_value
FROM customers c
JOIN transactions t
	ON c.customer_id = t.customer_id
GROUP BY c.region
ORDER BY AVG_order_value DESC;

-- 4. Monthly Revenue Analysis
/*
-- 4.1 Monthly revenue trend
-- 4.2 Monthly customer acquisition trend
*/
-- 4.1 Monthly revenue trend
SELECT
    DATE_FORMAT(transaction_date, '%Y-%m') AS months,
    SUM(order_amount) AS revenue
FROM transactions
GROUP BY months
ORDER BY months;

-- 4.2 Monthly customer acquisition trend
SELECT
	DATE_FORMAT(signup_date, '%Y-%m') AS months,
    COUNT(*) AS total_customers_acquired
FROM customers
GROUP BY months
order by months;





