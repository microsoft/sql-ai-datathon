create or alter procedure [dbo].[get_embedding]
@inputText nvarchar(max),
@embedding vector(1536) output,
@error nvarchar(max) = null output
as
declare @retval int;
declare @payload nvarchar(max) = json_object('input': @inputText);
declare @response nvarchar(max)
begin try
    exec @retval = sp_invoke_external_rest_endpoint
        @url = 'https://<FOUNDRY_RESOURCE_NAME>.cognitiveservices.azure.com/openai/deployments/text-embedding-ada-002/embeddings?api-version=2023-03-15-preview',
        @method = 'POST',
        @credential = [https://<FOUNDRY_RESOURCE_NAME>.cognitiveservices.azure.com/],
        @payload = @payload,
        @response = @response output
        with result sets none;
end try
begin catch
    set @error = json_object('error':'Embedding:REST', 'error_code':ERROR_NUMBER(), 'error_message':ERROR_MESSAGE())
    return -1
end catch

if @retval != 0 begin
    set @error = json_object('error':'Embedding:OpenAI', 'error_code':@retval, 'error_message':@response)
    return @retval
end

declare @re nvarchar(max) = json_query(@response, '$.result.data[0].embedding')
set @embedding = cast(@re as vector(1536));

return @retval
go


create or alter procedure [dbo].[get_similar_items]
@inputText nvarchar(max),
@result nvarchar(max) = null output,
@error nvarchar(max) = null output
as
declare @top int = 10
declare @min_similarity decimal(19,16) = 0.75
declare @qv vector(1536)
declare @embedding vector(1536)
exec dbo.get_embedding @inputText = @inputText, @embedding = @embedding output, @error = @error output
if @error is not null
    return -1

SELECT @result = (
    SELECT  
        w.id,
        w.product_name AS name,
        w.description
    FROM VECTOR_SEARCH(
             TABLE = dbo.walmart_ecommerce_product_details AS w,
             COLUMN = embedding,
             SIMILAR_TO = @embedding,
             METRIC = 'cosine',
             TOP_N = @top
         ) AS r
    WHERE r.distance <= 1 - @min_similarity
    ORDER BY r.distance
    FOR JSON PATH
);

SELECT @result AS result;
