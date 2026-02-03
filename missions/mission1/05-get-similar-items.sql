declare @top int = 50
declare @min_similarity decimal(19,16) = 0.75
drop table if exists similar_items;
declare @qv vector(1536) = (
	select top(1)
		cast(json_query(response, '$.result.data[0].embedding') as vector(1536)) as query_vector
	from 
		dbo.http_response
)

SELECT TOP (10) w.id,
                w.product_name,
                w.description,
                w.category,
                r.distance,
                similarity = 1 - r.distance
INTO similar_items
FROM VECTOR_SEARCH(
         TABLE = dbo.walmart_ecommerce_product_details AS w,
         COLUMN = embedding,
         SIMILAR_TO = @qv,
         METRIC = 'cosine',
         TOP_N = 10
     ) AS r
WHERE r.distance <= 1 - @min_similarity
ORDER BY r.distance;

select * from similar_items;