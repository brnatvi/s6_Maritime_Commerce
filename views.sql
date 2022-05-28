
/* \dv to see views */

/* ================================ only departure and arrival dates for each steps ====================================== */
CREATE OR REPLACE VIEW view_travel_dep_arr AS 
(
    SELECT id_travel, min(date_departure) AS date_departure, max(date_arrival) AS date_arrival 
    FROM step GROUP BY id_travel ORDER BY id_travel;
);

/* Set attributes date_departure et date_arrival in table travel */
UPDATE travel SET date_departure = A.dates FROM (SELECT id_travel, date_departure FROM view_travel_dep_arr) AS A(id, dates) WHERE (id_travel = A.id);
UPDATE travel SET date_arrival = A.dates FROM (SELECT id_travel, date_arrival FROM view_travel_dep_arr) AS A(id, dates) WHERE (id_travel = A.id);

/* ======================================= IMPORTANT : distances + reverse distances ======================================== */
CREATE OR REPLACE VIEW view_distances AS 
(
    SELECT * FROM distances_ports 
    UNION 
    SELECT id_port2 as id_port1, id_port1 AS id_port2, distance FROM distances_ports);

/* ======================================= IMPORTANT : relations + reverse relations ======================================== */
CREATE OR REPLACE VIEW view_relations AS 
(
    SELECT * FROM country_relations 
    UNION 
    SELECT id_country2 AS id_country1, id_country1 AS id_country2, relation FROM country_relations
);

/* ======================================= IMPORTANT : distances of etaps =================================================== */
CREATE OR REPLACE VIEW view_distances_etaps AS 
(
    SELECT id_travel, p1.id_port AS port1, p2.id_port AS port2, d.distance 
    FROM step p1 JOIN step p2 USING (id_travel) LEFT JOIN view_distances d ON d.id_port1 = p1.id_port AND d.id_port2 = p2.id_port 
    WHERE  p2.visiting_order = p1.visiting_order + 1 
    ORDER BY id_travel, p1.visiting_order
);

/* ======================================= BEGIN definition of tr_type for travel =================================================== */
CREATE OR REPLACE VIEW view_total_dist_trips AS 
(
    SELECT id_travel, sum(distance) FROM view_distances_etaps GROUP BY id_travel
);

/* Set attribute tr_type in table travel */
UPDATE travel SET tr_type = 'court' FROM (SELECT * FROM view_total_dist_trips) AS B(id1, sum1) WHERE (id_travel = B.id1 AND B.sum1 < 1000);
UPDATE travel SET tr_type = 'medium' FROM (SELECT * FROM view_total_dist_trips) AS B(id1, sum1) WHERE (id_travel = B.id1 AND B.sum1 >= 1000 AND B.sum1 <= 2000);
UPDATE travel SET tr_type = 'long' FROM (SELECT * FROM view_total_dist_trips) AS B(id1, sum1) WHERE (id_travel = B.id1 AND B.sum1 > 2000);
/* ======================================= END definition of tr_type for travel =================================================== */


/* ======================== Duration of trip etap by etap =====================================================*/
/*
 CREATE VIEW view_total_distances AS (SELECT id_travel, SUM(distance) AS total_distance) FROM view_distances_etaps GROUP BY id_travel);  */

/*	La durée d’un voyage est définie par : vitesse_navire * SUM ALL ( distances intermédiaires de son voyage) / ( 0.5*SUM ALL(poids_produit)).*/

/*===================================== BEGIN definition of class for travel ====================================================*/
/* continent for each step*/
CREATE OR REPLACE VIEW view_continents_steps AS 
(
    SELECT step.id_travel, port.id_port, continent.id_continent, visiting_order FROM continent 
    NATURAL JOIN port 
    JOIN step ON port.id_port = step.id_port
);

CREATE OR REPLACE VIEW view_nb_continents_diff AS 
(
    SELECT id_travel, COUNT(DISTINCT id_continent) AS nb_cont 
    FROM view_continents_steps 
    GROUP BY id_travel
);

/* id_travel and class */
CREATE OR REPLACE VIEW view_idTravel_class AS 
(
    SELECT step.id_travel, name_continent AS travel_class 
    FROM view_nb_continents_diff 
    NATURAL JOIN step 
    NATURAL JOIN port 
    NATURAL JOIN continent
);

CREATE OR REPLACE VIEW new_view AS 
(
    SELECT id_travel, travel_class, count(*) AS nb_steps FROM view_idTravel_class 
    GROUP BY id_travel, travel_class 
);

/* Set attribute class in table travel */
/*====================================== IMPORTANT only national travels =========================================================*/
CREATE OR REPLACE VIEW view_not_intercontinental AS
WITH nonDuplicatedValues AS (
        SELECT id_travel, COUNT(id_travel) AS CNT
        FROM new_view
        GROUP BY id_travel
        HAVING COUNT(id_travel) = 1
   )
   SELECT id_travel, travel_class
   FROM new_view
   WHERE id_travel IN (SELECT id_travel FROM nonDuplicatedValues)
   ORDER BY id_travel, travel_class;

UPDATE travel SET class = A.newVal2 FROM (SELECT id_travel, travel_class FROM view_not_intercontinental) AS A(newVal1, newVal2) 
WHERE id_travel = A.newVal1;

UPDATE travel SET class = 'Intercontinental' WHERE class IS NULL;
/*====================================== END definition of class for travel ====================================================*/


