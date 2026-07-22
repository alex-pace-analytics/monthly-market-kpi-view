-- Monthly market KPI view: year-over-year telecom performance metrics by market area
-- Co-authored with CoCo

--------------------------------------------------------------------------------
-- PART 1: Year-over-Year Market KPI Table
--
-- Rebuilds a summary table comparing key performance indicators across markets
-- for two consecutive year-end periods.
--
-- Metrics: footprint, revenue, growth, product mix, equipment adoption,
-- speed tiers, and fiber/last-mile technology.
--
-- CONFIGURATION:
--   Replace all <PLACEHOLDER> values with your environment-specific references.
--   See the "Placeholders" section at the bottom of this file.
--------------------------------------------------------------------------------

DROP TABLE IF EXISTS <TARGET_DB>.<TARGET_SCHEMA>.MARKET_KPI;

CREATE TABLE <TARGET_DB>.<TARGET_SCHEMA>.MARKET_KPI AS
SELECT
    sys.MARKET_DESC,

    -- Homes Passed
    SUM(CASE WHEN foot.TIME_KEY = '<PRIOR_YEAR_END>' THEN foot.HOME_PASSED_CURR_CNT ELSE 0 END) AS homes_passed_prior,
    SUM(CASE WHEN foot.TIME_KEY = '<CURRENT_YEAR_END>' THEN foot.HOME_PASSED_CURR_CNT ELSE 0 END) AS homes_passed_current,

    -- Subscribers
    SUM(CASE WHEN foot.TIME_KEY = '<PRIOR_YEAR_END>' THEN foot.SUBSCRIBER_CURR_CNT ELSE 0 END) AS subscribers_prior,
    SUM(CASE WHEN foot.TIME_KEY = '<CURRENT_YEAR_END>' THEN foot.SUBSCRIBER_CURR_CNT ELSE 0 END) AS subscribers_current,

    -- Penetration %
    (SUM(CASE WHEN foot.TIME_KEY = '<PRIOR_YEAR_END>' THEN foot.SUBSCRIBER_CURR_CNT ELSE 0 END)
     / NULLIF(SUM(CASE WHEN foot.TIME_KEY = '<PRIOR_YEAR_END>' THEN foot.HOME_PASSED_CURR_CNT ELSE 0 END), 0)
    ) * 100 AS penetration_pct_prior,
    (SUM(CASE WHEN foot.TIME_KEY = '<CURRENT_YEAR_END>' THEN foot.SUBSCRIBER_CURR_CNT ELSE 0 END)
     / NULLIF(SUM(CASE WHEN foot.TIME_KEY = '<CURRENT_YEAR_END>' THEN foot.HOME_PASSED_CURR_CNT ELSE 0 END), 0)
    ) * 100 AS penetration_pct_current,

    -- ARPU (Average Revenue Per User)
    ROUND(
        SUM(CASE WHEN foot.TIME_KEY = '<PRIOR_YEAR_END>' THEN foot.TOTAL_NET_MRC_CURR_AMT ELSE 0 END)
        / NULLIF(SUM(CASE WHEN foot.TIME_KEY = '<PRIOR_YEAR_END>' THEN foot.SUBSCRIBER_CURR_CNT ELSE 0 END), 0),
    2) AS arpu_prior,
    ROUND(
        SUM(CASE WHEN foot.TIME_KEY = '<CURRENT_YEAR_END>' THEN foot.TOTAL_NET_MRC_CURR_AMT ELSE 0 END)
        / NULLIF(SUM(CASE WHEN foot.TIME_KEY = '<CURRENT_YEAR_END>' THEN foot.SUBSCRIBER_CURR_CNT ELSE 0 END), 0),
    2) AS arpu_current,

    -- Connect Rate % (new connections / addressable non-subscribers)
    (SUM(CASE WHEN foot.TIME_KEY = '<PRIOR_YEAR_END>' THEN foot.CONN_CNT ELSE 0 END)
     / NULLIF(SUM(CASE WHEN foot.TIME_KEY = '<PRIOR_YEAR_END>' THEN foot.NON_SUBSCRIBER_PREV_CNT ELSE 0 END), 0)
    ) * 100 AS connect_rate_pct_prior,
    (SUM(CASE WHEN foot.TIME_KEY = '<CURRENT_YEAR_END>' THEN foot.CONN_CNT ELSE 0 END)
     / NULLIF(SUM(CASE WHEN foot.TIME_KEY = '<CURRENT_YEAR_END>' THEN foot.NON_SUBSCRIBER_PREV_CNT ELSE 0 END), 0)
    ) * 100 AS connect_rate_pct_current,

    -- Churn % (disconnects / prior-period subscribers)
    (SUM(CASE WHEN foot.TIME_KEY = '<PRIOR_YEAR_END>' THEN foot.DISC_CNT ELSE 0 END)
     / NULLIF(SUM(CASE WHEN foot.TIME_KEY = '<PRIOR_YEAR_END>' THEN foot.SUBSCRIBER_PREV_CNT ELSE 0 END), 0)
    ) * 100 AS churn_pct_prior,
    (SUM(CASE WHEN foot.TIME_KEY = '<CURRENT_YEAR_END>' THEN foot.DISC_CNT ELSE 0 END)
     / NULLIF(SUM(CASE WHEN foot.TIME_KEY = '<CURRENT_YEAR_END>' THEN foot.SUBSCRIBER_PREV_CNT ELSE 0 END), 0)
    ) * 100 AS churn_pct_current,

    -- Contract/Promo Eligible (pattern-match on offer codes)
    -- Replace <ELIGIBLE_OFFER_PATTERNS> with your own LIKE patterns or IN list
    SUM(CASE WHEN foot.TIME_KEY = '<PRIOR_YEAR_END>'
         AND car.OFFER_CODE_STRING LIKE ANY (<ELIGIBLE_OFFER_PATTERNS>)
    THEN 1 ELSE 0 END) AS promo_eligible_prior,
    SUM(CASE WHEN foot.TIME_KEY = '<CURRENT_YEAR_END>'
         AND car.OFFER_CODE_STRING LIKE ANY (<ELIGIBLE_OFFER_PATTERNS>)
    THEN 1 ELSE 0 END) AS promo_eligible_current,

    -- Product Subscribers (Internet, Voice, Video, Home Automation, Mobile)
    SUM(CASE WHEN foot.TIME_KEY = '<PRIOR_YEAR_END>' AND foot.SUBSCRIBER_CURR_CNT = 1 AND psu.INTERNET_FLAG = 1 THEN 1 ELSE 0 END) AS internet_subscribers_prior,
    SUM(CASE WHEN foot.TIME_KEY = '<CURRENT_YEAR_END>' AND foot.SUBSCRIBER_CURR_CNT = 1 AND psu.INTERNET_FLAG = 1 THEN 1 ELSE 0 END) AS internet_subscribers_current,
    SUM(CASE WHEN foot.TIME_KEY = '<PRIOR_YEAR_END>' AND foot.SUBSCRIBER_CURR_CNT = 1 AND psu.VOICE_FLAG = 1 THEN 1 ELSE 0 END) AS voice_subscribers_prior,
    SUM(CASE WHEN foot.TIME_KEY = '<CURRENT_YEAR_END>' AND foot.SUBSCRIBER_CURR_CNT = 1 AND psu.VOICE_FLAG = 1 THEN 1 ELSE 0 END) AS voice_subscribers_current,
    SUM(CASE WHEN foot.TIME_KEY = '<PRIOR_YEAR_END>' AND foot.SUBSCRIBER_CURR_CNT = 1 AND psu.VIDEO_FLAG = 1 THEN 1 ELSE 0 END) AS video_subscribers_prior,
    SUM(CASE WHEN foot.TIME_KEY = '<CURRENT_YEAR_END>' AND foot.SUBSCRIBER_CURR_CNT = 1 AND psu.VIDEO_FLAG = 1 THEN 1 ELSE 0 END) AS video_subscribers_current,
    SUM(CASE WHEN foot.TIME_KEY = '<PRIOR_YEAR_END>' AND foot.SUBSCRIBER_CURR_CNT = 1 AND psu.HOME_AUTO_FLAG = 1 THEN 1 ELSE 0 END) AS home_auto_subscribers_prior,
    SUM(CASE WHEN foot.TIME_KEY = '<CURRENT_YEAR_END>' AND foot.SUBSCRIBER_CURR_CNT = 1 AND psu.HOME_AUTO_FLAG = 1 THEN 1 ELSE 0 END) AS home_auto_subscribers_current,
    SUM(CASE WHEN foot.TIME_KEY = '<PRIOR_YEAR_END>' AND foot.SUBSCRIBER_CURR_CNT = 1 AND wirls.MOBILE_FLAG = 1 THEN 1 ELSE 0 END) AS mobile_subscribers_prior,
    SUM(CASE WHEN foot.TIME_KEY = '<CURRENT_YEAR_END>' AND foot.SUBSCRIBER_CURR_CNT = 1 AND wirls.MOBILE_FLAG = 1 THEN 1 ELSE 0 END) AS mobile_subscribers_current,

    -- Mobile Lines (total lines, can exceed subscriber count)
    SUM(CASE WHEN foot.TIME_KEY = '<PRIOR_YEAR_END>' AND wirls.LINE_CNT != 0 AND wirls.MOBILE_FLAG = 1 THEN wirls.LINE_CNT ELSE 0 END) AS mobile_lines_prior,
    SUM(CASE WHEN foot.TIME_KEY = '<CURRENT_YEAR_END>' AND wirls.LINE_CNT != 0 AND wirls.MOBILE_FLAG = 1 THEN wirls.LINE_CNT ELSE 0 END) AS mobile_lines_current,

    -- % Managed Wifi (provider-supplied wifi equipment)
    (SUM(CASE WHEN foot.TIME_KEY = '<PRIOR_YEAR_END>' AND foot.SUBSCRIBER_CURR_CNT = 1 AND car.MANAGED_WIFI_FLAG = 1 AND psu.INTERNET_FLAG = 1 THEN 1 ELSE 0 END)
     / NULLIF(SUM(CASE WHEN foot.TIME_KEY = '<PRIOR_YEAR_END>' AND foot.SUBSCRIBER_CURR_CNT = 1 AND psu.INTERNET_FLAG = 1 THEN 1 ELSE 0 END), 0)
    ) * 100 AS managed_wifi_pct_prior,
    (SUM(CASE WHEN foot.TIME_KEY = '<CURRENT_YEAR_END>' AND foot.SUBSCRIBER_CURR_CNT = 1 AND car.MANAGED_WIFI_FLAG = 1 AND psu.INTERNET_FLAG = 1 THEN 1 ELSE 0 END)
     / NULLIF(SUM(CASE WHEN foot.TIME_KEY = '<CURRENT_YEAR_END>' AND foot.SUBSCRIBER_CURR_CNT = 1 AND psu.INTERNET_FLAG = 1 THEN 1 ELSE 0 END), 0)
    ) * 100 AS managed_wifi_pct_current,

    -- % BYOD (customer owns modem/router)
    (SUM(CASE WHEN foot.TIME_KEY = '<PRIOR_YEAR_END>' AND foot.SUBSCRIBER_CURR_CNT = 1 AND car.BYOD_FLAG = 1 AND psu.INTERNET_FLAG = 1 THEN 1 ELSE 0 END)
     / NULLIF(SUM(CASE WHEN foot.TIME_KEY = '<PRIOR_YEAR_END>' AND foot.SUBSCRIBER_CURR_CNT = 1 AND psu.INTERNET_FLAG = 1 THEN 1 ELSE 0 END), 0)
    ) * 100 AS byod_pct_prior,
    (SUM(CASE WHEN foot.TIME_KEY = '<CURRENT_YEAR_END>' AND foot.SUBSCRIBER_CURR_CNT = 1 AND car.BYOD_FLAG = 1 AND psu.INTERNET_FLAG = 1 THEN 1 ELSE 0 END)
     / NULLIF(SUM(CASE WHEN foot.TIME_KEY = '<CURRENT_YEAR_END>' AND foot.SUBSCRIBER_CURR_CNT = 1 AND psu.INTERNET_FLAG = 1 THEN 1 ELSE 0 END), 0)
    ) * 100 AS byod_pct_current,

    -- Speed Tier Breakdown
    -- Replace <TIER_NAMES_500MBPS_OR_LOWER>, <TIER_NAME_1GIG>, <TIER_NAME_2GIG>
    -- with your organization's tier/product names
    SUM(CASE WHEN foot.TIME_KEY = '<PRIOR_YEAR_END>'
         AND UPPER(tier.TIER_NAME) IN (<TIER_NAMES_500MBPS_OR_LOWER>)
    THEN 1 ELSE 0 END) AS speed_500mbps_or_lower_prior,
    SUM(CASE WHEN foot.TIME_KEY = '<CURRENT_YEAR_END>'
         AND UPPER(tier.TIER_NAME) IN (<TIER_NAMES_500MBPS_OR_LOWER>)
    THEN 1 ELSE 0 END) AS speed_500mbps_or_lower_current,
    SUM(CASE WHEN foot.TIME_KEY = '<PRIOR_YEAR_END>'
         AND UPPER(tier.TIER_NAME) = <TIER_NAME_1GIG>
    THEN 1 ELSE 0 END) AS speed_1gig_prior,
    SUM(CASE WHEN foot.TIME_KEY = '<CURRENT_YEAR_END>'
         AND UPPER(tier.TIER_NAME) = <TIER_NAME_1GIG>
    THEN 1 ELSE 0 END) AS speed_1gig_current,
    SUM(CASE WHEN foot.TIME_KEY = '<PRIOR_YEAR_END>'
         AND UPPER(tier.TIER_NAME) = <TIER_NAME_2GIG>
    THEN 1 ELSE 0 END) AS speed_2gig_prior,
    SUM(CASE WHEN foot.TIME_KEY = '<CURRENT_YEAR_END>'
         AND UPPER(tier.TIER_NAME) = <TIER_NAME_2GIG>
    THEN 1 ELSE 0 END) AS speed_2gig_current,

    -- Fiber / Last-Mile Technology
    SUM(CASE WHEN foot.TIME_KEY = '<PRIOR_YEAR_END>' AND foot.HOME_PASSED_CURR_CNT = 1 AND LOWER(car.TRANSPORT_METHOD) = 'fiber' THEN 1 ELSE 0 END) AS fiber_enabled_homes_prior,
    SUM(CASE WHEN foot.TIME_KEY = '<CURRENT_YEAR_END>' AND foot.HOME_PASSED_CURR_CNT = 1 AND LOWER(car.TRANSPORT_METHOD) = 'fiber' THEN 1 ELSE 0 END) AS fiber_enabled_homes_current,
    SUM(CASE WHEN foot.TIME_KEY = '<PRIOR_YEAR_END>' AND foot.HOME_PASSED_CURR_CNT = 1 AND LOWER(car.TRANSPORT_METHOD) = 'fiber' AND car.FIBER_ONT_FLAG = 1 THEN 1 ELSE 0 END) AS fiber_connected_subs_prior,
    SUM(CASE WHEN foot.TIME_KEY = '<CURRENT_YEAR_END>' AND foot.HOME_PASSED_CURR_CNT = 1 AND LOWER(car.TRANSPORT_METHOD) = 'fiber' AND car.FIBER_ONT_FLAG = 1 THEN 1 ELSE 0 END) AS fiber_connected_subs_current

FROM <FOOTPRINT_DB>.<FOOTPRINT_SCHEMA>.FOOTPRINT_MONTHLY_FACT AS foot
INNER JOIN <ACCOUNT_DB>.<ACCOUNT_SCHEMA>.CUSTOMER_ACCOUNT_MONTHLY_FACT AS car
    ON  car.CUSTOMER_KEY = foot.CUSTOMER_KEY
    AND car.TIME_KEY     = foot.TIME_KEY
    AND car.HOUSE_KEY    = foot.HOUSE_KEY
INNER JOIN <ACCOUNT_DB>.<ACCOUNT_SCHEMA>.PRODUCT_SUBSCRIPTION_DIM AS psu
    ON foot.PRODUCT_SUBSCRIPTION_KEY = psu.PRODUCT_SUBSCRIPTION_KEY
INNER JOIN <ACCOUNT_DB>.<ACCOUNT_SCHEMA>.WIRELESS_CUSTOMER_MONTHLY_FACT AS wirls
    ON  foot.CUSTOMER_KEY = wirls.CUSTOMER_KEY
    AND foot.TIME_KEY     = wirls.TIME_KEY
    AND foot.HOUSE_KEY    = wirls.HOUSE_KEY
INNER JOIN <ACCOUNT_DB>.<ACCOUNT_SCHEMA>.SPEED_TIER_DIM AS tier
    ON foot.TIER_KEY = tier.TIER_KEY
INNER JOIN <ACCOUNT_DB>.<ACCOUNT_SCHEMA>.MARKET_DIM AS sys
    ON foot.MARKET_KEY = sys.MARKET_KEY
WHERE foot.TIME_KEY IN ('<PRIOR_YEAR_END>', '<CURRENT_YEAR_END>')
GROUP BY sys.MARKET_DESC
ORDER BY sys.MARKET_DESC ASC;


--------------------------------------------------------------------------------
-- PART 2: Current-Month Aggregate KPI Query (single-row total across all markets)
--
-- Same metrics as above but for the current month-end only.
-- Uncomment GROUP BY / ORDER BY to split by market.
--------------------------------------------------------------------------------

SELECT
    SUM(foot.HOME_PASSED_CURR_CNT) AS homes_passed,
    SUM(foot.SUBSCRIBER_CURR_CNT) AS subscribers,
    (SUM(foot.SUBSCRIBER_CURR_CNT) / NULLIF(SUM(foot.HOME_PASSED_CURR_CNT), 0)) * 100 AS penetration_pct,
    ROUND(SUM(foot.TOTAL_NET_MRC_CURR_AMT) / NULLIF(SUM(foot.SUBSCRIBER_CURR_CNT), 0), 2) AS arpu,
    (SUM(foot.CONN_CNT) / NULLIF(SUM(foot.NON_SUBSCRIBER_PREV_CNT), 0)) * 100 AS connect_rate_pct,

    -- Contract/Promo Eligible
    SUM(CASE WHEN car.OFFER_CODE_STRING LIKE ANY (<ELIGIBLE_OFFER_PATTERNS>)
    THEN 1 ELSE 0 END) AS promo_eligible,

    -- Product Subscribers
    SUM(CASE WHEN foot.SUBSCRIBER_CURR_CNT = 1 AND psu.INTERNET_FLAG = 1 THEN 1 ELSE 0 END) AS internet_subscribers,
    SUM(CASE WHEN foot.SUBSCRIBER_CURR_CNT = 1 AND psu.VOICE_FLAG = 1 THEN 1 ELSE 0 END) AS voice_subscribers,
    SUM(CASE WHEN foot.SUBSCRIBER_CURR_CNT = 1 AND psu.VIDEO_FLAG = 1 THEN 1 ELSE 0 END) AS video_subscribers,
    SUM(CASE WHEN foot.SUBSCRIBER_CURR_CNT = 1 AND psu.HOME_AUTO_FLAG = 1 THEN 1 ELSE 0 END) AS home_auto_subscribers,
    SUM(CASE WHEN foot.SUBSCRIBER_CURR_CNT = 1 AND wirls.MOBILE_FLAG = 1 THEN 1 ELSE 0 END) AS mobile_subscribers,
    SUM(CASE WHEN wirls.LINE_CNT != 0 AND wirls.MOBILE_FLAG = 1 THEN wirls.LINE_CNT ELSE 0 END) AS mobile_lines,

    -- Equipment Adoption
    (SUM(CASE WHEN foot.SUBSCRIBER_CURR_CNT = 1 AND car.MANAGED_WIFI_FLAG = 1 AND psu.INTERNET_FLAG = 1 THEN 1 ELSE 0 END)
     / NULLIF(SUM(CASE WHEN foot.SUBSCRIBER_CURR_CNT = 1 AND psu.INTERNET_FLAG = 1 THEN 1 ELSE 0 END), 0)
    ) * 100 AS managed_wifi_pct,
    (SUM(CASE WHEN foot.SUBSCRIBER_CURR_CNT = 1 AND car.BYOD_FLAG = 1 AND psu.INTERNET_FLAG = 1 THEN 1 ELSE 0 END)
     / NULLIF(SUM(CASE WHEN foot.SUBSCRIBER_CURR_CNT = 1 AND psu.INTERNET_FLAG = 1 THEN 1 ELSE 0 END), 0)
    ) * 100 AS byod_pct,

    -- Speed Tiers
    SUM(CASE WHEN UPPER(tier.TIER_NAME) IN (<TIER_NAMES_500MBPS_OR_LOWER>)
    THEN 1 ELSE 0 END) AS speed_500mbps_or_lower,
    SUM(CASE WHEN UPPER(tier.TIER_NAME) = <TIER_NAME_1GIG> THEN 1 ELSE 0 END) AS speed_1gig,
    SUM(CASE WHEN UPPER(tier.TIER_NAME) = <TIER_NAME_2GIG> THEN 1 ELSE 0 END) AS speed_2gig,

    -- Fiber
    SUM(CASE WHEN foot.HOME_PASSED_CURR_CNT = 1 AND LOWER(car.TRANSPORT_METHOD) = 'fiber' THEN 1 ELSE 0 END) AS fiber_enabled_homes,
    SUM(CASE WHEN foot.HOME_PASSED_CURR_CNT = 1 AND LOWER(car.TRANSPORT_METHOD) = 'fiber' AND car.FIBER_ONT_FLAG = 1 THEN 1 ELSE 0 END) AS fiber_connected_subs

FROM <FOOTPRINT_DB>.<FOOTPRINT_SCHEMA>.FOOTPRINT_MONTHLY_FACT AS foot
INNER JOIN <ACCOUNT_DB>.<ACCOUNT_SCHEMA>.CUSTOMER_ACCOUNT_MONTHLY_FACT AS car
    ON  car.CUSTOMER_KEY = foot.CUSTOMER_KEY
    AND car.TIME_KEY     = foot.TIME_KEY
    AND car.HOUSE_KEY    = foot.HOUSE_KEY
INNER JOIN <ACCOUNT_DB>.<ACCOUNT_SCHEMA>.PRODUCT_SUBSCRIPTION_DIM AS psu
    ON foot.PRODUCT_SUBSCRIPTION_KEY = psu.PRODUCT_SUBSCRIPTION_KEY
INNER JOIN <ACCOUNT_DB>.<ACCOUNT_SCHEMA>.WIRELESS_CUSTOMER_MONTHLY_FACT AS wirls
    ON  foot.CUSTOMER_KEY = wirls.CUSTOMER_KEY
    AND foot.TIME_KEY     = wirls.TIME_KEY
    AND foot.HOUSE_KEY    = wirls.HOUSE_KEY
INNER JOIN <ACCOUNT_DB>.<ACCOUNT_SCHEMA>.SPEED_TIER_DIM AS tier
    ON foot.TIER_KEY = tier.TIER_KEY
INNER JOIN <ACCOUNT_DB>.<ACCOUNT_SCHEMA>.MARKET_DIM AS sys
    ON foot.MARKET_KEY = sys.MARKET_KEY
WHERE foot.TIME_KEY = LAST_DAY(CURRENT_DATE);
-- GROUP BY sys.MARKET_DESC
-- ORDER BY sys.MARKET_DESC ASC;


--------------------------------------------------------------------------------
-- PLACEHOLDERS REFERENCE
--
-- <TARGET_DB>.<TARGET_SCHEMA>          Output table location
-- <FOOTPRINT_DB>.<FOOTPRINT_SCHEMA>    Footprint monthly fact
-- <ACCOUNT_DB>.<ACCOUNT_SCHEMA>        Customer account facts & dimensions
-- <PRIOR_YEAR_END>                     e.g. '2024-12-31'
-- <CURRENT_YEAR_END>                   e.g. '2025-12-31'
-- <ELIGIBLE_OFFER_PATTERNS>            LIKE patterns for contract-eligible offers
-- <TIER_NAMES_500MBPS_OR_LOWER>        IN list of tier names for ≤500 Mbps
-- <TIER_NAME_1GIG>                     Tier name for 1 Gbps product
-- <TIER_NAME_2GIG>                     Tier name for 2 Gbps product
--------------------------------------------------------------------------------
