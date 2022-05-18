
/* \dv to see views */

/* only departure and arrival dates for each steps */
CREATE VIEW travel_dep_arr_vue AS (SELECT step.id_travel AS id_travel, id_ship, date_departure, date_arrival, visiting_order FROM step, travel WHERE step.id_travel = travel.id_travel AND (visiting_order = 0 OR visiting_order = (SELECT MAX(visiting_order) FROM step)) ORDER BY id_travel, visiting_order);

/* distances + reverse distances */
CREATE VIEW distances_vue AS (SELECT * FROM distances_ports UNION SELECT id_port2 as id_port1, id_port1 as id_port2, distance FROM distances_ports);

/* relations + reverse relations */
CREATE VIEW relations_vue AS (SELECT * FROM country_relations UNION SELECT id_country2 as id_country1, id_country1 as id_country2, relation FROM country_relations);

/* distances of etaps */
CREATE VIEW distances_etaps_view AS (SELECT id_travel, p1.id_port AS port1, p2.id_port AS port2, d.distance FROM step p1 JOIN step p2 USING (id_travel) LEFT JOIN distances_ports d ON d.id_port1 = p1.id_port AND d.id_port2 = p2.id_port WHERE  p2.visiting_order = p1.visiting_order + 1 ORDER BY id_travel, p1.visiting_order);


/* duration of trip etap by etap */
/* CREATE VIEW duration_vue AS (SELECT id_travel, (() AS duration) FROM distances_ports);  */
