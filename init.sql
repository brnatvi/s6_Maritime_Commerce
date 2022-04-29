DROP DATABASE IF EXISTS maritime_commerce;
CREATE DATABASE maritime_commerce;

\connect maritime_commerce

DROP TABLE IF EXISTS ingredients cascade;
DROP TABLE IF EXISTS security_client cascade;

DROP TABLE IF EXISTS ship cascade;
DROP TABLE IF EXISTS type_ship cascade;
DROP TABLE IF EXISTS country_relations cascade;
DROP TABLE IF EXISTS country cascade; 
DROP TABLE IF EXISTS continent cascade;
DROP TABLE IF EXISTS distances_ports cascade;
DROP TABLE IF EXISTS port cascade;


CREATE TYPE eTypeTrip AS ENUM ('court', 'medium', 'long');
CREATE TYPE eClassTrip AS ENUM ('Europe', 'America', 'Asia', 'Africa', 'Oceania', 'Intercontinental');
CREATE TYPE eAction AS ENUM ('load', 'unload');
CREATE TYPE eRelationDiplom AS ENUM ('ally commercial', 'ally', 'neutral', 'belligerent');



CREATE TABLE continent (
    id_continent SERIAL PRIMARY KEY,    
    name_continent VARCHAR(255) NOT NULL UNIQUE   
);

CREATE TABLE country (
    id_country SERIAL PRIMARY KEY,    
    name_country VARCHAR(255) NOT NULL UNIQUE,
    id_continent INT,
    FOREIGN KEY (id_continent) REFERENCES continent (id_continent)
);

CREATE TABLE country_relations (
    id_country1 INT,
    id_country2 INT,
    relation eRelationDiplom NOT NULL,
    FOREIGN KEY (id_country1) REFERENCES country (id_country),
    FOREIGN KEY (id_country2) REFERENCES country (id_country)   
);

CREATE TABLE port (
    id_port SERIAL PRIMARY KEY,
    name_port VARCHAR(255) NOT NULL,
    category_port INT CONSTRAINT from_1_to_5 CHECK (category_port >= 1 AND category_port <= 5)
);

CREATE TABLE distances_ports (
    id_port1 INT,
    id_port2 INT,
    distance NUMERIC(10, 2),
    PRIMARY KEY (id_port1, id_port2),
    FOREIGN KEY (id_port1) REFERENCES port (id_port),
    FOREIGN KEY (id_port2) REFERENCES port (id_port)
);

CREATE TABLE type_ship (
    id_type SERIAL PRIMARY KEY,   
    name_type VARCHAR(255),
    category_ship INT CONSTRAINT from_1_to_5 CHECK (category_ship >= 1 AND category_ship <= 5),
    speed NUMERIC(4,1)
);

CREATE TABLE ship (
    id_ship SERIAL PRIMARY KEY,
    name_ship VARCHAR(255),
    id_type INT,
    nationality INT,
    volume_hold INT NOT NULL,   
    nb_places_passagers INT NOT NULL,  
    localisation NUMERIC(4,4),
    FOREIGN KEY (id_type) REFERENCES type_ship (id_type),
    FOREIGN KEY (nationality) REFERENCES country (id_country)
);


CREATE TABLE product (
    id_product SERIAL PRIMARY KEY,   
    name_product VARCHAR(255),
    is_dry BOOLEAN,
    volume_product NUMERIC(4,1) NOT NULL CONSTRAINT v_positive CHECK (volume_product > 0),
    weight_product NUMERIC(4,1) NOT NULL CONSTRAINT w_positive CHECK (weight_product > 0),
    price_kilo NUMERIC(4,1) NOT NULL
);


\COPY country(id_country, nom_country, id_continent) FROM 'csv/country.csv' (DELIMITER ',', FORMAT CSV);
\COPY continent(id_continent, nom_continent) FROM 'csv/continent.csv' (DELIMITER ',', FORMAT CSV);
\COPY port(id_port, nam_port, category_port) FROM 'csv/port.csv' (DELIMITER ',', FORMAT CSV);
\COPY country_relations(id_country1, id_country2, relation) FROM 'csv/country_relations.csv' (DELIMITER ',', FORMAT CSV);
\COPY distances_ports(id_port1, id_port2, distance) FROM 'csv/distances_ports.csv' (DELIMITER ',', FORMAT CSV);
\COPY type_ship(id_type, name_type, category_ship, speed) FROM 'csv/category_ship.csv' (DELIMITER ',', FORMAT CSV);
\COPY product(id_product, name_product, is_dry, volume_product, weight_product, price_kilo) FROM 'csv/product.csv' (DELIMITER ',', FORMAT CSV);