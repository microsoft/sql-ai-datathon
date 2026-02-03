# Mission 2: Retrieval Augmented Generation (RAG)

This mission demonstrates how to build production-ready AI applications that combine the semantic understanding of embeddings with the generative capabilities of large language models. Retrieval augmented generation (RAG) is a fundamental pattern for creating trustworthy AI systems that answer questions based on your specific domain knowledge.

The techniques learned here enable you to build chatbots, knowledge assistants, and intelligent search systems that provide accurate, source-backed responses.

You will be guided through implementing retrieval augmented generation (RAG) capabilities using embedding models and SQL Database. In this mission, you will:

## Learning Objectives
- **Implement RAG Pipeline**: Build an end-to-end retrieval-augmented generation workflow in SQL
- **Query with Context**: Use vector similarity search to find relevant documents based on user questions
- **Generate Informed Responses**: Feed retrieved context to a language model to produce accurate, grounded answers


## Prerequisites
1. Mission 1 completed
1. Embedding model access (you can use the free AI Proxy to generate embeddings for free)
1. Completion model access (you can use the free AI Proxy to generate completions for free)

## Walkthrough

### Chatting with Data
- In `06-chat-with-data.sql`, replace the placeholders with your endpoints and actual Foundry resource name if using Microsoft Foundry.
- Run the script to see how the RAG pipeline retrieves relevant products from the database and generates a response based on the user's request.

### Structured Output from Chat
- In `07-chat-with-data-structured-output.sql`, replace the placeholders with your endpoints and actual Foundry resource name if using Microsoft Foundry.
- Run the script to see how to prompt the language model to return structured JSON output based on the retrieved data.

## Next Steps
After completing this mission, you will have implemented a robust RAG pipeline that can answer questions based on your SQL data.
Proceed to [Mission 3: Orchestrate SQL + AI workflows](/missions/mission3/README.md) to learn how to build complex, multi-step AI workflows that integrate RAG with other SQL and AI capabilities.