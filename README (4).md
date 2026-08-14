# Marketing Campaign Performance & Customer Segmentation

> **End-to-end marketing analytics project using MySQL and Tableau to evaluate campaign performance, customer acquisition, purchasing behavior, and regional/segment performance.**

![SQL](https://img.shields.io/badge/SQL-MySQL-4479A1?style=for-the-badge&logo=mysql&logoColor=white)
![Tableau](https://img.shields.io/badge/Tableau-Public-E97627?style=for-the-badge&logo=tableau&logoColor=white)
![Analytics](https://img.shields.io/badge/Analytics-Marketing-2F80ED?style=for-the-badge)

---

## Table of Contents

- [Project Overview](#project-overview)
- [Business Problem](#business-problem)
- [Business Objectives](#business-objectives)
- [Stakeholders](#stakeholders)
- [Dataset](#dataset)
- [Database Schema Design](#database-schema-design)
- [Data Cleaning & Validation](#data-cleaning--validation)
- [SQL Analysis](#sql-analysis)
- [Key Findings](#key-findings)
- [Tableau Dashboard](#tableau-dashboard)
- [Recommendations](#recommendations)
- [Limitations & Analytical Considerations](#limitations--analytical-considerations)
- [Project Structure](#project-structure)
- [Tools & Skills Demonstrated](#tools--skills-demonstrated)
- [How to Reproduce](#how-to-reproduce)

---

## Project Overview

This project evaluates the effectiveness of marketing campaigns and customer acquisition channels while examining purchasing behavior across customer segments and regions.

Rather than treating the source CSVs as ready-to-query data, I approached the project as an end-to-end analytics workflow:

**Raw Data → Relational Database Design → Data Cleaning & Validation → SQL Analysis → Tableau Visualization → Business Insights → Recommendations**

The analysis covers the **2021–2025 reporting period used in the Tableau dashboards**.

The goal is to help marketing stakeholders understand:

- Which campaigns generate the strongest revenue and return relative to spend.
- Which acquisition channels attract the most customers and highest-value customers.
- Which campaigns produce repeat buyers.
- How customer value differs across age groups and regions.
- How quickly customers make their first purchase.
- Where marketing investment and customer-engagement opportunities may exist.

---

## Business Problem

The marketing team has invested in multiple campaigns across several channels, but needs clearer evidence of which campaigns and channels are delivering the strongest commercial outcomes.

At the same time, customer purchasing behavior varies across acquisition sources, age groups, and regions. Without a structured analysis, marketing budget allocation and customer-targeting decisions may rely too heavily on aggregate performance.

## Business Objective

The project aims to:

1. Evaluate campaign revenue and return on marketing spend.
2. Compare acquisition channels by customer volume and customer value.
3. Understand repeat-purchase behavior among campaign-acquired customers.
4. Identify high-value customer segments by age and region.
5. Measure the time from customer signup to first purchase.
6. Identify customers without purchase activity for potential re-engagement.
7. Translate the analysis into actionable marketing recommendations.

---

## Stakeholders

### Primary Stakeholders

- **Chief Marketing Officer (CMO)** — campaign and budget allocation.
- **Marketing Manager** — campaign and channel performance.
- **Customer/CRM Manager** — customer acquisition and repeat-purchase behavior.

### Secondary Stakeholders

- Finance
- Regional Managers
- Executive Leadership

---

## Dataset

The project uses three related datasets.

| Table | Purpose |
|---|---|
| `campaigns` | Campaign name, marketing channel, and campaign budget |
| `customers` | Customer demographics, region, signup date, acquisition channel, and acquisition campaign |
| `transactions` | Transaction dates, attributed campaign, and order amount |

### Data scale

- **25 campaigns**
- **50,000 customers**
- **164,549 transactions**
- Customer signup period: **2021–2025**
- Transaction period: **2021–2026 in the source data**
- Tableau reporting period: **2021–2025**

---

## Database Schema Design

The original source tables did not enforce a complete relational structure. I therefore rebuilt the analytical database with explicit primary keys, foreign keys, appropriate data types, and constraints before beginning the analysis.

### Final schema

```text
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
```

### Relationships

```text
                 ┌──────────────────┐
                 │     campaigns     │
                 │──────────────────│
                 │ campaign_id (PK) │
                 │ campaign_name    │
                 │ channel          │
                 │ budget           │
                 └────────┬─────────┘
                          │
             ┌────────────┴────────────┐
             │                         │
             ▼                         ▼
     acquisition_campaign_id       campaign_id
             │                         │
     ┌───────┴────────┐        ┌───────┴─────────┐
     │   customers    │        │   transactions  │
     │────────────────│        │─────────────────│
     │ customer_id PK │◄───────┤ customer_id FK  │
     │ age            │        │ campaign_id FK  │
     │ region         │        │ transaction_date│
     │ signup_date    │        │ order_amount    │
     │ acquisition_   │        └─────────────────┘
     │ channel        │
     └────────────────┘
```

### Acquisition vs. Transaction Campaign

A key modeling decision was to retain both campaign concepts:

- **Acquisition campaign**: the campaign associated with acquiring the customer.
- **Transaction campaign**: the campaign associated with an individual transaction.

These fields are not interchangeable. A customer may have been acquired through one campaign and make a later purchase associated with another campaign.

---

## Data Cleaning & Validation

Several data-quality and modeling issues were addressed before analysis.

### 1. Data type correction

`signup_date` was converted from a text representation into the SQL `DATE` data type.

### 2. Missing campaign IDs

The raw data represented missing campaign relationships using empty strings (`''`).

These were converted to proper SQL `NULL` values using:

```sql
NULLIF(acquisition_campaign_id, '')
```

The same treatment was applied to nullable transaction campaign IDs.

This allows missing campaign relationships to be handled using standard SQL `NULL` logic.

### 3. Referential integrity

Primary and foreign keys were implemented to enforce valid relationships between:

- Customers and campaigns.
- Transactions and customers.
- Transactions and campaigns.

### 4. Validation checks

The analysis included checks for:

- Duplicate customer IDs.
- Orphaned campaign IDs.
- Completely empty campaign records.
- Missing campaign relationships.

---

# SQL Analysis

The SQL analysis was organized around four business areas.

## 1. Executive Campaign Performance

### Stakeholder questions

- Which campaigns generated the highest revenue?
- Which campaigns delivered the strongest return on marketing spend?
- Which acquisition channels generated the most customers?
- Which acquisition channels generated the highest revenue?

### Metrics

**Revenue**

```text
SUM(order_amount)
```

**Revenue-to-spend ratio**

```text
Revenue / Campaign Budget
```

**ROI %**

```text
(Revenue - Campaign Budget) / Campaign Budget × 100
```

> Revenue divided by budget is treated as a revenue-to-spend ratio. It is not technically ROI; the percentage formula above is used as the ROI-style measure.

---

## 2. Customer Acquisition

### Stakeholder questions

- Which acquisition channels attracted the highest-value customers?
- Which campaigns produce repeat buyers?
- What proportion of customers were acquired through campaigns versus without an associated campaign?
- How long does it take customers from each acquisition channel to make their first purchase?

### Repeat-buyer definition

A repeat buyer was defined through a stakeholder rule:

> **A repeat buyer is a customer who made transactions in at least two distinct calendar months.**

This was implemented using a CTE that counts distinct transaction months per customer.

---

## 3. Customer Segmentation

### Stakeholder questions

- Which age groups generate the most revenue?
- Which age groups generate the most revenue per customer?
- Which regions generate the highest revenue?
- Which regions have the highest average order value?
- Which customers have never purchased after signup?

### Age segments

| Age | Segment |
|---|---|
| 18–24 | Gen Z |
| 25–40 | Millennials |
| 41–56 | Gen X |
| 57+ | Baby Boomers |

The analysis compares revenue, revenue per customer, transaction volume, and average order value across the segments.

---

## 4. Time-Based Analysis

The project also examines:

- Monthly revenue trends.
- Monthly customer acquisition trends.
- Time from signup to first purchase.

---

# Key Findings

> **Important:** The findings below use the 2021–2025 reporting period used by the dashboard analysis. Campaign revenue/ROI is based on transactions attributed to campaigns, while acquisition-channel revenue is based on the acquisition channel of the customer.

## 1. Email was the strongest acquisition channel by both customer volume and revenue

Email acquired the largest customer group:

- **15,073 customers**
- **$8.38M revenue** during 2021–2025

It also generated the highest revenue per acquired customer at approximately **$556** over the dashboard period.

This suggests that Email was not only effective at acquiring customers at scale but also generated strong commercial value.

---

## 2. Campaign performance varied substantially by return on spend

The highest-revenue campaign during 2021–2025 was:

**Premium Bundle Email — $2.16M attributed revenue**

The highest ROI campaign was:

**Newsletter Promo Email — approximately 48,359% ROI**

This illustrates why campaign performance should not be evaluated using revenue alone. A campaign can generate substantial revenue while another produces a stronger return relative to its budget.

---

## 3. Email campaigns dominated the highest-performing campaigns

The strongest campaigns by both revenue and ROI were heavily represented by Email campaigns.

This indicates that Email was particularly effective within the campaign portfolio and may warrant further investment or testing.

However, budget reallocation should consider customer quality and repeat purchasing alongside immediate revenue.

---

## 4. East and North were the strongest regions

The **East** region generated the highest revenue during 2021–2025:

**$6.86M**

The **North** region followed closely at:

**$6.75M**

North had the highest average order value at approximately **$214**, while East generated the highest revenue per customer at approximately **$571**.

This suggests that East and North represent the strongest regional markets, although they demonstrate slightly different strengths.

---

## 5. Gen X and Millennials generated similar customer value

The age analysis showed that:

- **Gen X** generated approximately **$7.47M**
- **Millennials** generated approximately **$7.43M**

Gen X had the highest revenue per customer at approximately **$544**, closely followed by Millennials at approximately **$543**.

This indicates that these two segments represent particularly valuable customer groups, although Baby Boomers generated the highest total revenue because of their larger customer base.

---

## 6. Repeat purchasing represents a significant opportunity

Using the stakeholder's definition of a repeat buyer—transactions in at least two distinct calendar months—approximately **20,909 customers** qualified as repeat buyers in the transaction data used for the analysis.

Among campaign-acquired customers, **Search Generic Keywords** had the highest repeat-purchase rate at approximately **43.9%**.

This suggests that campaign effectiveness should not be judged solely on acquisition volume or first-purchase revenue. The ability of a campaign to attract customers who continue purchasing is also important.

---

## 7. Customers generally converted relatively quickly after signup

Average time to first purchase was approximately **15 days across acquisition channels**, with only small differences between channels.

Paid Search had the shortest average time to first purchase at approximately **14.9 days**.

The relatively small difference between channels suggests that acquisition-channel selection may have a greater impact on customer value and volume than on initial purchase timing in this dataset.

---

## 8. Geographic performance was concentrated in East and North

East and North together generated substantially more revenue than the remaining regions.

Meanwhile, South had the lowest revenue per customer and lowest average order value.

This creates an opportunity for region-specific marketing strategies rather than applying the same budget allocation across every market.

---

# Tableau Dashboard

The SQL analysis was connected to Tableau to create an interactive marketing performance dashboard.

### Dashboard objectives

The dashboard allows stakeholders to:

- Monitor overall marketing performance.
- Compare campaign revenue and ROI.
- Evaluate acquisition-channel performance.
- Explore customer segments.
- Compare regional performance.
- Analyze performance by year and date range.
- Drill into campaign and customer-level performance.

### Dashboard views

The dashboard is organized around:

1. **Executive Overview**
2. **Customer & Regional Analysis**
3. **Campaign Performance**
4. **Year-based analysis through interactive filters**

The yearly views are controlled through dashboard filters rather than being separate analytical datasets.

### Tableau Public

**[View the interactive Marketing Campaign Performance Dashboard](https://public.tableau.com/views/campaignproject_17866101499390/Dashboard12?:language=en-US&publish=yes)**

---

# Recommendations

## 1. Prioritize high-return Email campaigns

Email campaigns consistently appeared among the strongest campaigns by revenue and ROI.

**Recommendation:**  
Prioritize high-performing Email campaigns while continuing controlled testing of messaging, offers, and audience targeting rather than simply increasing spend.

---

## 2. Evaluate campaigns using customer quality, not acquisition volume alone

Some campaigns attract large numbers of customers, but acquisition volume does not necessarily indicate long-term customer value.

**Recommendation:**  
Use a combined campaign scorecard containing:

- Revenue
- ROI
- Revenue per acquired customer
- Repeat-buyer rate
- Customer acquisition volume

---

## 3. Focus regional investment on East and North

East generated the highest revenue while North demonstrated the highest average order value.

**Recommendation:**  
Prioritize these regions for growth initiatives while investigating why South and Central produce lower customer value.

---

## 4. Target Gen X and Millennials with value-focused campaigns

These segments demonstrated the highest revenue per customer.

**Recommendation:**  
Develop targeted offers and messaging for Gen X and Millennials while avoiding the assumption that age alone determines customer value.

---

## 5. Develop re-engagement strategies around repeat purchasing

Repeat buyers represent a substantial customer group, and some acquisition campaigns produce stronger repeat-purchase rates than others.

**Recommendation:**  
Use campaign-level repeat-purchase performance when evaluating acquisition quality and design follow-up campaigns for customers who have not returned after their first purchase.

---

# Analytical Considerations & Limitations

### Campaign attribution

The project contains both acquisition-campaign and transaction-campaign fields. They answer different attribution questions and should not be treated as interchangeable.

### ROI interpretation

The analysis treats campaign budget as marketing investment and transaction revenue as campaign-attributed revenue. This produces a **revenue-based ROI proxy**, not accounting profit.

A true profitability analysis would require additional cost data such as:

- Product cost
- Fulfillment
- Discounts
- Operational costs
- Other marketing expenses

### Customer lifetime value

Revenue per customer is used as a customer-value metric. It should not automatically be interpreted as a full Customer Lifetime Value (CLV) calculation without a defined lifetime/cohort methodology.

### Organic acquisition

Customers with a `NULL` acquisition campaign are treated as having no associated campaign. If the source system does not explicitly define these customers as organic, they should more precisely be described as **unattributed/no-campaign customers**.

### Dataset limitations

The dataset does not contain:

- Impressions
- Clicks
- Email opens
- Conversion-funnel events
- Product-level costs
- Gross margin
- Customer demographics beyond age and region

Therefore, metrics such as CTR, CAC, true profit margin, and full-funnel conversion cannot be calculated reliably from the available data.

---

# Project Structure

```text
Marketing-Campaign-Performance/
│
├── data/
│   └── raw/
│       ├── campaigns.csv
│       ├── customers.csv
│       └── transactions.csv
│
├── sql/
│   ├── Marketing Analysis Portfolio.sql
│   └── Marketing analysis eda.sql
│
├── dashboard/
│   └── Tableau Public dashboard
│
├── images/
│   └── dashboard screenshots
│
└── README.md
```

---

# Tools & Skills Demonstrated

### MySQL

- Relational database design
- Primary and foreign keys
- Constraints
- Data cleaning
- Data validation
- `JOIN`
- `LEFT JOIN`
- `GROUP BY`
- `HAVING`
- Aggregate functions
- `CASE`
- CTEs
- Window functions
- `COUNT(DISTINCT ...)`
- Conditional aggregation
- `NULLIF()`
- `TIMESTAMPDIFF()`
- Date formatting
- Ranking and comparative analysis

### Tableau

- KPI design
- Interactive filters
- Campaign performance visualization
- Customer segmentation
- Regional analysis
- Time-series analysis
- Executive dashboard design
- Business storytelling

### Business Analysis

- Stakeholder question formulation
- KPI definition
- Marketing performance analysis
- Customer acquisition analysis
- Customer segmentation
- Repeat-purchase analysis
- Regional performance analysis
- Recommendation development

---

# How to Reproduce

1. Load the raw CSV files into MySQL staging tables.
2. Create the cleaned relational schema using the database-design SQL script.
3. Load the raw data into the cleaned tables.
4. Run the data-cleaning and validation checks.
5. Execute the analytical SQL queries.
6. Connect the resulting data to Tableau.
7. Apply the dashboard filters to explore different years, channels, and date ranges.

---

## Final Takeaway

This project demonstrates an end-to-end approach to marketing analytics:

> **I didn't just query a dataset. I designed the relational structure, cleaned and validated the data, defined business metrics, analyzed campaign and customer performance with MySQL, and translated the results into an interactive Tableau dashboard.**

The analysis shows that **Email is a particularly strong acquisition channel, East and North are the strongest regions, Gen X and Millennials demonstrate high customer value, and repeat purchasing provides an important dimension for evaluating campaign quality beyond initial revenue.**

---

### Author

**Akan**  
Aspiring Data Analyst

**Skills:** MySQL · SQL · Tableau · Data Analysis · Database Design · Data Visualization
