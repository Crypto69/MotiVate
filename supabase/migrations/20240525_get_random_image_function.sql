-- Function to get a random image, optionally filtered by category IDs
-- Returns: id, image_url, likes_count, dislikes_count
-- If no category_ids provided or empty array, returns random image from all categories

CREATE OR REPLACE FUNCTION get_random_image(category_ids bigint[] DEFAULT NULL)
RETURNS TABLE (
    id bigint,
    image_url text,
    likes_count integer,
    dislikes_count integer
) 
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- If category_ids is NULL or empty array, return random image from all categories
    IF category_ids IS NULL OR array_length(category_ids, 1) IS NULL THEN
        RETURN QUERY
        SELECT 
            i.id,
            i.image_url,
            i.likes_count,
            i.dislikes_count
        FROM public.images i
        ORDER BY random()
        LIMIT 1;
    ELSE
        -- Return random image from specified categories
        RETURN QUERY
        SELECT 
            i.id,
            i.image_url,
            i.likes_count,
            i.dislikes_count
        FROM public.images i
        JOIN public.image_categories ic ON ic.image_id = i.id
        WHERE ic.category_id = ANY(category_ids)
        ORDER BY random()
        LIMIT 1;
    END IF;
END;
$$;

-- Grant execute permission to anonymous users since all users of the application are anonymous
GRANT EXECUTE ON FUNCTION get_random_image(bigint[]) TO anon;

-- Example usage:
-- Get random image from specific categories:
-- SELECT * FROM get_random_image(ARRAY[1,2]);
-- 
-- Get completely random image:
-- SELECT * FROM get_random_image();