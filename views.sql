
/* \dv to see views */

/* only departure and arrival dates for each steps */
CREATE VIEW travel_dep_arr_vue AS (SELECT step.id_travel AS id_travel, id_ship, date_departure, date_arrival, visiting_order FROM step, travel WHERE step.id_travel = travel.id_travel AND (visiting_order = 0 OR visiting_order = (SELECT MAX(visiting_order) FROM step)) ORDER BY id_travel, visiting_order);

/* distances + reverse distances */
CREATE VIEW distances_vue AS (SELECT * FROM distances_ports UNION SELECT id_port2 as id_port1, id_port1 as id_port2, distance FROM distances_ports);

/* relations + reverse relations */
CREATE VIEW relations_vue AS (SELECT * FROM country_relations UNION SELECT id_country2 as id_country1, id_country1 as id_country2, relation FROM country_relations);

/* distances of trips */

/* test table
CREATE TABLE paths (id_travel int, point int, visited int);

INSERT INTO paths VALUES
  (10, 35, 0),
  (10, 16, 1),
  (10, 93, 2),
  (5, 15, 0),
  (5, 26, 1),
  (5, 193, 2)
  (5, 31, 3);

CREATE TABLE distances (id_port1 int, id_port2 int, distance int CHECK (distance > 0), PRIMARY KEY (id_port1, id_port2));

INSERT INTO distances VALUES
  (35, 16, 1568), 
  (16, 93, 987), 
  (15, 26, 251), 
  (26, 193, 87), 
  (193, 31, 356);

SELECT id_travel, p1.point AS point1, p2.point AS point2, d.distance 
FROM   paths p1
JOIN   paths p2 USING (id_travel)
LEFT   JOIN distances d ON d.id_port1 = p1.point
                       AND d.id_port2 = p2.point
WHERE  p2.visited = p1.visited + 1
ORDER  BY id_travel, p2.visited;
*/

CREATE VIEW distances_etaps_view AS (SELECT id_travel, p1.id_port AS port1, p2.id_port AS port2, d.distance FROM step p1 JOIN step p2 USING (id_travel) LEFT JOIN distances_ports d ON d.id_port1 = p1.id_port AND d.id_port2 = p2.id_port WHERE  p2.visited = p1.visited + 1 ORDER BY id_travel, p1.visited);


/* duration of trips */
/* CREATE VIEW duration_vue AS (SELECT id_travel, (() AS duration) FROM distances_ports);  */
