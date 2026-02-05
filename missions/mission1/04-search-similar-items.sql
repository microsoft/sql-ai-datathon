-- =============================================================================
-- Mission 1: Generate Search Query Embedding
-- =============================================================================
-- Description: Transforms a natural language search query into a vector embedding
--              using Azure OpenAI's text-embedding-3-small model. The resulting
--              vector is stored in a temporary table for use in similarity searches.
--
-- Prerequisites:
--   - 03-create-http-credentials.sql must be executed first
--   - Azure OpenAI endpoint accessible from SQL Server
--   - Valid database-scoped credentials configured
--
-- Configuration:
--   Replace the following placeholders:
--   - <OPENAI_URL>: Your Azure OpenAI endpoint URL
--
-- How It Works:
--   1. Takes a natural language search query (e.g., "racing car toys for teenagers")
--   2. Calls Azure OpenAI embedding API via sp_invoke_external_rest_endpoint
--   3. Extracts the 1536-dimensional vector from the API response
--   4. Stores the result in dbo.http_response table for subsequent queries
--
-- Output:
--   - dbo.http_response table containing the embedding vector as JSON
--
-- Next Step:
--   Run 05-get-similar-items.sql to perform semantic search using this vector
-- =============================================================================


-- -----------------------------------------------------------------------------
-- SECTION 1: Define Search Query
-- -----------------------------------------------------------------------------
DECLARE @text NVARCHAR(MAX) = 'anything for a teenager boy passionate about racing cars? he owns an XBOX, he likes to build stuff';


-- -----------------------------------------------------------------------------
-- SECTION 2: Call Azure OpenAI Embedding API
-- -----------------------------------------------------------------------------
SELECT AI_GENERATE_EMBEDDINGS(@text USE MODEL MyEmbeddingModel);
GO


-- -----------------------------------------------------------------------------
-- SECTION 1: Configure Search Parameters
-- -----------------------------------------------------------------------------
DECLARE @top INT = 50;
DECLARE @min_similarity DECIMAL(19,16) = 0.75;
DECLARE @qv VECTOR(1536) = AI_GENERATE_EMBEDDINGS(@text USE MODEL MyEmbeddingModel);

-- -----------------------------------------------------------------------------
-- SECTION 3: Execute Vector Similarity Search
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS similar_items;
GO

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