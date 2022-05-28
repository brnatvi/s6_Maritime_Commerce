
DROP DATABASE IF EXISTS test;
CREATE DATABASE test;

\connect test


DROP TABLE IF EXISTS step cascade;
DROP TABLE IF EXISTS travel cascade;
DROP TABLE IF EXISTS distances_ports cascade;
DROP TABLE IF EXISTS port cascade;
DROP TABLE IF EXISTS continent cascade;


CREATE TABLE continent (
    id_continent SERIAL PRIMARY KEY,    
    name_continent VARCHAR(20) NOT NULL UNIQUE
);

CREATE TABLE port (
    id_port SERIAL PRIMARY KEY,
    id_continent INT,
    FOREIGN KEY (id_continent) REFERENCES continent (id_continent)    
);

CREATE TABLE distances_ports (
    id_port1 INT,
    id_port2 INT,
    distance INT CHECK (distance > 0), 
    FOREIGN KEY (id_port1) REFERENCES port (id_port),
    FOREIGN KEY (id_port2) REFERENCES port (id_port)
);


CREATE TABLE travel (
    id_travel INT UNIQUE NOT NULL,
    class VARCHAR(20) CHECK (class IN ('Europe', 'Asia', 'Africa', 'Intercontinental')),
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
    FOREIGN KEY (id_port) REFERENCES port (id_port) ,
    FOREIGN KEY (id_travel) REFERENCES travel (id_travel),
    CONSTRAINT respect_date CHECK (date_arrival <= date_departure) 
);


INSERT INTO continent VALUES (1, 'Europe');
INSERT INTO continent VALUES (2, 'Asia');
INSERT INTO continent VALUES (3, 'Africa');

INSERT INTO port (id_continent) VALUES (1);
INSERT INTO port (id_continent) VALUES (1);
INSERT INTO port (id_continent) VALUES (1);
INSERT INTO port (id_continent) VALUES (2);
INSERT INTO port (id_continent) VALUES (1);
INSERT INTO port (id_continent) VALUES (3);
INSERT INTO port (id_continent) VALUES (3);

INSERT INTO distances_ports VALUES (1, 2, 15);
INSERT INTO distances_ports VALUES (1, 3, 21);
INSERT INTO distances_ports VALUES (1, 4, 32);
INSERT INTO distances_ports VALUES (1, 5, 19);
INSERT INTO distances_ports VALUES (1, 6, 12);
INSERT INTO distances_ports VALUES (1, 7, 5);
INSERT INTO distances_ports VALUES (2, 3, 32);
INSERT INTO distances_ports VALUES (2, 4, 12);
INSERT INTO distances_ports VALUES (2, 5, 32);
INSERT INTO distances_ports VALUES (2, 6, 18);
INSERT INTO distances_ports VALUES (2, 7, 21);
INSERT INTO distances_ports VALUES (3, 4, 21);
INSERT INTO distances_ports VALUES (3, 5, 23);
INSERT INTO distances_ports VALUES (3, 6, 13);
INSERT INTO distances_ports VALUES (3, 7, 17);
INSERT INTO distances_ports VALUES (4, 5, 22);
INSERT INTO distances_ports VALUES (4, 6, 34);
INSERT INTO distances_ports VALUES (4, 7, 16);
INSERT INTO distances_ports VALUES (5, 6, 45);
INSERT INTO distances_ports VALUES (5, 7, 43);
INSERT INTO distances_ports VALUES (6, 7, 12);


INSERT INTO travel (id_travel) VALUES (1);
INSERT INTO travel (id_travel) VALUES (2);
INSERT INTO travel (id_travel) VALUES (3);


INSERT INTO step(id_travel, id_port, visiting_order, date_arrival, date_departure) VALUES (1, 1, 0, null, '2021-01-12');
INSERT INTO step(id_travel, id_port, visiting_order, date_arrival, date_departure) VALUES (1, 2, 1, '2021-05-20', '2021-05-22');
INSERT INTO step(id_travel, id_port, visiting_order, date_arrival, date_departure) VALUES (1, 3, 2, '2021-07-27', null);
INSERT INTO step(id_travel, id_port, visiting_order, date_arrival, date_departure) VALUES (2, 4, 0, null, '2021-02-13');
INSERT INTO step(id_travel, id_port, visiting_order, date_arrival, date_departure) VALUES (2, 5, 1, '2021-02-27', null);
INSERT INTO step(id_travel, id_port, visiting_order, date_arrival, date_departure) VALUES (3, 7, 0, null, '2022-01-12');
INSERT INTO step(id_travel, id_port, visiting_order, date_arrival, date_departure) VALUES (3, 6, 1, '2022-05-27', null);


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

UPDATE travel SET tr_type = 'court' FROM (SELECT * FROM view_total_dist_trips) AS B(id1, sum1) WHERE (id_travel = B.id1 AND B.sum1 < 30);
UPDATE travel SET tr_type = 'medium' FROM (SELECT * FROM view_total_dist_trips) AS B(id1, sum1) WHERE (id_travel = B.id1 AND B.sum1 >= 30 AND B.sum1 <= 40);
UPDATE travel SET tr_type = 'long' FROM (SELECT * FROM view_total_dist_trips) AS B(id1, sum1) WHERE (id_travel = B.id1 AND B.sum1 > 40);

/*=============================================================================*/


CREATE OR REPLACE VIEW view_travel_dep_arr AS 
(
    SELECT id_travel, min(date_departure) AS date_departure, max(date_arrival) AS date_arrival
    FROM step GROUP BY id_travel ORDER BY id_travel
);

UPDATE travel SET date_departure = A.dates FROM (SELECT id_travel, date_departure FROM view_travel_dep_arr) AS A(id, dates) WHERE (id_travel = A.id);
UPDATE travel SET date_arrival = A.dates FROM (SELECT id_travel, date_arrival FROM view_travel_dep_arr) AS A(id, dates) WHERE (id_travel = A.id);
