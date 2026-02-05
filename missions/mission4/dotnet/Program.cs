using Microsoft.Data.SqlClient;
using Microsoft.SemanticKernel;
using Microsoft.SemanticKernel.ChatCompletion;
using System.Text.Json;

// Load configuration from .env first (needed for connection string)
DotNetEnv.Env.Load("../.env");

// Load DAB config for entity mappings
var dabConfig = JsonSerializer.Deserialize<JsonElement>(File.ReadAllText("../dab-config.json"));

// Get connection string from environment variable (DAB config uses @env('SERVER_CONNECTION_STRING'))
var connectionString = Environment.GetEnvironmentVariable("SERVER_CONNECTION_STRING")
    ?? throw new InvalidOperationException("SERVER_CONNECTION_STRING not set in .env file");

// Load AI settings from .env
var aoaiEndpoint = Environment.GetEnvironmentVariable("AZURE_OPENAI_ENDPOINT") 
    ?? Environment.GetEnvironmentVariable("MODEL_ENDPOINT_URL")
    ?? throw new InvalidOperationException("AZURE_OPENAI_ENDPOINT not set");
var apiKey = Environment.GetEnvironmentVariable("MODEL_API_KEY") 
    ?? throw new InvalidOperationException("MODEL_API_KEY not set");

// Extract entity configuration from DAB
var entities = dabConfig.GetProperty("entities");
var productsEntity = entities.GetProperty("Products");
var productsTable = productsEntity.GetProperty("source").GetProperty("object").GetString();

var builder = WebApplication.CreateBuilder(args);

// Configure to use port 5001 (DAB uses 5000)
builder.WebHost.UseUrls("http://localhost:5001");

// Add services
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();
builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(policy =>
    {
        policy.WithOrigins("http://localhost:3000", "http://localhost:5173")
              .AllowAnyHeader()
              .AllowAnyMethod();
    });
});

// Configure Semantic Kernel
// NOTE: This uses the gpt-5-mini model. To use a different model, update the model name below
// and in any other files that reference it (e.g., mission3 notebooks, mission2 SQL scripts).
var kernelBuilder = Kernel.CreateBuilder();
kernelBuilder.AddAzureOpenAIChatCompletion("gpt-5-mini", aoaiEndpoint, apiKey);
var kernel = kernelBuilder.Build();
builder.Services.AddSingleton(kernel);

// Add HttpClient for DAB API calls
builder.Services.AddHttpClient("DAB", client =>
{
    client.BaseAddress = new Uri("http://localhost:5000");
});

var app = builder.Build();

// Configure middleware
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}
app.UseCors();

// Serve static files from frontend folder
var frontendPath = Path.Combine(Directory.GetCurrentDirectory(), "..", "frontend");
if (Directory.Exists(frontendPath))
{
    app.UseStaticFiles(new StaticFileOptions
    {
        FileProvider = new Microsoft.Extensions.FileProviders.PhysicalFileProvider(frontendPath),
        RequestPath = ""
    });
    
    // Serve index.html as default
    app.MapGet("/app", async context =>
    {
        var indexPath = Path.Combine(frontendPath, "index.html");
        context.Response.ContentType = "text/html";
        await context.Response.SendFileAsync(indexPath);
    });
}

// =============================================================================
// API Endpoints
// =============================================================================

// Health check
app.MapGet("/", () => Results.Ok(new { status = "healthy", service = "SQL AI API" }))
   .WithName("HealthCheck")
   .WithOpenApi();

// Get all products (paginated) - uses DAB API
app.MapGet("/api/products", async (IHttpClientFactory httpClientFactory, int page = 1, int pageSize = 10) =>
{
    var client = httpClientFactory.CreateClient("DAB");
    
    // Calculate offset for DAB's $first and $after pagination
    var offset = (page - 1) * pageSize;
    
    // DAB REST API with OData-style query parameters
    var dabUrl = $"/api/Products?$first={pageSize}&$after={offset}";
    
    try
    {
        var response = await client.GetAsync(dabUrl);
        response.EnsureSuccessStatusCode();
        
        var json = await response.Content.ReadAsStringAsync();
        var dabResponse = JsonSerializer.Deserialize<JsonElement>(json);
        
        // Extract products from DAB response
        var products = new List<object>();
        if (dabResponse.TryGetProperty("value", out var valueArray))
        {
            foreach (var item in valueArray.EnumerateArray())
            {
                products.Add(item);
            }
        }
        
        return Results.Ok(new { page, pageSize, products });
    }
    catch (HttpRequestException ex)
    {
        return Results.Problem($"Error connecting to DAB: {ex.Message}. Make sure DAB is running on port 5000.");
    }
})
.WithName("GetProducts")
.WithOpenApi();

// Search products using vector similarity
app.MapGet("/api/products/search", (string query) =>
{
    using var connection = new SqlConnection(connectionString);
    connection.Open();
    
    using var command = new SqlCommand();
    command.Connection = connection;
    command.CommandText = @"
        SET NOCOUNT ON;
        DECLARE @result nvarchar(max);
        DECLARE @error nvarchar(max);
        EXEC [dbo].[get_similar_items] @inputText = @searchTerm, @result = @result OUTPUT, @error = @error OUTPUT;
        SELECT @result AS result, @error AS error;";
    command.Parameters.AddWithValue("@searchTerm", query);
    
    using var reader = command.ExecuteReader();
    if (reader.Read())
    {
        var resultJson = reader["result"]?.ToString();
        var error = reader["error"]?.ToString();
        
        if (!string.IsNullOrEmpty(error))
        {
            return Results.Problem($"Search error: {error}");
        }
        
        if (!string.IsNullOrEmpty(resultJson))
        {
            var products = JsonSerializer.Deserialize<List<Dictionary<string, object>>>(resultJson);
            return Results.Ok(new { query, results = products });
        }
    }
    
    return Results.Ok(new { query, results = new List<object>() });
})
.WithName("SearchProducts")
.WithOpenApi();

// AI-powered product assistant chat
app.MapPost("/api/chat", async (ChatRequest request, Kernel kernel) =>
{
    // First, search for relevant products
    var productResults = SearchProducts(request.Message, connectionString);
    
    // Create context with product data
    var systemPrompt = $"""
        You are a helpful product assistant. Use the following product catalog data to answer user questions.
        Be concise and helpful. Only recommend products from the provided data.
        
        Available Products:
        {productResults}
        
        If no relevant products are found, politely inform the user.
        """;
    
    var chatService = kernel.GetRequiredService<IChatCompletionService>();
    var chatHistory = new ChatHistory(systemPrompt);
    chatHistory.AddUserMessage(request.Message);
    
    var response = await chatService.GetChatMessageContentAsync(chatHistory);
    
    return Results.Ok(new 
    { 
        userMessage = request.Message, 
        assistantResponse = response.Content,
        productsFound = !string.IsNullOrWhiteSpace(productResults)
    });
})
.WithName("Chat")
.WithOpenApi();

// Chat with structured JSON output
app.MapPost("/api/chat/structured", async (ChatRequest request, Kernel kernel) =>
{
    var productResults = SearchProducts(request.Message, connectionString);
    
    var systemPrompt = $$"""
        You are a product recommendation assistant. Analyze the user's request and the available products.
        Return a JSON response with the following structure:
        {
            "recommendations": [
                {
                    "productName": "string",
                    "reason": "string",
                    "confidence": "high|medium|low"
                }
            ],
            "summary": "Brief summary of recommendations"
        }
        
        Available Products:
        {{productResults}}
        """;
    
    var chatService = kernel.GetRequiredService<IChatCompletionService>();
    var chatHistory = new ChatHistory(systemPrompt);
    chatHistory.AddUserMessage(request.Message);
    
    var response = await chatService.GetChatMessageContentAsync(chatHistory);
    
    // Try to parse as JSON, return raw if parsing fails
    try
    {
        var jsonResponse = JsonSerializer.Deserialize<object>(response.Content ?? "{}");
        return Results.Ok(jsonResponse);
    }
    catch
    {
        return Results.Ok(new { rawResponse = response.Content });
    }
})
.WithName("ChatStructured")
.WithOpenApi();

app.Run();

// =============================================================================
// Helper Functions
// =============================================================================

static string SearchProducts(string searchTerm, string connString)
{
    using var connection = new SqlConnection(connString);
    connection.Open();
    
    using var command = new SqlCommand();
    command.Connection = connection;
    command.CommandText = @"
        SET NOCOUNT ON;
        DECLARE @result nvarchar(max);
        DECLARE @error nvarchar(max);
        EXEC [dbo].[get_similar_items] @inputText = @searchTerm, @result = @result OUTPUT, @error = @error OUTPUT;
        SELECT @result AS result, @error AS error;";
    command.Parameters.AddWithValue("@searchTerm", searchTerm);
    
    using var reader = command.ExecuteReader();
    if (reader.Read())
    {
        var resultJson = reader["result"]?.ToString();
        if (!string.IsNullOrEmpty(resultJson))
        {
            return resultJson;
        }
    }
    
    return string.Empty;
}

// =============================================================================
// Request/Response Models
// =============================================================================

public record ChatRequest(string Message);
