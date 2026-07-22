# monthly-market-kpi-view

Year-over-year market performance KPI table for telecom operations, built on Snowflake.

## Overview

This query builds a single summary table (`AP_MARKET_KPI`) that compares key subscriber and revenue metrics across geographic markets (sub-systems) for two consecutive year-end periods. It's designed to be run on a schedule and feed downstream dashboards (ThoughtSpot, Power BI, etc.).

A second query variant provides the same metrics for the **current month-end** as an aggregate across all markets.

## Metrics Computed

| Category | Metrics |
|----------|---------|
| **Footprint** | Homes Passed, Total Subscribers, Penetration % |
| **Revenue** | ARRPC (Average Revenue Per Customer) |
| **Growth** | Connect Rate %, Churn % |
| **Contract Eligibility** | CR Eligible count (pattern-matched from TE codes) |
| **Product Mix** | Internet, Voice, Video, Homelife, and Mobile subscribers; Mobile line count |
| **Equipment** | % Panoramic Wifi adoption, % BYOD modem |
| **Speed Tiers** | Subscribers at ≤500 Mbps, 1 Gig, 2 Gig |
| **Fiber** | Fiber-enabled homes, Fiber-connected subscribers |

## Data Model

```
CA_FOOTPRINT_MTHLY_FACT_V (foot)        ← primary grain: house × month
  ├── INNER JOIN  CA_CAR_MTHLY_FACT_V (car)         on customer + time + house
  ├── INNER JOIN  CA_PSU_MIGRATION_DIM_V (psu)      on PSU migration key
  ├── INNER JOIN  CA_WIRLS_CUSTOMER_MTHLY_FACT_V    on customer + time + house
  ├── INNER JOIN  CA_CHSI_TIER_MIGRATION_DIM_V      on tier migration key
  └── INNER JOIN  CA_SUB_SYSTEM_DIM_V (sys)         on sub-system key
```

All joins are **inner**, so the output only includes records that exist across all six tables for the filtered time periods.

## Configuration

Replace these placeholders with your environment-specific values before running:

| Placeholder | Description |
|-------------|-------------|
| `<TARGET_DB>.<TARGET_SCHEMA>` | Database/schema where the output table is created |
| `<FOOTPRINT_DB>.<FOOTPRINT_SCHEMA>` | Location of `CA_FOOTPRINT_MTHLY_FACT_V` |
| `<CAR_DB>.<CAR_SCHEMA>` | Location of CAR fact views and dimension views |

### Date Periods

- **Part 1** compares `2024-12-31` vs `2025-12-31`. Update these literals to shift the comparison window.
- **Part 2** uses `LAST_DAY(CURRENT_DATE)` — no changes needed for current-month runs.

## Usage

```sql
-- Full rebuild of the YoY KPI table
-- (drops and recreates)
\i monthly_market_kpi_view.sql
```

For the current-month query only, run Part 2 standalone. Uncomment the `GROUP BY` / `ORDER BY` lines to split results by market.

## Output Schema (Part 1)

| Column | Type | Description |
|--------|------|-------------|
| `SUB_SYSTEM_DESC` | VARCHAR | Market/region name |
| `homes_passed_2024` | NUMBER | Total homes passed (prior year) |
| `homes_passed_2025` | NUMBER | Total homes passed (current year) |
| `subscribers_2024` | NUMBER | Total subscribers (prior year) |
| `subscribers_2025` | NUMBER | Total subscribers (current year) |
| `penetration_pct_2024` | FLOAT | Subscriber / Homes Passed × 100 |
| `penetration_pct_2025` | FLOAT | Subscriber / Homes Passed × 100 |
| `arrpc_2024` | FLOAT | Avg revenue per customer |
| `arrpc_2025` | FLOAT | Avg revenue per customer |
| `connect_rate_pct_*` | FLOAT | New connects / non-subscribers × 100 |
| `churn_pct_*` | FLOAT | Disconnects / prior subscribers × 100 |
| `cr_eligible_*` | NUMBER | Count matching contract renewal TE codes |
| `internet_subscribers_*` | NUMBER | Subscribers with internet (DATA_AFTER_FLG) |
| `voice_subscribers_*` | NUMBER | Subscribers with phone |
| `video_subscribers_*` | NUMBER | Subscribers with video |
| `homelife_subscribers_*` | NUMBER | Subscribers with home automation |
| `mobile_subscribers_*` | NUMBER | Subscribers with mobile |
| `mobile_lines_*` | NUMBER | Total mobile lines (can be >1 per sub) |
| `pano_wifi_pct_*` | FLOAT | % of internet subs on Pano wifi |
| `byod_pct_*` | FLOAT | % of internet subs using own modem |
| `speed_500mbps_or_lower_*` | NUMBER | Subs on tiers ≤500 Mbps |
| `speed_1gig_*` | NUMBER | Subs on 1 Gig tier |
| `speed_2gig_*` | NUMBER | Subs on 2 Gig tier |
| `fiber_enabled_homes_*` | NUMBER | Homes passed with fiber transport |
| `fiber_connected_subs_*` | NUMBER | Fiber homes with active ONT |

## Requirements

- **Snowflake** (standard SQL dialect)
- Read access to the footprint fact, CAR fact, and associated dimension views
- A warehouse sized appropriately for the monthly fact table scan (~M or larger recommended)

## Design Decisions

- **NULLIF on all denominators** prevents divide-by-zero errors in markets with zero homes passed or zero subscribers.
- **INNER JOINs throughout** — intentional. Records missing from any dimension table are excluded. If you need to preserve footprint records without a CAR match, switch the CAR join to `LEFT JOIN`.
- **Year-end snapshots only** — the `TIME_KEY IN (...)` filter means only month-end records for December are included, keeping the scan efficient.

## License

MIT
