# Marketing Campaign Performance Analysis

## Overview

This project analyzes a multi-year marketing dataset (2021–2025) covering three channels of activity — **campaigns**, **customers**, and **transactions** — to answer a core business question: *which acquisition channels, campaigns, and customer segments actually drive profitable revenue, and where is marketing spend being wasted?*

The work spans the full analytics lifecycle: raw data cleaning and schema redesign, exploratory SQL analysis structured around specific business questions, and two Tableau dashboards built for an executive audience.

## Business Questions

The analysis was organized around four themes, each translating a business need into a specific, answerable question.

**1. Executive Performance**
- Which campaigns generated the highest revenue, and which delivered the highest ROI?
- Which acquisition channels generated the most customers, and the most revenue?

**2. Customer Acquisition**
- Which channels attracted the highest-value customers?
- Which campaigns produce repeat buyers? *(Defined with stakeholder input as a customer transacting in 2+ distinct months — this required a follow-up conversation to pin down, since "repeat buyer" had no fixed definition in the raw data.)*
- What share of customers were acquired organically vs. through paid campaigns?
- How long does it take a customer to make their first purchase, by channel?

**3. Customer Segmentation**
- Which age groups and regions spend the most, and generate the highest average order value?
- Which customers signed up but never purchased?

**4. Time Trends**
- What does monthly revenue and customer acquisition look like over time?

## Data & Schema

The raw dataset arrived without enforced relationships or clean typing. The database was rebuilt with a proper relational schema before any analysis began:

- **`campaigns`** (campaign_id PK) — name, channel, budget
- **`customers`** (customer_id PK) — age, region, signup_date, acquisition_channel, acquisition_campaign_id (FK, nullable for organic signups)
- **`transactions`** (transaction_id PK) — customer_id (FK), campaign_id (FK, nullable for organic purchases), transaction_date, order_amount

Cleaning steps included converting `signup_date` from text to a proper `DATE` type, and using `NULLIF()` to convert empty-string placeholders in the raw tables into true SQL `NULL` values for customers/transactions with no associated campaign. Post-load validation checked for duplicate customer records, orphaned foreign keys, and fully empty rows.

## Key Findings

**Channel efficiency is wildly uneven.** Email marketing consistently and dramatically outperforms every other channel on ROI — individual email campaigns regularly returned 1,300%–2,400% ROI in 2021 alone. Paid Search is the weakest performer by a wide margin: several individual campaigns (e.g., `Search_Discount_20`, `Search_Generic_Keywords`) actually produced **negative ROI** in 2021, meaning they lost money outright. This is the single most actionable finding in the dataset — it points to specific paid search campaigns worth pausing or restructuring, not just "spend less on paid search" in general.

**Revenue is concentrated in two regions.** East and North each account for roughly 25% of total revenue and customer volume, while West and South trail meaningfully on both volume and average order value (~$190 AOV vs. ~$216 in East/North).

**The 57+ age group is the top-spending segment**, generating the largest single share of total revenue — a notable finding for a brand whose campaign creative (social/influencer-led) likely skews toward a younger assumed audience.

**Organic acquisition is not a rounding error.** Roughly 20% of all customers acquired came through no paid campaign at all, contributing several million dollars in revenue with zero attributable spend — a channel worth explicitly tracking and protecting, not just a leftover bucket.

**Repeat-buyer rates vary meaningfully by campaign**, which made it possible to separate campaigns that acquire high-volume but one-and-done customers from campaigns that acquire smaller numbers of durably loyal ones — a distinction the raw revenue-by-campaign ranking alone would have hidden.

## Dashboards

Two Tableau dashboards were built for an executive audience, filterable by channel and year:

- **Executive Overview** — Total revenue, spend, net profit, ROI%, and customer count at a glance, with revenue-over-time, revenue-by-channel, revenue-by-age breakdowns, and a full campaign performance index.
- **Customer & Regional Performance** — Top region by revenue/customers/AOV, channel acquisition mix, organic-vs-paid split, and a region-level performance table.

## Known Data Limitations & Design Decisions

Two issues surfaced during dashboard QA and are documented here rather than hidden:

1. **Monthly trend aggregation bug (fixed).** The initial monthly revenue trend grouped by month-number only (`%m`), which collapsed five years of data into twelve buckets and produced a misleading spike. Fixed by including the year in the date grouping.
2. **ROI framing on multi-year views.** Campaign `budget` in the source data is a single fixed value with no per-year dimension. On multi-year ("All Years") views, this means cumulative revenue is compared against a one-time cost, producing very large percentages (e.g., 4,000%+). Rather than fabricate a per-year budget split that the data doesn't support, multi-year views are labeled as a **lifetime revenue multiple** rather than an annualized ROI%, with a note clarifying that the budget reflects a single recorded investment, not recurring annual spend.

## Tools Used

MySQL (schema design, data cleaning, EDA) · Tableau (dashboard design)

## Files in This Project

| File | Description |
|---|---|
| `Marketing Analysis Portfolio.sql` | Schema redesign, data cleaning, and load/validation queries |
| `Marketing analysis eda.sql` | Business-question-driven exploratory analysis |
| Tableau dashboards | Executive Overview and Customer & Regional Performance |

## Next Steps

- Add an ERD and data dictionary for faster onboarding of new reviewers
- Add a schema setup script so the project can be reproduced end-to-end from raw data
- Revisit the ROI framing if a per-year budget field becomes available in the source data
