# Mission 1: Creating Embeddings and Performing Search

You will be guided through implementing semantic search capabilities using embedding models and Azure SQL Database. In this mission, you will:

## Learning Objectives
- **Convert Text to Vectors**: Use an embedding model to convert text into high-dimensional vector representations
- **Store Embeddings**: Store embeddings efficiently in Azure SQL Database
- **Query with Vector Similarity**: Query the database using vector similarity to find semantically related content
- **Maintain Embeddings**: Keep embeddings updated as data changes

## Prerequisites
1. Embedding model access (you can use the free AI Proxy to generate embeddings for free)

## Walkthrough

### Create a SQL Database

You have two options to create an SQL Database:
- Azure SQL Database instance
- Local SQL Server instance with SQL Server 2025 or later, use the free developer edition

## Setting Up the Database

- Run query in `01-create-table.sql` to create the database and table structure.
- Download the sample data, and unzip it to access the `walmart_ecommerce_product_details.csv` file.
- Use the provided `02-load-table.sql` script to load data from Azure Blob Storage or local storage.

> You can also use SQL Server Management Studio 21 (SSMS 21), which has a built-in import wizard to load CSV data directly into your table. 


## Select up the Embedding and Chat Models
In these next steps, you will be converting prompts and queries into vector representations to perform semantic search and generating responses based on retrieved information. You will need access to the [text-embedding-ada-002](https://ai.azure.us/explore/models/text-embedding-ada-002/version/2/registry/azure-openai) embedding model and a chat model provider.

There are several embedding model providers available, below are popular options:
- You may use the provided free AI Proxy.
- Deploy models with Microsoft Foundry.
- Use local models with Ollama or similar tools.

The recommended completion models for this mission are as follows:
| Purpose | Model | Provider |
|---------|-------|----------|
| **Required Embedding Model** | [text-embedding-ada-002](https://ai.azure.us/explore/models/text-embedding-ada-002/version/2/registry/azure-openai) | Microsoft Foundry / AI Proxy |
| Text Generation | [GPT-4.1](https://ai.azure.us/explore/models/gpt-4.1/version/2025-04-14/registry/azure-openai) | Microsoft Foundry / AI Proxy |
| Text Generation | [GPT-4o](https://ai.azure.us/explore/models/gpt-4o/version/2024-11-20/registry/azure-openai) | Microsoft Foundry |
| Text Generation | [Phi-4](https://ai.azure.us/explore/models/Phi-4/version/8/registry/azureml) | Microsoft Foundry / [Ollama](https://ollama.com/library/phi4) |


## Store Database Scope Credentials
You'll add your model provider credentials to the database scope for secure access.

- Run the `03-add-database-scope-credentials.sql` script, replacing placeholders with your actual credentials.

## Your First Semantic Search
- Replace the placeholders in the `04-get-search-vector.sql` script with your actual search terms and run the script to turn the search query into a vector.
- Next, run the `05-get-similar-items.sql` script to perform your first semantic search query using vector similarity.
- Modify the query to test different search terms and observe the results.

## Test your Semantic Search
Verify that your semantic search is working correctly by your results from the search term "reading glasses for books". You should see items related to reading glasses, such as eyewear, magnifying glasses, and other vision-related products.


## Next Steps
After completing this mission, you will have implemented a semantic search solution that can find relevant information based on meaning rather than just keywords.
Proceed to [Mission 2: Retrieval Augmented Generation (RAG)](/missions/mission2/README.md) to learn how to build an end-to-end RAG pipeline that combines embeddings with language model generation.