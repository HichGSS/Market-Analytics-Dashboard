SELECT * FROM vginsights.games_tabe;
SELECT * FROM developer_stats;


/* Market Trend Forecasting

Classifier les jeux par difficulté de developpement et regarder l'effet financier ? 
Supposons que jsuis un indie, comment je fais pour m'inserer sur le marché en mode grave safe  ? 



What statistical methods best capture emerging genre trends and market shifts?
How can seasonal patterns be modeled to optimize release timing decisions?
What leading indicators predict shifts in consumer preferences for game characteristics?
How can developer portfolio data be used to predict market saturation points? */

-- What game characteristics, developer attributes, and market conditions combine to create the highest probability of financial success? (python ML)
-- What is the optimal genre portfolio balance for maximizing total developer revenue? (Python ML )
-- What tags/genre have the most quality monetization efficiency ($ per rating point)
-- What combination of tags/genre (or not) maximise the RPAG AND revenue_per_game ? 
-- Is there an optimal price point for different types of games that maximizes revenue?


-- Fil conducteur dev Indie (ou pas) qui cherche a s'insérer sur le marché --> best caractéristiques pour entrer dans le marché et faire le plus de THUNASSE 

-- Dash cools : afficher diff KPI par genre/sous genres et combinaisons pr voir niche/pas niche   RPAG etc. Graphs radars etc 
-- Ptit dash fun avec GTA 

-- CREATING A GAME_CLASSIFICATION COLUMN -- 
(ALTER TABLE games_tabe
ADD game_classification VARCHAR(50)); -- Adjust data type/length as needed

(UPDATE games_tabe
SET game_classification = CASE 
    WHEN name LIKE '%Black Myth: Wukong%' THEN 'AAA'
    WHEN publishers_type LIKE '%AAA%' THEN 'AAA'
    WHEN publishers_type LIKE '%AA%' THEN 'AA'
    WHEN tags LIKE '%Indie%' THEN 'Indie'
    WHEN publishers_type = ' ' THEN ' '
    ELSE 'Indie'
END);

SET SESSION sql_mode = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';

CREATE TABLE steam_sales AS(
SELECT id, game_id,igdb_id,steam_id, name,  revenue, units_sold
FROM games_tabe);

CREATE TABLE game_info AS(
SELECT id, game_id,igdb_id,steam_id, name,  released, price, reviews, followers, rating, avg_playtime, genres, developers, publishers, game_classification, tags
FROM games_tabe);

-- CREATING DEV TABLE FROM ORIGINAL TABLE --  PAS ACCURATE --> SCRAP VGINSIGHTS 
CREATE TABLE developer_stats AS
(WITH 
developer_medians AS (
    SELECT developers,
		   AVG(revenue) AS median_raw
    FROM ( SELECT developers, revenue,
            ROW_NUMBER() OVER (PARTITION BY developers ORDER BY revenue) AS row_num,
            COUNT(*) OVER (PARTITION BY developers) AS total_games
		   FROM games_tabe
		   WHERE price <> 0 ) AS ranked
    WHERE row_num IN (
        FLOOR((total_games + 1)/2),
        CEIL((total_games + 1)/2)
    )
    GROUP BY developers
)

SELECT 
    b.developers,
    b.publishers_type AS classification,
    COUNT(*) AS released_games,
    ROUND(SUM(b.revenue) / 1000000000,2) AS total_revenue,
    ROUND(SUM(b.units_sold)/1000000,2) AS tot_units_sold,
    ROUND(AVG(b.revenue) / 1000000,1) AS avg_rev_per_game,
    -- Median from pre-calculated developer-level values
    ROUND(m.median_raw / 1000000,1) AS median_rev_per_game,
    ROUND(AVG(CASE WHEN b.genres LIKE '%Indie%' THEN 1 ELSE 0 END) * 100) AS indie_pct,
    ROUND(AVG(CASE WHEN b.genres LIKE '%Action%' THEN 1 ELSE 0 END) * 100) AS action_pct,
    ROUND(AVG(CASE WHEN b.genres LIKE '%Adventure%' THEN 1 ELSE 0 END) * 100) AS adventure_pct,
    ROUND(AVG(CASE WHEN b.genres LIKE '%Casual%' THEN 1 ELSE 0 END) * 100) AS casual_pct,
    ROUND(AVG(CASE WHEN b.genres LIKE '%MMO%' THEN 1 ELSE 0 END) * 100) AS mmo_pct,
    ROUND(AVG(CASE WHEN b.genres LIKE '%Racing%' THEN 1 ELSE 0 END) * 100) AS racing_pct,
    ROUND(AVG(CASE WHEN b.genres LIKE '%RPG%' THEN 1 ELSE 0 END) * 100) AS rpg_pct,
    ROUND(AVG(CASE WHEN b.genres LIKE '%Simulation%' THEN 1 ELSE 0 END) * 100) AS simulation_pct,
    ROUND(AVG(CASE WHEN b.genres LIKE '%Sports%' THEN 1 ELSE 0 END) * 100) AS sports_pct,
    ROUND(AVG(CASE WHEN b.genres LIKE '%Strategy%' THEN 1 ELSE 0 END) * 100) AS strategy_pct,
    ROUND(AVG(CASE WHEN b.genres LIKE '%Free to Play%' THEN 1 ELSE 0 END) * 100) AS F2P_pct
FROM games_tabe b
LEFT JOIN developer_medians m
    ON b.developers = m.developers
GROUP BY b.developers, b.publishers_type, m.median_raw
ORDER BY total_revenue DESC);


-- REVENUE MARKET SHARE AND UNITS SOLD SHARE BY GAME CLASSIFICATION -- Pas ouf -- 
(WITH new2 AS (
  SELECT *,
    YEAR(released) AS year  -- Extract year from release date
  FROM games_tabe)

SELECT 
  game_classification,
  ROUND(SUM(revenue)/1000000000,1) AS classification_revenue_bn,
  ROUND(SUM(units_sold)/1000000000,1) AS classification_units_bn,
  ROUND(SUM(revenue) / (SELECT SUM(revenue) FROM new2 ) * 100) AS revenue_market_share,
  ROUND(SUM(units_sold) / (SELECT SUM(units_sold) FROM new2 ) * 100) AS units_market_share
FROM games_tabe
WHERE game_classification IS NOT NULL AND revenue <> 0 -- AND released BETWEEN '2024-01-01' AND '2024-09-30'
GROUP BY game_classification);

-- REVENUE MARKET SHARE AND UNITS SOLD SHARE BY GAME CLASSIFICATION BY YEAR -- GREAT -- Montrer les changements de tendence entre les classificaitons -- Courbe
(WITH new2 AS (
  SELECT *,
    YEAR(released) AS year  -- Extract year from release date
  FROM games_tabe
)

SELECT 
  year,
  game_classification,
  ROUND(SUM(revenue)/1000000000, 1) AS classification_revenue_bn,
  ROUND(SUM(units_sold)/1000000000, 1) AS classification_units_bn,
  ROUND(SUM(revenue) / (SELECT SUM(revenue) FROM new2 n2 
                       WHERE n2.year = new2.year  -- Correlated subquery for yearly total
                       AND game_classification IS NOT NULL AND revenue <> 0) * 100) 
    AS revenue_market_share,
  ROUND(SUM(units_sold) / (SELECT SUM(units_sold) FROM new2 n2 
                           WHERE n2.year = new2.year  -- Same for units
                           AND game_classification IS NOT NULL AND revenue <> 0) * 100) 
    AS units_market_share
FROM new2
WHERE game_classification IS NOT NULL AND revenue <> 0 AND year >= 2000
GROUP BY year, game_classification  -- Group by year + classification
ORDER BY year, game_classification DESC);


-- REVENUE AND UNITS SOLD MARKET SHARE FOR EACH DEVELOPER CLASSIFICATION -- meh
 (WITH dev_clean AS (SELECT * 
 FROM developer_stats 
 WHERE classification IS NOT NULL AND total_revenue <> 0)
 
 SELECT 
  classification,
  ROUND(SUM(total_revenue),1) AS classification_revenue_bn,
  ROUND(SUM(tot_units_sold)/1000,1) AS classification_units_bn,
  ROUND(SUM(total_revenue) / (SELECT SUM(total_revenue) FROM dev_clean) * 100) AS revenue_market_share,
  ROUND(SUM(tot_units_sold) / (SELECT SUM(tot_units_sold) FROM dev_clean) * 100) AS units_market_share

FROM dev_clean
WHERE classification IS NOT NULL
GROUP BY classification
LIMIT 3);


-- PCT OF TOT STEAM REVENUE GENERATED BY TOP 10% (ranked by revenue) GAMES FOR EACH CLASSIFICATION -- Pas ouf mais peut servir 
 (WITH revenue_rank AS (SELECT name, revenue, game_classification,
 NTILE(10) OVER(PARTITION BY game_classification ORDER BY revenue DESC) AS rn
 FROM games_tabe 
 WHERE game_classification IS NOT NULL)
 
 SELECT game_classification,
 SUM(revenue) / (SELECT SUM(revenue) FROM games_tabe) * 100 AS top10_pct_steam_revenue
 FROM revenue_rank
 WHERE rn = 1 
 GROUP BY game_classification);
 
 
 -- TOP 10 REVENUE GAMES IN EACH CLASSIFICATION -- Peut servir 
(WITH ranked_games AS (
    SELECT 
        *,
        ROW_NUMBER() OVER(
            PARTITION BY game_classification 
            ORDER BY revenue DESC
        ) AS classification_rank
    FROM (
        SELECT 
            name,
            revenue,
            game_classification,
            tags,
            NTILE(10) OVER(
                PARTITION BY game_classification 
                ORDER BY revenue DESC
            ) AS rn
        FROM games_tabe
        WHERE game_classification IN ('AAA', 'AA', 'Indie')
    ) AS base
    WHERE rn = 1
)

SELECT 
    game_classification,
    name,
    revenue,
    tags
FROM ranked_games
WHERE classification_rank <= 10
ORDER BY 
    game_classification,
    revenue DESC);

 

-- CREATE ALL VIEWS FOR 5 YEAR TIMEFRAME --
CREATE VIEW mshare2024 AS ( 
WITH dev_clean AS (SELECT * 
 FROM developer_stats2024
 WHERE total_revenue <> 0)
 
 SELECT 
  timeframe,
  
  CASE 
    WHEN classification LIKE '%AAA%' THEN 'AAA'
    WHEN classification LIKE '%AA%' THEN 'AA'
    WHEN classification = ' ' THEN ' '
    ELSE 'Indie'
  END AS classification_group,
   
  ROUND(SUM(total_revenue),1) AS classification_revenue_bn,
  ROUND(SUM(tot_units_sold)/1000000,1) AS classification_units_m,
  ROUND(SUM(total_revenue) / (SELECT SUM(total_revenue) FROM dev_clean) * 100) AS revenue_market_share,
  ROUND(SUM(tot_units_sold) / (SELECT SUM(tot_units_sold) FROM dev_clean) * 100) AS units_market_share

FROM dev_clean
GROUP BY classification_group, timeframe
LIMIT 3);

-- REVENUE AND UNITS SOLD MARKET SHARES BY 5 YEAR TIMEFRAME FOR EACH DEV CLASSIFICATION-- GREAT -- Pour montrer les changements de tendance et l'evolution auj --> prediction  --> Mettre en corrélation avec nouvelles techno/ IA/ des choses qui facilitent le dev indie ? 
(SELECT * FROM mshare2000
UNION ALL
SELECT * FROM mshare2005
UNION ALL
SELECT * FROM mshare2010
UNION ALL
SELECT * FROM mshare2015
UNION ALL
SELECT * FROM mshare2020
ORDER BY classification_group);
 
-- RELEASE TIMEFRAME ANALYSIS BY GENRE BY UNITS SOLD -- Can be used as predictive analysis for release timeframe for ANY SPECIFIC GENRE)
(SELECT
    MONTH(released) AS month,
    -- Use AVG() with conditional logic for automatic normalization
    AVG(CASE WHEN tags LIKE '%Puzzle%' THEN units_sold END) AS norm_units_puzzle,
    AVG(CASE WHEN genres LIKE '%Action%' THEN units_sold END) AS norm_units_action,
    AVG(CASE WHEN genres LIKE '%Adventure%' THEN units_sold END) AS norm_units_adventure,
    AVG(CASE WHEN genres LIKE '%Casual%' THEN units_sold END) AS norm_units_casual,
    AVG(CASE WHEN genres LIKE '%MMO%' THEN units_sold END) AS norm_units_mmo,
    AVG(CASE WHEN genres LIKE '%Racing%' THEN units_sold END) AS norm_units_racing,
    AVG(CASE WHEN genres LIKE '%RPG%' THEN units_sold END) AS norm_units_rpg,
    AVG(CASE WHEN genres LIKE '%Simulation%' THEN units_sold END) AS norm_units_simulation,
    AVG(CASE WHEN genres LIKE '%Sports%' THEN units_sold END) AS norm_units_sports,
    AVG(CASE WHEN genres LIKE '%Strategy%' THEN units_sold END) AS norm_units_strategy,
    AVG(CASE WHEN tags LIKE '%Horror%' THEN units_sold END) AS norm_units_horror,
    AVG(CASE WHEN tags LIKE '%Dating%' THEN units_sold END) AS norm_units_dating,
    CASE
		WHEN MONTH(released) = '1' THEN 'RTS' 
        WHEN MONTH(released) = '2' THEN 'Idler / Couch Co-op'
        WHEN MONTH(released) = '3' THEN 'Spring sale / Visual Novel / City builder'
        WHEN MONTH(released) = '4' THEN 'Wargames'
        WHEN MONTH(released) = '5' THEN 'Creature collector / ZvV'
        WHEN MONTH(released) = '6' THEN 'Steam Next/Fishing'
        WHEN MONTH(released) = '7' THEN 'Summer Sale/Automation'
        WHEN MONTH(released) = '8' THEN 'Racing/4X/TPS'
        WHEN MONTH(released) = '9' THEN 'Political Sim/Autumn Sale'
        WHEN MONTH(released) = '10' THEN 'Steam Next/Steam Scream'
        WHEN MONTH(released) = '11' THEN 'Animal Fest'
        WHEN MONTH(released) = '12' THEN 'Sports Fest'
     END AS steam_sale
FROM games_tabe
WHERE YEAR(released) > 2014
GROUP BY MONTH(released), steam_sale
ORDER BY month);


-- GENRE ANALYSIS BY NORMALIZED REVENUE -- SAME AS PREVIOUS AND CAN BE USED FOR DEEPER GENRES/TAGS -- CAN BE COOL FOR A DASH TO STUDY GROWTH EVOLUTION AND MARKET SHIFT -- Normalisation ok ou pas ? 
(SELECT game_classification, YEAR(released),
AVG(CASE WHEN tags LIKE '%Puzzle%' THEN revenue ELSE 0 END)/1000000 AS tot_revenue_puzzle,
AVG(CASE WHEN genres LIKE '%Action%' THEN revenue ELSE 0 END)/1000000 AS tot_revenue_action,
AVG(CASE WHEN genres LIKE '%Adventure%' THEN revenue ELSE 0 END)/1000000 AS tot_revenue_adventure,
AVG(CASE WHEN genres LIKE '%Casual%' THEN revenue ELSE 0 END)/1000000 AS tot_revenue_casual,
AVG(CASE WHEN genres LIKE '%MMO%' THEN revenue ELSE 0 END)/1000000 AS tot_revenue_MMO,
AVG(CASE WHEN genres LIKE '%Racing%' THEN revenue ELSE 0 END)/1000000 AS tot_revenue_racing,
AVG(CASE WHEN genres LIKE '%RPG%' THEN revenue ELSE 0 END)/1000000 AS tot_revenue_rpg,
AVG(CASE WHEN genres LIKE '%Simulation%' THEN revenue ELSE 0 END)/1000000 AS tot_revenue_simulation,
AVG(CASE WHEN genres LIKE '%Sports%' THEN revenue ELSE 0 END)/1000000 AS tot_revenue_sports,
AVG(CASE WHEN genres LIKE '%Strategy%' THEN revenue ELSE 0 END)/1000000 AS tot_revenue_strategy


FROM games_tabe
WHERE YEAR(released) > 2014 AND revenue > 100000
GROUP BY game_classification, YEAR(released)
ORDER BY game_classification, YEAR(released));


-- REV GENERATION WEIGHT ATTRIBUTED TO GENRES -- pas ouf, peut être intéressant avec les tags -- ptet parler des classifications pas assez précises ? 

(WITH aggregated_data AS (
   SELECT game_classification,
     SUM(CASE WHEN genres LIKE '%Action%' THEN revenue ELSE 0 END)/1e9 AS action,
     SUM(CASE WHEN genres LIKE '%Adventure%' THEN revenue ELSE 0 END)/1e9 AS adventure,
     SUM(CASE WHEN genres LIKE '%Casual%' THEN revenue ELSE 0 END)/1e9 AS casual,
     SUM(CASE WHEN genres LIKE '%MMO%' THEN revenue ELSE 0 END)/1e9 AS mmo,
     SUM(CASE WHEN genres LIKE '%Racing%' THEN revenue ELSE 0 END)/1e9 AS racing,
     SUM(CASE WHEN genres LIKE '%RPG%' THEN revenue ELSE 0 END)/1e9 AS rpg,
     SUM(CASE WHEN genres LIKE '%Simulation%' THEN revenue ELSE 0 END)/1e9 AS simulation,
     SUM(CASE WHEN genres LIKE '%Sports%' THEN revenue ELSE 0 END)/1e9 AS sports,
     SUM(CASE WHEN genres LIKE '%Strategy%' THEN revenue ELSE 0 END)/1e9 AS strategy
   FROM games_tabe
   WHERE YEAR(released) > 2009 AND revenue > 0
   GROUP BY game_classification
 ),
 
  base_data AS (SELECT 
   stats.genre,
   ROUND(SUM(stats.revenue_bn),2) AS tot_revenue
 FROM aggregated_data
 CROSS JOIN LATERAL (
   VALUES 
     ROW('Action', action),
     ROW('Adventure', adventure),
     ROW('Casual', casual),
     ROW('MMO', mmo),
     ROW('Racing', racing),
     ROW('RPG', rpg),
     ROW('Simulation', simulation),
     ROW('Sports', sports),
     ROW('Strategy', strategy)
 ) AS stats(genre, revenue_bn)
 GROUP BY stats.genre
 ORDER BY tot_revenue DESC)
 
SELECT *, 
log10((tot_revenue / (SELECT MAX(tot_revenue) FROM base_data))+1)  AS weight
FROM base_data);
 

-- AVG OF MEDIANS GROUPED BY DIVERSIFICATION COEFFICIENT -- Can also do weighed average but meh ? -- GREAT
(WITH div_coeff AS (SELECT developers, classification, released_games, tot_units_sold, avg_rev_per_game, median_rev_per_game,
       (CASE WHEN action_pct >= 10 THEN 1 ELSE 0 END +
        CASE WHEN adventure_pct >= 10 THEN 1 ELSE 0 END +
        CASE WHEN casual_pct >= 10 THEN 1 ELSE 0 END +
        CASE WHEN mmo_pct >= 10 THEN 1 ELSE 0 END +
        CASE WHEN racing_pct >= 10 THEN 1 ELSE 0 END +
        CASE WHEN rpg_pct >= 10 THEN 1 ELSE 0 END +  
        CASE WHEN simulation_pct >= 10 THEN 1 ELSE 0 END +  
        CASE WHEN sports_pct >= 10 THEN 1 ELSE 0 END +
        CASE WHEN strategy_pct >= 10 THEN 1 ELSE 0 END) 
        AS diversification_coefficient
FROM developer_stats)

SELECT diversification_coefficient,
AVG(median_rev_per_game) AS avg_of_medians 
FROM div_coeff
WHERE released_games >= 4 AND diversification_coefficient IS NOT NULL AND developers NOT IN('Facepunch Studios','Stunlock Studios')
GROUP BY diversification_coefficient
ORDER BY avg_of_medians DESC);

-- AVG OF MEDIANS GROUPED BY DIVERSIFICATION COEFFICIENT -- Can also do weighed average but meh ? -- GREAT 
(WITH div_coeff AS (SELECT developers, classification, released_games, tot_units_sold, avg_rev_per_game, median_rev_per_game,
       (CASE WHEN action_pct >= 10 AND adventure_pct >= 10 THEN 1 ELSE 0 END +
        CASE WHEN casual_pct >= 10 THEN 1 ELSE 0 END +
        CASE WHEN mmo_pct >= 10 THEN 1 ELSE 0 END +
        CASE WHEN racing_pct >= 10 THEN 1 ELSE 0 END +
        CASE WHEN rpg_pct >= 10 THEN 1 ELSE 0 END +  
        CASE WHEN simulation_pct >= 10 THEN 1 ELSE 0 END +  
        CASE WHEN sports_pct >= 10 THEN 1 ELSE 0 END +
        CASE WHEN strategy_pct >= 10 THEN 1 ELSE 0 END) 
        AS diversification_coefficient
FROM developer_stats)

SELECT diversification_coefficient,
AVG(median_rev_per_game) AS avg_of_medians 
FROM div_coeff
WHERE released_games >= 4 AND diversification_coefficient IS NOT NULL AND developers NOT IN('Facepunch Studios','Stunlock Studios')
GROUP BY diversification_coefficient
ORDER BY avg_of_medians DESC);

-- CODE TO FILTER DEVS BY DIVERSIFICATION COEFFICIENT -- 
(WITH div_coeff AS (SELECT developers, classification, released_games, tot_units_sold, avg_rev_per_game, median_rev_per_game,
       (CASE WHEN action_pct >= 10 THEN 1 ELSE 0 END +
        CASE WHEN adventure_pct >= 10 THEN 1 ELSE 0 END +
        CASE WHEN casual_pct >= 10 THEN 1 ELSE 0 END +
        CASE WHEN mmo_pct >= 10 THEN 1 ELSE 0 END +
        CASE WHEN racing_pct >= 10 THEN 1 ELSE 0 END +
        CASE WHEN rpg_pct >= 10 THEN 1 ELSE 0 END +  
        CASE WHEN simulation_pct >= 10 THEN 1 ELSE 0 END +  
        CASE WHEN sports_pct >= 10 THEN 1 ELSE 0 END +
        CASE WHEN strategy_pct >= 10 THEN 1 ELSE 0 END) 
        AS diversification_coefficient
FROM developer_stats)

SELECT *
FROM div_coeff
WHERE released_games >= 4 AND diversification_coefficient IS NOT NULL  AND diversification_coefficient = 2 AND developers NOT IN('Facepunch Studios','Stunlock Studios')
ORDER BY median_rev_per_game DESC);


-- STUDY OF REV / UNITS / RELEASED MARKET SHARE OF SPLIT-SCREEN GAMES AND HAZELIGHT WEIGHT IN IT -- can be modified to be better numbers -- GREAT -- Yassine : Mega intéressant 

(WITH annual_totals AS (
    SELECT 
        YEAR(released) AS release_year,
        SUM(revenue) AS total_revenue,
        SUM(units_sold) AS tot_units_sold
    FROM games_tabe
    WHERE revenue > 0
    GROUP BY YEAR(released)
),
market_shares AS (SELECT 
    YEAR(g.released) AS release_year,
    a.total_revenue,
    ROUND(
        SUM(
            CASE 
                WHEN g.tags LIKE '%Split screen%' 
                    AND g.price > 0 
                THEN g.revenue 
            END
        ) * 100.0 / a.total_revenue,
        2
    ) AS rev_market_share_pct,
    SUM(
        CASE 
            WHEN g.developers LIKE '%Hazelight%' 
            THEN revenue 
        END
    ) / a.total_revenue * 100 AS hazelight_market_share,
    ROUND(
        SUM(
            CASE 
                WHEN g.tags LIKE '%Split screen%' 
                    AND g.price > 0 
                THEN g.units_sold 
            END
        ) * 100.0 / a.tot_units_sold,
        2
    ) AS units_market_share_pct,
    COUNT(
        CASE 
            WHEN g.tags LIKE '%Split screen%' 
                AND genres LIKE '%Action, Adventure%' 
                AND price <> 0 
            THEN 1 
        END
    ) / COUNT(*) * 100 AS released_market_share,
    COUNT(
        CASE 
            WHEN g.tags LIKE '%Split screen%' 
                AND genres LIKE '%Action, Adventure%' 
                AND price <> 0 
            THEN 1 
        END
    ) AS ss_released,
    COUNT(*) AS total_games_released
FROM games_tabe g
LEFT JOIN annual_totals a
    ON YEAR(g.released) = a.release_year
WHERE YEAR(g.released) > 2009
GROUP BY 
    YEAR(g.released),
    a.total_revenue,
    a.tot_units_sold
ORDER BY release_year)

SELECT release_year, rev_market_share_pct,
total_revenue * (rev_market_share_pct / 100) / 1000000 AS rev_ms_in_dollars,
hazelight_market_share,
total_revenue * (hazelight_market_share / 100) / 1000000 AS hazelight_ms_in_dollars,
units_market_share_pct, 
released_market_share,
total_games_released,
ss_released
FROM market_shares 


);


-- STUDY OF VERY SUCCESSFUL NICHE GENRE -- GREAT

(WITH mod_genre AS(SELECT *,

REPLACE(
REPLACE(
REPLACE(
REPLACE(
REPLACE(
REPLACE(
genres,' Indie,','')
, ', Indie','')
, 'Indie, ','')
,' Early Access,','')
,', Early Access','') 
, 'Early Access, ','')
 AS new_genre 
FROM games_tabe),

genre_medians AS (
    SELECT 
        new_genre, 
        AVG(revenue) / 1000000 AS median_raw,
        MAX(total_games) AS total_games  -- Include total_games via aggregation
    FROM (
        SELECT 
            revenue, 
            new_genre,
            ROW_NUMBER() OVER (PARTITION BY new_genre ORDER BY revenue) AS row_num,
            COUNT(*) OVER (PARTITION BY new_genre) AS total_games
        FROM mod_genre
    ) AS ranked
    WHERE row_num IN (
        FLOOR((total_games + 1)/2),
        CEIL((total_games + 1)/2)
    )
    GROUP BY new_genre
    HAVING MAX(total_games) > 10  -- Filter AFTER including total_games
)
,

genre_concentrations AS (SELECT new_genre, 
COUNT(*) / (SELECT COUNT(*) FROM games_tabe) * 100 as genre_concentration
FROM mod_genre
GROUP BY new_genre)


SELECT gc.new_genre, gc.genre_concentration, gm.median_raw,
median_raw / genre_concentration AS niche_ratio
FROM genre_concentrations gc
LEFT JOIN genre_medians gm 
ON gc.new_genre = gm.new_genre
);

    
   -- CHECK WHAT GAMES ARE IN WHAT NEW_GENRE -- 
(WITH mod_genre AS(SELECT *,

REPLACE(
REPLACE(
REPLACE(
REPLACE(
REPLACE(
REPLACE(
genres,' Indie,','')
, ', Indie','')
, 'Indie, ','')
,' Early Access,','')
,', Early Access','') 
, 'Early Access, ','')
 AS new_genre 
FROM games_tabe)

SELECT *
FROM mod_genre
WHERE new_genre = 'Simulation, Sports, Racing, MMO');   
    
    
    -- CODE POUR CHECK BLANCHIMENT-- 
(WITH mod_genre AS(SELECT *,

REPLACE(
REPLACE(
REPLACE(
REPLACE(
REPLACE(
REPLACE(
genres,' Indie,','')
, ', Indie','')
, 'Indie, ','')
,' Early Access,','')
,', Early Access','') 
, 'Early Access, ','')
 AS new_genre 
FROM games_tabe)

SELECT publishers, YEAR(released) as year,
SUM(revenue)/1000000 AS total_rev,
MIN(released) as min_year,
MAX(released) as max_year
FROM mod_genre
WHERE publishers = 'hede'
group by publishers, YEAR(released));
    

-- QUALITY MONETIZATION EFFICIENCY BY GENRE, ALL TIME-  GREAT -- Can be done with more tags/genres ! -- Verifier la veracité statiqtique de ce truc -- Expliquer comment la emtric est calc et a quoi elle sert 

(WITH FilteredGames AS (
    SELECT 
        genres,
        tags,
        revenue,
        units_sold,  -- Added units_sold column
        rating
    FROM games_tabe
    WHERE rating <> 0 AND revenue <> 0 AND units_sold <> 0 AND YEAR(released) = 2024
),

CategoryMetrics AS (SELECT 
    category,
    AVG(revenue)/1000000 AS average_revenue,
    AVG(units_sold) AS average_units_sold,
    AVG(rating) AS average_rating
FROM (
    SELECT 
        'Puzzle' AS category,
        CASE WHEN tags LIKE '%Puzzle%' THEN revenue ELSE NULL END AS revenue,  -- Changed to NULL
        CASE WHEN tags LIKE '%Puzzle%' THEN units_sold ELSE NULL END AS units_sold,  -- New line
        CASE WHEN tags LIKE '%Puzzle%' THEN rating ELSE NULL END AS rating
    FROM FilteredGames
    
    UNION ALL
    
    SELECT 
        'Action' AS category,
        CASE WHEN genres LIKE '%Action%' THEN revenue ELSE NULL END,
        CASE WHEN genres LIKE '%Action%' THEN units_sold ELSE NULL END,  -- New line
        CASE WHEN genres LIKE '%Action%' THEN rating ELSE NULL END
    FROM FilteredGames
    
    -- Add this pattern to all categories --
    UNION ALL
    SELECT 'Adventure', 
        CASE WHEN genres LIKE '%Adventure%' THEN revenue ELSE NULL END,
        CASE WHEN genres LIKE '%Adventure%' THEN units_sold ELSE NULL END,
        CASE WHEN genres LIKE '%Adventure%' THEN rating ELSE NULL END
    FROM FilteredGames
    
    UNION ALL
    SELECT 'Casual', 
        CASE WHEN genres LIKE '%Casual%' THEN revenue ELSE NULL END,
        CASE WHEN genres LIKE '%Casual%' THEN units_sold ELSE NULL END,
        CASE WHEN genres LIKE '%Casual%' THEN rating ELSE NULL END
    FROM FilteredGames
    
    -- Continue for remaining genres --
    UNION ALL
    SELECT 'MMO', 
        CASE WHEN genres LIKE '%MMO%' THEN revenue ELSE NULL END,
        CASE WHEN genres LIKE '%MMO%' THEN units_sold ELSE NULL END,
        CASE WHEN genres LIKE '%MMO%' THEN rating ELSE NULL END
    FROM FilteredGames
    
    UNION ALL
    SELECT 'Racing', 
        CASE WHEN genres LIKE '%Racing%' THEN revenue ELSE NULL END,
        CASE WHEN genres LIKE '%Racing%' THEN units_sold ELSE NULL END,
        CASE WHEN genres LIKE '%Racing%' THEN rating ELSE NULL END
    FROM FilteredGames
    
    UNION ALL
    SELECT 'RPG', 
        CASE WHEN genres LIKE '%RPG%' THEN revenue ELSE NULL END,
        CASE WHEN genres LIKE '%RPG%' THEN units_sold ELSE NULL END,
        CASE WHEN genres LIKE '%RPG%' THEN rating ELSE NULL END
    FROM FilteredGames
    
    UNION ALL
    SELECT 'Simulation', 
        CASE WHEN genres LIKE '%Simulation%' THEN revenue ELSE NULL END,
        CASE WHEN genres LIKE '%Simulation%' THEN units_sold ELSE NULL END,
        CASE WHEN genres LIKE '%Simulation%' THEN rating ELSE NULL END
    FROM FilteredGames
    
    UNION ALL
    SELECT 'Sports', 
        CASE WHEN genres LIKE '%Sports%' THEN revenue ELSE NULL END,
        CASE WHEN genres LIKE '%Sports%' THEN units_sold ELSE NULL END,
        CASE WHEN genres LIKE '%Sports%' THEN rating ELSE NULL END
    FROM FilteredGames
    
    UNION ALL
    SELECT 'Strategy', 
        CASE WHEN genres LIKE '%Strategy%' THEN revenue ELSE NULL END,
        CASE WHEN genres LIKE '%Strategy%' THEN units_sold ELSE NULL END,
        CASE WHEN genres LIKE '%Strategy%' THEN rating ELSE NULL END
    FROM FilteredGames
) AS pivoted_data
GROUP BY category),

 norm_ratios AS (SELECT 
    category,
    average_revenue,
    average_units_sold,
    average_rating,
    -- Normalized ratios (0-1 scale)
    ROUND(
        (average_revenue / average_rating) / 
        MAX(average_revenue / average_rating) OVER(), 
    3) AS normalized_rev_ratio,
    ROUND(
        (average_units_sold / average_rating) / 
        MAX(average_units_sold / average_rating) OVER(), 
    3) AS normalized_units_ratio
FROM CategoryMetrics
WHERE average_rating > 0  -- Ensure no division by zero
ORDER BY normalized_rev_ratio DESC)

SELECT 
    category,
    average_revenue,
    average_units_sold,
    average_rating,
    normalized_rev_ratio,
    normalized_units_ratio,
    -- Combined efficiency ratio (50/50 weighting) --
    ROUND(
        (normalized_rev_ratio * 0.5) + 
        (normalized_units_ratio * 0.5), 
    3) AS combined_efficiency
FROM norm_ratios
ORDER BY combined_efficiency DESC);


-- QUALITY MONETIZATION EFFICIENCY BY GENRE, BY YEAR --  
(WITH FilteredGames AS (
    SELECT 
        genres,
        tags,
        revenue,
        units_sold,
        rating,
        YEAR(released) AS release_year
    FROM games_tabe
    WHERE rating <> 0 AND revenue <> 0 AND units_sold <> 0 AND YEAR(released) >= 2000
),

CategoryMetrics AS (
    SELECT 
        release_year,
        category,
        AVG(revenue)/1000000 AS average_revenue, -- Revenue in millions
        AVG(units_sold) AS average_units_sold,
        AVG(rating) AS average_rating
    FROM (
        SELECT 
            'Puzzle' AS category,
            release_year,
            CASE WHEN tags LIKE '%Puzzle%' THEN revenue ELSE NULL END AS revenue,
            CASE WHEN tags LIKE '%Puzzle%' THEN units_sold ELSE NULL END AS units_sold,
            CASE WHEN tags LIKE '%Puzzle%' THEN rating ELSE NULL END AS rating
        FROM FilteredGames

        UNION ALL
        
        SELECT 
            'Action' AS category,
            release_year,
            CASE WHEN genres LIKE '%Action%' THEN revenue ELSE NULL END,
            CASE WHEN genres LIKE '%Action%' THEN units_sold ELSE NULL END,
            CASE WHEN genres LIKE '%Action%' THEN rating ELSE NULL END
        FROM FilteredGames

        UNION ALL
        
        SELECT 
            'Adventure' AS category,
            release_year,
            CASE WHEN genres LIKE '%Adventure%' THEN revenue ELSE NULL END,
            CASE WHEN genres LIKE '%Adventure%' THEN units_sold ELSE NULL END,
            CASE WHEN genres LIKE '%Adventure%' THEN rating ELSE NULL END
        FROM FilteredGames

        UNION ALL
        
        SELECT 
            'Casual' AS category,
            release_year,
            CASE WHEN genres LIKE '%Casual%' THEN revenue ELSE NULL END,
            CASE WHEN genres LIKE '%Casual%' THEN units_sold ELSE NULL END,
            CASE WHEN genres LIKE '%Casual%' THEN rating ELSE NULL END
        FROM FilteredGames

        UNION ALL
        
        SELECT 
            'MMO' AS category,
            release_year,
            CASE WHEN genres LIKE '%MMO%' THEN revenue ELSE NULL END,
            CASE WHEN genres LIKE '%MMO%' THEN units_sold ELSE NULL END,
            CASE WHEN genres LIKE '%MMO%' THEN rating ELSE NULL END
        FROM FilteredGames

        UNION ALL
        
        SELECT 
            'Racing' AS category,
            release_year,
            CASE WHEN genres LIKE '%Racing%' THEN revenue ELSE NULL END,
            CASE WHEN genres LIKE '%Racing%' THEN units_sold ELSE NULL END,
            CASE WHEN genres LIKE '%Racing%' THEN rating ELSE NULL END
        FROM FilteredGames

        UNION ALL
        
        SELECT 
            'RPG' AS category,
            release_year,
            CASE WHEN genres LIKE '%RPG%' THEN revenue ELSE NULL END,
            CASE WHEN genres LIKE '%RPG%' THEN units_sold ELSE NULL END,
            CASE WHEN genres LIKE '%RPG%' THEN rating ELSE NULL END
        FROM FilteredGames

        UNION ALL
        
        SELECT 
            'Simulation' AS category,
            release_year,
            CASE WHEN genres LIKE '%Simulation%' THEN revenue ELSE NULL END,
            CASE WHEN genres LIKE '%Simulation%' THEN units_sold ELSE NULL END,
            CASE WHEN genres LIKE '%Simulation%' THEN rating ELSE NULL END
        FROM FilteredGames

        UNION ALL
        
        SELECT 
            'Sports' AS category,
            release_year,
            CASE WHEN genres LIKE '%Sports%' THEN revenue ELSE NULL END,
            CASE WHEN genres LIKE '%Sports%' THEN units_sold ELSE NULL END,
            CASE WHEN genres LIKE '%Sports%' THEN rating ELSE NULL END
        FROM FilteredGames

        UNION ALL
        
        SELECT 
            'Strategy' AS category,
            release_year,
            CASE WHEN genres LIKE '%Strategy%' THEN revenue ELSE NULL END,
            CASE WHEN genres LIKE '%Strategy%' THEN units_sold ELSE NULL END,
            CASE WHEN genres LIKE '%Strategy%' THEN rating ELSE NULL END
        FROM FilteredGames
    ) AS pivoted_data
    GROUP BY release_year, category
),

norm_ratios AS (
    SELECT 
        release_year, 
        category, 
        average_revenue, 
        average_units_sold, 
        average_rating,

        -- Normalized ratios (0-1 scale)
        ROUND(
          (average_revenue / average_rating) / MAX(average_revenue / average_rating) OVER(PARTITION BY release_year), 
          3
        ) AS normalized_rev_ratio,

        ROUND(
          (average_units_sold / average_rating) / MAX(average_units_sold / average_rating) OVER(PARTITION BY release_year), 
          3
        ) AS normalized_units_ratio
    FROM CategoryMetrics
    WHERE average_rating > 0 -- Ensure no division by zero
)

SELECT 
    release_year, 
    category, 
    average_revenue, 
    average_units_sold, 
    average_rating, 
    normalized_rev_ratio, 
    normalized_units_ratio,

    -- Combined efficiency ratio (50/50 weighting)
    ROUND(
      (normalized_rev_ratio * 0.5) + (normalized_units_ratio * 0.5), 
      3
    ) AS combined_efficiency
FROM norm_ratios
ORDER BY release_year ASC, combined_efficiency DESC);


-- NICHE STUDY WITHOUT CLASSIFICATION, NO REVENUE TRESHOLD-- GREAT +++ -- Can be done  with more genres/tags -- Possible ML -- Ca génère 12x + que TOUT le catalogue ou alors le catalogue dans le groupe classifié ?


(WITH FilteredGames AS (
    SELECT 
        genres,
        tags,
        revenue,
        units_sold,
        rating,
        YEAR(released) AS release_year,
        game_classification
    FROM games_tabe
    WHERE rating <> 0 AND revenue <> 0 AND units_sold > 10000 
)

SELECT 
    category, game_classification,
    COUNT(revenue) AS nb_games_in_genre,
    (SUM(revenue) / count(revenue)) AS revenue_per_game,
    (SUM(revenue) / (SELECT SUM(revenue) FROM FilteredGames)) /  (count(revenue) / (SELECT COUNT(*) FROM FilteredGames)) AS RPAG
    -- (SELECT NTILE(4) OVER (ORDER BY LOG(revenue) DESC) FROM FilteredGames) AS rev_treshold_25pct
    
FROM (
    SELECT 
		game_classification,
        'Choices Matter' AS category,
        CASE WHEN tags LIKE '%Choices Matter%' THEN revenue ELSE NULL END AS revenue,  -- Changed to NULL
        CASE WHEN tags LIKE '%Choices Matter%' THEN units_sold ELSE NULL END AS units_sold,  -- New line
        CASE WHEN tags LIKE '%Choices Matter%' THEN rating ELSE NULL END AS rating
    FROM FilteredGames
    
    UNION ALL
    
    SELECT 
		game_classification,
        'Online Co-Op' AS category,
        CASE WHEN tags LIKE '%Online Co-Op%' THEN revenue ELSE NULL END,
        CASE WHEN tags LIKE '%Online Co-Op%' THEN units_sold ELSE NULL END,  -- New line
        CASE WHEN tags LIKE '%Online Co-Op%' THEN rating ELSE NULL END
    FROM FilteredGames
    
    -- Add this pattern to all categories --
    UNION ALL
    SELECT 
		game_classification,
		'Co-op Campaign' AS category, 
        CASE WHEN tags LIKE '%Co-op Campaign%' THEN revenue ELSE NULL END,
        CASE WHEN tags LIKE '%Co-op Campaign%' THEN units_sold ELSE NULL END,
        CASE WHEN tags LIKE '%Co-op Campaign%' THEN rating ELSE NULL END
    FROM FilteredGames
    
    UNION ALL
    -- Co-op Campaign --
    SELECT 
        game_classification,
        'Female Protagonist' AS category,
        CASE WHEN tags LIKE '%Female Protagonist%' THEN revenue END,
        CASE WHEN tags LIKE '%Female Protagonist%' THEN units_sold END,
        CASE WHEN tags LIKE '%Female Protagonist%' THEN rating END
    FROM FilteredGames
) AS pivoted_data 
GROUP BY game_classification, category);


-- NICHE GAMES STUDY BY GAME CLASSIFICATION, WITH REVENUE TRESHOLD --  (rev per game, RPAG, top25% rev treshold) -- GREAT +++ -- 
(WITH FilteredGames AS (
    SELECT 
        genres,
        tags,
        revenue,
        units_sold,
        rating,
        YEAR(released) AS release_year,
        game_classification
    FROM games_tabe
    WHERE rating <> 0 AND revenue <> 0 AND units_sold > 10000 
),

RevenueThresholds AS (
    SELECT 
        game_classification,
        MIN(revenue) AS rev_threshold_25pct
    FROM (
        SELECT 
            game_classification,
            revenue,
            NTILE(4) OVER (
                PARTITION BY game_classification 
                ORDER BY log(revenue) DESC
            ) AS quartile
        FROM FilteredGames
    ) AS quartiled
    WHERE quartile = 1  -- Top 25% group
    GROUP BY game_classification
)

SELECT 
    category, 
    p.game_classification,
    COUNT(p.revenue) AS nb_games_in_genre,
    AVG(p.revenue) AS revenue_per_game,
    (SUM(p.revenue) / (SELECT SUM(revenue) FROM FilteredGames)) /  
    (COUNT(p.revenue) / (SELECT COUNT(*) FROM FilteredGames)) AS RPAG,
    MAX(rt.rev_threshold_25pct) AS rev_threshold_25pct -- Recheck PK y'a ça 
FROM (
    SELECT 
        game_classification,
        'Choices Matter' AS category,
        CASE WHEN tags LIKE '%Choices Matter%' THEN revenue END AS revenue,
        CASE WHEN tags LIKE '%Choices Matter%' THEN units_sold END AS units_sold,
        CASE WHEN tags LIKE '%Choices Matter%' THEN rating END AS rating
    FROM FilteredGames
    
    UNION ALL
    
    SELECT 
        game_classification,
        'Online Co-Op' AS category,
        CASE WHEN tags LIKE '%Online Co-Op%' THEN revenue END,
        CASE WHEN tags LIKE '%Online Co-Op%' THEN units_sold END,
        CASE WHEN tags LIKE '%Online Co-Op%' THEN rating END
    FROM FilteredGames
    
    UNION ALL
    SELECT 
        game_classification,
        'Co-op Campaign' AS category, 
        CASE WHEN tags LIKE '%Co-op Campaign%' THEN revenue END,
        CASE WHEN tags LIKE '%Co-op Campaign%' THEN units_sold END,
        CASE WHEN tags LIKE '%Co-op Campaign%' THEN rating END
    FROM FilteredGames
) AS p
LEFT JOIN RevenueThresholds rt ON p.game_classification = rt.game_classification
GROUP BY p.game_classification, category
HAVING revenue_per_game > rev_threshold_25pct AND RPAG > 1
ORDER BY p.game_classification, category
);

-- SAME BUT FOR MULTI/COOP/SPLIT SCREEN ETC --   Y'a moyen de faire un algo predictif qui classifie all tags et sors les plus niche et profitables -- RPAG tjrs PARMI le groupe classifié -- Définir ce que t'appelles 'niche'
(WITH FilteredGames AS (
    SELECT 
        genres,
        tags,
        revenue,
        units_sold,
        rating,
        YEAR(released) AS release_year,
        game_classification
    FROM games_tabe
    WHERE rating <> 0 AND revenue <> 0 AND  price > 0 AND units_sold > 10000 
),

RevenueThresholds AS (
    SELECT 
        game_classification,
        MIN(revenue) AS rev_threshold_25pct
    FROM (
        SELECT 
            game_classification,
            revenue,
            NTILE(10) OVER (
                PARTITION BY game_classification 
                ORDER BY LOG(revenue) DESC
            ) AS quartile
        FROM FilteredGames
    ) AS quartiled
    WHERE quartile = 1
    GROUP BY game_classification
)

SELECT 
    category, 
    p.game_classification,
    COUNT(p.revenue) AS nb_games_in_genre,
    AVG(p.revenue)/1000000 AS revenue_per_game,
    (SUM(p.revenue) / (SELECT SUM(revenue) FROM FilteredGames)) /  
    (COUNT(p.revenue) / (SELECT COUNT(*) FROM FilteredGames)) AS RPAG,
    MAX(rt.rev_threshold_25pct)/1000000 AS rev_threshold_25pct
FROM (
    -- Co-op --
    SELECT 
        game_classification,
        'Co-op' AS category,
        CASE WHEN tags LIKE '%Co-op%' THEN revenue END AS revenue,
        CASE WHEN tags LIKE '%Co-op%' THEN units_sold END AS units_sold,
        CASE WHEN tags LIKE '%Co-op%' THEN rating END AS rating
    FROM FilteredGames
    
    UNION ALL
    
    -- Split Screen --
    SELECT 
        game_classification,
        'Split Screen' AS category,
        CASE WHEN tags LIKE '%Split Screen%' THEN revenue END,
        CASE WHEN tags LIKE '%Split Screen%' THEN units_sold END,
        CASE WHEN tags LIKE '%Split Screen%' THEN rating END
    FROM FilteredGames
    
    UNION ALL
    
    -- Online Co-Op --
    SELECT 
        game_classification,
        'Online Co-Op' AS category,
        CASE WHEN tags LIKE '%Online Co-Op%' THEN revenue END,
        CASE WHEN tags LIKE '%Online Co-Op%' THEN units_sold END,
        CASE WHEN tags LIKE '%Online Co-Op%' THEN rating END
    FROM FilteredGames
    
    UNION ALL
    
    -- Local Co-Op --
    SELECT 
        game_classification,
        'Local Co-Op' AS category,
        CASE WHEN tags LIKE '%Local Co-Op%' THEN revenue END,
        CASE WHEN tags LIKE '%Local Co-Op%' THEN units_sold END,
        CASE WHEN tags LIKE '%Local Co-Op%' THEN rating END
    FROM FilteredGames
    
    UNION ALL
    
    -- Co-op Campaign --
    SELECT 
        game_classification,
        'Co-op Campaign' AS category,
        CASE WHEN tags LIKE '%Co-op Campaign%' THEN revenue END,
        CASE WHEN tags LIKE '%Co-op Campaign%' THEN units_sold END,
        CASE WHEN tags LIKE '%Co-op Campaign%' THEN rating END
	FROM FilteredGames  
    
    UNION ALL
    
    SELECT 
        game_classification,
        'Life Sim' AS category,
        CASE WHEN tags LIKE '%Life Sim%' THEN revenue END,
        CASE WHEN tags LIKE '%Life Sim%' THEN units_sold END,
        CASE WHEN tags LIKE '%Life Sim%' THEN rating END
	FROM FilteredGames 
    
     UNION ALL
    
    -- Online Co-Op --
    SELECT 
        game_classification,
        'Online Co-Op & PvE' AS category,
        CASE WHEN tags LIKE '%Online Co-Op%' AND tags LIKE '%PvE%' THEN revenue END,
        CASE WHEN tags LIKE '%Online Co-Op%' AND tags LIKE '%PvE%' THEN units_sold END,
        CASE WHEN tags LIKE '%Online Co-Op%' AND tags LIKE '%PvE%' THEN rating END
    FROM FilteredGames
    
) AS p
LEFT JOIN RevenueThresholds rt ON p.game_classification = rt.game_classification
GROUP BY p.game_classification, category
HAVING revenue_per_game > rev_threshold_25pct 
ORDER BY p.game_classification, category);

-- DOES GTA RLY HAS THE IMPACT DEVS ARE SCARED OF ? -- GROUPED MONTHLY -- GREAT 
(WITH formatted_table AS (
  SELECT name, revenue, units_sold,
         DATE_FORMAT(released, '%Y-%m') AS formatted_date,
         YEAR(released) AS formatted_year,
         MONTH(released) AS formatted_month
  FROM games_tabe
),

best_gta AS (
  SELECT *
  FROM formatted_table
  WHERE name LIKE '%Grand theft%' AND revenue > 1000000
  ORDER BY revenue DESC
  LIMIT 3
),

-- Calculate total games released per year
yearly_releases AS (
  SELECT formatted_year, COUNT(name) AS total_games_per_year
  FROM formatted_table
  GROUP BY formatted_year
)

SELECT 
  ft.formatted_date,
  COUNT(ft.name) AS num_games_released,
  -- Normalize by dividing by total games released that year
  (COUNT(ft.name) / yr.total_games_per_year) * 100 AS normalized_count
FROM formatted_table ft
INNER JOIN best_gta bg 
  ON ft.formatted_date = bg.formatted_date OR ft.formatted_month = bg.formatted_month
INNER JOIN yearly_releases yr 
  ON ft.formatted_year = yr.formatted_year
WHERE ft.revenue > 0 AND ft.name NOT LIKE '%Grand theft auto%'
GROUP BY ft.formatted_date, yr.total_games_per_year
HAVING SUBSTRING(ft.formatted_date, 6) = '04');


-- DOES GTA RLY HAS THE IMPACT DEVS ARE SCARED OF ? -- GROUPED WEEKLY -- GREAT -- Check les jeux release le mm jour/semaine que GTA ont perdu financierement par rapp aux autres jeux du mm genre pas release dans cette timeframe 
(WITH formatted_table AS (
  SELECT name, revenue, units_sold,
         DATE_FORMAT(released, '%Y-%m-%d') AS formatted_date,
         YEAR(released) AS formatted_year,
         MONTH(released) AS formatted_month,
         DAY(released) AS formatted_day,
         WEEK(released,1) AS formatted_week
  FROM games_tabe
  WHERE YEAR(released) > 2009
  -- WHERE game_classification = 'AAA'
),

best_gta AS (
  SELECT *
  FROM formatted_table
  WHERE name LIKE '%Grand theft%' AND revenue > 1000000
  ORDER BY revenue DESC
  LIMIT 3
),

-- Calculate total games released per year
yearly_releases AS (
  SELECT formatted_year, COUNT(name) AS total_games_per_year
  FROM formatted_table
  GROUP BY formatted_year
)


SELECT 
  ft.formatted_year, ft.formatted_week,
  COUNT(ft.name) AS num_games_released,
  yr.total_games_per_year AS games_released_year,
  -- Normalize by dividing by total games released that year
  (COUNT(ft.name) / yr.total_games_per_year) * 100 AS normalized_count
FROM formatted_table ft
INNER JOIN best_gta bg 
  ON ft.formatted_week = bg.formatted_week
INNER JOIN yearly_releases yr 
  ON ft.formatted_year = yr.formatted_year
WHERE ft.revenue > 0 AND ft.name NOT LIKE '%Grand theft auto%'
GROUP BY ft.formatted_year, ft.formatted_week, yr.total_games_per_year
HAVING formatted_week = '16');

-- DOES GTA RLY HAS THE IMPACT DEVS ARE SCARED OF ? -- GROUPED MONTHLY AND FOR ACTION ADVENTURE GENRE -- GREAT 
(WITH formatted_table AS (
  SELECT name, revenue, units_sold,
         DATE_FORMAT(released, '%Y-%m') AS formatted_date,
         YEAR(released) AS formatted_year,
         MONTH(released) AS formatted_month
  FROM games_tabe
  WHERE genres LIKE '%Action, Adventure%'  AND YEAR(released) > 2009
),

best_gta AS (
  SELECT *
  FROM formatted_table
  WHERE name LIKE '%Grand theft%' AND revenue > 1000000
  ORDER BY revenue DESC
  LIMIT 3
),

-- Calculate total games released per year
yearly_releases AS (
  SELECT formatted_year, COUNT(name) AS total_games_per_year
  FROM formatted_table
  GROUP BY formatted_year
)

SELECT 
  ft.formatted_date,
  COUNT(ft.name) AS num_games_released,
  -- Normalize by dividing by total games released that year
  (COUNT(ft.name) / yr.total_games_per_year) * 100 AS normalized_count
FROM formatted_table ft
INNER JOIN best_gta bg 
  ON ft.formatted_date = bg.formatted_date OR ft.formatted_month = bg.formatted_month
INNER JOIN yearly_releases yr 
  ON ft.formatted_year = yr.formatted_year
WHERE ft.revenue > 0 AND ft.name NOT LIKE '%Grand theft auto%'
GROUP BY ft.formatted_date, yr.total_games_per_year
HAVING SUBSTRING(ft.formatted_date, 6) = '04');

 -- GTA MARKET SHARE AND REV AND UNITS SOLD IN THE DAY OF RELEASE --

(WITH formatted_table AS (
  SELECT name, revenue, units_sold,
         DATE_FORMAT(released, '%Y-%m-%d') AS formatted_date,
         YEAR(released) AS formatted_year,
         MONTH(released) AS formatted_month,
         DAY(released) AS formatted_day,
         WEEK(released,1) AS formatted_week
  FROM games_tabe
  WHERE YEAR(released) > 2009
  -- WHERE game_classification = 'AAA'
),

best_gta AS (
  SELECT *
  FROM formatted_table
  WHERE name LIKE '%Grand theft%' AND revenue > 1000000
  ORDER BY revenue DESC
  LIMIT 3
)

SELECT ft.formatted_date,
SUM(ft.revenue) AS market_revenue,
COUNT(ft.name) AS nb_games_released,
SUM(ft.units_sold) AS market_tot_units_sold,
bg.revenue  / SUM(ft.revenue) *100 as GTA_rev_market_share,
bg.units_sold  / SUM(ft.units_sold) *100 as GTA_units_market_share
FROM formatted_table ft
INNER JOIN best_gta bg
ON ft.formatted_date = bg.formatted_date 
GROUP BY ft.formatted_date, bg.revenue, bg.units_sold );


 -- GTA MARKET SHARE AND REV AND UNITS SOLD IN THE WEEK OF RELEASE --

(WITH formatted_table AS (
  SELECT name, revenue, units_sold,
         DATE_FORMAT(released, '%Y-%m-%d') AS formatted_date,
         YEAR(released) AS formatted_year,
         MONTH(released) AS formatted_month,
         DAY(released) AS formatted_day,
         WEEK(released,1) AS formatted_week
  FROM games_tabe
  WHERE YEAR(released) > 2009
  -- WHERE game_classification = 'AAA'
),

best_gta AS (
  SELECT *
  FROM formatted_table
  WHERE name LIKE '%Grand theft%' AND revenue > 1000000
  ORDER BY revenue DESC
  LIMIT 3
)

SELECT ft.formatted_year, ft.formatted_week,
SUM(ft.revenue) AS market_revenue,
COUNT(ft.name) AS nb_games_released,
SUM(ft.units_sold) AS market_tot_units_sold,
bg.revenue  / SUM(ft.revenue) *100 as GTA_rev_market_share,
bg.units_sold  / SUM(ft.units_sold) *100 as GTA_units_market_share
FROM formatted_table ft
INNER JOIN best_gta bg
ON ft.formatted_year = bg.formatted_year AND ft.formatted_week = bg.formatted_week
GROUP BY ft.formatted_year, ft.formatted_week, bg.revenue, bg.units_sold);



 -- GTA MARKET SHARE AND REV AND UNITS SOLD IN THE MONTH OF RELEASE -- Maybe + d'argent sur ce mois uassi du fait de gta ?


(WITH formatted_table AS (
  SELECT name, revenue, units_sold,
         DATE_FORMAT(released, '%Y-%m-%d') AS formatted_date,
         YEAR(released) AS formatted_year,
         MONTH(released) AS formatted_month,
         DAY(released) AS formatted_day,
         WEEK(released,1) AS formatted_week
  FROM games_tabe
  WHERE YEAR(released) > 2009
  
),

best_gta AS (
  SELECT *
  FROM formatted_table
  WHERE name LIKE '%Grand theft%' AND revenue > 1000000
  ORDER BY revenue DESC
  LIMIT 3
)

SELECT ft.formatted_year, ft.formatted_month,
SUM(ft.revenue) AS market_revenue,
COUNT(ft.name) AS nb_games_released,
SUM(ft.units_sold) AS market_tot_units_sold,
bg.revenue  / SUM(ft.revenue) *100 as GTA_rev_market_share,
bg.units_sold  / SUM(ft.units_sold) *100 as GTA_units_market_share
FROM formatted_table ft
INNER JOIN best_gta bg
ON ft.formatted_year = bg.formatted_year AND ft.formatted_month = bg.formatted_month
GROUP BY ft.formatted_year, ft.formatted_month, bg.revenue, bg.units_sold);

 

SET SQL_MODE='TRADITIONAL,ALLOW_INVALID_DATES, ONLY_FULL_GROUP_BY';
