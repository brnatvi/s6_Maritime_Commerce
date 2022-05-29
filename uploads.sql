
/* Nautical distances: https://classic.searoutes.com/routing/4294967355/4294967513?speed=13&panama=true&suez=true&kiel=true&rivers=block&roads=block  */

\COPY country(id_country, name_country) FROM 'csv/country.csv' (DELIMITER ',', FORMAT CSV);
\COPY continent(id_continent, name_continent) FROM 'csv/continent.csv' (DELIMITER ',', FORMAT CSV);
\COPY port(id_port, name_port, category_port, id_continent, nationality) FROM 'csv/port.csv' (DELIMITER ',', FORMAT CSV);
\COPY country_relations(id_country1, id_country2, relation) FROM 'csv/country_relations.csv' (DELIMITER ',', FORMAT CSV);
\COPY distances_ports(id_port1, id_port2, distance) FROM 'csv/distances_ports.csv' (DELIMITER ',', FORMAT CSV);
\COPY type_ship(id_type, name_type, category_ship, speed) FROM 'csv/category_ship.csv' (DELIMITER ',', FORMAT CSV);
\COPY product(id_product, name_product, is_dry, weight_product, price_kilo) FROM 'csv/product.csv' (DELIMITER ',', FORMAT CSV);
\COPY distances_ports(id_port1, id_port2, distance) FROM 'csv/distances.csv' (DELIMITER ',', FORMAT CSV);
\COPY cargo_port(id_port, id_product, quantity)  FROM 'csv/cargo_port.csv' (DELIMITER ',', FORMAT CSV);
\COPY ship (id_ship, name_ship, id_type, nationality, volume_hold, nb_places_passagers, localisation) FROM 'csv/ship.csv' (DELIMITER ',', FORMAT CSV);
