
/* 
    since we were not able to implement automatic updating of data in source tables using triggers 
    (triggers are beyond the program), 
    after each addition of records to table <step> it is recommended to run manially this script (  \i non_auto_updates.sql;  ) 
    so that fields 
        - date_departure
        - date_arrival
        - class
        - tr_type
    in table <travel> will be filled
*/

/* Set attributes date_departure et date_arrival in table travel */
UPDATE travel SET date_departure = A.dates FROM (SELECT id_travel, date_departure FROM view_travel_dep_arr) AS A(id, dates) WHERE (id_travel = A.id);
UPDATE travel SET date_arrival = A.dates FROM (SELECT id_travel, date_arrival FROM view_travel_dep_arr) AS A(id, dates) WHERE (id_travel = A.id);

 /* Set attribute tr_type in table travel */
UPDATE travel SET tr_type = 'court' FROM (SELECT * FROM view_total_dist_trips) AS B(id1, sum1) WHERE (id_travel = B.id1 AND B.sum1 < 1000);
UPDATE travel SET tr_type = 'medium' FROM (SELECT * FROM view_total_dist_trips) AS B(id1, sum1) WHERE (id_travel = B.id1 AND B.sum1 >= 1000 AND B.sum1 <= 2000);
UPDATE travel SET tr_type = 'long' FROM (SELECT * FROM view_total_dist_trips) AS B(id1, sum1) WHERE (id_travel = B.id1 AND B.sum1 > 2000);

/* Set attribute class in table travel */
UPDATE travel SET class = A.newVal2 FROM (SELECT id_travel, travel_class FROM view_not_intercontinental) AS A(newVal1, newVal2) WHERE id_travel = A.newVal1;
UPDATE travel SET class = 'Intercontinental' WHERE class IS NULL;