-- =============================================================================
-- Mission 1: Create Product Database and Table
-- =============================================================================
-- Description: Creates the ProductDB database and the walmart_ecommerce_product_details
--              table with vector embedding support for semantic search capabilities.
-- 
-- Prerequisites:
--   - SQL Server 2025 or Azure SQL Database with vector support enabled
--   - Appropriate permissions to create databases and tables
--
-- Usage:
--   Run this script first before loading data with 02-load-table.sql
--
-- Table Columns:
--   - id: Primary key identifier
--   - source_unique_id: Original source identifier (32-char hash)
--   - crawl_timestamp: When the product data was collected
--   - product_url: Link to the product page
--   - product_name: Name of the product
--   - description: Detailed product description
--   - list_price: Original list price
--   - sale_price: Current sale price
--   - brand: Product brand name
--   - item_number: Internal item number
--   - gtin: Global Trade Item Number
--   - package_size: Size/variant information
--   - category: Product category path
--   - postal_code: Location information
--   - available: Availability status
--   - embedding: 1536-dimensional vector for semantic search
-- =============================================================================


-- -----------------------------------------------------------------------------
-- SECTION 1: Create Database
-- -----------------------------------------------------------------------------
CREATE DATABASE ProductDB;
GO

USE ProductDB;
GO


-- -----------------------------------------------------------------------------
-- SECTION 2: Create Product Table
-- -----------------------------------------------------------------------------
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


-- -----------------------------------------------------------------------------
-- SECTION 3: Enable Preview Features (Required for Vector Support)
-- -----------------------------------------------------------------------------
ALTER DATABASE SCOPED CONFIGURATION
SET PREVIEW_FEATURES = ON;
GO

--- -----------------------------------------------------------------------------
-- SECTION 4: Enable External REST Endpoint (Required for sp_invoke_external_rest_endpoint)
-- -----------------------------------------------------------------------------
EXECUTE sp_configure 'external rest endpoint enabled', 1;
RECONFIGURE WITH OVERRIDE;