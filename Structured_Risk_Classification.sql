-- Step 2.4.A: Create classification prompt table with required 'prompt' column
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
    '''{COUNTY_RISK_CLASSIFICATION_PROMPT}''',
    'Analyze this county insurance risk profile:',
    '- Total historical damage: $', CAST(ROUND(total_historical_damage, 0) AS STRING),
    '- Total events recorded: ', CAST(total_historical_events AS STRING),
    '- Recent activity level: ', CAST(current_activity_level AS STRING), ' reports in last 30 days',
    '- Risk volatility: ', volatility_category
  ) AS prompt
FROM `{DATASET_ID}.enriched_location_master`;

-- Step 2.4: Generate structured risk classifications using AI.GENERATE_TABLE
CREATE OR REPLACE TABLE `{DATASET_ID}.ai_risk_classifications` AS
SELECT 
  -- Original columns from the input table are passed through
  county_fips,
  county_name,
  state,
  total_historical_damage,
  
  -- Generated columns based on output_schema
  risk_score,
  risk_tier,
  confidence_level,
  primary_hazard,
  premium_factor,
  
  -- Add metadata
  CURRENT_TIMESTAMP() AS classification_timestamp
  
FROM
  AI.GENERATE_TABLE(
    MODEL `{DATASET_ID}.{VERTEX_AI_CONNECTION_MODEL_ENDPOINT}`,
    (
      -- Select the required prompt column and other fields to pass through
      SELECT 
        county_fips,
        county_name,
        state,
        total_historical_damage,
        prompt  -- Required column name for AI.GENERATE_TABLE
      FROM 
        `{DATASET_ID}.classification_prompts{SAMPLE_SUFFIX}`
        WHERE county_fips IS NOT NULL 
        AND county_name IS NOT NULL 
        AND state IS NOT NULL
    ),
    STRUCT(
      -- Define the schema as a string literal
      "risk_score INT64, risk_tier STRING, confidence_level FLOAT64, primary_hazard STRING, premium_factor FLOAT64" AS output_schema,
      {MAX_OUTPUT_TOKEN} AS max_output_tokens,
      {TEMPERATURE} AS temperature,
      {TOP_P} AS top_p
    )
  );
