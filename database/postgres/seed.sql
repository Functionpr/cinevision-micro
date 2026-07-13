-- CineVision PostgreSQL seed data (movie-service)
-- Safe to re-run: uses natural-key checks before insert/update where practical.

INSERT INTO category (category_name)
SELECT 'Sci-Fi'
WHERE NOT EXISTS (SELECT 1 FROM category WHERE category_name = 'Sci-Fi');

INSERT INTO category (category_name)
SELECT 'Action'
WHERE NOT EXISTS (SELECT 1 FROM category WHERE category_name = 'Action');

INSERT INTO director (director_name)
SELECT 'Christopher Nolan'
WHERE NOT EXISTS (SELECT 1 FROM director WHERE director_name = 'Christopher Nolan');

INSERT INTO director (director_name)
SELECT 'Denis Villeneuve'
WHERE NOT EXISTS (SELECT 1 FROM director WHERE director_name = 'Denis Villeneuve');

INSERT INTO movie (movie_name, description, duration, release_date, is_display, movie_trailer_url, category_id, director_id)
SELECT
    'Interstellar',
    'A team of explorers travels through a wormhole in space to secure humanity''s future.',
    169,
    DATE '2014-11-07',
    TRUE,
    'https://www.youtube.com/embed/zSWdZVtXT7E',
    (SELECT category_id FROM category WHERE category_name = 'Sci-Fi'),
    (SELECT director_id FROM director WHERE director_name = 'Christopher Nolan')
WHERE NOT EXISTS (SELECT 1 FROM movie WHERE movie_name = 'Interstellar');

INSERT INTO movie (movie_name, description, duration, release_date, is_display, movie_trailer_url, category_id, director_id)
SELECT
    'Dune: Messiah',
    'Paul Atreides faces the political and personal cost of prophecy in the next chapter of Arrakis.',
    155,
    CURRENT_DATE + INTERVAL '90 days',
    FALSE,
    'https://www.youtube.com/embed/Way9Dexny3w',
    (SELECT category_id FROM category WHERE category_name = 'Action'),
    (SELECT director_id FROM director WHERE director_name = 'Denis Villeneuve')
WHERE NOT EXISTS (SELECT 1 FROM movie WHERE movie_name = 'Dune: Messiah');

INSERT INTO movie_image (image_url, movie_movie_id)
SELECT
    'https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?auto=format&fit=crop&w=900&q=80',
    m.movie_id
FROM movie m
WHERE m.movie_name = 'Interstellar'
  AND NOT EXISTS (SELECT 1 FROM movie_image mi WHERE mi.movie_movie_id = m.movie_id);

INSERT INTO movie_image (image_url, movie_movie_id)
SELECT
    'https://images.unsplash.com/photo-1517604931442-7e0c8ed2963c?auto=format&fit=crop&w=900&q=80',
    m.movie_id
FROM movie m
WHERE m.movie_name = 'Dune: Messiah'
  AND NOT EXISTS (SELECT 1 FROM movie_image mi WHERE mi.movie_movie_id = m.movie_id);

INSERT INTO actor (actor_name, movie_movie_id)
SELECT 'Matthew McConaughey', m.movie_id
FROM movie m
WHERE m.movie_name = 'Interstellar'
  AND NOT EXISTS (
      SELECT 1 FROM actor a WHERE a.actor_name = 'Matthew McConaughey' AND a.movie_movie_id = m.movie_id
  );

INSERT INTO actor (actor_name, movie_movie_id)
SELECT 'Anne Hathaway', m.movie_id
FROM movie m
WHERE m.movie_name = 'Interstellar'
  AND NOT EXISTS (
      SELECT 1 FROM actor a WHERE a.actor_name = 'Anne Hathaway' AND a.movie_movie_id = m.movie_id
  );

INSERT INTO actor (actor_name, movie_movie_id)
SELECT 'Timothee Chalamet', m.movie_id
FROM movie m
WHERE m.movie_name = 'Dune: Messiah'
  AND NOT EXISTS (
      SELECT 1 FROM actor a WHERE a.actor_name = 'Timothee Chalamet' AND a.movie_movie_id = m.movie_id
  );

INSERT INTO actor (actor_name, movie_movie_id)
SELECT 'Zendaya', m.movie_id
FROM movie m
WHERE m.movie_name = 'Dune: Messiah'
  AND NOT EXISTS (
      SELECT 1 FROM actor a WHERE a.actor_name = 'Zendaya' AND a.movie_movie_id = m.movie_id
  );

INSERT INTO city (city_name, movie_id)
SELECT 'Douala', m.movie_id
FROM movie m
WHERE m.movie_name = 'Interstellar'
  AND NOT EXISTS (
      SELECT 1 FROM city c WHERE c.city_name = 'Douala' AND c.movie_id = m.movie_id
  );

INSERT INTO city (city_name, movie_id)
SELECT 'Yaounde', m.movie_id
FROM movie m
WHERE m.movie_name = 'Interstellar'
  AND NOT EXISTS (
      SELECT 1 FROM city c WHERE c.city_name = 'Yaounde' AND c.movie_id = m.movie_id
  );

INSERT INTO saloon (saloon_name, city_id)
SELECT 'Bonanjo Hall 1', c.city_id
FROM city c
WHERE c.city_name = 'Douala'
  AND NOT EXISTS (
      SELECT 1 FROM saloon s WHERE s.saloon_name = 'Bonanjo Hall 1' AND s.city_id = c.city_id
  );

INSERT INTO saloon (saloon_name, city_id)
SELECT 'Akwa Hall 3', c.city_id
FROM city c
WHERE c.city_name = 'Douala'
  AND NOT EXISTS (
      SELECT 1 FROM saloon s WHERE s.saloon_name = 'Akwa Hall 3' AND s.city_id = c.city_id
  );

INSERT INTO saloon (saloon_name, city_id)
SELECT 'Centre Hall 2', c.city_id
FROM city c
WHERE c.city_name = 'Yaounde'
  AND NOT EXISTS (
      SELECT 1 FROM saloon s WHERE s.saloon_name = 'Centre Hall 2' AND s.city_id = c.city_id
  );

INSERT INTO movie_saloon_time (movie_begin_time, saloon_id, movie_id)
SELECT '18:00', s.saloon_id, m.movie_id
FROM saloon s
JOIN city c ON c.city_id = s.city_id
JOIN movie m ON m.movie_name = 'Interstellar'
WHERE s.saloon_name = 'Bonanjo Hall 1'
  AND c.city_name = 'Douala'
  AND NOT EXISTS (
      SELECT 1 FROM movie_saloon_time mst
      WHERE mst.movie_begin_time = '18:00' AND mst.saloon_id = s.saloon_id AND mst.movie_id = m.movie_id
  );

INSERT INTO movie_saloon_time (movie_begin_time, saloon_id, movie_id)
SELECT '20:45', s.saloon_id, m.movie_id
FROM saloon s
JOIN city c ON c.city_id = s.city_id
JOIN movie m ON m.movie_name = 'Interstellar'
WHERE s.saloon_name = 'Akwa Hall 3'
  AND c.city_name = 'Douala'
  AND NOT EXISTS (
      SELECT 1 FROM movie_saloon_time mst
      WHERE mst.movie_begin_time = '20:45' AND mst.saloon_id = s.saloon_id AND mst.movie_id = m.movie_id
  );

INSERT INTO movie_saloon_time (movie_begin_time, saloon_id, movie_id)
SELECT '21:15', s.saloon_id, m.movie_id
FROM saloon s
JOIN city c ON c.city_id = s.city_id
JOIN movie m ON m.movie_name = 'Interstellar'
WHERE s.saloon_name = 'Centre Hall 2'
  AND c.city_name = 'Yaounde'
  AND NOT EXISTS (
      SELECT 1 FROM movie_saloon_time mst
      WHERE mst.movie_begin_time = '21:15' AND mst.saloon_id = s.saloon_id AND mst.movie_id = m.movie_id
  );

INSERT INTO comment (comment_text, comment_by, comment_by_user_id, movie_movie_id)
SELECT
    'Great visuals and soundtrack.',
    'Demo Customer',
    'demo-user-id',
    m.movie_id
FROM movie m
WHERE m.movie_name = 'Interstellar'
  AND NOT EXISTS (
      SELECT 1 FROM comment c WHERE c.comment_text = 'Great visuals and soundtrack.' AND c.movie_movie_id = m.movie_id
  );
