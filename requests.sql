


/* une requete qui porte sur au moins trois tables ;*/

SELECT step.id_travel, name_continent AS travel_class 
FROM view_nb_continents_diff 
NATURAL JOIN step 
NATURAL JOIN port 
NATURAL JOIN continent;

/*  une 'auto jointure' (jointure de deux copies d'une meme table)*/



/*  une sous-requete correlee ;*/



/*  une sous-requete dans le FROM;*/



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
    FROM step p1 
    JOIN step p2 USING (id_travel) 
    LEFT JOIN distances_ports d ON d.id_port1 = p1.id_port AND d.id_port2 = p2.id_port 
    WHERE  p2.visiting_order = p1.visiting_order + 1 
    ORDER BY id_travel, p1.visiting_order;

/*  deux requetes equivalentes exprimant une condition de totalite, l'une avec des sous requetes correlees et l'autre avec de l'agregation*/
/*1*/

/*2*/


/*  deux requetes qui renverraient le meme resultat si vos tables de contenaient pas de nulls, mais qui renvoient
des resultats differents ici (vos donnees devront donc contenir quelques nulls), vous proposerez egalement de petites modications de vos
requetes (dans l'esprit de ce qui a ete presente en cours) afin qu'elles retournent le meme resultat */
/*1*/

/*2*/
