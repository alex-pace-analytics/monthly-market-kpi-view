# monthly-market-kpi-view

Year-over-year market performance KPI table for telecom subscriber operations, built on Snowflake.

## Overview

This query builds a single summary table that compares key subscriber and revenue metrics across geographic markets for two consecutive year-end periods. It's designed to be run on a schedule and feed downstream dashboards.

A second query variant provides the same metrics for the **current month-end** as an aggregate across all markets.

## Metrics Computed

| Category | Metrics |
|----------|---------|
| **Footprint** | Homes Passed, Total Subscribers, Penetration % |
| **Revenue** | ARPU (Average Revenue Per User) |
| **Growth** | Connect Rate %, Churn % |
| **Promo Eligibility** | Count of subscribers matching configurable offer-code patterns |
| **Product Mix** | Internet, Voice, Video, Home Automation, and Mobile subscribers; Mobile line count |
| **Equipment** | % Managed Wifi adoption, % BYOD (customer-owned modem) |
| **Speed Tiers** | Subscribers at ≤500 Mbps, 1 Gig, 2 Gig |
| **Last-Mile Technology** | Fiber-enabled homes, Fiber-connected subscribers (ONT active) |

## Data Model

The query joins six tables following a star schema pattern:

```
FOOTPRINT_MONTHLY_FACT (foot)                 ← primary grain: house × month
  ├── INNER JOIN  CUSTOMER_ACCOUNT_MONTHLY_FACT   on customer + time + house
  ├── INNER JOIN  PRODUCT_SUBSCRIPTION_DIM        on product subscription key
  ├── INNER JOIN  WIRELESS_CUSTOMER_MONTHLY_FACT  on customer + time + house
  ├── INNER JOIN  SPEED_TIER_DIM                  on tier key
  └── INNER JOIN  MARKET_DIM                      on market key
```

All joins are **inner**, so the output only includes records present across all tables for the filtered time periods.

## Configuration

Replace these placeholders before running:

| Placeholder | Description | Example |
|-------------|-------------|---------|
| `<TARGET_DB>.<TARGET_SCHEMA>` | Where the output table is created | `ANALYTICS.REPORTING` |
| `<FOOTPRINT_DB>.<FOOTPRINT_SCHEMA>` | Footprint monthly fact location | `DW.SUBSCRIBER` |
| `<ACCOUNT_DB>.<ACCOUNT_SCHEMA>` | Customer account facts & dimensions | `DW.ACCOUNT` |
| `<PRIOR_YEAR_END>` | Prior year comparison date | `'2024-12-31'` |
| `<CURRENT_YEAR_END>` | Current year comparison date | `'2025-12-31'` |
| `<ELIGIBLE_OFFER_PATTERNS>` | LIKE patterns for promo-eligible offer codes | `'%RETCORE%', '%ACQCORE%'` |
| `<TIER_NAMES_500MBPS_OR_LOWER>` | IN list of tier names for ≤500 Mbps | `'BASIC', 'STANDARD', 'PLUS'` |
| `<TIER_NAME_1GIG>` | Tier name for 1 Gbps product | `'GIGABIT'` |
| `<TIER_NAME_2GIG>` | Tier name for 2 Gbps product | `'GIGABIT_PRO'` |

## Usage

```sql
-- Full rebuild of the YoY KPI table (drops and recreates)
-- Run Part 1 of the script

-- Current-month snapshot only
-- Run Part 2 standalone
-- Uncomment GROUP BY / ORDER BY to split by market
```

## Output Schema (Part 1)

One row per market with paired prior/current columns:

| Column Pattern | Type | Description |
|----------------|------|-------------|
| `MARKET_DESC` | VARCHAR | Market/region name |
| `homes_passed_*` | NUMBER | Total serviceable homes |
| `subscribers_*` | NUMBER | Active subscriber count |
| `penetration_pct_*` | FLOAT | Subscribers / Homes Passed × 100 |
| `arpu_*` | FLOAT | Net MRC / Subscribers |
| `connect_rate_pct_*` | FLOAT | New connects / non-subscribers × 100 |
| `churn_pct_*` | FLOAT | Disconnects / prior subscribers × 100 |
| `promo_eligible_*` | NUMBER | Subscribers on qualifying offers |
| `internet_subscribers_*` | NUMBER | Subs with internet product |
| `voice_subscribers_*` | NUMBER | Subs with voice product |
| `video_subscribers_*` | NUMBER | Subs with video product |
| `home_auto_subscribers_*` | NUMBER | Subs with home automation |
| `mobile_subscribers_*` | NUMBER | Subs with mobile product |
| `mobile_lines_*` | NUMBER | Total mobile lines (≥1 per sub) |
| `managed_wifi_pct_*` | FLOAT | % of internet subs on provider wifi |
| `byod_pct_*` | FLOAT | % of internet subs using own equipment |
| `speed_500mbps_or_lower_*` | NUMBER | Subs on tiers ≤500 Mbps |
| `speed_1gig_*` | NUMBER | Subs on 1 Gbps tier |
| `speed_2gig_*` | NUMBER | Subs on 2 Gbps tier |
| `fiber_enabled_homes_*` | NUMBER | Homes passed with fiber last-mile |
| `fiber_connected_subs_*` | NUMBER | Fiber homes with active ONT |

## Design Decisions

- **NULLIF on all denominators** — prevents divide-by-zero in markets with zero homes passed or zero subscribers.
- **INNER JOINs throughout** — records missing from any dimension are excluded. Switch to `LEFT JOIN` on the account table if you need to preserve footprint records without a customer match.
- **Year-end snapshots only** — the `TIME_KEY IN (...)` filter keeps the scan efficient.
- **Generic column naming** — uses `_prior` / `_current` suffixes rather than hardcoded years, making the pattern reusable.

## Adapting This Query

This pattern works for any multi-product telecom or subscription business. To adapt:

1. Replace table/column names with your data warehouse equivalents
2. Add or remove product lines from the product subscriber section
3. Adjust speed tier groupings to match your plan hierarchy
4. Modify the offer-code eligibility logic for your contract/promo rules

## Requirements

- Snowflake (standard SQL dialect, uses `NULLIF`, `LIKE ANY`)
- Read access to footprint, account, and dimension tables
- A warehouse sized for monthly fact table scans

## License

MIT
