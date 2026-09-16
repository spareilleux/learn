-- Lesson 12, exercise 1: Aurora's default max_connections, LEAST({DBInstanceClassMemory/9531392}, 5000), for a few memory
-- sizes. DBInstanceClassMemory is somewhat less than the instance class's memory: these are upper bounds.
SELECT memory_gib, least(memory_gib::bigint * 1024 * 1024 * 1024 / 9531392, 5000) AS max_connections
FROM unnest(ARRAY[2, 4, 16, 32, 64]) AS memory_gib
ORDER BY memory_gib;
