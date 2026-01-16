# Mission 2: Retrieval Augmented Generation (RAG)

You will be guided through implementing retrieval augmented generation (RAG) capabilities using embedding models and Azure SQL Database. In this mission, you will:

## Learning Objectives
- **Implement RAG Pipeline**: Build an end-to-end retrieval-augmented generation workflow
- **Query with Context**: Use vector similarity search to find relevant documents based on user questions
- **Generate Informed Responses**: Feed retrieved context to a language model to produce accurate, grounded answers
- **Prevent Hallucinations**: Learn techniques to ensure LLM responses are based on actual data rather than fabricated information
- **Optimize Context Windows**: Understand how to select and rank the most relevant information for the language model


## Prerequisites
1. Mission 1 completed
1. Embedding model access (you can use the free AI Proxy to generate embeddings for free)
1. Language model access (you can use the free AI Proxy to generate completions for free)

# Key Concepts
This mission demonstrates how to build production-ready AI applications that combine the semantic understanding of embeddings with the generative capabilities of large language models. RAG is a fundamental pattern for creating trustworthy AI systems that answer questions based on your specific domain knowledge.

The techniques learned here enable you to build chatbots, knowledge assistants, and intelligent search systems that provide accurate, source-backed responses.

## Next Steps
After completing this mission, you will have implemented a robust RAG pipeline that can answer questions based on your SQL data.
Proceed to [Mission 3: Orchestrate SQL + AI workflows](../mission3/README.md) to learn how to build complex, multi-step AI workflows that integrate RAG with other SQL and AI capabilities.