
/* \dv to see views */

/* only departure and arrival dates for each steps */
CREATE OR REPLACE VIEW view_travel_dep_arr AS 
(
    SELECT step.id_travel AS id_travel, id_ship, date_departure, date_arrival, visiting_order 
    FROM step, travel 
    WHERE step.id_travel = travel.id_travel AND (visiting_order = 0 OR visiting_order = 
    (
        SELECT MAX(visiting_order) FROM step)
    ) 
    ORDER BY id_travel, visiting_order
);

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
    FROM step p1 JOIN step p2 USING (id_travel) LEFT JOIN distances_ports d ON d.id_port1 = p1.id_port AND d.id_port2 = p2.id_port 
    WHERE  p2.visiting_order = p1.visiting_order + 1 
    ORDER BY id_travel, p1.visiting_order
);


/* duration of trip etap by etap */
/* CREATE VIEW duration_vue AS (SELECT id_travel, (() AS duration) FROM distances_ports);  */



/*===================================== IMPORTANT : definition of eClassTravel for travel ====================================================*/
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

/* id_travel and eClassTravel */
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

/* Set attribute eClassTravel in table travel */
CREATE OR REPLACE VIEW view_not_intercontinental AS
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

UPDATE travel SET class = A.newVal2 FROM (SELECT id_travel, travel_class FROM view_not_intercontinental) AS A(newVal1, newVal2) 
WHERE id_travel = A.newVal1;

UPDATE travel SET class = 'Intercontinental' WHERE class IS NULL;
/*==========================================================================================*/