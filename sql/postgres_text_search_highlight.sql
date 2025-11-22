-- PostgreSQL Text Search with Highlighting and Position Tracking
--
-- Description:
--   Searches for a word/phrase in content, returns highlighted snippets with context
--   (20 words before/after the match), and returns the position of both the search
--   word and the entire snippet in the original content.
--
-- Features:
--   - Strips HTML tags and entities when HTML is detected
--   - Partial word matching (case-insensitive)
--   - Returns all matches (not just first one)
--   - Configurable context window (currently 20 words before/after)
--   - Position tracking for search word and snippet
--
-- Parameters:
--   :search_word - The text to search for (e.g., 'drug', 'drug products')
--
-- Usage Example:
--   -- In your application/query tool, set parameter:
--   :search_word = 'drug products'
--
-- Returns:
--   - search_word_start: Character position where search word starts
--   - search_word_end: Character position where search word ends
--   - snippet_start: Character position where context snippet starts
--   - snippet_end: Character position where context snippet ends
--   - sentence_with_highlight: Text snippet with >>>word<<< highlighting
--
-- Customization:
--   - Change {0,20} to {0,N} for more/less context words
--   - Change '>>>\1<<<' to other markers like '**\1**' or '<mark>\1</mark>'

SELECT DISTINCT
  position(lower(:search_word) IN lower(content)) AS search_word_start,
  position(lower(:search_word) IN lower(content)) + length(:search_word) - 1 AS search_word_end,
  position(lower(match[1]) IN lower(content)) AS snippet_start,
  position(lower(match[1]) IN lower(content)) + length(match[1]) - 1 AS snippet_end,
  '...' ||
  regexp_replace(
    trim(regexp_replace(match[1], '\s+', ' ', 'g')),
    '(' || :search_word || ')',
    '>>>\1<<<',
    'gi'
  ) ||
  '...' AS sentence_with_highlight
FROM product_content,
     regexp_matches(
       CASE
         WHEN content ~ '<[^>]+>' THEN
           regexp_replace(
             regexp_replace(
               regexp_replace(content, '<[^>]+>', ' ', 'g'),  -- Remove tags
               '&[a-z]+;', ' ', 'gi'  -- Remove HTML entities like &nbsp;
             ),
             '\s+', ' ', 'g'  -- Clean up multiple spaces
           )
         ELSE
           content
         END,
         '(?:(?:\S+\s+)){0,20}' || :search_word || '(?:(?:\s+\S+)){0,20}',
         'gi'
       ) AS match
WHERE content ILIKE '%' || :search_word || '%';


-- ALTERNATIVE VERSION: Simple snippet without positions
-- Use this if you only need the highlighted text without position tracking

/*
SELECT DISTINCT
  '...' ||
  regexp_replace(
    trim(regexp_replace(match[1], '\s+', ' ', 'g')),
    '(' || :search_word || ')',
    '>>>\1<<<',
    'gi'
  ) ||
  '...' AS sentence_with_highlight
FROM product_content,
     regexp_matches(
       CASE
         WHEN content ~ '<[^>]+>' THEN
           regexp_replace(
             regexp_replace(
               regexp_replace(content, '<[^>]+>', ' ', 'g'),
               '&[a-z]+;', ' ', 'gi'
             ),
             '\s+', ' ', 'g'
           )
         ELSE
           content
         END,
         '(?:(?:\S+\s+)){0,20}' || :search_word || '(?:(?:\s+\S+)){0,20}',
         'gi'
       ) AS match
WHERE content ILIKE '%' || :search_word || '%';
*/
