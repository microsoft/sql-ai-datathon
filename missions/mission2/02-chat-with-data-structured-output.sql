-- =============================================================================
-- Mission 2: Structured JSON Output from Chat
-- =============================================================================
-- Description: Extends RAG implementation to return structured JSON output
--              instead of free-form text. Uses OpenAI's JSON Schema feature
--              to enforce consistent output format for easier processing.
--
-- Prerequisites:
--   - Mission 1 completed (similar_items table populated)
--   - Azure OpenAI gpt-5-mini model deployed (API version 2025-04-01-preview)
--   - Database-scoped credentials configured
--
-- Configuration:
--   Replace <FOUNDRY_RESOURCE_NAME> with your Azure OpenAI resource name
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
-- How It Works:
--   1. Builds prompt with product data from vector search
--   2. Attaches JSON schema via $.text.format parameter
--   3. Calls Azure OpenAI Responses API with structured output enabled
--   4. Extracts JSON from $.result.output[1].content[0].text path
--   5. Parses JSON response and joins back to product table
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
USE ProductDB;
GO

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
DECLARE @prompt NVARCHAR(MAX) = JSON_OBJECT(
    'input': JSON_ARRAY(
        JSON_OBJECT(
            'role': 'system',
            'content': '
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
            '
        ),
        JSON_OBJECT(
            'role': 'assistant',
            'content': 'The available products are the following:'
        ),
        JSON_OBJECT(
            'role': 'assistant',
            'content': COALESCE(CAST(@products AS NVARCHAR(MAX)), '')
        ),
        JSON_OBJECT(
            'role': 'user',
            'content': @request
        )
    ),    
    'model': 'gpt-5-mini'
);


-- -----------------------------------------------------------------------------
-- SECTION 4: Define Structured Output JSON Schema
-- -----------------------------------------------------------------------------
DECLARE @js NVARCHAR(MAX) = N'{
    "format": {
        "type": "json_schema",
        "name": "products",
        "strict": true,
        "schema": {
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
        }        
    }        
}';

SET @prompt = JSON_MODIFY(@prompt, '$.text', JSON_QUERY(@js));


-- -----------------------------------------------------------------------------
-- SECTION 5: Call Azure OpenAI Chat Completion API
-- -----------------------------------------------------------------------------
-- NOTE: This uses the gpt-5-mini model. To use a different model, update "gpt-5-mini" in the URL below
-- and in any other files that reference it (e.g., mission3 notebooks, mission4 apps).
DECLARE @retval INT, @response NVARCHAR(MAX);

EXEC @retval = sp_invoke_external_rest_endpoint
    @url = 'https://<FOUNDRY_RESOURCE_NAME>.cognitiveservices.azure.com/openai/deployments/gpt-5-mini/chat/completions?api-version=2025-04-01-preview',
    @headers = '{"Content-Type":"application/json"}',
    @method = 'POST',
    @credential = [https://<FOUNDRY_RESOURCE_NAME>.cognitiveservices.azure.com/],
    @timeout = 120,
    @payload = @prompt,
    @response = @response OUTPUT
    WITH RESULT SETS NONE;


-- -----------------------------------------------------------------------------
-- SECTION 6: Store Response for Processing
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS #r;
CREATE TABLE #r (response NVARCHAR(MAX));
INSERT INTO #r VALUES (@response);
GO


-- -----------------------------------------------------------------------------
-- SECTION 7: Parse Structured JSON Results
-- -----------------------------------------------------------------------------
SELECT 
    sr.* 
FROM 
    #r
CROSS APPLY
    OPENJSON(response, '$.result.output[1].content') WITH (
        [text] NVARCHAR(MAX) '$.text'
    ) m
CROSS APPLY
    OPENJSON(m.[text], '$.products') WITH (
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
    OPENJSON(response, '$.result.output[1].content') WITH (
        [text] NVARCHAR(MAX) '$.text'
    ) m
CROSS APPLY
    OPENJSON(m.[text], '$.products') WITH (
        result_position INT,
        id INT,        
        [description] NVARCHAR(MAX),
        thoughts NVARCHAR(MAX)
    ) AS sr
INNER JOIN
    dbo.[walmart_ecommerce_product_details] p ON sr.id = p.id
ORDER BY
    sr.result_position;