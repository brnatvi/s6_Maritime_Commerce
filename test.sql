
DROP DATABASE IF EXISTS test;
CREATE DATABASE test;

\connect test

DROP TABLE IF EXISTS cargo_port cascade;
DROP TABLE IF EXISTS cargo_step cascade;
DROP TABLE IF EXISTS step cascade;
DROP TABLE IF EXISTS travel cascade;
DROP TABLE IF EXISTS product cascade;

DROP TABLE IF EXISTS ship cascade;
DROP TABLE IF EXISTS type_ship cascade;
DROP TABLE IF EXISTS country_relations cascade;
DROP TABLE IF EXISTS country cascade; 
DROP TABLE IF EXISTS continent cascade;
DROP TABLE IF EXISTS distances_ports cascade;
DROP TABLE IF EXISTS port cascade;


CREATE TABLE continent (
    id_continent SERIAL PRIMARY KEY,    
    name_continent VARCHAR(20) NOT NULL UNIQUE
);

CREATE TABLE country (
    id_country SERIAL PRIMARY KEY,    
    name_country VARCHAR(20) NOT NULL UNIQUE   
);

CREATE TABLE country_relations (
    id_country1 INT,
    id_country2 INT,
    relation VARCHAR(50) CHECK (relation IN ('ally commercial', 'ally', 'neutral', 'belligerent')),
    PRIMARY KEY (id_country1, id_country2),
    FOREIGN KEY (id_country1) REFERENCES country (id_country),
    FOREIGN KEY (id_country2) REFERENCES country (id_country)   
);

CREATE TABLE port (
    id_port SERIAL PRIMARY KEY,
    name_port VARCHAR(50) UNIQUE NOT NULL,
    category_port INT CHECK (category_port >= 1 AND category_port <= 5),
    id_continent INT,
    nationality INT,    
    FOREIGN KEY (id_continent) REFERENCES continent (id_continent),
    FOREIGN KEY (nationality) REFERENCES country (id_country)
);

CREATE TABLE distances_ports (
    id_port1 INT,
    id_port2 INT,
    distance INT CHECK (distance > 0),    
    FOREIGN KEY (id_port1) REFERENCES port (id_port),
    FOREIGN KEY (id_port2) REFERENCES port (id_port)
);

CREATE TABLE type_ship (
    id_type SERIAL PRIMARY KEY,   
    name_type VARCHAR(20),
    category_ship INT CHECK (category_ship >= 1 AND category_ship <= 5),
    speed NUMERIC(4,1) CHECK (speed > 0)
);

CREATE TABLE ship (
    id_ship SERIAL PRIMARY KEY,
    name_ship VARCHAR(50),
    id_type INT,
    nationality INT,
    volume_hold INT NOT NULL CHECK (volume_hold > 0),
    nb_places_passagers INT CHECK (nb_places_passagers >= 0) DEFAULT 0,  
    localisation NUMERIC(20,10),
    FOREIGN KEY (id_type) REFERENCES type_ship (id_type),
    FOREIGN KEY (nationality) REFERENCES country (id_country)
);

CREATE TABLE product (
    id_product SERIAL PRIMARY KEY,   
    name_product VARCHAR(20),
    is_dry BOOLEAN,    
    volume_product NUMERIC(7,3) CHECK (volume_product > 0),    /* volume for 1 unity */
    weight_product NUMERIC(7,3) CHECK (weight_product > 0)     /* weight for 1 unity */
);


CREATE TABLE travel (
    id_travel INT UNIQUE NOT NULL,
    id_ship INT,
    class VARCHAR(20) CHECK (class IN ('Europe', 'America', 'Asia', 'Africa', 'Intercontinental')),
    tr_type VARCHAR(20) CHECK (tr_type IN ('court', 'medium', 'long')),    
    date_departure DATE,
    date_arrival DATE
);


CREATE TABLE step (
    id_step SERIAL PRIMARY KEY,
    id_travel INT,
    id_port INT,
    visiting_order INT CHECK (visiting_order >= 0),
    date_arrival DATE,
    date_departure DATE,   
    FOREIGN KEY (id_travel) REFERENCES travel (id_travel),
    FOREIGN KEY (id_port) REFERENCES port (id_port),
    CONSTRAINT respect_date CHECK (date_arrival <= date_departure)  
);


CREATE TABLE cargo_step (    
    id_step INT,
    id_product INT,
    load_unload VARCHAR(10) CHECK (load_unload IN ('load', 'unload')),
    quantity INT,
    FOREIGN KEY (id_product) REFERENCES product (id_product),
    FOREIGN KEY (id_step) REFERENCES step (id_step)
);


CREATE TABLE cargo_port (    
    id_port INT,
    id_product INT,      
    quantity INT,                                                                       /* number of unities of product */
    FOREIGN KEY (id_product) REFERENCES product (id_product),
    FOREIGN KEY (id_port) REFERENCES port (id_port)
);


\i uploads.sql

/* ======================================= IMPORTANT : distances + reverse distances ======================================== */
CREATE OR REPLACE VIEW view_distances AS 
(
    SELECT * FROM distances_ports 
    UNION 
    SELECT id_port2 as id_port1, id_port1 AS id_port2, distance FROM distances_ports);

/* ======================================= IMPORTANT : distances of etaps =================================================== */
CREATE OR REPLACE VIEW view_distances_etaps AS 
(
    SELECT id_travel, p1.id_port AS port1, p2.id_port AS port2, d.distance 
    FROM step p1 JOIN step p2 USING (id_travel) LEFT JOIN view_distances d ON d.id_port1 = p1.id_port AND d.id_port2 = p2.id_port 
    WHERE  p2.visiting_order = p1.visiting_order + 1 
    ORDER BY id_travel, p1.visiting_order
);

/*=============================================================================*/
CREATE OR REPLACE VIEW view_continents_steps AS (SELECT step.id_travel, port.id_port, continent.id_continent FROM continent NATURAL JOIN port JOIN step ON port.id_port = step.id_port);

CREATE OR REPLACE VIEW view_nb_continents_diff AS SELECT id_travel, COUNT(DISTINCT id_continent) AS nb_cont FROM view_continents_steps GROUP BY id_travel;

CREATE OR REPLACE VIEW view_idTravel_class AS (SELECT step.id_travel, name_continent AS travel_class FROM view_nb_continents_diff NATURAL JOIN step NATURAL JOIN port NATURAL JOIN continent);

CREATE OR REPLACE VIEW new_view AS (SELECT id_travel, travel_class, count(*) AS nb_steps FROM view_idTravel_class GROUP BY id_travel, travel_class );

CREATE OR REPLACE VIEW not_intercontinental AS
WITH DuplicatedValues AS (
        SELECT id_travel, COUNT(id_travel) AS CNT
        FROM new_view
        GROUP BY id_travel
        HAVING COUNT(id_travel) = 1
   )
   SELECT id_travel, travel_class
   FROM new_view
   WHERE id_travel IN (SELECT id_travel FROM DuplicatedValues)
   ORDER BY id_travel, travel_class;


UPDATE travel SET class = A.newVal2 FROM (SELECT id_travel, travel_class FROM not_intercontinental) AS A(newVal1, newVal2) WHERE id_travel = A.newVal1;
UPDATE travel SET class = 'Intercontinental' WHERE class IS NULL;
/*=============================================================================*/

CREATE OR REPLACE VIEW view_total_dist_trips AS 
(
    SELECT id_travel, sum(distance) FROM view_distances_etaps GROUP BY id_travel
);

UPDATE travel SET tr_type = 'court' FROM (SELECT * FROM view_total_dist_trips) AS B(id1, sum1) WHERE (id_travel = B.id1 AND B.sum1 < 1000);
UPDATE travel SET tr_type = 'medium' FROM (SELECT * FROM view_total_dist_trips) AS B(id1, sum1) WHERE (id_travel = B.id1 AND B.sum1 >= 1000 AND B.sum1 <= 2000);
UPDATE travel SET tr_type = 'long' FROM (SELECT * FROM view_total_dist_trips) AS B(id1, sum1) WHERE (id_travel = B.id1 AND B.sum1 > 2000);

/*=============================================================================*/

CREATE OR REPLACE VIEW view_travel_dep_arr AS 
(
    SELECT id_travel, min(date_departure) AS date_departure, max(date_arrival) AS date_arrival
    FROM step GROUP BY id_travel ORDER BY id_travel
);

UPDATE travel SET date_departure = A.dates FROM (SELECT id_travel, date_departure FROM view_travel_dep_arr) AS A(id, dates) WHERE (id_travel = A.id);
UPDATE travel SET date_arrival = A.dates FROM (SELECT id_travel, date_arrival FROM view_travel_dep_arr) AS A(id, dates) WHERE (id_travel = A.id);



/*============================================= IMPORTANT data about each ship ============================================================================ */
CREATE OR REPLACE VIEW view_data_ships AS 
(
    SELECT id_ship, name_ship, speed, category_ship FROM ship NATURAL JOIN type_ship
);



/* ============================================= cargo_step calculations ======================================================================== */
CREATE OR REPLACE VIEW view_etaps_load_unload AS 
(
    SELECT S.id_step, S.id_travel, S.id_port, S.visiting_order, S.date_arrival, S.date_departure, CS.id_product, CS.load_unload, CS.quantity FROM step S LEFT JOIN cargo_step CS ON CS.id_step = S.id_step
);
/*========================================== IMPORTANT quantity load and unload for each step =================================================== */

CREATE OR REPLACE VIEW view_etaps_quantity_load_unload AS 
(
SELECT c1.id_step, c1.id_travel, c1.id_port, c1.visiting_order, c1.date_arrival, c1.date_departure, c1.id_product, c1.quantity AS quantity_load, c2.quantity AS quantity_unload FROM view_etaps_load_unload c1 LEFT JOIN view_etaps_load_unload c2 ON (c1.id_product = c2.id_product AND c1.id_step = c2.id_step AND c1.quantity <> c2.quantity) WHERE c1.load_unload = 'load' ORDER BY c1.id_travel, c1.id_step
);

CREATE OR REPLACE VIEW view1 AS 
(
SELECT id_step, id_travel, id_port, visiting_order, date_arrival, date_departure, id_product, (quantity_load - COALESCE(quantity_unload, 0)) AS quantity_added_on 
FROM view_etaps_quantity_load_unload
);

SELECT id_step, id_product, sum(quantity_added_on) FROM view1 GROUP BY id_step, id_product;



/*==================================== IMPORTANT possibles and preferables destinations ==================================================*/
CREATE OR REPLACE VIEW view_not_between_belligerent AS
(
    SELECT DISTINCT CR1.id_country1, CR2.id_country2, CR1.relation, p1.id_port AS id_port1, p1.name_port AS name_port1, p2.id_port AS id_port2, p2.name_port AS name_port2, d.distance
    FROM country_relations CR1 
    JOIN country_relations CR2 USING (id_country2) 
    LEFT JOIN port p1 ON (CR1.id_country1 = p1.nationality) 
    LEFT JOIN port p2 ON (CR2.id_country2 = p2.nationality) 
    LEFT JOIN view_distances d ON (p1.id_port = d.id_port1 AND p2.id_port = d.id_port2)
    WHERE CR1.relation <> 'belligerent'  AND p1.id_port <> p2.id_port
    ORDER BY CR1.id_country1
);

SELECT * FROM view_not_between_belligerent WHERE relation = 'ally commercial';


CREATE OR REPLACE VIEW view_preferences_ally_commercial AS
(
    SELECT DISTINCT CR1.id_country1, CR2.id_country2, CR1.relation, p1.id_port AS id_port1, p1.name_port AS name_port1, p2.id_port AS id_port2, p2.name_port AS name_port2, d.distance
    FROM country_relations CR1 
    JOIN country_relations CR2 USING (id_country1) 
    LEFT JOIN port p1 ON (CR1.id_country1 = p1.nationality) 
    LEFT JOIN port p2 ON (CR2.id_country2 = p2.nationality) 
    LEFT JOIN view_distances d ON (p1.id_port = d.id_port1 AND p2.id_port = d.id_port2)
    WHERE CR1.relation = 'ally commercial' AND p1.id_port <> p2.id_port
    ORDER BY CR1.id_country1
);


/*	La dur??e d???un voyage est d??finie par : vitesse_navire * SUM ALL ( distances interm??diaires de son voyage) / ( 0.5*SUM ALL(poids_produit)).*/


/*
\COPY continent(id_continent, name_continent) FROM 'csv/continent.csv' (DELIMITER ',', FORMAT CSV);
\COPY country(id_country, name_country) FROM 'csv/country.csv' (DELIMITER ',', FORMAT CSV);
\COPY type_ship(id_type, name_type, category_ship, speed) FROM 'csv/category_ship.csv' (DELIMITER ',', FORMAT CSV);
\COPY port(id_port, name_port, category_port, id_continent, nationality) FROM 'csv/port.csv' (DELIMITER ',', FORMAT CSV);
\COPY country_relations(id_country1, id_country2, relation) FROM 'csv/country_relations.csv' (DELIMITER ',', FORMAT CSV);
\COPY distances_ports(id_port1, id_port2, distance) FROM 'csv/distances.csv' (DELIMITER ',', FORMAT CSV);



\COPY product(id_product, name_product, is_dry, volume_product, weight_product) FROM 'csv/product.csv' (DELIMITER ',', FORMAT CSV);
\COPY ship (id_ship, name_ship, id_type, nationality, volume_hold, nb_places_passagers, localisation) FROM 'csv/ship.csv' (DELIMITER ',', FORMAT CSV);
\COPY cargo_port(id_port, id_product, quantity)  FROM 'csv/cargo_port.csv' (DELIMITER ',', FORMAT CSV);



INSERT INTO travel (id_travel, id_ship) VALUES (1, 2);
INSERT INTO travel (id_travel, id_ship) VALUES (2, 1);
INSERT INTO travel (id_travel, id_ship) VALUES (3, 1);

INSERT INTO step(id_travel, id_port, visiting_order, date_arrival, date_departure) VALUES (1, 1, 0, null, '2021-01-12');
INSERT INTO step(id_travel, id_port, visiting_order, date_arrival, date_departure) VALUES (1, 2, 1, '2021-05-20', '2021-05-22');
INSERT INTO step(id_travel, id_port, visiting_order, date_arrival, date_departure) VALUES (1, 3, 2, '2021-07-27', null);
INSERT INTO step(id_travel, id_port, visiting_order, date_arrival, date_departure) VALUES (2, 4, 0, null, '2021-02-13');
INSERT INTO step(id_travel, id_port, visiting_order, date_arrival, date_departure) VALUES (2, 5, 1, '2021-02-27', null);
INSERT INTO step(id_travel, id_port, visiting_order, date_arrival, date_departure) VALUES (3, 7, 0, null, '2022-01-12');
INSERT INTO step(id_travel, id_port, visiting_order, date_arrival, date_departure) VALUES (3, 6, 1, '2022-05-27', null);



INSERT INTO cargo_step VALUES (1, 10, 'load', 30);
INSERT INTO cargo_step VALUES (1, 10, 'unload', 10);
INSERT INTO cargo_step VALUES (1, 3, 'load', 30);
INSERT INTO cargo_step VALUES (1, 7, 'unload', 3);
INSERT INTO cargo_step VALUES (1, 9, 'load', 20);
INSERT INTO cargo_step VALUES (1, 9, 'unload', 8);
INSERT INTO cargo_step VALUES (2, 10, 'load', 30);
INSERT INTO cargo_step VALUES (2, 10, 'unload', 10);
INSERT INTO cargo_step VALUES (2, 3, 'load', 10);
INSERT INTO cargo_step VALUES (2, 7, 'unload', 3);
INSERT INTO cargo_step VALUES (3, 10, 'unload', 30);
INSERT INTO cargo_step VALUES (3, 10, 'load', 10);
INSERT INTO cargo_step VALUES (3, 3, 'unload', 10);
INSERT INTO cargo_step VALUES (3, 7, 'load', 3);

*/
