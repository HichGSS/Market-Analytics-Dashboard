SELECT *,
count(*) as dup_count 
FROM dev_stats ds
LEFT JOIN dev_id_mapping dm
ON ds.developers = dm.developers
GROUP BY dm.dev_id 
HAVING dup_count > 1;

ALTER TABLE developer_stats_vg
ADD COLUMN dev_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY;
    
CREATE TABLE developer_lookup2 AS(
SELECT name, dev_id, type
FROM developer_stats_vg
);
    
CREATE TABLE developer_stats AS(
SELECT *
FROM developer_stats_vg
);    
    
Mettre le dev id 
Update developer lookup
Update games_lookup et enlever la colonne released
Update steam_sales et mettre la colonne released 
Update dev_stats 
Refaire le data model and u good to go ;
  


CREATE TABLE full_steam_stats3 AS(  
SELECT  gt.* , dl.dev_id 
FROM games_tabe gt 
LEFT JOIN developer_lookup dl 
ON gt.developers = dl.name
);

SELECT gt.* , dl.dev_id
FROM games_tabe gt 
LEFT JOIN developer_lookup dl 
ON gt.developers = dl.name