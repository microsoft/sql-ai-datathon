
# SQL + AI Datathon – Open Hack Challenge
Welcome to the SQL + AI Datathon Open Hack! This challenge is your opportunity to apply what you learned across the four missions and build a focused, end‑to‑end SQL + AI solution.

## Objective
You will choose one project type, implement a core SQL + AI pattern using Retrieval‑Augmented Generation (RAG), and submit a well‑documented solution.

Your solution must:

- Use SQL (SQL Server 2025 or Azure SQL) as the data source
- Implement RAG (Retrieval Augmented Generation)
- Focus on one clear feature, implemented well
- Be easy to understand, reproduce, and review

## Choose One Project Type
You must choose one of the following options:

### Option 1: RAG‑Based Chatbot Agent
Build a simple chatbot that answers user questions by retrieving relevant data from a Microsoft SQL database before generating a response.
What this should demonstrate:

- Natural language questions from a user
- Retrieval of relevant data from SQL (via search, embeddings, or semantic queries)
- AI‑generated responses that are grounded in SQL data, not hallucinated

>Example:
Ask the bot about a product, and it fetches details from the SQL database before generating a response.



### Option 2: Semantic Search Tool
Build a search experience that allows users to enter natural language queries and receive relevant results from a Microsoft SQL database.
What this should demonstrate:

Use of embeddings or semantic search stored in SQL
Retrieval of the most relevant records
AI‑generated summaries or explanations based on retrieved SQL data
>Example:
Search for a topic, and the tool finds matching records in SQL and provides an AI‑generated summary.


## Core Requirements (Both Options)
Your project must:

- Use Microsoft SQL Server as the primary data source
- Implement RAG (Retrieval Augmented Generation): Retrieve data from SQL
- Use AI to generate or enhance the response
- Focus on one main feature only (chatbot or search)
- Include clear documentation explaining your approach

## Scope Guardrails (Important)

### To keep the Open Hack achievable and fair:
✅ Do:

- Pick one project type
- Keep the experience simple and focused
- Optimize for clarity and correctness

🚫 Don’t:

- Build both a chatbot and a search tool
- Attempt a full production system
- Use another database besides Microsoft SQL Server or Azure SQL


## Submission Requirements

Submit your project by **creating a GitHub Issue** in this repository.

### How to Submit

1. Go to the **Issues** tab in this repository
2. Click **New Issue**
3. Use the title format: `[Submission] Your Project Name`
4. Include the following in your issue:

```markdown
**Team/Participant Name:** 
**Project Type:** (Chatbot / Semantic Search)

**GitHub Repository:** [link to your repo]

**Video Demo:** [link to video]

**Brief Description:**
(2-3 sentences about what your solution does)

**Tech Stack:**
- Database: (SQL Server 2025 / Azure SQL)
- Language: (Python / C# / etc.)
- AI Service: (Azure OpenAI / etc.)

**Challenges or Tradeoffs:**
(Optional - any interesting learnings)
```

### Repository Requirements

Your linked GitHub repository should contain:

- Your completed solution
- Clear setup and run instructions
- A description of your architecture and approach
- Notes on any challenges or tradeoffs you encountered

### Video Demo Requirements

Provide a short demo video that shows:

- The application running
- The core user flow (chatting or searching)
- Evidence that SQL data is being retrieved and used by the AI

Guidelines:
- No voice narration required
- Screen recording is sufficient
- 2–5 minutes is recommended

If you feel stuck, simplify. A clear, working RAG flow is better than a complex, incomplete solution.


## What We’re Looking For

Judging will focus on four key areas:

| Criteria | What Judges Look For |
|----------|---------------------|
| **Problem Understanding** | Clear project type (Chatbot or Search), SQL as data source, proper RAG implementation |
| **Innovation & Creativity** | Original approach, creative use of embeddings/semantic search, unique UX or data usage |
| **Technical Execution** | Sound implementation, reproducible setup, focused scope, clear documentation |
| **Insight & Impact** | Meaningful outcomes, depth of analysis, real-world applicability |

> **Tip:** A simple, well-executed RAG flow beats a complex, incomplete solution.

## Ready to Get Started?
Good luck, and happy building!
