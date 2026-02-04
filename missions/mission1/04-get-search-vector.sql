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
-- SECTION 2: Prepare API Request
-- -----------------------------------------------------------------------------
DECLARE @retval INT, @response NVARCHAR(MAX);
DECLARE @payload NVARCHAR(MAX);
SET @payload = JSON_OBJECT('input': @text);


-- -----------------------------------------------------------------------------
-- SECTION 3: Call Azure OpenAI Embedding API
-- -----------------------------------------------------------------------------
BEGIN TRY
    EXEC @retval = sp_invoke_external_rest_endpoint
        @url = '<OPENAI_URL>/openai/deployments/text-embedding-3-small/embeddings?api-version=2023-03-15-preview',
        @method = 'POST',
        @credential = [https://<OPENAI_URL>.openai.azure.com],
        @payload = @payload,
        @response = @response OUTPUT;
END TRY
BEGIN CATCH
    SELECT 
        'SQL' AS error_source, 
        ERROR_NUMBER() AS error_code,
        ERROR_MESSAGE() AS error_message;
    RETURN;
END CATCH


-- -----------------------------------------------------------------------------
-- SECTION 4: Handle API Errors
-- -----------------------------------------------------------------------------
IF (@retval != 0) 
BEGIN
    SELECT 
        'OPENAI' AS error_source, 
        JSON_VALUE(@response, '$.result.error.code') AS error_code,
        JSON_VALUE(@response, '$.result.error.message') AS error_message,
        @response AS error_response;
    RETURN;
END;


-- -----------------------------------------------------------------------------
-- SECTION 5: Store Response for Subsequent Queries
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS dbo.http_response;
CREATE TABLE dbo.http_response (response JSON);
INSERT INTO dbo.http_response (response) VALUES (@response);

SELECT * FROM dbo.http_response;


-- -----------------------------------------------------------------------------
-- SECTION 6: View the Generated Embedding Vector
-- -----------------------------------------------------------------------------
SELECT TOP(1)
    JSON_QUERY(response, '$.result.data[0].embedding') AS embedding
FROM 
    dbo.http_response;
GO
