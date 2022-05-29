
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


/*==================================== IMPORTANT possibles and preferables destinations ==================================================*/
CREATE OR REPLACE VIEW view_not_between_belligerent AS
(
    SELECT DISTINCT CR1.id_country1, CR2.id_country2, CR1.relation, p1.id_port AS id_port1, p1.name_port AS name_port1, p2.id_port AS id_port2, p2.name_port AS name_port2, d.distance
    FROM country_relations CR1 
    JOIN country_relations CR2 USING (id_country1) 
    LEFT JOIN port p1 ON (CR1.id_country1 = p1.nationality) 
    LEFT JOIN port p2 ON (CR2.id_country2 = p2.nationality) 
    LEFT JOIN view_distances d ON (p1.id_port = d.id_port1 AND p2.id_port = d.id_port2)
    WHERE CR1.relation <> 'belligerent' AND p1.id_port <> p2.id_port
    ORDER BY CR1.id_country1
);

CREATE OR REPLACE VIEW view_preferences_ally_commercial AS
(
    SELECT DISTINCT CR1.id_country1, CR2.id_country2, CR1.relation, p1.id_port AS id_port1, p1.name_port AS name_port1, p2.id_port AS id_port2, p2.name_port AS name_port2, d.distance
    FROM country_relations CR1 
    JOIN country_relations CR2 USING (id_country2) 
    LEFT JOIN port p1 ON (CR1.id_country1 = p1.nationality) 
    LEFT JOIN port p2 ON (CR2.id_country2 = p2.nationality) 
    LEFT JOIN view_distances d ON (p1.id_port = d.id_port1 AND p2.id_port = d.id_port2)
    WHERE CR1.relation = 'ally commercial'
    ORDER BY CR1.id_country1
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


/* ========================================== Duration of trip etap by etap =====================================================*/

CREATE VIEW view_total_distances AS 
(
    SELECT id_travel, SUM(distance) AS total_distance FROM view_distances_etaps 
    GROUP BY id_travel
);
/*	La durée d’un voyage est définie par : vitesse_navire * SUM ALL ( distances intermédiaires de son voyage) / ( 0.5*SUM ALL(poids_produit)).*/
CREATE VIEW view_data_ships AS 
(
    SELECT id_ship, speed, category_ship FROM ship NATURAL JOIN type_ship
);



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


/*============================================= data about each ship ============================================================================ */
CREATE VIEW view_data_ships AS 
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
SELECT c1.id_step, c1.id_travel, c1.id_port, c1.visiting_order, c1.date_arrival, c1.date_departure, c1.id_product, c1.quantity AS quantity_load, c2.quantity AS quantity_unload FROM view_etaps_load_unload c1 LEFT JOIN view_etaps_load_unload c2 ON (c1.id_product = c2.id_product AND c1.id_step = c2.id_step AND c1.quantity <> c2.quantity) WHERE c1.load_unload = 'load' ORDER BY c1.id_travel, c1.id_step;
);

CREATE OR REPLACE VIEW view1 AS 
(
SELECT id_step, id_travel, id_port, visiting_order, date_arrival, date_departure, id_product, (quantity_load - COALESCE(quantity_unload, 0)) AS total_etap_prod 
FROM view_etaps_quantity_load_unload;
);

