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
    name_country VARCHAR(255) NOT NULL UNIQUE    
);

CREATE TABLE country_relations (
    id_country1 INT,
    id_country2 INT,
    relation eRelationDiplom,
    PRIMARY KEY (id_country1, id_country2),
    FOREIGN KEY (id_country1) REFERENCES country (id_country),
    FOREIGN KEY (id_country2) REFERENCES country (id_country)   
);


CREATE TABLE port (
    id_port SERIAL PRIMARY KEY,
    name_port VARCHAR(255) NOT NULL,
    category_port INT CHECK (category_port >= 1 AND category_port <= 5),
    id_continent INT,
    nationality INT,    
    FOREIGN KEY (id_continent) REFERENCES continent (id_continent),
    FOREIGN KEY (nationality) REFERENCES country (id_country)
);

CREATE TABLE distances_ports (
    id_port1 INT,
    id_port2 INT,
    distance NUMERIC(10, 2) CHECK (distance > 0),
    PRIMARY KEY (id_port1, id_port2),
    FOREIGN KEY (id_port1) REFERENCES port (id_port),
    FOREIGN KEY (id_port2) REFERENCES port (id_port)
);


CREATE TABLE type_ship (
    id_type SERIAL PRIMARY KEY,   
    name_type VARCHAR(255),
    category_ship INT CHECK (category_ship >= 1 AND category_ship <= 5),
    speed NUMERIC(4,1) CHECK (speed > 0)
);

CREATE TABLE ship (
    id_ship SERIAL PRIMARY KEY,
    name_ship VARCHAR(255),
    id_type INT,
    nationality INT,
    volume_hold INT NOT NULL CHECK (volume_hold > 0),
    nb_places_passagers INT NOT NULL CHECK (nb_places_passagers > 0),  
    localisation NUMERIC(8,8),
    FOREIGN KEY (id_type) REFERENCES type_ship (id_type),
    FOREIGN KEY (nationality) REFERENCES country (id_country)
);


CREATE TABLE product (
    id_product SERIAL PRIMARY KEY,   
    name_product VARCHAR(255),
    is_dry BOOLEAN,    
    weight_product NUMERIC(4,1) NOT NULL CHECK (weight_product > 0),
    price_kilo NUMERIC(4,1) NOT NULL CHECK (price_kilo > 0)
);


/*
TODO: CREATE TABLE
travel_class
travel_category
??
*/

CREATE TABLE travel (
    id_travel SERIAL PRIMARY KEY,
    id_ship INT,
    quantity INT,   
    FOREIGN KEY (id_ship) REFERENCES ship (id_ship) 
);

CREATE TABLE step (
    id_step SERIAL PRIMARY KEY,
    id_travel INT,
    id_port INT,
    visiting_order INT CHECK (visiting_order >= 0),
    date_arrival DATE,
    date_departure DATE,
    nb_passagers_in INT DEFAULT 0 CHECK (nb_passagers_in >= 0),
    nb_passagers_out INT DEFAULT 0 CHECK (nb_passagers_out >= 0),
    FOREIGN KEY (id_travel) REFERENCES travel (id_travel),
    FOREIGN KEY (id_port) REFERENCES port (id_port),
    CONSTRAINT respect_date CHECK (date_arrival <= date_departure)
);

CREATE TABLE cargo_step (
    id_cargo_step SERIAL PRIMARY KEY,
    id_step INT,
    id_product INT,
    load_unload eAction,
    quantity INT,
    FOREIGN KEY (id_product) REFERENCES product (id_product),
    FOREIGN KEY (id_step) REFERENCES step (id_step)
);

CREATE TABLE cargo_port (
    id_cargo_port SERIAL PRIMARY KEY,
    id_port INT,
    id_product INT,      
    quantity INT,
    FOREIGN KEY (id_product) REFERENCES product (id_product),
    FOREIGN KEY (id_port) REFERENCES port (id_port)
);


\i views.sql
\i triggers.sql
/* \i uploads.sql  */
