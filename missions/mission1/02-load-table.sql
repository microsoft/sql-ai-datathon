/*
	Cleanup if needed
*/
if not exists(select * from sys.symmetric_keys where [name] = '##MS_DatabaseMasterKey##')
begin
	create master key encryption by password = 'Pa$$w0rd!'
end
go
if exists(select * from sys.[external_data_sources] where name = 'openai_playground')
begin
	drop external data source [openai_playground];
end
go
if exists(select * from sys.[database_scoped_credentials] where name = 'openai_playground')
begin
	drop database scoped credential [openai_playground];
end
go

/*
	Create database scoped credential and external data source.
	File is assumed to be in a path like: 
	https://<myaccount>.blob.core.windows.net/playground/walmart/walmart-product-with-embeddings-dataset-usa.csv

	Please note that it is recommened to avoid using SAS tokens: the best practice is to use Managed Identity as described here:
	https://learn.microsoft.com/en-us/sql/relational-databases/import-export/import-bulk-data-by-using-bulk-insert-or-openrowset-bulk-sql-server?view=sql-server-ver16#bulk-importing-from-azure-blob-storage
*/


/* If source is from Azure Blob Storage, replace <SAS_TOKEN> and <STORAGE_ACCOUNT> before running this script. 
	If loading from local file system, you can skip this section. Comment out or remove the lines between the markers.
*/	


create database scoped credential [openai_playground]
with identity = 'SHARED ACCESS SIGNATURE',
secret = '<SAS_TOKEN>'; -- make sure not to include the ? at the beginning
go


create external data source [openai_playground]
with 
( 
	type = blob_storage,
 	location = 'https://<STORAGE_ACCOUNT>.blob.core.windows.net/sample-data', -- replace <STORAGE_ACCOUNT> with your storage account name
 	credential = [openai_playground]
);
go
/* End of external data source creation */


/*
	Test access to the file
*/


SELECT * FROM OPENROWSET(
    BULK 'walmart-product-with-embeddings-dataset-usa.csv', -- if loading from local file system, replace with your file path ie: C:\data\walmart-product-with-embeddings-dataset-usa.csv
    DATA_SOURCE = 'openai_playground',
    SINGLE_CLOB
) AS test;

/*
    Import data
*/
bulk insert dbo.[walmart_ecommerce_product_details]
from 'walmart-product-with-embeddings-dataset-usa.csv' -- if loading from local file system, replace with your file path ie: C:\data\walmart-product-with-embeddings-dataset-usa.csv
with (
	data_source = 'openai_playground', -- if loading from local file system, remove or comment this line
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

/*
	Add indexes
*/

CREATE VECTOR INDEX vec_idx
ON dbo.walmart_ecommerce_product_details(embedding)
WITH (METRIC = 'COSINE', TYPE = 'DISKANN');
GO