-- =============================================================================
-- Mission 1: Load Product Data with Embeddings
-- =============================================================================
-- Description: Loads the Walmart product dataset with pre-computed embeddings
--              from Azure Blob Storage or local file system into the database.
--
-- Prerequisites:
--   - 01-create-table.sql must be executed first
--   - For Azure Blob Storage: Valid SAS token and storage account
--   - For local file: CSV file accessible from SQL Server
--
-- Configuration:
--   Replace the following placeholders before running:
--   - <SAS_TOKEN>: Your Azure Blob Storage SAS token (without leading '?')
--   - <STORAGE_ACCOUNT>: Your Azure Storage account name
--   - File path if loading from local file system
--
-- Data Source:
--   walmart-product-with-embeddings-dataset-usa.csv
--   Contains ~10,000 products with pre-computed 1536-dimensional embeddings
--
-- Index Created:
--   - vec_idx: DISKANN vector index on embedding column for fast similarity search
-- =============================================================================
USE ProductDB;
GO

-- -----------------------------------------------------------------------------
-- SECTION 1: Prerequisites & Cleanup
-- -----------------------------------------------------------------------------
/*
    Create database scoped credential and external data source.
    File is assumed to be in a path like: 
    https://<myaccount>.blob.core.windows.net/playground/walmart/walmart-product-with-embeddings-dataset-usa.csv

    Best Practice: Use Managed Identity instead of SAS tokens when possible.
    See: https://learn.microsoft.com/en-us/sql/relational-databases/import-export/import-bulk-data-by-using-bulk-insert-or-openrowset-bulk-sql-server
*/

-- Create master key if it doesn't exist
IF NOT EXISTS (SELECT * FROM sys.symmetric_keys WHERE [name] = '##MS_DatabaseMasterKey##')
BEGIN
    CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'Pa$$w0rd!';
END
GO

-- Remove existing external data source if present
IF EXISTS (SELECT * FROM sys.[external_data_sources] WHERE name = 'openai_playground')
BEGIN
    DROP EXTERNAL DATA SOURCE [openai_playground];
END
GO

-- Remove existing credential if present
IF EXISTS (SELECT * FROM sys.[database_scoped_credentials] WHERE name = 'openai_playground')
BEGIN
    DROP DATABASE SCOPED CREDENTIAL [openai_playground];
END
GO


-- -----------------------------------------------------------------------------
-- SECTION 2: Create External Data Source (Azure Blob Storage)
-- -----------------------------------------------------------------------------
/*
    If loading from local file system, skip this section.
    Replace <SAS_TOKEN> and <STORAGE_ACCOUNT> with your values.
*/

CREATE DATABASE SCOPED CREDENTIAL [openai_playground]
WITH IDENTITY = 'SHARED ACCESS SIGNATURE',
     SECRET = '<SAS_TOKEN>'; -- Do not include the leading '?'
GO

CREATE EXTERNAL DATA SOURCE [openai_playground]
WITH 
( 
    TYPE = BLOB_STORAGE,
    LOCATION = 'https://<STORAGE_ACCOUNT>.blob.core.windows.net/sample-data',
    CREDENTIAL = [openai_playground]
);
GO
/*
    Import data
*/
bulk insert dbo.[walmart_ecommerce_product_details]
from 'walmart/walmart-product-with-embeddings-dataset-usa.csv'
with (
	data_source = 'openai_playground',
    format = 'csv',
    firstrow = 2,
    codepage = '65001',
	fieldterminator = ',',
	rowterminator = '0x0a',
    fieldquote = '"',
    batchsize = 1000,
    tablock
)
go


-- -----------------------------------------------------------------------------
-- SECTION 3: Validate File Access
-- -----------------------------------------------------------------------------
SELECT * FROM OPENROWSET(
    BULK 'walmart-product-with-embeddings-dataset-usa-copy.csv',
    DATA_SOURCE = 'openai_playground',
    SINGLE_CLOB
) AS test;


-- -----------------------------------------------------------------------------
-- SECTION 4: Import Product Data (Skip if already done in Section 2)
-- -----------------------------------------------------------------------------
/*
    For local file system: Replace path and remove DATA_SOURCE parameter
    Example: 'C:\data\walmart-product-with-embeddings-dataset-usa.csv'
*/

BULK INSERT dbo.[walmart_ecommerce_product_details]
FROM 'walmart-product-with-embeddings-dataset-usa-copy.csv'
-- Uncomment and use the line below if loading from containerized environment
-- FROM '/data/walmart-product-with-embeddings-dataset-usa-copy.csv'
WITH (
    DATA_SOURCE = 'openai_playground',
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    FIELDQUOTE = '"',
    BATCHSIZE = 1000,
    TABLOCK
);
GO




-- -----------------------------------------------------------------------------
-- SECTION 5: Create Vector Index for Similarity Search
-- -----------------------------------------------------------------------------
CREATE VECTOR INDEX vec_idx
ON dbo.walmart_ecommerce_product_details(embedding)
WITH (METRIC = 'COSINE', TYPE = 'DISKANN');
GO

