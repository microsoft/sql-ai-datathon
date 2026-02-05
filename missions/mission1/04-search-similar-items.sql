-- =============================================================================
-- Mission 1: Semantic Search with AI_GENERATE_EMBEDDINGS
-- =============================================================================
-- Description: Performs end-to-end semantic similarity search by:
--              1. Generating a vector embedding from a natural language query
--              2. Using VECTOR_SEARCH to find similar products
--              Uses AI_GENERATE_EMBEDDINGS() with the MyEmbeddingModel external model.
--
-- Prerequisites:
--   - 03-create-http-credentials.sql must be executed first (creates External Model)
--   - Product table with embeddings populated (from 02-load-table.sql)
--
-- How It Works:
--   1. Takes a natural language search query (e.g., "racing car toys for teenagers")
--   2. Calls AI_GENERATE_EMBEDDINGS(@text USE MODEL MyEmbeddingModel)
--   3. Uses VECTOR_SEARCH to find nearest neighbors in embedding space
--   4. Returns products with similarity above threshold
--
-- Key SQL Server 2025 Functions:
--   - AI_GENERATE_EMBEDDINGS() - Generates embeddings via External Model
--   - VECTOR_SEARCH() - Performs approximate nearest neighbor search
--
-- Output:
--   - similar_items table with matching products and similarity scores
-- =============================================================================


-- -----------------------------------------------------------------------------
-- SECTION 1: Define Search Query
-- -----------------------------------------------------------------------------
USE ProductDB;
GO


DECLARE @text NVARCHAR(MAX) = 'anything for a teenager boy passionate about racing cars? he owns an XBOX, he likes to build stuff';


-- -----------------------------------------------------------------------------
-- SECTION 2: Call Azure OpenAI Embedding API
-- -----------------------------------------------------------------------------
SELECT AI_GENERATE_EMBEDDINGS(@text USE MODEL MyEmbeddingModel);


-- -----------------------------------------------------------------------------
-- SECTION 3: Configure Search Parameters
-- -----------------------------------------------------------------------------
DECLARE @top INT = 50;
DECLARE @min_similarity DECIMAL(19,16) = 0.75;
DECLARE @qv VECTOR(1536) = AI_GENERATE_EMBEDDINGS(@text USE MODEL MyEmbeddingModel);

-- -----------------------------------------------------------------------------
-- SECTION 4: Execute Vector Similarity Search
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS similar_items;

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
-- SECTION 5: Display Results
-- -----------------------------------------------------------------------------
SELECT * FROM similar_items;