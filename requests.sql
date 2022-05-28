
/* une requete qui porte sur au moins trois tables ;*/

SELECT step.id_travel, name_continent AS travel_class 
FROM view_nb_continents_diff 
NATURAL JOIN step 
NATURAL JOIN port 
NATURAL JOIN continent;

/*  une 'auto jointure' (jointure de deux copies d'une meme table)*/


/*  une sous-requete correlee ;*/

SELECT DISTINCT step.id_travel, sub_query1.date_departure, sub_query.date_arrival
FROM  step
INNER JOIN
    (SELECT step.id_travel, MAX(step.date_arrival) as date_arrival
     FROM step
     GROUP BY step.id_travel
    )
    AS sub_query ON (sub_query.id_travel = step.id_travel)
INNER JOIN 
    (SELECT id_travel, date_departure FROM step WHERE visiting_order = 0 GROUP BY id_travel, date_departure)
    AS sub_query1 ON (sub_query1.id_travel = sub_query.id_travel)
ORDER BY id_travel; 

/*  une sous-requete dans le FROM;*/

UPDATE travel SET date_departure = A.dates FROM (SELECT id_travel, date_departure FROM view_travel_dep_arr) AS A(id, dates) WHERE (id_travel = A.id);

/*  une sous-requete dans le WHERE;*/




/*  deux agregats necessitant GROUP BY et HAVING ;*/
/*1*/
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

/*2*/
SELECT id_travel, COUNT(DISTINCT id_continent) AS nb_cont 
FROM continents_steps 
GROUP BY id_travel;

/*  une requete impliquant le calcul de deux agregats (par exemple, les moyennes d'un ensemble de maximums)*/




/*  une jointure externe (LEFT JOIN, RIGHT JOIN ou FULL JOIN) ; */
SELECT id_travel, p1.id_port AS port1, p2.id_port AS port2, d.distance 
    FROM step p1 JOIN step p2 USING (id_travel) LEFT JOIN view_distances d ON d.id_port1 = p1.id_port AND d.id_port2 = p2.id_port 
    WHERE  p2.visiting_order = p1.visiting_order + 1 
    ORDER BY id_travel, p1.visiting_order

/*  deux requetes equivalentes exprimant une condition de totalite, l'une avec des sous requetes correlees et l'autre avec de l'agregation*/
/*1*/

/*2*/


/*  deux requetes qui renverraient le meme resultat si vos tables de contenaient pas de nulls, mais qui renvoient
des resultats differents ici (vos donnees devront donc contenir quelques nulls), vous proposerez egalement de petites modications de vos
requetes (dans l'esprit de ce qui a ete presente en cours) afin qu'elles retournent le meme resultat */
/*1*/

/*2*/

/*une requete recursive (par exemple pour reconstituer le trajet effectue par un certain bateau sur un laps de temps 
recouvrant des voyages differents).*/
