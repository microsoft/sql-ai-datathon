# Mission 3: Orchestrate SQL + AI workflows

This mission advances your skills by teaching you how to orchestrate complex workflows that combine SQL database operations with AI capabilities. You'll learn to build intelligent, multi-step processes that seamlessly integrate data retrieval, transformation, and AI-powered decision making.

## Overview
Learn how to design and implement sophisticated AI workflows that coordinate multiple database queries, embedding operations, and language model calls to solve complex business problems requiring multiple steps and decision points.

## Learning Objectives
- **Build Multi-Step Workflows**: Create orchestrated processes that chain together SQL queries, vector searches, and AI model calls
- **Implement Conditional Logic**: Use AI responses to determine next steps in your workflow
- **Handle Data Transformations**: Process and prepare data between workflow stages

## Prerequisites
1. Mission 1 completed (embeddings and vector search with `AI_GENERATE_EMBEDDINGS()` and External Model `MyEmbeddingModel`)
2. Mission 2 completed (RAG implementation with stored procedures `get_embedding` and `get_similar_items`)
3. Embedding model access (Azure OpenAI `text-embedding-3-small`)
4. Chat model access (Azure OpenAI `gpt-5-mini`)

## Walkthrough

Choose your preferred language and open the corresponding notebook:

### Python
Open the <a href="https://github.com/microsoft/sql-ai-datathon/blob/main/missions/mission3/py/mission3.ipynb" target="_blank">Python notebook</a> (`missions/mission3/py/mission3.ipynb`) and follow the step-by-step instructions to:
1. Set up your environment and install dependencies
2. Connect to your SQL database using `mssql-python`
3. Build an AI agent using LangChain that orchestrates SQL queries
4. Use the `get_similar_items` stored procedure for vector search
5. Run the agent with sample queries

**Requirements:** See `requirements.txt` in the `py` folder.

**Key Components:**
- `AzureAIChatCompletionsModel` for chat completions (`gpt-5-mini`)
- Custom `find_products` tool that calls the stored procedure

### .NET (C#)
Open the <a href="https://github.com/microsoft/sql-ai-datathon/blob/main/missions/mission3/dotnet/mission3.ipynb" target="_blank">.NET notebook</a> (`missions/mission3/dotnet/mission3.ipynb`) and follow the step-by-step instructions to:
1. Set up your environment and install NuGet packages
2. Connect to your SQL database using `Microsoft.Data.SqlClient`
3. Build an AI agent using Semantic Kernel that orchestrates SQL queries
4. Register a `find_products` function as a kernel plugin
5. Run the agent with sample queries

**Key Components:**
- Semantic Kernel with Azure OpenAI Chat Completion (`gpt-5-mini`)
- `ChatCompletionAgent` for agent orchestration
- `KernelFunctionFactory` for registering SQL query functions

### Environment Configuration
Before running either notebook, copy `.env.sample` to `.env` and fill in your credentials:

```properties
# Database connection
SERVER_CONNECTION_STRING=Server=YOUR_SERVER;Database=YOUR_DATABASE;Trusted_Connection=yes;TrustServerCertificate=yes;

# Azure OpenAI
AZURE_OPENAI_ENDPOINT=https://your-resource.openai.azure.com/
MODEL_ENDPOINT_URL=https://your-resource.cognitiveservices.azure.com/
MODEL_API_KEY=your-api-key-here
```

## Next Steps
After completing this mission, you will have built a robust AI orchestration layer that can handle complex scenarios by integrating SQL data operations with AI capabilities.

Proceed to [Mission 4: Building a Full-Stack AI Application](../mission4/README.md) to learn how to create a complete application that leverages the workflows you've built in this mission.