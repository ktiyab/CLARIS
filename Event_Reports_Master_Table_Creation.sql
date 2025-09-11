-- Consolidate all preliminary reports into unified format
-- This table captures real-time signals and social media intelligence
CREATE OR REPLACE TABLE `{DATASET_ID}.event_reports_master` AS
WITH standardized_reports AS (
  -- Standardize hail reports
  SELECT 
    'HAIL' AS report_type,
    timestamp,
    EXTRACT(DATE FROM timestamp) AS report_date,
    time AS report_hour_utc,
    size/100.0 AS severity_measure,  -- Convert to inches
    'inches' AS severity_unit,
    location,
    county,
    state,
    latitude,
    longitude,
    comments,
    report_point,
    -- Extract social media indicators
    CASE 
      WHEN UPPER(comments) LIKE '%SOCIAL MEDIA%' THEN TRUE 
      ELSE FALSE 
    END AS from_social_media,
    CASE 
      WHEN UPPER(comments) LIKE '%PHOTO%' THEN TRUE 
      ELSE FALSE 
    END AS has_photo_evidence
  FROM `bigquery-public-data.noaa_preliminary_severe_storms.hail_reports`
  
  UNION ALL
  
  -- Standardize tornado reports
  SELECT 
    'TORNADO' AS report_type,
    timestamp,
    EXTRACT(DATE FROM timestamp) AS report_date,
    time AS report_hour_utc,
    -- Categorize tornado severity by mapping note string values to numeric scale (0-5)
    CASE 
      WHEN UPPER(f_scale) IN ('EF0', 'EF-0', 'F0') THEN 1
      WHEN UPPER(f_scale) IN ('EF1', 'EF-1', 'F1') THEN 2
      WHEN UPPER(f_scale) IN ('EF2', 'EF-2', 'F2') THEN 3
      WHEN UPPER(f_scale) IN ('EF3', 'EF-3', 'F3') THEN 4
      WHEN UPPER(f_scale) IN ('EF4', 'EF-4', 'F4') THEN 5
      WHEN UPPER(f_scale) IN ('EF5', 'EF-5', 'F5') THEN 6
      WHEN UPPER(f_scale) IN ('EFU', 'EF-U', 'UNK', 'UNKNOWN') THEN 0
      WHEN f_scale IS NULL THEN 0
      ELSE 0
    END AS severity_measure,
    'f_scale' AS severity_unit,
    location,
    county,
    state,
    latitude,
    longitude,
    comments,
    report_point,
    CASE 
      WHEN UPPER(comments) LIKE '%SOCIAL MEDIA%' THEN TRUE 
      ELSE FALSE 
    END AS from_social_media,
    CASE 
      WHEN UPPER(comments) LIKE '%PHOTO%' OR UPPER(comments) LIKE '%VIDEO%' THEN TRUE 
      ELSE FALSE 
    END AS has_photo_evidence
  FROM `bigquery-public-data.noaa_preliminary_severe_storms.tornado_reports`
  WHERE f_scale IS NOT NULL
  
  UNION ALL
  
  -- Standardize wind reports
  SELECT 
    'WIND' AS report_type,
    timestamp,
    EXTRACT(DATE FROM timestamp) AS report_date,
    time AS report_hour_utc,
    IFNULL(0, speed) AS severity_measure,  -- Already in MPH
    'mph' AS severity_unit,
    location,
    county,
    state,
    latitude,
    longitude,
    comments,
    report_point,
    CASE 
      WHEN UPPER(comments) LIKE '%SOCIAL MEDIA%' THEN TRUE 
      ELSE FALSE 
    END AS from_social_media,
    CASE 
      WHEN UPPER(comments) LIKE '%MEASURED%' OR UPPER(comments) LIKE '%ASOS%' THEN TRUE 
      ELSE FALSE 
    END AS has_photo_evidence  -- For wind, this indicates official measurement
  FROM `bigquery-public-data.noaa_preliminary_severe_storms.wind_reports`
),
-- Add temporal clustering to identify storm systems
event_clustering AS (
  SELECT 
    *,
    -- Identify potential storm clusters (events within 6 hours and 50 miles)
    LAG(timestamp) OVER (
      PARTITION BY state, report_date 
      ORDER BY timestamp
    ) AS previous_event_time,
    
    -- Count events in surrounding area
    COUNT(*) OVER (
      PARTITION BY state, report_date, CAST(latitude AS INT64), CAST(longitude AS INT64)
    ) AS local_event_density,
    
    -- Normalized severity for cross-type comparison
    CASE 
      WHEN report_type = 'HAIL' THEN 
        CASE 
          WHEN severity_measure >= 2.0 THEN 'SEVERE'
          WHEN severity_measure >= 1.0 THEN 'MODERATE'
          ELSE 'MINOR'
        END
      WHEN report_type = 'TORNADO' THEN
        CASE 
          WHEN severity_measure >= 3 THEN 'SEVERE'
          WHEN severity_measure >= 1 THEN 'MODERATE'
          ELSE 'MINOR'
        END
      WHEN report_type = 'WIND' THEN
        CASE 
          WHEN severity_measure >= 75 THEN 'SEVERE'
          WHEN severity_measure >= 58 THEN 'MODERATE'
          ELSE 'MINOR'
        END
    END AS severity_category
    
  FROM standardized_reports
)
SELECT 
  *,
  -- Storm system indicator
  CASE 
    WHEN previous_event_time IS NOT NULL 
      AND DATETIME_DIFF(timestamp, previous_event_time, HOUR) <= 6 
    THEN TRUE 
    ELSE FALSE 
  END AS part_of_storm_system,
  
  -- Data freshness indicator
  DATETIME_DIFF(CURRENT_TIMESTAMP(), timestamp, HOUR) AS hours_since_report,
  
  -- Quality score based on evidence
  (CASE WHEN from_social_media THEN 1 ELSE 2 END + 
   CASE WHEN has_photo_evidence THEN 2 ELSE 0 END) AS report_quality_score,
   
  CURRENT_TIMESTAMP() AS last_updated_timestamp
  
FROM event_clustering;