/* une requete qui porte sur au moins trois tables ;*/
/* recuperer nationalité des etapes de voyages */
SELECT step.id_travel, name_continent AS nationality 
FROM view_nb_continents_diff 
NATURAL JOIN step 
NATURAL JOIN port 
NATURAL JOIN continent;

/*  une 'auto jointure' (jointure de deux copies d'une meme table)*/
/* le nom des pays ayant séparé de moins de 500km (en prenant compte les colonies) */
SELECT c1.name_country AS pays_a, c2.name_country AS pays_b 
FROM country c1, country c2, distances_ports p 
WHERE p.id_port1=c1.id_country AND p.id_port2=c2.id_country AND distance < 500;

/*  une sous-requete correlee ;*/
/* recuperer les dates de depart et d'arrivee de voyages */
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
/* Le classe et le type du premier voyage réalisé */
SELECT class, tr_type FROM (
    SELECT * FROM (SELECT id_travel, min(date_departure) AS date_departure, max(date_arrival) AS date_arrival 
    FROM step GROUP BY id_travel ORDER BY id_travel) AS A
    NATURAL JOIN travel 
    ORDER BY date_departure
) AS foo LIMIT 1;


/*  une sous-requete dans le WHERE;*/
/* récupère les produits avec le volume le plus élevé */
SELECT * FROM product p1 
WHERE NOT EXISTS (
    SELECT * 
    FROM product p2 
    WHERE p1.volume_product < p2.volume_product
);

/*  deux agregats necessitant GROUP BY et HAVING ;*/
/*1 recherche des voyages nationaux, i.e. dont les ports se trouvent sur même continent */
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

/*  une requete impliquant le calcul de deux agregats (par exemple, les moyennes d'un ensemble de maximums)*/
/* La moyenne du nombre des articles les plus présent dans les ports */
SELECT AVG(max)::INTEGER FROM(
    SELECT id_port, MAX(quantity) 
    FROM cargo_port 
    GROUP BY id_port
) AS foo;

/* une jointure externe (LEFT JOIN, RIGHT JOIN ou FULL JOIN) ; */
/* recuperer les ports et les distances entre les ports à partir de table <step> on fonction de visiting_order*/
SELECT id_travel, p1.id_port AS port1, p2.id_port AS port2, d.distance 
    FROM step p1 
    JOIN step p2 USING (id_travel) 
    LEFT JOIN view_distances d ON d.id_port1 = p1.id_port AND d.id_port2 = p2.id_port 
    WHERE  p2.visiting_order = p1.visiting_order + 1 
    ORDER BY id_travel, p1.visiting_order;

/*  deux requetes equivalentes exprimant une condition de totalite, l'une avec des sous requetes correlees et l'autre avec de l'agregation*/
/* 1 Les pays possédant au moins un navire */
SELECT *                                                                                                                                              
FROM country 
WHERE EXISTS(
    SELECT nationality FROM ship
    WHERE country.id_country=ship.nationality
);
/* 2 */
SELECT nationality, name_country 
FROM ship
JOIN country ON country.id_country=ship.nationality 
GROUP BY nationality, name_country 
HAVING COUNT(*) > 1;


/*  deux requetes qui renverraient le meme resultat si vos tables de contenaient pas de nulls, mais qui renvoient
des resultats differents ici (vos donnees devront donc contenir quelques nulls), vous proposerez egalement de petites modications de vos
requetes (dans l'esprit de ce qui a ete presente en cours) afin qu'elles retournent le meme resultat */
/* 1 La somme des dates sous formes de chaine de caractère */
SELECT SUM(
    to_char(date_arrival, 'YYYYMMDD')::integer+to_char(date_departure, 'YYYYMMDD')::integer
) FROM step;
/* et */
SELECT SUM(
    to_char(date_arrival, 'YYYYMMDD')::integer)+SUM(to_char(date_departure, 'YYYYMMDD')::integer
) FROM step;
/* 2 version corrigé */
SELECT SUM(
    COALESCE(
        to_char(date_arrival, 'YYYYMMDD')::integer,0
    )+COALESCE(
        to_char(date_departure, 'YYYYMMDD')::integer,0
    )
) FROM step;
/* et */
SELECT SUM(
    COALESCE(
        to_char(date_arrival, 'YYYYMMDD')::integer,0
    ))+SUM(COALESCE(
        to_char(date_departure, 'YYYYMMDD')::integer,0
    ))
) FROM step;

/* la liste des articles ayant été chargé dans un bateau par ordre croissant */
SELECT name_product, sum 
FROM product NATURAL 
JOIN (
    SELECT id_product, SUM(quantity) 
    FROM cargo_step NATURAL 
    JOIN product 
    WHERE load_unload='load' 
    GROUP BY id_product) AS FOO 
ORDER BY sum DESC;

/* L'id des produits représentant plus de la moitié des produits d'un port */
SELECT id_product
FROM cargo_port, (
    SELECT id_port, SUM(quantity) 
    FROM cargo_port 
    GROUP BY id_port
) AS FOO 
WHERE FOO.id_port=cargo_port.id_port AND quantity > sum/2;

/*La liste des continents ne possédant aucun port*/
SELECT * 
FROM continent 
WHERE id_continent 
NOT IN (
    SELECT id_continent 
    FROM port 
    GROUP BY id_continent
);

/* Le nom des pays en guerre */
SELECT DISTINCT name_country 
FROM country 
JOIN (
    (SELECT DISTINCT id_country1 
     FROM country_relations 
     WHERE relation='belligerent'
    ) 
    UNION 
    (SELECT DISTINCT id_country2 
     FROM country_relations 
     WHERE relation='belligerent'
    )
) AS id_countryc ON id_countryc.id_country1=country.id_country;

/* Les pays possédant les navires les plus rapide */
select name_country 
from ship 
NATURAL JOIN (
    select * 
    from type_ship, (
        SELECT MAX(speed) 
        from type_ship
    ) AS FOO 
    WHERE speed=max) AS BAR
JOIN country ON nationality=id_country;
