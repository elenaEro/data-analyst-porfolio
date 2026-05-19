# E-COMMERCE SITE DATA ANALYTICS

## Uploading files with raw data to BigQuery

Uploaded the Olist Brazilian E-Commerce dataset using:
- Kaggle API to download the data
- Google Colab + Python to upload to BigQuery

- Dataset 1: https://www.kaggle.com/olistbr/brazilian-ecommerce
- Dataset 2: https://www.kaggle.com/datasets/olistbr/marketing-funnel-olist

[Google Colab file](https://github.com/elenaEro/data-analyst-porfolio/blob/main/ecommerce-elt-and-insights/bquery_files_uploading.ipynb)

## Data Cleaning & Preparation

## Overview

The analysis is based on a B2B2C marketplace dataset covering the period from June 2017 to November 2018. The raw data consisted of four source tables: MQL records, closed deals, orders, and order items. The preparation process involved three layers: staging (cleaning individual tables), aggregation (summarising order data at seller level), and a final analytical table combining all sources.

---

## Source Tables

- **mqls** - records of all marketing qualified leads with origin, landing page, and contact date
- **closed_deals** - information on won deals including SDR/SR assignment, business type, and won date
- **orders** - individual order records with status and purchase dates
- **order_items** - line items within each order including item price and freight value

---

## Staging Layer

Each source table was cleaned independently before joining.

### Orders & Order Items

- Freight value was separated from item price. GMV is calculated as the sum of item prices only, excluding freight, as freight represents a logistics cost rather than merchandise value
- Order statuses were standardised. Only two statuses were retained for analysis: `delivered` (completed transactions) and `canceled` (failed transactions). Other intermediate statuses such as `shipped` and `invoiced` were excluded as they do not represent a final transaction outcome
- Orders were aggregated at seller level producing one row per seller with total delivered orders, total canceled orders, total GMV, cancellation rate, AOV, and first/last order dates for both delivered and canceled orders

### MQLs & Closed Deals

- MQL records were joined with closed deal information to enrich each lead with post-conversion attributes where available
- `business_type`, `sdr_id`, `sr_id`, `won_date` and other deal-level fields are only populated for converted sellers. This is an intentional data characteristic, not a gap, as these fields are captured at the deal stage

---

## Final Analytical Table: fct_funnel

A single analytical table `fct_funnel` was created joining the enriched MQL view with the seller-level orders summary via a LEFT JOIN on `seller_id`. The table contains one row per MQL, 8,000 records total, preserving all leads regardless of conversion status.

### Key Derived Fields

| Field | Description |
|---|---|
| `is_won` | Binary flag, 1 if the MQL converted to a seller |
| `activated` | Binary flag, 1 if the won seller placed at least one delivered order |
| `sales_cycle_days` | Days between first contact date and won date |
| `days_to_activation` | Days between won date and first delivered order |
| `canc_rate` | Canceled orders / (delivered + canceled orders) |
| `aov` | GMV / delivered orders, NULL for sellers with no delivered orders |
| `gmv_tier` | Quartile-based seller segmentation (Q1 Low, Q2 Medium, Q3 High, Q4 Top) calculated using PERCENTILE_CONT to ensure boundaries fall between real data points |

---

## Data Quality Findings

### Null Values

- `declared_monthly_revenue` has an 89% null rate. This field was only captured for a small subset of leads and was excluded from segmentation analysis
- `business_type`, `sdr_id`, and other deal-level fields are null for all non-converted MQLs by design. These are post-conversion attributes not available at the MQL stage
- All order-related fields (GMV, AOV, cancellation rate) are null for non-converted and non-activated sellers. This is expected and intentional

### Zombie Sellers

465 won sellers have no corresponding order data. They signed contracts but never placed a single order on the platform. These sellers are counted in MQL to Won conversion metrics but excluded from Won to Activated rate calculations and post-conversion quality analysis.

### Negative Sales Cycle

One record was identified with a sales cycle of -2 days, meaning the won date preceded the first contact date. This is attributed to a CRM data entry error. The `sales_cycle_days` field was set to NULL for this record. It remains included in all conversion metrics.

### Data Coverage Gap

Won dates extend to November 2018 but order activity stops in August 2018. Sellers won after August 2018 had no opportunity to activate within the dataset window. These sellers are included in conversion metrics but excluded from activation rate calculations to avoid artificially deflating the won to activated rate.

### Join Coverage

The orders dataset contains 3,021 distinct seller IDs compared to 842 won sellers in the funnel table. The additional sellers in the orders data represent merchants onboarded through channels outside the MQL funnel or prior to the MQL tracking system being implemented.

---

## Limitations

- No intermediate funnel stage timestamps are available. Only first contact date and won date exist. Sales cycle length represents total time from first touch to close with no visibility into individual stage durations
- Landing page IDs are UUIDs with no associated metadata. Page content and intent cannot be inferred from the data alone
- The dataset covers a relatively short window of order activity (January to August 2018), limiting the depth of post-conversion seller behaviour analysis
- 495 distinct landing pages were identified but 87% have fewer than 20 MQLs. Only 64 pages meet the minimum threshold for reliable conversion rate analysis

## Sales Funnel Overview

### Funnel Structure

The funnel consists of three stages reflecting the seller 
acquisition journey on the platform:

1. **MQL** — lead submits a form expressing interest in 
selling on the platform
2. **Won** — lead signs a contract and is onboarded 
as a seller
3. **Activated** — seller places at least one delivered 
order on the platform

### Funnel Performance

| Stage | Volume | Conversion Rate |
|---|---|---|
| MQL | 8,000 | - |
| Won (signed contract) | 842 | 11% of MQLs |
| Activated (first order) | 376 | 45% of Won |
| Overall (MQL to Activated) | 376 | 5% of MQLs |

### Key Findings

**The primary drop-off occurs at the MQL to Won stage.**
Only 11% of all leads sign a contract, meaning 89% of generated leads do not convert to sellers. This is where 
the largest volume of leads is lost and represents the biggest lever for funnel improvement.

**Zombie sellers are a significant problem.**
Of 842 won sellers, only 376 placed at least one order, meaning 466 sellers (55%) signed contracts but never 
activated on the platform. Winning a seller does not guarantee platform participation. This pattern suggests 
issues in post-onboarding engagement or seller readiness at the point of signing.

**End-to-end efficiency is low.**
Only 5% of all MQLs result in an activated seller. While this reflects typical B2B marketplace dynamics 
where lead-to-activation journeys are long and complex, it highlights the importance of lead quality over lead 
volume acquiring fewer but better-qualified leads would have a disproportionate impact on platform GMV.

### Data Period
The dataset covers MQL activity from June 2017 to November 2018 with order activity recorded between 
January 2018 and August 2018. Sellers won after August 2018 are excluded from activation rate 
calculations as they had insufficient time to activate within the dataset window.

## Channel Performance Analysis

Conversion rates were calculated across all acquisition channels for two funnel stages: MQL to Won and Won to Activated.

### Key Findings

**Attribution gap**
Unknown origin records the highest MQL to won rate at 17%, indicating untagged traffic rather than a genuine channel. 
1,159 MQLs (14% of total) are unattributed, representing a priority fix for tracking infrastructure.

**Search channels lead on conversion quality**
Organic search and paid search are the two largest channels by volume (2,296 and 1,586 MQLs) and both convert at 12%. 
Paid search shows stronger post-conversion activation at 51% vs 41% for organic, suggesting paid traffic attracts more 
commercially motivated sellers.

**Direct traffic reflects multi-touch behaviour**
Direct traffic converts at 11% with the highest activation rate at 55%. This likely reflects a last-click attribution 
effect, sellers returning after earlier interactions rather than discovering the platform for the first time.

**Social media — volume without quality**
Social is the third largest channel at 1,350 MQLs but converts at only 6%, the largest volume-to-quality gap 
in the funnel. Activation among converted sellers (41%) is comparable to organic search, suggesting the issue 
is lead qualification at the top of the funnel rather than seller quality itself.

**Referral — small but efficient**
Referral converts at 8% with the fastest sales cycle of any channel. Pre-qualified leads require less convincing 
and close significantly faster than any other source.

**Email and other_publicities underperform**
Both channels convert at 3% despite generating 493 and 215 MQLs respectively. Poor conversion relative to volume 
suggests a targeting or messaging issue requiring review.

### Limitation
Single-touch last-click attribution at MQL stage understates upper-funnel channel contributions and overstates direct 
traffic as an independent acquisition source. A multi-touch attribution model would provide a more accurate picture 
of channel influence across the full buyer journey.Sonnet 4.6Claude is AI and can make mistakes. Please double-check responses.ShareContentYour previous message wasn't sent. You can try again.

## Landing Page Performance

Conversion analysis was restricted to landing pages with a minimum of 20 MQLs, 64 pages out of 495 total. Pages are identified by UUID only as no metadata table linking IDs to page content was available.

### Volume Distribution

Of 495 distinct landing pages identified in the dataset, 87% have fewer than 20 MQLs and were excluded from analysis 
due to insufficient sample size for reliable conversion rate calculation. The 29 analysed pages account for the majority 
of total MQL volume.

### Key Findings

**Two pages drive disproportionate volume and quality**
The two highest volume pages generate 912 and 883 MQLs respectively — 22% of all leads combined — while converting 
at 19% and 20%, nearly double the overall funnel average of 11%. Activation rates for both pages sit at 47%. 
These pages represent the most efficient lead generation assets in the funnel.

**High volume does not guarantee quality**
Two pages with 495 and 445 MQLs convert at only 5% and 7% respectively, well below the funnel average. These pages 
attract significant traffic that does not translate to seller conversions, suggesting audience or messaging 
misalignment.

**Zero conversion pages require investigation**
Several pages with 40 to 90 MQLs show zero or near-zero conversions. One page generates 49 MQLs with zero won 
sellers. These pages consume acquisition budget and SDR capacity without producing pipeline value.

**Activation rates vary significantly**
Among pages with sufficient won seller volume, activation rates range from 20% to 57%. Pages 6 and 17 show notably 
strong activation at 52% and 57% respectively, suggesting the leads they attract are not only more likely to sign 
contracts, but also more likely to transact on the platform.

### Limitation
Landing page IDs are UUIDs with no associated content metadata. It is not possible to determine page topic, 
offer type, or target audience from the available data. Connecting page IDs to content categories would 
significantly enrich this analysis and enable actionable optimisation recommendations.

### Recommendation

- Investigate zero-conversion high-volume pages. Audit messaging, targeting, and lead qualification criteria for pages generating 40 plus MQLs with no conversions
- Study the two flagship pages — understand what makes them work and replicate those characteristics across lower-performing pages

## Sales Cycle Analysis

### Baseline Metrics

| Metric | Value |
|---|---|
| Minimum | 0 days |
| Q1 (25th percentile) | 5 days |
| Median | 14 days |
| Q3 (75th percentile) | 55 days |
| Maximum | 427 days |
| Average | 48.5 days |
| Won sellers analysed | 841 |

### Distribution Shape

The average sales cycle of 48.5 days is more than three times the median of 14 days, confirming a heavily right-skewed distribution. A small number of deals taking 130 to 427 days to close pulls the average up significantly. Median is used as the primary sales cycle metric throughout this analysis to avoid distortion from outliers.

### Key Observations

50% of won deals close within 14 days, suggesting motivated sellers decide quickly and the onboarding process is relatively frictionless. The interquartile range of 5 to 55 days indicates significant variability that warrants investigation by channel and SDR. One record was excluded due to a data entry error where the won date preceded first contact date.
For SMB-focused B2B2C marketplaces, a median of 14 days is competitive, reflecting the relatively low complexity of the seller onboarding decision compared to enterprise B2B contracts.


## Sales Cycle by Origin

| Origin | Won Sellers | Median Days | Avg Days |
|---|---|---|---|
| Display | 6 | 7 | 10.3 |
| Direct Traffic | 56 | 10 | 31.1 |
| Unknown | 193 | 11 | 41.9 |
| Referral | 24 | 13 | 32.5 |
| Organic Search | 270 | 14 | 50.2 |
| Paid Search | 195 | 15 | 56.6 |
| Email | 15 | 21 | 52.2 |
| Social | 75 | 30 | 61.0 |
| Other Publicities | 7 | 35 | 25.6 |

## Key Findings

Organic search and paid search account for 55% of all won deals (465 out of 841) but carry the heaviest outlier tail. Their averages of 50.2 and 56.6 days align with the overall Q3 threshold of 55 days, while their medians sit at 14-15 days. A 40-day gap indicating a significant proportion of slow-closing deals within these channels.

Referral shows the tightest distribution with median 13 days and average 32.5 days, a 19-day gap compared to 40 days for search channels. Referral leads close consistently fast with fewer outliers, confirming the pre-qualification effect of trust-based acquisition.

Social is the slowest channel at median 30 days, double the overall median of 14 days. Combined with a 6% MQL to won conversion rate, social attracts low-intent leads that both convert poorly and take longest to close.

Unknown origin closes at median 11 days despite being unattributed, suggesting these are high-intent leads from untracked sources arriving already decided.

Display and other_publicities have insufficient sample sizes (6 and 7 won sellers) and are excluded from conclusions.

## Recommendations

Fix attribution tracking for unknown origin — 193 won sellers closing in 11 days median is likely your most efficient segment, but cannot be actioned without source identification.

Investigate referral scaling: highest closing efficiency across all tracked channels with the tightest distribution. Active referral incentive programmes could yield consistent high-intent leads at low acquisition cost.

Review social strategy: the slowest closing channel with the lowest conversion rate. Improved audience targeting or budget reallocation toward search is warranted.

## SR Performance Analysis
SR performance was evaluated among won sellers only. Since `sr_id` is not captured for lost MQLs, true conversion rates per SR are unmeasurable. Analysis covers 16 SRs with a minimum of 10 won sellers.

### Key Findings

A correlation of -0.91 between median sales cycle and activation rate is the strongest finding in this section. 
SRs closing faster consistently produce better activated sellers. The two slowest SRs (median 88 and 148 days) show the lowest activation rates at 22% and 20%.

The activation rate ceiling across all SRs is 56%, with most clustering between 42% and 51%, pointing to a systemic onboarding problem rather than individual SR performance issues.

Average GMV per activated seller ranges from 464 to 6,147, reflecting two distinct seller profiles: high volume, low value and low volume, high value. Cancellation rates are consistently low at 0.0 to 0.05 and are not a differentiating factor between SRs.

### Recommendation

Review qualification criteria for SRs with median sales cycles above 55 days. The -0.91 correlation suggests these reps are progressing hesitant leads to signing rather than disqualifying early, producing sellers who never activate.

### Limitation

Analysis cannot distinguish SR skill from lead quality allocation. A controlled analysis accounting for lead source per SR would be needed to isolate the true SR contribution.

The activation rate ceiling of 56% is consistent across all SRs, meaning the problem is not individual rep performance but a systemic issue in the post-signing journey. 466 won sellers never placed a single order despite signing a contract.

This points to gaps in the onboarding process, seller readiness, or platform adoption support rather than sales quality. Recommended actions include reviewing the onboarding sequence, introducing first-order incentives, and implementing activation checkpoints at 30 and 60 days post-signing.


