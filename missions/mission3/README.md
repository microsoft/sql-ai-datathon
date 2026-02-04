# Mission 3: Orchestrate SQL + AI workflows

This mission advances your skills by teaching you how to orchestrate complex workflows that combine SQL database operations with AI capabilities. You'll learn to build intelligent, multi-step processes that seamlessly integrate data retrieval, transformation, and AI-powered decision making.

## Overview
Learn how to design and implement sophisticated AI workflows that coordinate multiple database queries, embedding operations, and language model calls to solve complex business problems requiring multiple steps and decision points.

## Learning Objectives
- **Build Multi-Step Workflows**: Create orchestrated processes that chain together SQL queries, vector searches, and AI model calls
- **Implement Conditional Logic**: Use AI responses to determine next steps in your workflow
- **Handle Data Transformations**: Process and prepare data between workflow stages

## Prerequisites
1. Mission 1 completed (embeddings and vector search)
1. Mission 2 completed (RAG implementation)
1. Embedding and language model access

## Walkthrough

Choose your preferred language and open the corresponding notebook:

### Python
Open the <a href="https://github.com/microsoft/sql-ai-datathon/blob/main/missions/mission3/py/mission3.ipynb" target="_blank">Python notebook</a> (`missions/mission3/py/mission3.ipynb`) and follow the step-by-step instructions to:
1. Set up your environment and install dependencies
2. Connect to your SQL database
3. Build an AI agent that orchestrates SQL queries and embeddings
4. Run the agent with sample queries

**Requirements:** See `requirements.txt` in the `py` folder.

### .NET (C#)
Open the <a href="https://github.com/microsoft/sql-ai-datathon/blob/main/missions/mission3/dotnet/mission3.ipynb" target="_blank">.NET notebook</a> (`missions/mission3/dotnet/mission3.ipynb`) and follow the step-by-step instructions to:
1. Set up your environment and install NuGet packages
2. Connect to your SQL database
3. Build an AI agent that orchestrates SQL queries and embeddings
4. Run the agent with sample queries

### Environment Configuration
Before running either notebook, copy `.env.sample` to `.env` and fill in your credentials:
- Database connection string
- Azure OpenAI endpoint and API key

## Next Steps
After completing this mission, you will have built a robust AI orchestration layer that can handle complex scenarios by integrating SQL data operations with AI capabilities.

Proceed to [Mission 4: Building a Full-Stack AI Application](../mission4/README.md) to learn how to create a complete application that leverages the workflows you've built in this mission.