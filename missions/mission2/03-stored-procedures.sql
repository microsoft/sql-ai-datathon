-- =============================================================================
-- Mission 2: Stored Procedures for RAG Pipeline
-- =============================================================================
-- Description: Reusable stored procedures that encapsulate embedding generation
--              and vector similarity search logic for the RAG pipeline.
--
-- Prerequisites:
--   - Azure OpenAI endpoint configured with text-embedding-3-small
--   - Database-scoped credentials created
--   - Product table with embeddings populated
--
-- Configuration:
--   Replace <FOUNDRY_RESOURCE_NAME> with your Azure OpenAI resource name
--
-- Procedures:
--   1. dbo.get_embedding     - Generates vector embedding for input text
--   2. dbo.get_similar_items - Finds similar products using vector search
-- =============================================================================


/*
================================================================================
STORED PROCEDURE: dbo.get_embedding
================================================================================
Description:
    Generates a 1536-dimensional vector embedding for input text using 
    Azure OpenAI's text-embedding-3-small model.

Parameters:
    @inputText   nvarchar(max)   [IN]  - The text to convert into a vector embedding
    @embedding   vector(1536)    [OUT] - The resulting embedding vector
    @error       nvarchar(max)   [OUT] - JSON error object if the operation fails

Returns:
    0           - Success
    -1          - REST endpoint failure
    Non-zero    - OpenAI API error
================================================================================
*/
create or alter procedure [dbo].[get_embedding]
@inputText nvarchar(max),
@embedding vector(1536) output,
@error nvarchar(max) = null output
as
declare @retval int;
declare @payload nvarchar(max) = json_object('input': @inputText);
declare @response nvarchar(max)
begin try
    exec @retval = sp_invoke_external_rest_endpoint
        @url = 'https://<FOUNDRY_RESOURCE_NAME>.cognitiveservices.azure.com/openai/deployments/text-embedding-3-small/embeddings?api-version=2023-03-15-preview',
        @method = 'POST',
        @credential = [https://<FOUNDRY_RESOURCE_NAME>.cognitiveservices.azure.com/],
        @payload = @payload,
        @response = @response output
        with result sets none;
end try
begin catch
    set @error = json_object('error':'Embedding:REST', 'error_code':ERROR_NUMBER(), 'error_message':ERROR_MESSAGE())
    return -1
end catch

if @retval != 0 begin
    set @error = json_object('error':'Embedding:OpenAI', 'error_code':@retval, 'error_message':@response)
    return @retval
end

declare @re nvarchar(max) = json_query(@response, '$.result.data[0].embedding')
set @embedding = cast(@re as vector(1536));

return @retval
go

/*
Test query for get_embedding:
    DECLARE @embedding vector(1536), @error nvarchar(max);
    EXEC dbo.get_embedding @inputText = 'wireless headphones', @embedding = @embedding OUTPUT, @error = @error OUTPUT;
    SELECT @embedding, @error;
*/


/*
================================================================================
STORED PROCEDURE: dbo.get_similar_items
================================================================================
Description:
    Performs a semantic similarity search against the walmart_ecommerce_product_details
    table, returning products that match the input text based on vector similarity.

Parameters:
    @inputText   nvarchar(max)   [IN]  - Search query text
    @result      nvarchar(max)   [OUT] - JSON array of matching products
    @error       nvarchar(max)   [OUT] - JSON error object if the operation fails

Behavior:
    - Returns top 10 most similar products
    - Filters results with minimum similarity of 0.75 (cosine distance <= 0.25)
    - Uses VECTOR_SEARCH with cosine metric

Result Schema (JSON):
    [
      {
        "id": 123,
        "name": "Product Name",
        "description": "Product description",
        "category": "Category",
        "sale_price": 29.99
      }
    ]

Returns:
    0           - Success
    -1          - Embedding generation failure
================================================================================
*/
create or alter procedure [dbo].[get_similar_items]
@inputText nvarchar(max),
@result nvarchar(max) = null output,
@error nvarchar(max) = null output
as
declare @top int = 10
declare @min_similarity decimal(19,16) = 0.75
declare @qv vector(1536)
declare @embedding vector(1536)
exec dbo.get_embedding @inputText = @inputText, @embedding = @embedding output, @error = @error output
if @error is not null
    return -1

SELECT @result = (
    SELECT  
        w.id,
        w.product_name AS name,
        w.description,
        w.category,
        w.sale_price
    FROM VECTOR_SEARCH(
             TABLE = dbo.walmart_ecommerce_product_details AS w,
             COLUMN = embedding,
             SIMILAR_TO = @embedding,
             METRIC = 'cosine',
             TOP_N = @top
         ) AS r
    WHERE r.distance <= 1 - @min_similarity
    ORDER BY r.distance
    FOR JSON PATH
);

SELECT @result AS result;
go

/*
Test query for get_similar_items:
    DECLARE @result nvarchar(max), @error nvarchar(max);
    EXEC dbo.get_similar_items @inputText = 'wireless headphones', @result = @result OUTPUT, @error = @error OUTPUT;
    SELECT @result, @error;
*/