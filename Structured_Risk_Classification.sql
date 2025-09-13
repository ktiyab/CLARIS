-- Step 2.4.A: Create classification prompt table
CREATE OR REPLACE TABLE `{DATASET_ID}.classification_prompts` AS
SELECT 
  county_fips,
  county_name,
  state,
  total_historical_damage,
  total_historical_events,
  current_activity_level,
  volatility_category,
  -- AI.GENERATE_TABLE requires a column named 'prompt'
  CONCAT(
    '{COUNTY_RISK_CLASSIFICATION_PROMPT}',
    'Analyze this county insurance risk profile:',
    '- Total historical damage: $', CAST(ROUND(total_historical_damage, 0) AS STRING),
    '- Total events recorded: ', CAST(total_historical_events AS STRING),
    '- Recent activity level: ', CAST(current_activity_level AS STRING), ' reports in last 30 days',
    '- Risk volatility: ', volatility_category
  ) AS prompt
FROM `{DATASET_ID}.enriched_location_master`;

-- Step 2.4.B: Generate structured classifications
CREATE OR REPLACE TABLE `{DATASET_ID}.ai_risk_classifications` AS
SELECT 
  -- Original columns passed through
  county_fips,
  county_name,
  state,
  total_historical_damage,
  
  -- Generated structured columns
  risk_score,        -- 0-100 numeric score
  risk_tier,         -- LOW/MEDIUM/HIGH/EXTREME
  confidence_level,  -- 0.0-1.0 confidence
  primary_hazard,    -- HAIL/HURRICANE/FLOOD etc
  premium_factor,    -- 0.5-5.0 rate multiplier
  
  CURRENT_TIMESTAMP() AS classification_timestamp
  
FROM
  AI.GENERATE_TABLE(
    MODEL `{DATASET_ID}.{VERTEX_AI_CONNECTION_MODEL_ENDPOINT}`,
    (
      SELECT 
        county_fips,
        county_name,
        state,
        total_historical_damage,
        prompt
      FROM `{DATASET_ID}.classification_prompts{SAMPLE_SUFFIX}`
      WHERE county_fips IS NOT NULL
    ),
    STRUCT(
      -- Define exact output schema
      "risk_score INT64, risk_tier STRING, confidence_level FLOAT64, primary_hazard STRING, premium_factor FLOAT64" AS output_schema,
      {MAX_OUTPUT_TOKEN} AS max_output_tokens,
      {TEMPERATURE} AS temperature,
      {TOP_P} AS top_p
    )
  );