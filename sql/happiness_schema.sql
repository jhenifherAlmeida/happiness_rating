-- 1. TABLE SETUP (MySQL compatible)
DROP TABLE IF EXISTS happiness_data;
DROP TABLE IF EXISTS countries;

CREATE TABLE countries (
    country_id INT AUTO_INCREMENT PRIMARY KEY,
    country_name VARCHAR(100) UNIQUE NOT NULL,
    region VARCHAR(50)
) ENGINE=InnoDB;

CREATE TABLE happiness_data (
    entry_id INT AUTO_INCREMENT PRIMARY KEY,
    country_id INT NOT NULL,
    year INT NOT NULL,
    happiness_score DECIMAL(5,3),
    gdp DECIMAL(10,6),
    social_support DECIMAL(10,6),
    life_expectancy DECIMAL(10,6),
    freedom DECIMAL(10,6),
    corruption DECIMAL(10,6),
    generosity DECIMAL(10,6),
    FOREIGN KEY (country_id) REFERENCES countries(country_id),
    UNIQUE KEY (country_id, year)
) ENGINE=InnoDB;

-- 2. DATA LOADING (Python replaces MySQL loading)
-- The Python script handles:
-- - Inserting into countries
-- - Inserting into happiness_data
-- You don’t need to load or drop temp_import

-- 3. ANALYSIS QUERIES (MySQL compatible)

-- A. Bottom 10 Countries (most recent year)
SELECT 
    c.country_name, 
    c.region, 
    h.happiness_score
FROM happiness_data h
JOIN countries c ON h.country_id = c.country_id
WHERE h.year = (SELECT MAX(year) FROM happiness_data)
ORDER BY h.happiness_score ASC
LIMIT 10;

-- B. Factor Correlations
SELECT 
    ROUND((SELECT (COUNT(*) * SUM(h.gdp * h.happiness_score) - SUM(h.gdp) * SUM(h.happiness_score)) / 
          (SQRT(COUNT(*) * SUM(h.gdp * h.gdp) - SUM(h.gdp) * SUM(h.gdp)) * 
           SQRT(COUNT(*) * SUM(h.happiness_score * h.happiness_score) - SUM(h.happiness_score) * SUM(h.happiness_score)))
    FROM happiness_data h WHERE h.year = 2019), 3) AS gdp_corr,
    
    ROUND((SELECT (COUNT(*) * SUM(h.social_support * h.happiness_score) - SUM(h.social_support) * SUM(h.happiness_score)) / 
          (SQRT(COUNT(*) * SUM(h.social_support * h.social_support) - SUM(h.social_support) * SUM(h.social_support)) * 
           SQRT(COUNT(*) * SUM(h.happiness_score * h.happiness_score) - SUM(h.happiness_score) * SUM(h.happiness_score)))
    FROM happiness_data h WHERE h.year = 2019), 3) AS social_corr
FROM DUAL;

-- C. Yearly Changes
SELECT 
    curr.country_name,
    curr.year,
    curr.happiness_score - prev.happiness_score AS `change`
FROM (
    SELECT 
        c.country_name,
        h.year,
        h.happiness_score,
        h.country_id
    FROM happiness_data h
    JOIN countries c ON h.country_id = c.country_id
) curr
JOIN (
    SELECT 
        country_id,
        year,
        happiness_score
    FROM happiness_data
) prev ON curr.country_id = prev.country_id 
       AND prev.year = (SELECT MAX(year) FROM happiness_data WHERE year < curr.year)
WHERE curr.happiness_score - prev.happiness_score IS NOT NULL
ORDER BY `change` DESC
LIMIT 10;
