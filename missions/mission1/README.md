# Mission 1: Creating Embeddings and Performing Search

You will be guided through implementing semantic search capabilities using embedding models. In this mission, you will:

- **Convert Text to Vectors**: Use the `AI_GENERATE_EMBEDDINGS()` function with an external model to convert text into high-dimensional vector representations
- **Store Embeddings**: Store embeddings efficiently in Azure SQL Database
- **Query with Vector Similarity**: Query the database using `VECTOR_SEARCH` to find semantically related content

## Prerequisites
1. Embedding model access, instructions available in the [Select the Embedding and Chat Models](#select-the-embedding-and-chat-models) section below

## Walkthrough

### Use SQL Server 2025 in GitHub Codespaces
This repository is configured to install SQL Server 2025 and the [SQL Server (mssql) VSCode extension](https://marketplace.visualstudio.com/items?itemName=ms-mssql.mssql) in your Codespace environment. If you are using Codespaces, follow these steps to get started in the extension:

1. Open the Command Palette (Ctrl+Shift+P or Cmd+Shift+P) and select "SQL Server: Focus on Connections View".
2. You should see a connection profile for your local SQL Server instance. Click on it to connect. If you don't see it, you can create a new connection profile with the details below:
    If you do not see a connection profile in the connection dialog, enter the following details:
    - Server name: `localhost, 1433`
    - Authentication type: `SQL Login`
    - Username: `SA`
    - Password: Check `.devcontainer/devcontainer.json` for the value.
3. Click "Connect" to establish a connection to your local SQL Server instance.

![Screenshot of the SQL Server connection setup page in VSCode](mssql-connection-setup.png)


### Create a SQL Database

> You may skip this step if you are using the provided Codespaces environment, as SQL Server 2025 is already installed and running. You can connect to the local instance using the connection details provided in the previous section.

You have a few options to create an SQL Database, click one of the links below for instructions:
- [Local SQL Server instance with SQL Server 2025 or later, use the free developer edition](https://learn.microsoft.com/sql/database-engine/install-windows/install-sql-server?view=sql-server-ver17#installation-media)
- [Azure SQL Database instance (free offer)](https://aka.ms/sqlfreeoffer)
- [Local SQL Server Container with Visual Studio Code extension](https://learn.microsoft.com/sql/tools/visual-studio-code-extensions/mssql/mssql-local-container?view=sql-server-ver17)
- [Docker container with SQL Server 2025 or later](https://learn.microsoft.com/sql/linux/quickstart-install-connect-docker?view=sql-server-ver17&preserve-view=true&tabs=cli&pivots=cs1-bash)


## Setting Up the Database

> This script is also available in the repo as <a href="https://github.com/microsoft/sql-ai-datathon/blob/main/missions/mission1/01-create-table.sql" target="_blank">01-create-table.sql</a>

1. Open a new query window in your SQL client (e.g., VSCode with MSSQL extension, SQL Server Management Studio) and verify you're connected to your SQL Server instance.

1. Run the following query to create the database:

```sql
CREATE DATABASE ProductDB;
GO
```

### Verify Database Context in VSCode
If using the MSSQL Extension, switch to the newly created database context in order to create the table in the correct database. 
    - You can do this by clicking on the database name in the bottom right corner of VSCode and selecting `ProductDB` from the list.

### Verify Database Context in SSMS 22
Navigate to SQL Editor tool bar and select `ProductDB` from the database dropdown menu to switch the context to the newly created database.

1. Run the following script to create a table for storing product details along with their embeddings:

```sql
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

1. Download the [sample data from kaggle](https://www.kaggle.com/datasets/mauridb/product-data-from-walmart-usa-with-embeddings?select=walmart-product-with-embeddings-dataset-usa-text-3-small) and unzip it to access the `walmart-product-with-embeddings-dataset-usa-text-3-small.csv` file.

1. Load data from Azure Blob Storage or local storage (see <a href="https://github.com/microsoft/sql-ai-datathon/blob/main/missions/mission1/02-load-table.sql" target="_blank">02-load-table.sql</a> for blob storage details and cleanup scripts for mistakes). If you are using local storage, you can use the following command to bulk insert data into your table:

```sql
BULK INSERT dbo.[walmart_ecommerce_product_details]
FROM 'walmart-product-with-embeddings-dataset-usa-text-3-small.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    FIELDQUOTE = '"',
    BATCHSIZE = 1000,
    TABLOCK
);
GO
```

> You can also use SQL Server Management Studio 22 (SSMS 22), which has a [built-in import wizard](https://learn.microsoft.com/sql/relational-databases/import-export/use-a-format-file-to-bulk-import-data-sql-server?view=sql-server-ver17) to load CSV data directly into your table. 

1. After loading the data, create a vector index on the `embedding` column to optimize similarity search queries:

```sql
CREATE VECTOR INDEX vec_idx
ON dbo.walmart_ecommerce_product_details(embedding)
WITH (METRIC = 'COSINE', TYPE = 'DISKANN');
GO
```

1. Verify that the data has been loaded correctly by running a simple query:
```sql
SELECT * FROM dbo.walmart_ecommerce_product_details;
```

## Select the Embedding and Chat Models
In these next steps, you will be converting prompts and queries into vector representations to perform semantic search and generating responses based on retrieved information. You will need access to the [text-embedding-3-small](https://ai.azure.us/explore/models/text-embedding-3-small/version/2/registry/azure-openai) embedding model and a chat model provider, this walkthrough will use [gpt-5-mini](https://ai.azure.com/catalog/models/gpt-5-mini).

There are several model providers available, below are two recommended options:
- GitHub Models, which is free to use. You can find quickstart guides on how to use models from [GitHub Models](https://docs.github.com/en/github-models/quickstart)
- Deploy models with Microsoft Foundry. Docuementation can be found [here](https://learn.microsoft.com/ai/foundry/model-management/deploy-models).

You can get your endpoint and key from the provider you choose. Make sure to have these ready for the next steps. You can find the Microsoft Foundry model keys in the project overview of your Foundry resouce. [Visit the documentation](https://learn.microsoft.com/azure/ai-foundry/foundry-models/how-to/deploy-foundry-models?view=foundry)

## Store Database Scope Credentials

Run the following script, replacing placeholders with your actual credentials (see <a href="https://github.com/microsoft/sql-ai-datathon/blob/main/missions/mission1/03-create-http-credentials.sql" target="_blank">03-create-http-credentials.sql</a> for more options including Managed Identity):

### Option A: Microsoft Foundry (API Key)

```sql
IF NOT EXISTS (SELECT * FROM sys.database_scoped_credentials WHERE [name] = '<OPENAI_URL>')
BEGIN
    CREATE DATABASE SCOPED CREDENTIAL [<OPENAI_URL>]
    WITH IDENTITY = 'HTTPEndpointHeaders', 
         SECRET = '{"api-key":"<OPENAI_API_KEY>"}';
END
GO
```

### Option B: GitHub Models

```sql
IF NOT EXISTS (SELECT * FROM sys.database_scoped_credentials WHERE [name] = 'https://models.github.ai/inference')
BEGIN
    CREATE DATABASE SCOPED CREDENTIAL [https://models.github.ai/inference]
    WITH IDENTITY = 'HTTPEndpointHeaders', 
         SECRET = '{"Authorization":"Bearer <GITHUB_TOKEN>"}';
END
GO
```

Verify your credentials:

```sql
SELECT * FROM sys.database_scoped_credentials;
GO
```

### Create External Model for Embeddings

Create an external model that enables the `AI_GENERATE_EMBEDDINGS()` function. Choose the provider that matches your credentials:

#### Option A: Microsoft Foundry

```sql
IF NOT EXISTS (SELECT * FROM sys.external_models WHERE [name] = 'MyEmbeddingModel')
BEGIN
    CREATE EXTERNAL MODEL MyEmbeddingModel
    WITH (
          LOCATION = 'https://<FOUNDRY_RESOURCE_NAME>.cognitiveservices.azure.com/openai/deployments/text-embedding-3-small/embeddings?api-version=2023-05-15',
          API_FORMAT = 'Azure OpenAI',
          MODEL_TYPE = EMBEDDINGS,
          MODEL = 'text-embedding-3-small',
          CREDENTIAL = [<OPENAI_URL>],
          PARAMETERS = '{"dimensions":1536}'
    );
END
GO
```

#### Option B: GitHub Models

```sql
IF NOT EXISTS (SELECT * FROM sys.external_models WHERE [name] = 'MyEmbeddingModel')
BEGIN
    CREATE EXTERNAL MODEL MyEmbeddingModel
    WITH (
          LOCATION = 'https://models.github.ai/inference/embeddings',
          API_FORMAT = 'OpenAI',
          MODEL_TYPE = EMBEDDINGS,
          MODEL = 'text-embedding-3-small',
          CREDENTIAL = [https://models.github.ai/inference],
          PARAMETERS = '{"dimensions":1536}'
    );
END
GO
```

#### Test External Model

```sql
SELECT AI_GENERATE_EMBEDDINGS('Test text' USE MODEL MyEmbeddingModel);
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
DECLARE @min_similarity DECIMAL(19,16) = 0.3;

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
