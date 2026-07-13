-- CineVision PostgreSQL schema (movie-service)
-- Industrial baseline: explicit DDL, FK constraints, unique constraints, and index coverage.

CREATE TABLE IF NOT EXISTS category (
    category_id SERIAL PRIMARY KEY,
    category_name VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS director (
    director_id SERIAL PRIMARY KEY,
    director_name VARCHAR(150) NOT NULL
);

CREATE TABLE IF NOT EXISTS movie (
    movie_id SERIAL PRIMARY KEY,
    movie_name VARCHAR(200) NOT NULL,
    description TEXT NOT NULL,
    duration INTEGER NOT NULL CHECK (duration > 0),
    release_date DATE NOT NULL,
    is_display BOOLEAN NOT NULL DEFAULT FALSE,
    movie_trailer_url VARCHAR(500),
    category_id INTEGER NOT NULL REFERENCES category(category_id),
    director_id INTEGER NOT NULL REFERENCES director(director_id)
);

CREATE TABLE IF NOT EXISTS movie_image (
    image_id SERIAL PRIMARY KEY,
    image_url VARCHAR(500) NOT NULL,
    movie_movie_id INTEGER UNIQUE REFERENCES movie(movie_id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS actor (
    actor_id SERIAL PRIMARY KEY,
    actor_name VARCHAR(150) NOT NULL,
    movie_movie_id INTEGER REFERENCES movie(movie_id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS actor_image (
    image_id SERIAL PRIMARY KEY,
    image_url VARCHAR(500) NOT NULL,
    actor_actor_id INTEGER UNIQUE REFERENCES actor(actor_id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS city (
    city_id SERIAL PRIMARY KEY,
    city_name VARCHAR(120) NOT NULL,
    movie_id INTEGER REFERENCES movie(movie_id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS saloon (
    saloon_id SERIAL PRIMARY KEY,
    saloon_name VARCHAR(150) NOT NULL,
    city_id INTEGER NOT NULL REFERENCES city(city_id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS movie_saloon_time (
    id SERIAL PRIMARY KEY,
    movie_begin_time VARCHAR(20) NOT NULL,
    saloon_id INTEGER NOT NULL REFERENCES saloon(saloon_id) ON DELETE CASCADE,
    movie_id INTEGER NOT NULL REFERENCES movie(movie_id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS comment (
    comment_id SERIAL PRIMARY KEY,
    comment_text TEXT NOT NULL,
    comment_by VARCHAR(150) NOT NULL,
    comment_by_user_id VARCHAR(100) NOT NULL,
    movie_movie_id INTEGER REFERENCES movie(movie_id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_movie_is_display ON movie(is_display);
CREATE INDEX IF NOT EXISTS idx_movie_release_date ON movie(release_date);
CREATE INDEX IF NOT EXISTS idx_actor_movie ON actor(movie_movie_id);
CREATE INDEX IF NOT EXISTS idx_city_movie ON city(movie_id);
CREATE INDEX IF NOT EXISTS idx_saloon_city ON saloon(city_id);
CREATE INDEX IF NOT EXISTS idx_mst_movie ON movie_saloon_time(movie_id);
CREATE INDEX IF NOT EXISTS idx_mst_saloon ON movie_saloon_time(saloon_id);
CREATE INDEX IF NOT EXISTS idx_comment_movie ON comment(movie_movie_id);
