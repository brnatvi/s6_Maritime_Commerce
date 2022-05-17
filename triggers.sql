
/* To see all triggers ->   SELECT tgname FROM pg_trigger;   */

/* increase-decrease quantity of port's stock once cargo is loaded-unloaded on some step */
CREATE OR REPLACE FUNCTION load_unload() RETURNS TRIGGER AS $$
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
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS modif_stocks ON cargo_step;
CREATE TRIGGER modif_stocks BEFORE INSERT ON cargo_step FOR EACH STATEMENT EXECUTE FUNCTION load_unload();