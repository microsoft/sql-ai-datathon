# Mission 1: Creating Embeddings and Performing Search

You will be guided through implementing semantic search capabilities using embedding models. In this mission, you will:

- **Convert Text to Vectors**: Use the `AI_GENERATE_EMBEDDINGS()` function with an external model to convert text into high-dimensional vector representations
- **Store Embeddings**: Store embeddings efficiently in Azure SQL Database
- **Query with Vector Similarity**: Query the database using `VECTOR_SEARCH` to find semantically related content

## Prerequisites
1. Embedding model access, instructions available in the [Select the Embedding and Chat Models](#select-the-embedding-and-chat-models) section below

## Walkthrough

### Create a SQL Database

You have a few options to create an SQL Database, click one of the links below for instructions:
- [Local SQL Server instance with SQL Server 2025 or later, use the free developer edition](https://learn.microsoft.com/sql/database-engine/install-windows/install-sql-server?view=sql-server-ver17#installation-media)
- [Local SQL Server Container with Visual Studio Code extension](https://learn.microsoft.com/sql/tools/visual-studio-code-extensions/mssql/mssql-local-container?view=sql-server-ver17)
- [Docker container with SQL Server 2025 or later](https://learn.microsoft.com/sql/linux/quickstart-install-connect-docker?view=sql-server-ver17&preserve-view=true&tabs=cli&pivots=cs1-bash)
- [Azure SQL Database instance](https://learn.microsoft.com/azure/azure-sql/database/single-database-create-quickstart?view=azuresql&tabs=azure-portal)


## Setting Up the Database

1. Run the following query to create the database and table structure:

```sql
CREATE DATABASE ProductDB;
GO

USE ProductDB;
GO

DROP TABLE IF EXISTS [dbo].[walmart_ecommerce_product_details];

CREATE TABLE [dbo].[walmart_ecommerce_product_details]
(
	[id] [int] not null,
	[source_unique_id] [char](32) not null,
	[crawl_timestamp] [nvarchar](50) not null,
	[product_url] [nvarchar](200) not null,
	[product_name] [nvarchar](200) not null,
	[description] [nvarchar](max) null,
	[list_price] [decimal](18, 10) null,
	[sale_price] [decimal](18, 10) null,
	[brand] [nvarchar](500) null,
	[item_number] [bigint] null,
	[gtin] [bigint] null,
	[package_size] [nvarchar](500) null,
	[category] [nvarchar](1000) null,
	[postal_code] [nvarchar](10) null,
	[available] [nvarchar](10) not null,
	[embedding] [vector](1536) null,
    CONSTRAINT [PK_walmart_ecommerce_product_details] PRIMARY KEY CLUSTERED ([id] ASC)
);
GO

-- Enable AI Preview Features
ALTER DATABASE SCOPED CONFIGURATION
SET PREVIEW_FEATURES = ON;
GO
```

2. Download the [sample data from kaggle](https://www.kaggle.com/datasets/mauridb/product-data-from-walmart-usa-with-embeddings) and unzip it to access the `walmart_ecommerce_product_details.csv` file.

3. Load data from Azure Blob Storage or local storage (see <a href="https://github.com/microsoft/sql-ai-datathon/blob/main/missions/mission1/02-load-table.sql" target="_blank">02-load-table.sql</a> for blob storage details and cleanup scripts for mistakes). If you are using local storage, you can use the following command to bulk insert data into your table:

```sql
BULK INSERT [dbo].[walmart_ecommerce_product_details]
FROM 'walmart_ecommerce_product_details.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    TABLOCK
);
```

> You can also use SQL Server Management Studio 21 (SSMS 21), which has a [built-in import wizard](https://learn.microsoft.com/sql/relational-databases/import-export/use-a-format-file-to-bulk-import-data-sql-server?view=sql-server-ver17) to load CSV data directly into your table. 


## Select the Embedding and Chat Models
In these next steps, you will be converting prompts and queries into vector representations to perform semantic search and generating responses based on retrieved information. You will need access to the [text-embedding-3-small](https://ai.azure.us/explore/models/text-embedding-3-small/version/2/registry/azure-openai) embedding model and a chat model provider.

There are several embedding model providers available, below are popular options:
- GitHub Models. You can find quickstart guides on how to use models from [GitHub Models](https://docs.github.com/en/github-models/quickstart)
- Deploy models with Microsoft Foundry. Docuementation can be found [here](https://learn.microsoft.com/ai/foundry/model-management/deploy-models).
- Use local models with Ollama or similar tools.

The recommended completion models for this mission are as follows:
| Purpose | Model | Provider |
|---------|-------|----------|
| **Required Embedding Model** | [text-embedding-3-small](https://github.com/marketplace/models/azure-openai/text-embedding-3-small) | Microsoft Foundry / [GitHub Models](https://github.com/marketplace/models/azure-openai/text-embedding-3-small) |
| Text Generation | [gpt-5-mini](https://ai.azure.com/catalog/models/gpt-5-mini) | Microsoft Foundry / [GitHub Models](https://github.com/marketplace/models/azure-openai/gpt-5-mini)|
| Text Generation | [qwen3](https://ai.azure.com/catalog/models/qwen-qwen3-8b) | Microsoft Foundry/[Ollama](https://ollama.com/library/qwen3) |
| Text Generation | [Claude Sonnet 4.5](https://ai.azure.com/catalog/models/claude-sonnet-4-5) | Microsoft Foundry |

You can get your endpoint and key from the provider you choose. Make sure to have these ready for the next steps. You can find the Microsoft Foundry model keys in the project overview of your Foundry resouce. [Visit the documentation](https://learn.microsoft.com/azure/ai-foundry/foundry-models/how-to/deploy-foundry-models?view=foundry)

## Store Database Scope Credentials

Run the following script, replacing placeholders with your actual credentials (see <a href="https://github.com/microsoft/sql-ai-datathon/blob/main/missions/mission1/03-create-http-credentials.sql" target="_blank">03-create-http-credentials.sql</a> for more options including Managed Identity):

```sql
CREATE DATABASE SCOPED CREDENTIAL [https://<OPENAI_URL>.openai.azure.com]
WITH IDENTITY = 'HTTPEndpointHeaders', 
     SECRET = '{"api-key":"<OPENAI_API_KEY>"}';
GO
```

Verify your credentials:

```sql
SELECT * FROM sys.database_scoped_credentials WHERE [name] = 'https://<OPENAI_URL>.openai.azure.com';
GO
```

### Create External Model for Embeddings

Create an external model that enables the `AI_GENERATE_EMBEDDINGS()` function to call Azure OpenAI:

```sql
CREATE EXTERNAL MODEL MyEmbeddingModel
WITH (
      LOCATION = 'https://<FOUNDRY_RESOURCE_NAME>.cognitiveservices.azure.com/openai/deployments/text-embedding-3-small/embeddings?api-version=2023-05-15',
      API_FORMAT = 'Azure OpenAI',
      MODEL_TYPE = EMBEDDINGS,
      MODEL = 'text-embedding-3-small',
      CREDENTIAL = [https://<OPENAI_URL>.openai.azure.com],
      PARAMETERS = '{"dimensions":1536}'
);
GO
```

## Your First Semantic Search

### Step 1: Generate Search Query Embedding

Run the following script to convert a natural language search query into a vector embedding using `AI_GENERATE_EMBEDDINGS()` and find products semantically similar to your search query (see <a href="https://github.com/microsoft/sql-ai-datathon/blob/main/missions/mission1/04-search-similar-items.sql" target="_blank">04-search-similar-items.sql</a>):

```sql
DECLARE @text NVARCHAR(MAX) = 'anything for a teenager boy passionate about racing cars? he owns an XBOX, he likes to build stuff';

-- Generate embedding using the external model
DECLARE @searchVector VECTOR(1536) = AI_GENERATE_EMBEDDINGS(@text USE MODEL MyEmbeddingModel);

-- View the generated embedding
SELECT @searchVector AS embedding;
GO

DECLARE @text NVARCHAR(MAX) = 'anything for a teenager boy passionate about racing cars? he owns an XBOX, he likes to build stuff';
DECLARE @top INT = 50;
DECLARE @min_similarity DECIMAL(19,16) = 0.75;

-- Generate embedding for search query using AI_GENERATE_EMBEDDINGS
DECLARE @qv VECTOR(1536) = AI_GENERATE_EMBEDDINGS(@text USE MODEL MyEmbeddingModel);

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
    TOP_N = @top
) AS r
WHERE r.distance <= 1 - @min_similarity
ORDER BY r.distance;

SELECT * FROM similar_items;
```

### Step 3: Experiment with Different Queries

Modify the `@text` variable in Step 1 to test different search terms and observe the results.

## Test your Semantic Search
Verify that your semantic search is working correctly by your results from the search term "reading glasses for books". You should see items related to reading glasses, like eyewear, magnifying glasses, and other vision-related products.


## Next Steps
After completing this mission, you will have implemented a semantic search solution that can find relevant information based on meaning rather than only keywords.

Proceed to [Mission 2: Retrieval Augmented Generation (RAG)](../mission2/README.md) to learn how to build an end-to-end RAG pipeline that combines embeddings with language model generation.