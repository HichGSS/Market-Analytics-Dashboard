CREATE TABLE completion_time (
    id INT,
    name TEXT,
    PC_Polled DOUBLE,
    PC_Main DOUBLE,
    PC_Main_extras DOUBLE,
    PC_100 DOUBLE,
    PC_Fastest DOUBLE,
    PC_Slowest DOUBLE,
    platform TEXT
);


LOAD DATA LOCAL INFILE 'C:/Users/Hicham/Desktop/Data Analytics/PROJECTS/Power Bi dashboard/completion_time_info.csv'
INTO TABLE completion_time
FIELDS TERMINATED BY ',' 
OPTIONALLY ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 LINES;


CREATE TABLE player_volume_info (
	index_id INT,
    app_id INT,
    game_name TEXT,
    month TEXT,
    avg_players DOUBLE,
    gain DOUBLE,
    percent_gain DOUBLE,
    peak_players DOUBLE
);

LOAD DATA LOCAL INFILE 'C:/Users/Hicham/Desktop/Data Analytics/PROJECTS/Power Bi dashboard/player_volume_info.csv'
INTO TABLE player_volume_info
FIELDS TERMINATED BY ',' 
OPTIONALLY ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

CREATE TABLE completion_time2 (
	name TEXT,
    PC_Polled DOUBLE,
    PC_Main DOUBLE,
    PC_Main_extras DOUBLE,
    PC_100 DOUBLE,
    PC_Fastest DOUBLE,
    PC_Slowest DOUBLE,
    platform DOUBLE,
    release_date DATETIME
    );
    
    SHOW VARIABLES LIKE 'secure_file_priv';
    
LOAD DATA LOCAL INFILE 'C:/Users/Hicham/Desktop/Data Analytics/PROJECTS/Power Bi dashboard/Tables/pc_games_with_date.csv'
INTO TABLE completion_time2
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

CREATE TABLE developer_stats_vg (
	id INT,
    vgi_id DOUBLE,
    name TEXT,
    slug TEXT,
    type DOUBLE,
    games_developed DOUBLE,
    games_released DOUBLE,
    games_unreleased DOUBLE,
    revenue_sum DOUBLE,
    revenue_median DOUBLE,
    revenue_avg DOUBLE, 
    self_published INT,
    indie  INT,
    action INT,
    casual INT,
    adventure INT,
    simulation INT,
    strategy INT,
    rpg INT,
    mmo INT,
    racing INT,
    sports INT,
    country_name TEXT
    );
    
LOAD DATA LOCAL INFILE 'C:/Users/Hicham/Desktop/Data Analytics/PROJECTS/Power Bi dashboard/Tables/developers_genres_group_1.csv'
INTO TABLE developer_stats_vg
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;
