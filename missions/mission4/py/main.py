from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse
from pydantic import BaseModel
import dotenv
import mssql_python
from langchain_azure_ai.chat_models import AzureAIChatCompletionsModel
from langchain.messages import HumanMessage, SystemMessage
import json
import os
import httpx

# DAB API URL
DAB_URL = "http://localhost:5000"

# Load environment variables
dotenv.load_dotenv("../.env")

connection_string = dotenv.get_key("../.env", "SERVER_CONNECTION_STRING")
endpoint = dotenv.get_key("../.env", "MODEL_ENDPOINT_URL") or dotenv.get_key("../.env", "AZURE_OPENAI_ENDPOINT")
api_key = dotenv.get_key("../.env", "MODEL_API_KEY")

# Initialize FastAPI app
app = FastAPI(
    title="SQL AI API",
    description="AI-powered product search and chat API",
    version="1.0.0"
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000", "http://localhost:5173", "http://localhost:8000"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize AI model
# NOTE: This uses the gpt-5-mini model. To use a different model, update the model name below
# and in any other files that reference it (e.g., mission3 notebooks, mission2 SQL scripts).
chat_model = AzureAIChatCompletionsModel(
    endpoint=endpoint,
    credential=api_key,
    model="gpt-5-mini",
)


# =============================================================================
# Request/Response Models
# =============================================================================

class ChatRequest(BaseModel):
    message: str


class ChatResponse(BaseModel):
    user_message: str
    assistant_response: str
    products_found: bool


class ProductSearchResponse(BaseModel):
    query: str
    results: list


# =============================================================================
# Helper Functions
# =============================================================================

def get_connection():
    """Create a new database connection."""
    return mssql_python.connect(connection_string)


def find_products(search_term: str) -> str:
    """Search the product catalog using vector similarity."""
    connection = get_connection()
    cursor = connection.cursor()
    
    sql = """SET NOCOUNT ON;
    DECLARE @result nvarchar(max);
    DECLARE @error nvarchar(max);
    EXEC [dbo].[get_similar_items] @inputText = ?, @result = @result OUTPUT, @error = @error OUTPUT;
    SELECT @result AS result, @error AS error;"""
    
    cursor.execute(sql, (search_term,))
    results = []
    
    while True:
        rows = cursor.fetchall()
        if cursor.description:
            columns = [desc[0] for desc in cursor.description]
            for row in rows:
                row_dict = dict(zip(columns, row))
                if row_dict.get('result'):
                    return row_dict['result']
        if not cursor.nextset():
            break
    
    cursor.close()
    connection.close()
    return str(results) if results else "[]"


# =============================================================================
# API Endpoints
# =============================================================================

@app.get("/")
def health_check():
    """Health check endpoint."""
    return {"status": "healthy", "service": "SQL AI API"}


@app.get("/app")
def serve_frontend():
    """Serve the frontend application."""
    frontend_path = os.path.join(os.path.dirname(__file__), "..", "frontend", "index.html")
    if os.path.exists(frontend_path):
        return FileResponse(frontend_path)
    raise HTTPException(status_code=404, detail="Frontend not found")


@app.get("/api/products")
async def get_products(page: int = 1, page_size: int = 10):
    """Get paginated list of products from DAB."""
    try:
        # Use DAB API with cursor-based pagination
        dab_url = f"{DAB_URL}/api/Products?$first={page_size}"
        
        async with httpx.AsyncClient() as client:
            response = await client.get(dab_url)
            response.raise_for_status()
            data = response.json()
        
        # DAB returns products in 'value' array
        products = data.get("value", [])
        
        return {"page": page, "pageSize": page_size, "products": products}
    except httpx.RequestError as e:
        raise HTTPException(
            status_code=503, 
            detail=f"Error connecting to DAB: {str(e)}. Make sure DAB is running on port 5000."
        )


@app.get("/api/products/search")
def search_products(query: str):
    """Search products using vector similarity."""
    connection = get_connection()
    cursor = connection.cursor()
    
    sql = """SET NOCOUNT ON;
    DECLARE @result nvarchar(max);
    DECLARE @error nvarchar(max);
    EXEC [dbo].[get_similar_items] @inputText = ?, @result = @result OUTPUT, @error = @error OUTPUT;
    SELECT @result AS result, @error AS error;"""
    
    cursor.execute(sql, (query,))
    result_json = None
    error = None
    
    while True:
        rows = cursor.fetchall()
        if cursor.description:
            columns = [desc[0] for desc in cursor.description]
            for row in rows:
                row_dict = dict(zip(columns, row))
                result_json = row_dict.get('result')
                error = row_dict.get('error')
        if not cursor.nextset():
            break
    
    cursor.close()
    connection.close()
    
    if error:
        raise HTTPException(status_code=500, detail=f"Search error: {error}")
    
    if result_json:
        try:
            products = json.loads(result_json)
            return {"query": query, "results": products}
        except json.JSONDecodeError:
            return {"query": query, "results": []}
    
    return {"query": query, "results": []}


@app.post("/api/chat")
def chat(request: ChatRequest) -> ChatResponse:
    """AI-powered product assistant chat."""
    # Search for relevant products
    product_results = find_products(request.message)
    
    system_prompt = f"""You are a helpful product assistant. Use the following product catalog data to answer user questions.
Be concise and helpful. Only recommend products from the provided data.

Available Products:
{product_results}

If no relevant products are found, politely inform the user."""
    
    messages = [
        SystemMessage(content=system_prompt),
        HumanMessage(content=request.message)
    ]
    
    response = chat_model.invoke(messages)
    
    return ChatResponse(
        user_message=request.message,
        assistant_response=response.content,
        products_found=bool(product_results and product_results != "[]")
    )


@app.post("/api/chat/structured")
def chat_structured(request: ChatRequest):
    """AI chat with structured JSON output."""
    product_results = find_products(request.message)
    
    system_prompt = f"""You are a product recommendation assistant. Analyze the user's request and the available products.
Return a JSON response with the following structure:
{{
    "recommendations": [
        {{
            "productName": "string",
            "reason": "string",
            "confidence": "high|medium|low"
        }}
    ],
    "summary": "Brief summary of recommendations"
}}

Available Products:
{product_results}"""
    
    messages = [
        SystemMessage(content=system_prompt),
        HumanMessage(content=request.message)
    ]
    
    response = chat_model.invoke(messages)
    
    # Try to parse as JSON
    try:
        return json.loads(response.content)
    except json.JSONDecodeError:
        return {"raw_response": response.content}


# =============================================================================
# Run the app
# =============================================================================

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)