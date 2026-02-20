-- =============================================================================
-- Mission 2: Structured JSON Output from Chat
-- =============================================================================
-- ⚠️ BEFORE RUNNING: Verify you are connected to ProductDB
-- =============================================================================
-- Description: Extends RAG implementation to return structured JSON output
--              instead of free-form text. Uses JSON Schema feature
--              to enforce consistent output format for easier processing.
--
-- Supported Providers:
--   - FOUNDRY: Uses Microsoft Foundry
--   - GITHUB: Uses GitHub Models
--
-- Prerequisites:
--   - Mission 1 completed (similar_items table populated)
--   - Model deployed and credentials configured
--
-- Configuration:
--   1. Set @provider to 'FOUNDRY' or 'GITHUB' in SECTION 5
--   2. Replace placeholders with your values:
--      Microsoft Foundry:
--        - <FOUNDRY_RESOURCE_NAME>: Your Microsoft Foundry resource name
--        - <OPENAI_URL>: Your credential name
--      GitHub Models:
--        - Ensure credential exists for https://models.github.ai/inference
--
-- JSON Schema Definition:
--   {
--     "products": [
--       {
--         "result_position": number,    // Ranking position
--         "id": number,                 // Product ID
--         "description": string,        // Brief summary (max 10 words)
--         "thoughts": string            // Explanation of why selected
--       }
--     ]
--   }
--
-- Output Columns:
--   - id, product_name, description: Original product data
--   - genai_short_description: AI-generated brief description
--   - category: Product category
--   - thoughts: AI reasoning for recommendation
-- =============================================================================


-- -----------------------------------------------------------------------------
-- SECTION 1: Define User Request
-- -----------------------------------------------------------------------------

DECLARE @request NVARCHAR(MAX) = 'anything for a teenager boy passionate about racing cars? he owns an XBOX, he likes to build stuff';


-- -----------------------------------------------------------------------------
-- SECTION 2: Retrieve Products from Vector Search Results
-- -----------------------------------------------------------------------------
DECLARE @products JSON =
(
    SELECT 
        JSON_ARRAYAGG(
            JSON_OBJECT(
                'id': [id],
                'name': [product_name],
                'description': [description]
            )
        )
    FROM 
        dbo.similar_items
);


-- -----------------------------------------------------------------------------
-- SECTION 3: Build Chat Prompt with System Instructions
-- -----------------------------------------------------------------------------
DECLARE @system_content NVARCHAR(MAX) = '
    You as a system assistant who helps users find the best products available in the catalog to satesfy the requested ask.
    Products are provided in an assitant message using a JSON Array with the following format: [{id, name, description}].                 
    Use only the provided products to help you answer the question.        
    Use only the information available in the provided JSON to answer the question.
    Return up to top ten products that best answer the question. Return less than that ten products if not all products fit the request.
    Don''t return products that are not relevant with the ask or that don''t comply with user request.
    Make sure to use details, notes, and description that are provided in each product are used only with that product.                
    If the question cannot be answered by the provided samples, don''t return any result.
    If asked question is about topics you don''t know, don''t return any result.
    If no products are provided, don''t return any result.                    
';


-- -----------------------------------------------------------------------------
-- SECTION 4: Define Structured Output JSON Schema
-- -----------------------------------------------------------------------------
DECLARE @json_schema NVARCHAR(MAX) = N'{
    "type": "object",
    "properties": {
        "products": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "result_position": {
                        "type": "number"
                    },
                    "id": {
                        "type": "number"
                    },
                    "description": {
                        "type": "string",
                        "description": "a brief and summarized description of the product, no more than ten words"
                    },                            
                    "thoughts": {
                        "type": "string",
                        "description": "explanation of why the product has been chosen"
                    }
                },
                "required": [
                    "result_position",
                    "id",                            
                    "description",                            
                    "thoughts"                            
                ],
                "additionalProperties": false
            }
        }
    },
    "required": ["products"],
    "additionalProperties": false
}';


-- -----------------------------------------------------------------------------
-- SECTION 5: Call Chat Completion API (Supports Microsoft Foundry or GitHub Models)
-- -----------------------------------------------------------------------------
-- CONFIGURATION: Set @provider to choose the model provider
--   'FOUNDRY' - Use Microsoft Foundry 
--   'GITHUB'  - Use GitHub Models
-- -----------------------------------------------------------------------------
DECLARE @provider NVARCHAR(20) = 'FOUNDRY';  -- Change to 'GITHUB' for GitHub Models

DECLARE @prompt NVARCHAR(MAX);
DECLARE @retval INT, @response NVARCHAR(MAX);
DECLARE @url NVARCHAR(500), @credential NVARCHAR(200);

IF @provider = 'FOUNDRY'
BEGIN
    -- Build prompt for Foundry 
    SET @prompt = JSON_OBJECT(
        'input': JSON_ARRAY(
            JSON_OBJECT('role': 'system', 'content': @system_content),
            JSON_OBJECT('role': 'assistant', 'content': 'The available products are the following:'),
            JSON_OBJECT('role': 'assistant', 'content': COALESCE(CAST(@products AS NVARCHAR(MAX)), '')),
            JSON_OBJECT('role': 'user', 'content': @request)
        ),    
        'model': 'gpt-5-mini'
    );
    
    -- Add structured output format for Foundry ($.text.format)
    DECLARE @foundry_format NVARCHAR(MAX) = JSON_OBJECT(
        'format': JSON_OBJECT(
            'type': 'json_schema',
            'name': 'products',
            'strict': CAST(1 AS BIT),
            'schema': JSON_QUERY(@json_schema)
        )
    );
    SET @prompt = JSON_MODIFY(@prompt, '$.text', JSON_QUERY(@foundry_format));
    
    -- Replace <FOUNDRY_RESOURCE_NAME> with your Microsoft Foundry resource name
    SET @url = 'https://<FOUNDRY_RESOURCE_NAME>.cognitiveservices.azure.com/openai/deployments/gpt-5-mini/chat/completions?api-version=2025-04-01-preview';
    SET @credential = '<OPENAI_URL>';
END
ELSE IF @provider = 'GITHUB'
BEGIN
    -- Build prompt for GitHub Models (uses 'messages' array)
    SET @prompt = JSON_OBJECT(
        'messages': JSON_ARRAY(
            JSON_OBJECT('role': 'system', 'content': @system_content),
            JSON_OBJECT('role': 'assistant', 'content': 'The available products are the following:'),
            JSON_OBJECT('role': 'assistant', 'content': COALESCE(CAST(@products AS NVARCHAR(MAX)), '')),
            JSON_OBJECT('role': 'user', 'content': @request)
        ),    
        'model': 'gpt-4o-mini',
        'response_format': JSON_OBJECT(
            'type': 'json_schema',
            'json_schema': JSON_OBJECT(
                'name': 'products',
                'strict': CAST(1 AS BIT),
                'schema': JSON_QUERY(@json_schema)
            )
        )
    );
    
    SET @url = 'https://models.github.ai/inference/chat/completions';
    SET @credential = 'https://models.github.ai/inference';
END

-- Call the API
EXEC @retval = sp_invoke_external_rest_endpoint
    @url = @url,
    @headers = '{"Content-Type":"application/json"}',
    @method = 'POST',
    @credential = @credential,
    @timeout = 120,
    @payload = @prompt,
    @response = @response OUTPUT
    WITH RESULT SETS NONE;


-- -----------------------------------------------------------------------------
-- SECTION 6: Store Response and Extract Content (Provider-Specific Parsing)
-- -----------------------------------------------------------------------------
-- Extract the structured JSON content based on provider
-- Foundry path: $.result.output[1].content[0].text
-- GitHub path:  $.result.choices[0].message.content
DECLARE @content NVARCHAR(MAX);

IF @provider = 'FOUNDRY'
BEGIN
    SELECT @content = JSON_VALUE(m.[text], '$')
    FROM OPENJSON(@response, '$.result.output[1].content') WITH ([text] NVARCHAR(MAX) '$.text') m;
END
ELSE IF @provider = 'GITHUB'
BEGIN
    SELECT @content = content
    FROM OPENJSON(@response, '$.result.choices') WITH (content NVARCHAR(MAX) '$.message.content');
END

DROP TABLE IF EXISTS #r;
CREATE TABLE #r (response NVARCHAR(MAX), content NVARCHAR(MAX));
INSERT INTO #r VALUES (@response, @content);
GO


-- -----------------------------------------------------------------------------
-- SECTION 7: Parse Structured JSON Results
-- -----------------------------------------------------------------------------
SELECT 
    sr.* 
FROM 
    #r
CROSS APPLY
    OPENJSON(content, '$.products') WITH (
        result_position INT,
        id INT,        
        [description] NVARCHAR(MAX),
        thoughts NVARCHAR(MAX)
    ) AS sr;


-- -----------------------------------------------------------------------------
-- SECTION 8: Join AI Results with Original Product Data
-- -----------------------------------------------------------------------------
SELECT 
    p.[id], 
    p.[product_name], 
    p.[description],
    sr.[description] AS genai_short_description,
    p.[category],
    sr.thoughts
FROM 
    #r
CROSS APPLY
    OPENJSON(content, '$.products') WITH (
        result_position INT,
        id INT,        
        [description] NVARCHAR(MAX),
        thoughts NVARCHAR(MAX)
    ) AS sr
INNER JOIN
    dbo.[walmart_ecommerce_product_details] p ON sr.id = p.id
ORDER BY
    sr.result_position;