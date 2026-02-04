-- =============================================================================
-- Mission 1: Perform Vector Similarity Search
-- =============================================================================
-- Description: Executes a semantic similarity search using the VECTOR_SEARCH function
--              to find products that are semantically similar to the search query.
--              Uses cosine distance metric to measure similarity between vectors.
--
-- Prerequisites:
--   - 04-get-search-vector.sql must be executed first to generate query vector
--   - Product table must have embeddings populated
--   - Vector index (vec_idx) should be created for optimal performance
--
-- Parameters:
--   - @top: Maximum number of results to consider (default: 50)
--   - @min_similarity: Minimum similarity threshold 0-1 (default: 0.75)
--
-- How It Works:
--   1. Retrieves the query vector from dbo.http_response table
--   2. Uses VECTOR_SEARCH to find nearest neighbors in embedding space
--   3. Filters results by minimum similarity threshold
--   4. Returns top 10 most similar products ordered by distance
--
-- Output Columns:
--   - id: Product identifier
--   - product_name: Name of the matching product
--   - description: Product description
--   - category: Product category
--   - distance: Cosine distance (lower = more similar)
--   - similarity: Calculated similarity score (1 - distance)
--
-- Example Results:
--   For "racing car toys for teenagers", expect XBOX games, building kits,
--   remote control cars, and similar products
-- =============================================================================


-- -----------------------------------------------------------------------------
-- SECTION 1: Configure Search Parameters
-- -----------------------------------------------------------------------------
DECLARE @top INT = 50;
DECLARE @min_similarity DECIMAL(19,16) = 0.75;


-- -----------------------------------------------------------------------------
-- SECTION 2: Retrieve Query Vector from Previous Step
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS similar_items;

DECLARE @qv VECTOR(1536) = (
    SELECT TOP(1)
        CAST(JSON_QUERY(response, '$.result.data[0].embedding') AS VECTOR(1536)) AS query_vector
    FROM 
        dbo.http_response
);


-- -----------------------------------------------------------------------------
-- SECTION 3: Execute Vector Similarity Search
-- -----------------------------------------------------------------------------
SELECT TOP (10) 
    
    w.id,
    w.product_name,
    w.description,
    w.category,
    r.distance,
    1 - r.distance AS similarity
INTO similar_items
FROM VECTOR_SEARCH(
    TABLE = dbo.walmart_ecommerce_product_details AS w,
    COLUMN = embedding,
    SIMILAR_TO = @qv,
    METRIC = 'cosine',
    TOP_N = 10
) AS r
WHERE r.distance <= 1 - @min_similarity
ORDER BY r.distance;


-- -----------------------------------------------------------------------------
-- SECTION 4: Display Results
-- -----------------------------------------------------------------------------
SELECT * FROM similar_items;