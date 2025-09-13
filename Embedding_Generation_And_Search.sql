-- Query 2.3.A: Generate embeddings for risk profiles
CREATE OR REPLACE TABLE `{DATASET_ID}.risk_embeddings` AS
SELECT
  ml_generate_embedding_result AS risk_embedding_vector,
  county_fips,
  county_name,
  state,
  risk_summary,
  preliminary_risk_classification,
  total_historical_damage,
  CURRENT_TIMESTAMP() AS embedding_timestamp
FROM
  ML.GENERATE_EMBEDDING(
    MODEL `{DATASET_ID}.{VERTEX_AI_CONNECTION_EMBEDDING_ENDPOINT}`,
    (
      SELECT
        county_fips,
        county_name,
        state,
        risk_summary,
        preliminary_risk_classification,
        total_historical_damage,
        risk_summary AS content  -- Required column name
      FROM `{DATASET_ID}.risk_narrative_prep{SET_SAMPLE}`
    ),
    STRUCT(
      'SEMANTIC_SIMILARITY' AS task_type,
      {EMBEDDING_SIZE} AS output_dimensionality
    )
  );

-- Query 2.3.B: Generate context embeddings with validation
CREATE OR REPLACE TABLE `{DATASET_ID}.context_embeddings` AS
SELECT
  ml_generate_embedding_result AS context_embedding_vector,
  CASE 
    WHEN ml_generate_embedding_result IS NULL THEN 'FAILED'
    WHEN ARRAY_LENGTH(ml_generate_embedding_result) != {EMBEDDING_SIZE} THEN 'INVALID_DIMENSION'
    ELSE 'SUCCESS'
  END AS embedding_status,
  county_fips,
  county_name,
  state,
  risk_context,
  CURRENT_TIMESTAMP() AS embedding_timestamp
FROM
  ML.GENERATE_EMBEDDING(
    MODEL `{DATASET_ID}.{VERTEX_AI_CONNECTION_EMBEDDING_ENDPOINT}`,
    (
      SELECT
        county_fips,
        county_name,
        state,
        risk_context,
        risk_context AS content
      FROM `{DATASET_ID}.risk_narrative_prep{SET_SAMPLE}`
      WHERE LENGTH(risk_context) > 0
    ),
    STRUCT(
      'SEMANTIC_SIMILARITY' AS task_type,
      {EMBEDDING_SIZE} AS output_dimensionality
    )
  );

-- Query 2.3.C: Vector similarity search
WITH query_vectors AS (
  SELECT 
    county_fips AS query_county_fips,
    county_name AS query_county_name,
    state AS query_state,
    risk_embedding_vector AS query_vector
  FROM `{DATASET_ID}.risk_embeddings_complete`
  WHERE county_fips = '{TARGET_COUNTY_FIPS}'
    AND has_valid_embeddings = TRUE
)
SELECT
  qv.query_county_name,
  qv.query_state,
  search_result.base.county_name AS similar_county_name,
  search_result.base.state AS similar_county_state,
  1 - search_result.distance AS similarity_score,
  search_result.base.preliminary_risk_classification AS similar_risk_class,
  search_result.base.risk_summary AS similar_risk_summary
FROM
  query_vectors qv,
  VECTOR_SEARCH(
    (SELECT county_fips, county_name, state, risk_embedding_vector,
            preliminary_risk_classification, total_historical_damage, risk_summary
     FROM `{DATASET_ID}.risk_embeddings_complete`
     WHERE has_valid_embeddings = TRUE),
    'risk_embedding_vector',
    TABLE query_vectors,
    'query_vector',
    top_k => 10,
    distance_type => 'COSINE'
  ) AS search_result
WHERE search_result.base.county_fips != qv.query_county_fips
ORDER BY search_result.distance ASC;