
/* To see all triggers ->   SELECT tgname FROM pg_trigger;   */

/*================= increase-decrease quantity of port's stock once cargo is loaded-unloaded on some step ==========================================*/
CREATE OR REPLACE FUNCTION load_unload() RETURNS TRIGGER AS 
$$
DECLARE 
    port INT;    
BEGIN    
    IF TG_OP = 'UPDATE' OR TG_OP = 'INSERT' THEN
    BEGIN
        SELECT id_port INTO port FROM step WHERE id_step = NEW.id_step;
        IF NEW.load_unload = 'load' THEN UPDATE cargo_port SET quantity = quantity - NEW.quantity WHERE id_product = NEW.id_product AND cargo_port.id_port = port;
        ELSE UPDATE cargo_port SET quantity = quantity + NEW.quantity WHERE id_product = NEW.id_product AND cargo_port.id_port = port;
        END IF;
        RETURN NEW;
    END;
    END IF;
END;
$$ 
LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS modif_stocks ON cargo_step;
CREATE TRIGGER modif_stocks BEFORE INSERT ON cargo_step FOR EACH STATEMENT EXECUTE FUNCTION load_unload();



/*=========== fill eTypeTravel ('court', 'medium', 'long') as tr_type to table travel according summary distance of travel =========================*/
/*CREATE OR REPLACE FUNCTION find_type() RETURNS TRIGGER AS 
$$
DECLARE 
    sum INT;
BEGIN    
    IF TG_OP = 'UPDATE' OR TG_OP = 'INSERT' THEN
    BEGIN
        SELECT id_travel, sum(distance) INTO sum FROM view_distances_etaps GROUP BY id_travel WHERE id_travel = NEW.id_travel;      

        IF sum < 1000 THEN UPDATE travel SET tr_type = 'court' WHERE id_travel = NEW.id_travel;
            ELSEIF sum >= 1000 AND sum <= 2000 THEN UPDATE travel SET tr_type = 'medium' WHERE id_travel = NEW.id_travel;
            ELSE UPDATE travel SET tr_type = 'long' WHERE id_travel = NEW.id_travel;
        END IF;
        RETURN NEW;
    END;
    END IF;
END;
$$
LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS define_type_travel ON view_distances_etaps;
CREATE TRIGGER define_type_travel BEFORE INSERT ON view_distances_etaps FOR EACH STATEMENT EXECUTE FUNCTION find_type();
*/