# Mission 2: Retrieval Augmented Generation (RAG)

This mission demonstrates how to build production-ready AI applications that combine the semantic understanding of embeddings with the generative capabilities of large language models. Retrieval augmented generation (RAG) is a fundamental pattern for creating trustworthy AI systems that answer questions based on your specific domain knowledge.

The techniques learned here enable you to build chatbots, knowledge assistants, and intelligent search systems that provide accurate, source-backed responses.

You will be guided through implementing retrieval augmented generation (RAG) capabilities using embedding models and SQL Database. In this mission, you will:

## Learning Objectives
- **Implement RAG Pipeline**: Build an end-to-end retrieval-augmented generation workflow in SQL
- **Query with Context**: Use vector similarity search to find relevant documents based on user questions
- **Generate Informed Responses**: Feed retrieved context to a language model to produce accurate, grounded answers


## Prerequisites
1. Mission 1 completed (similar_items table populated)
1. Embedding model access (you can use the free AI Proxy to generate embeddings for free)
1. Completion model access (you can use the free AI Proxy to generate completions for free)

## Walkthrough

### Step 1: Chatting with Data

This script implements RAG by combining vector search results with a language model to generate natural language responses grounded in actual product data (see <a href="https://github.com/microsoft/sql-ai-datathon/blob/main/missions/mission2/01-chat-with-data.sql" target="_blank">01-chat-with-data.sql</a>).

Replace `<FOUNDRY_RESOURCE_NAME>` with your Azure OpenAI resource name:

```sql
DECLARE @request NVARCHAR(MAX) = 'anything for a teenager boy passionate about racing cars? he owns an XBOX, he likes to build stuff';

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

DECLARE @prompt NVARCHAR(MAX) = JSON_OBJECT(
    'messages': JSON_ARRAY(
        JSON_OBJECT(
            'role': 'system',
            'content': '
                You as a system assistant who helps users find the best products available in the catalog to satisfy the requested ask.
                Products are provided in an assitant message using a JSON Array with the following format: [{id, name, description}].                 
                Use only the provided products to help you answer the question.        
                Use only the information available in the provided JSON to answer the question.
                Return the top ten products that best answer the question.
                For each returned product add a short explanation of why the product has been suggested. Put the explanation in parenthesis and start with "Thoughts:"
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
    'temperature': 0.2,
    'frequency_penalty': 0,
    'presence_penalty': 0,    
    'stop': NULL
);

-- NOTE: This uses the gpt5-mini model. To use a different model, update "gpt5-mini" in the URL.
DECLARE @retval INT, @response NVARCHAR(MAX);

EXEC @retval = sp_invoke_external_rest_endpoint
    @url = 'https://<FOUNDRY_RESOURCE_NAME>.cognitiveservices.azure.com/openai/deployments/gpt5-mini/chat/completions?api-version=2024-08-01-preview',
    @headers = '{"Content-Type":"application/json"}',
    @method = 'POST',
    @credential = [https://<FOUNDRY_RESOURCE_NAME>.cognitiveservices.azure.com/],
    @timeout = 120,
    @payload = @prompt,
    @response = @response OUTPUT
    WITH RESULT SETS NONE;

SELECT JSON_VALUE(@response, '$.result.choices[0].message.content') AS chat_response;
```

### Step 2: Structured Output from Chat

This script extends RAG to return structured JSON output instead of free-form text, making it easier to process programmatically (see <a href="https://github.com/microsoft/sql-ai-datathon/blob/main/missions/mission2/02-chat-with-data-structured-output.sql" target="_blank">02-chat-with-data-structured-output.sql</a>).

The JSON schema enforces this output format:
```json
{
  "products": [
    {
      "result_position": 1,
      "id": 123,
      "description": "Brief summary (max 10 words)",
      "thoughts": "Explanation of why selected"
    }
  ]
}
```

Replace `<FOUNDRY_RESOURCE_NAME>` with your Azure OpenAI resource name and run the script.

### Step 3: Setting up Stored Procedures

Create reusable stored procedures that encapsulate the RAG logic (see <a href="https://github.com/microsoft/sql-ai-datathon/blob/main/missions/mission2/03-stored-procedures.sql" target="_blank">03-stored-procedures.sql</a>).

#### Procedure 1: Generate Embeddings

```sql
CREATE OR ALTER PROCEDURE [dbo].[get_embedding]
@inputText NVARCHAR(MAX),
@embedding VECTOR(1536) OUTPUT,
@error NVARCHAR(MAX) = NULL OUTPUT
AS
DECLARE @retval INT;
DECLARE @payload NVARCHAR(MAX) = JSON_OBJECT('input': @inputText);
DECLARE @response NVARCHAR(MAX)
BEGIN TRY
    EXEC @retval = sp_invoke_external_rest_endpoint
        @url = 'https://<FOUNDRY_RESOURCE_NAME>.cognitiveservices.azure.com/openai/deployments/text-embedding-3-small/embeddings?api-version=2023-03-15-preview',
        @method = 'POST',
        @credential = [https://<FOUNDRY_RESOURCE_NAME>.cognitiveservices.azure.com/],
        @payload = @payload,
        @response = @response OUTPUT
        WITH RESULT SETS NONE;
END TRY
BEGIN CATCH
    SET @error = JSON_OBJECT('error':'Embedding:REST', 'error_code':ERROR_NUMBER(), 'error_message':ERROR_MESSAGE())
    RETURN -1
END CATCH

IF @retval != 0 BEGIN
    SET @error = JSON_OBJECT('error':'Embedding:OpenAI', 'error_code':@retval, 'error_message':@response)
    RETURN @retval
END

DECLARE @re NVARCHAR(MAX) = JSON_QUERY(@response, '$.result.data[0].embedding')
SET @embedding = CAST(@re AS VECTOR(1536));

RETURN @retval
GO
```

#### Procedure 2: Find Similar Items

```sql
CREATE OR ALTER PROCEDURE [dbo].[get_similar_items]
@inputText NVARCHAR(MAX),
@result NVARCHAR(MAX) = NULL OUTPUT,
@error NVARCHAR(MAX) = NULL OUTPUT
AS
DECLARE @top INT = 10
DECLARE @min_similarity DECIMAL(19,16) = 0.75
DECLARE @qv VECTOR(1536)
DECLARE @embedding VECTOR(1536)
EXEC dbo.get_embedding @inputText = @inputText, @embedding = @embedding OUTPUT, @error = @error OUTPUT
IF @error IS NOT NULL
    RETURN -1

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
GO
```

#### Test the Stored Procedures

```sql
DECLARE @embedding VECTOR(1536), @error NVARCHAR(MAX);
EXEC dbo.get_embedding @inputText = 'wireless headphones', @embedding = @embedding OUTPUT, @error = @error OUTPUT;
SELECT @embedding, @error;
```

```sql
DECLARE @result NVARCHAR(MAX), @error NVARCHAR(MAX);
EXEC dbo.get_similar_items @inputText = 'wireless headphones', @result = @result OUTPUT, @error = @error OUTPUT;
SELECT @result, @error;
```


## Next Steps
After completing this mission, you will have implemented a robust RAG pipeline that can answer questions based on your SQL data.

Proceed to [Mission 3: Orchestrate SQL + AI workflows](../mission3/README.md) to learn how to build complex, multi-step AI workflows that integrate RAG with other SQL and AI capabilities.