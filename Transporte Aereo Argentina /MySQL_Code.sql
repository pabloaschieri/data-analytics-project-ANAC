CREATE DATABASE anac;
USE anac;

## 1) Creacion de tabla, carga de datos y primer análisis exploratorio.
# 1.1) Creamos la tabla donde vamos a importar los datos de la ANAC. Por el momento vamos a definir todas con VARCHAR, luego editaremos algunos de ellos:
CREATE TABLE vuelos (
    fecha VARCHAR(100),
    hora VARCHAR(100),
    clase_vuelo VARCHAR(100),
    tipo_vuelo VARCHAR(100),
    movimiento VARCHAR(100),
    aeropuerto VARCHAR(100),
    origen_destino VARCHAR(100),
    aerolinea VARCHAR(100),
    aeronave VARCHAR(100),
    pasajeros VARCHAR(100),
    tipo_dato VARCHAR(100)
);

# 1.2) Cargamos los datos de cada año por separado mediante las siguiente sentencias. 
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/2019-informe-ANAC.csv' 
INTO TABLE vuelos
FIELDS TERMINATED BY ';' 
 ENCLOSED BY '"'
 ESCAPED BY '"'
 LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/2020-informe-ANAC.csv' 
INTO TABLE vuelos
FIELDS TERMINATED BY ';' 
 ENCLOSED BY '"'
 ESCAPED BY '"'
 LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/2021-informe-ANAC.csv' 
INTO TABLE vuelos
FIELDS TERMINATED BY ';' 
 ENCLOSED BY '"'
 ESCAPED BY '"'
 LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/2022-informe-ANAC.csv' 
INTO TABLE vuelos
FIELDS TERMINATED BY ';' 
 ENCLOSED BY '"'
 ESCAPED BY '"'
 LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/2023-informe-ANAC.csv' 
INTO TABLE vuelos
FIELDS TERMINATED BY ';' 
 ENCLOSED BY '"'
 ESCAPED BY '"'
 LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

# 1.3) Ejecutamos una simple query para ver nuestra tabla. La misma fue cargado exitosamente:
SELECT * FROM vuelos
LIMIT 5;

# 1.4) Analizamos más en profundidad la tabla: 2.426.101 records.
SELECT COUNT(fecha) FROM vuelos;

-- 1.5) Antes de realizar cambios en la tabla Vuelos, realizamos un backup por cuestiones de seguridad.
CREATE TABLE vuelos_backup AS
	SELECT * FROM vuelos;
    
-- 1.5) Lo primero que hacemos en garantizarnos que por lo menos todos los records tengan registrada "Fecha":
SELECT COUNT(fecha) FROM vuelos
WHERE fecha="" OR fecha=" " OR fecha IS NULL;

select "provisorio" as Tipo, count(fecha) from vuelos;

SELECT 
       SUM(IF(fecha IS NULL OR fecha = '', 1, 0)) AS null_columna1,
       SUM(IF(hora IS NULL OR hora = '', 1, 0)) AS null_columna2,
       SUM(IF(clase_vuelo IS NULL OR clase_vuelo = '', 1, 0)) AS null_columna3,
       SUM(IF(tipo_vuelo IS NULL OR fecha = '', 1, 0)) AS null_columna4,
       SUM(IF(movimiento IS NULL OR movimiento = '', 1, 0)) AS null_columna5,
       SUM(IF(aeropuerto IS NULL OR fecha = '', 1, 0)) AS null_columna6,
       SUM(IF(origen_destino IS NULL OR fecha = '', 1, 0)) AS null_columna7
FROM vuelos;
