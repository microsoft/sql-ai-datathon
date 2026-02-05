-- =============================================================================
-- Mission 1: Configure Credentials and External Model for Azure OpenAI
-- =============================================================================
-- Description: Creates database-scoped credentials and an external model for 
--              secure access to Azure OpenAI endpoints. The external model is
--              used by AI_GENERATE_EMBEDDINGS() to generate vector embeddings.
--
-- Prerequisites:
--   - Azure OpenAI resource deployed with text-embedding-3-small model
--   - API key or Managed Identity configured
--
-- Configuration:
--   Replace the following placeholders:
--   - <OPENAI_URL>: Your Azure OpenAI endpoint URL (e.g., https://myresource.openai.azure.com)
--   - <OPENAI_API_KEY>: Your Azure OpenAI API key
--   - <FOUNDRY_RESOURCE_NAME>: Your Azure AI Foundry resource name
--
-- Security Options:
--   1. API Key Authentication (shown below)
--   2. Managed Identity (recommended for production - see commented section)
--
-- Usage:
--   Run once after database creation, before executing search queries.
--   After running, you can use:
--     AI_GENERATE_EMBEDDINGS(@text USE MODEL MyEmbeddingModel)
-- =============================================================================


-- -----------------------------------------------------------------------------
-- SECTION 1: Create HTTP Credentials (API Key Method)
-- -----------------------------------------------------------------------------
USE ProductDB;
GO


IF NOT EXISTS (SELECT * FROM sys.database_scoped_credentials WHERE [name] = '<OPENAI_URL>')
BEGIN
    CREATE DATABASE SCOPED CREDENTIAL [<OPENAI_URL>]
    WITH IDENTITY = 'HTTPEndpointHeaders', 
         SECRET = '{"api-key":"<OPENAI_API_KEY>"}';
END
GO


-- -----------------------------------------------------------------------------
-- SECTION 2: Alternative - Managed Identity (Recommended for Production)
-- -----------------------------------------------------------------------------
/*
    Use Managed Identity for passwordless authentication. More info:
    https://devblogs.microsoft.com/azure-sql/go-passwordless-when-calling-azure-openai-from-azure-sql-using-managed-identities/

    IF NOT EXISTS (SELECT * FROM sys.database_scoped_credentials WHERE [name] = '<OPENAI_URL>')
    BEGIN
        CREATE DATABASE SCOPED CREDENTIAL [<OPENAI_URL>]
        WITH IDENTITY = 'Managed Identity', 
             SECRET = '{"resourceid":"https://cognitiveservices.azure.com"}';
    END
    GO
*/


-- -----------------------------------------------------------------------------
-- SECTION 3: Verify Credentials
-- -----------------------------------------------------------------------------
SELECT * FROM sys.database_scoped_credentials WHERE [name] = '<OPENAI_URL>';
GO

-- -----------------------------------------------------------------------------
-- SECTION 4: Create External Model for Embeddings
-- -----------------------------------------------------------------------------
-- Note: Adjust LOCATION, MODEL, and CREDENTIAL as needed

CREATE EXTERNAL MODEL MyEmbeddingModel
WITH (
      LOCATION = 'https://<FOUNDRY_RESOURCE_NAME>.cognitiveservices.azure.com/openai/deployments/text-embedding-3-small/embeddings?api-version=2023-05-15',
      API_FORMAT = 'Azure OpenAI',
      MODEL_TYPE = EMBEDDINGS,
      MODEL = 'text-embedding-3-small',
      CREDENTIAL = [<OPENAI_URL>],
      PARAMETERS = '{"dimensions":1536}'
);
GO

-- -----------------------------------------------------------------------------
-- SECTION 5: Test External Model for Embeddings
-- -----------------------------------------------------------------------------
SELECT AI_GENERATE_EMBEDDINGS('Test text' USE MODEL MyEmbeddingModel)