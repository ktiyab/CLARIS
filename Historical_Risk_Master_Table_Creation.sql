-- Create comprehensive historical risk aggregation at county-month level
-- This table serves as the foundation for understanding long-term risk patterns
CREATE OR REPLACE TABLE `{DATASET_ID}.historical_risk_master` AS
WITH storm_aggregation AS (
  -- Aggregate all historical storm events from 1950-2025
  SELECT 
    state_fips_code,
    cz_fips_code AS county_fips,
    cz_name AS county_name,
    state,
    -- Temporal dimensions for seasonality analysis
    EXTRACT(YEAR FROM event_begin_time) AS event_year,
    EXTRACT(MONTH FROM event_begin_time) AS event_month,
    FORMAT_DATE('%Y-%m', DATE(event_begin_time)) AS year_month,
    
    -- Event type and severity metrics
    event_type,
    COUNT(*) AS event_count,
    
    -- Financial impact metrics (handling nulls for $0 damages)
    SUM(IFNULL(damage_property, 0)) AS total_property_damage,
    SUM(IFNULL(damage_crops, 0)) AS total_crop_damage,
    SUM(IFNULL(damage_property, 0) + IFNULL(damage_crops, 0)) AS total_damage,
    AVG(IFNULL(damage_property, 0) + IFNULL(damage_crops, 0)) AS avg_damage_per_event,
    MAX(IFNULL(damage_property, 0) + IFNULL(damage_crops, 0)) AS max_single_event_damage,
    
    -- Human impact metrics for severity assessment
    SUM(IFNULL(deaths_direct, 0) + IFNULL(deaths_indirect, 0)) AS total_deaths,
    SUM(IFNULL(injuries_direct, 0) + IFNULL(injuries_indirect, 0)) AS total_injuries,
    
    -- Event characteristics for pattern analysis
    AVG(CASE WHEN magnitude IS NOT NULL THEN magnitude END) AS avg_magnitude,
    MAX(CASE WHEN magnitude IS NOT NULL THEN magnitude END) AS max_magnitude,
    STRING_AGG(DISTINCT tor_f_scale, ', ' ORDER BY tor_f_scale) AS tornado_scales_observed,
    
    -- Duration metrics for exposure analysis
    AVG(DATETIME_DIFF(event_end_time, event_begin_time, HOUR)) AS avg_event_duration_hours,
    MAX(DATETIME_DIFF(event_end_time, event_begin_time, HOUR)) AS max_event_duration_hours
    
  FROM `bigquery-public-data.noaa_historic_severe_storms.storms_*`
  WHERE _TABLE_SUFFIX BETWEEN '1950' AND '2025'
    AND cz_fips_code IS NOT NULL  -- Ensure geographic identification
  GROUP BY 1, 2, 3, 4, 5, 6, 7, 8
),
-- Add rolling statistics for trend analysis
rolling_metrics AS (
  SELECT 
    *,
    -- 3-year rolling averages for smoothing
    AVG(total_damage) OVER (
      PARTITION BY county_fips, county_name, state
      ORDER BY year_month 
      ROWS BETWEEN 35 PRECEDING AND CURRENT ROW
    ) AS rolling_3yr_avg_damage,
    
    -- Year-over-year change indicators
    LAG(total_damage, 12) OVER (
      PARTITION BY county_fips, county_name, state
      ORDER BY year_month
    ) AS previous_year_damage,
    
    -- Cumulative risk exposure
    SUM(total_damage) OVER (
      PARTITION BY county_fips, county_name, state
      ORDER BY year_month
    ) AS cumulative_historical_damage
    
  FROM storm_aggregation
)
SELECT 
  *,
  -- Risk trend indicators
  CASE 
    WHEN previous_year_damage > 0 
    THEN ((total_damage - previous_year_damage) / previous_year_damage) * 100
    ELSE NULL 
  END AS year_over_year_change_pct,
  
  -- Seasonal risk flags
  CASE 
    WHEN event_month BETWEEN 4 AND 10 THEN 'HIGH_SEASON'
    ELSE 'LOW_SEASON'
  END AS seasonal_risk_period,
  
  -- Data quality indicator
  CURRENT_TIMESTAMP() AS last_updated_timestamp
FROM rolling_metrics;