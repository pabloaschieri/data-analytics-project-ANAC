CREATE DATABASE anac;
USE anac;

/* A) Creacion de tabla, carga de datos y primer análisis exploratorio.
1.1) Creamos la tabla donde vamos a importar los datos de la ANAC. Por el momento vamos a definir todas con VARCHAR, luego editaremos algunos de ellos:*/
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

/* 1.2) Cargamos los datos de cada año por separado mediante las siguiente sentencias. */
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

/* 1.3) Ejecutamos una simple query para ver nuestra tabla. La misma fue cargado exitosamente:*/
SELECT * FROM vuelos
LIMIT 5;

/* 1.4) Analizamos más en profundidad la tabla: 1.997.997 records.*/
SELECT COUNT(*) FROM vuelos;

/* 1.5) Antes de realizar cambios en la tabla Vuelos, realizamos un backup por cuestiones de seguridad.*/
CREATE TABLE vuelos_backup AS
	SELECT * FROM vuelos;
    
/* 1.5) Solo se considerarán los records donde las columnas Fecha, Clase_vuelo, Momimiento, Aeropuerto, Origen_destino estén completas. Encontramos 263.878 records vacíos*/
SELECT 
    SUM(IF(fecha IN ('' , ' '), 1, 0)) AS vacios_fecha,
    SUM(IF(clase_vuelo IN ('' , ' '), 1, 0)) AS vacios_clasevuelo,
    SUM(IF(movimiento IN ('' , ' '), 1, 0)) AS vacios_movimiento,
    SUM(IF(aeropuerto IN ('' , ' '), 1, 0)) AS vacios_aeropuerto,
    SUM(IF(origen_destino IN ('' , ' '), 1, 0)) AS vacios_origendestino
FROM vuelos;
    
/* 1.6) Procedemos a eliminarlos: nuestra nueva tabla de Vuelos ahora posee 1.734.119 records.*/
DELETE FROM vuelos 
WHERE
    fecha IN ('' , ' ')
    OR clase_vuelo IN ('' , ' ')
    OR movimiento IN ('' , ' ')
    OR aeropuerto IN ('' , ' ')
    OR origen_destino IN ('' , ' ');
    
/* 2) VALORES DUPLICADOS /*
/* 2.1) Buscamos filas duplicadas mediante un CONCAT de todas las columnas */

SELECT 
		concat AS detalle_vuelo
    FROM (
		SELECT CONCAT(fecha, hora, clase_vuelo, tipo_vuelo, movimiento, aeropuerto, origen_destino, aerolinea, aeronave, pasajeros, tipo_dato) AS concat 
		FROM vuelos) a
	GROUP BY concat
	HAVING count(concat) > 1
	ORDER BY 1;

/* 2.2) Sabemos que todos los vuelos anteriores están duplicados, pero ahora queremos conocer la cantidad de veces y el total de filas a eliminar: 3738 filas*/
SELECT
	*,
    SUM(records - 1) OVER (ORDER BY ranking) AS suma_duplicados_acumulado,
    SUM(records - 1) OVER () AS suma_duplicados_total
FROM (
	SELECT 
		ROW_NUMBER() OVER(ORDER BY COUNT(concat) DESC) AS ranking, 
		concat AS detalle_vuelo,
        COUNT(concat) AS records
    FROM (
		SELECT CONCAT(fecha, hora, clase_vuelo, tipo_vuelo, movimiento, aeropuerto, origen_destino, aerolinea, aeronave, pasajeros, tipo_dato) AS concat 
		FROM vuelos) a
	GROUP BY concat
	HAVING count(concat) > 1
	ORDER BY 1) aa;

/* 2.3) Para eliminar los duplicados, utilizaremos una columna auxiliar ID que la definimos con AUTO INCREMENT (la colocamos en primer lugar) */

ALTER TABLE vuelos ADD id INT AUTO_INCREMENT UNIQUE FIRST;

/* 2.4) Queremos encontrar los ID de todas las filas duplicadas. Usamos la función ROW_NUMBER haciendo un PARTITION BY usando todas las columnas, esto
genera un nuevo número de fila cuando alguna de las columnas cambian, por lo que las filas mayores a 1 (la conservamos como original) son duplicadas.*/

SELECT id FROM (
	SELECT
		id, 
        ROW_NUMBER() OVER(PARTITION BY fecha, hora, clase_vuelo, tipo_vuelo, movimiento, aeropuerto, origen_destino, aerolinea, aeronave, pasajeros, tipo_dato) AS num_fila
	FROM vuelos) a
WHERE num_fila > 1;

/* 2.5) Eliminamos los duplicados */
DELETE FROM vuelos
WHERE id IN (SELECT id FROM (
	SELECT
		id, 
        ROW_NUMBER() OVER(PARTITION BY fecha, hora, clase_vuelo, tipo_vuelo, movimiento, aeropuerto, origen_destino, aerolinea, aeronave, pasajeros, tipo_dato) AS num_fila
	FROM vuelos) a
WHERE num_fila > 1);

/* B) Análisis de columnas */ 
/* 1.1) Unificación de Fecha y Hora y cambio de tipo de dato. Analizamos la columna "Hora" y "Fecha": */
SELECT DISTINCT
    LENGTH(hora), COUNT(hora), LENGTH(fecha), COUNT(fecha)
FROM
    vuelos
GROUP BY 1;

SELECT DISTINCT
    LENGTH(fecha), COUNT(fecha)
FROM
    vuelos
GROUP BY 1;

/* 1.2) Buscamos que no haya letras en las columnas: */
SELECT *
FROM
    vuelos
WHERE fecha REGEXP "[a-z]" OR hora REGEXP "[a-z]";

/* 2.2) La columna HORA tiene algunos valores con detalle de segundos y otras no, procedemos a cambiar el tipo de dato y unificamos criterio:*/
UPDATE vuelos SET hora = 
    CONCAT(hora, IF(LENGTH(hora) = 5, ':00', ''));

/* 2.3) Unificamos en una nueva columna la Fecha y Hora, y la convertimos a DATETIME:*/
ALTER TABLE vuelos ADD COLUMN fecha_hora VARCHAR(50);

UPDATE vuelos 
SET fecha_hora = CONCAT(fecha, ' ', hora);
    
ALTER TABLE vuelos ADD COLUMN fecha_hora2 DATETIME;

UPDATE vuelos 
SET fecha_hora2 = STR_TO_DATE(fecha_hora, '%d/%m/%Y %H:%i:%s');

/* 2.4) Eliminamos columnas que ya no queremos, y renombramos y ordenamos otras:*/
ALTER TABLE vuelos DROP COLUMN fecha;
ALTER TABLE vuelos DROP COLUMN hora;
ALTER TABLE vuelos DROP COLUMN fecha_hora;
ALTER TABLE vuelos RENAME COLUMN fecha_hora2 TO fecha;
ALTER TABLE vuelos MODIFY COLUMN fecha DATETIME AFTER id;

/* 3) Análisis de columna clase_vuelo: 16 clases de vuelo diferente. */
SELECT DISTINCT 
	clase_vuelo, 
	COUNT(movimiento) as movimientos 
FROM vuelos
GROUP BY 1
ORDER BY 2 DESC;

/* 3.1) Para simplificar la columna "Clase_vuelo", actualizamos la tabla "vuelos" haciendo un JOIN con la tabla "clase_vuelo" agrupando el criterio.
La tabla clase_vuelo es una tabla externa que se importó con la opción de Import Wizard. */
UPDATE vuelos v 
LEFT JOIN clase_vuelo cv
	ON v.clase_vuelo = cv.clase_vuelo
SET v.clase_vuelo = cv.agrupado;

/* 3.2) Evaluamos el resultado obteniendo la cantidad de movimientos y su respectivo porcentaje respecto al total por clase de vuelo: 7 clases de vuelo */
SELECT 
    clase_vuelo,
    COUNT(movimiento) AS movimientos,
    ROUND((COUNT(movimiento) / (SELECT COUNT(movimiento) FROM vuelos) * 100), 2) AS porcentaje
FROM vuelos
GROUP BY 1
ORDER BY 2 DESC;

/* 4) Análisis de columna Tipo_vuelo */
SELECT DISTINCT tipo_vuelo FROM vuelos;

/* 4.1) Agrupamos los vuelos "Cabotaje" y "Domestico" bajo el mismo criterio. */
UPDATE vuelos 
SET 
    tipo_vuelo = (CASE
        WHEN tipo_vuelo = 'CABOTAJE' OR tipo_vuelo="Domestico" THEN 'Doméstico'
        WHEN tipo_vuelo = 'INTERNACIONAL' THEN 'Internacional'
        ELSE tipo_vuelo
    END);
    
/* 4.2) Evaluamos el resultado: 83% de los vuelos son domésticos, mientras que un 16% es internacional. */
SELECT 
    tipo_vuelo,
    ROUND((COUNT(movimiento) / (SELECT COUNT(movimiento) FROM vuelos) * 100), 2) AS porcentaje
FROM vuelos
GROUP BY 1
ORDER BY 2 DESC;

/* 5) Análisis de columna "Movimiento": se genera una fila por cada movimiento ya sea aterrizaje o despegue de aeronave. Por lo tanto cada vuelo 
generará 2 movimientos: despegue y aterrizaje (dos records).*/
SELECT DISTINCT movimiento, COUNT(movimiento) FROM vuelos
GROUP BY movimiento;

/* 6) Análisis de columnas "Aeropuerto" y "Origen Destino".
 Los aeropuertos locales están representados bajo el código local FAA que consiste en 3 letras, mientras que los aeropuertos internacionales se rigen bajo códigos OACI.
 Cargamos dos tablas externas a nuestra base de datos: "Aero_nacional" con el detalle de todos los aerodromos locales, y "aero_internacional" con el detalle de los internacionales.
 La carga se realiza utilizando la opción "Import Wizard".
*/

SELECT * FROM aero_nacional;

SELECT * FROM aero_internacional;

/*Creamos un procedure que toma como input algún código de aeropuerto (FAA o OACI), y nos entrega información complementaria:*/
DELIMITER $$
CREATE PROCEDURE info_aeropuerto(IN codigo_input VARCHAR(10))
BEGIN
	WITH cte AS (SELECT codigo, denominacion, referencia AS ciudad, provincia AS provincia_pais FROM aero_nacional
		UNION
        SELECT codigo, denominacion, ciudad, pais FROM aero_internacional)
	SELECT * FROM cte WHERE codigo=codigo_input;
END $$
DELIMITER ;

/*Consultamos el aeropuerto de Madrid LEMD o el aeropuerto nacional de Mendoza DOZ: */
CALL info_aeropuerto("LEMD");
CALL info_aeropuerto("DOZ");

/* 6.1) Aplicaremos la siguiente lógica en el análisis: solo consideraremos como válidos a los códigos de columna "aeropuerto" y "origen_destino" que estén presentes 
en las tablas [aero_nacional] y [aero internacional], esto se debe a la necesidad de conocer a que ciudad o país corresponde cada código. A su vez, eliminaremos de estas tablas
los códigos de aeropuertos que no tengan movimientos en la tabla [Vuelos] ya que no son de nuestra incumbencia. */

/*Listado único de aeropuertos nacionales e internacionales con movimientos:*/
SELECT aeropuerto from vuelos
UNION
SELECT origen_destino from vuelos;

/*Listado único de aeropuertos nacionales e internacionales según tablas externas:*/
SELECT codigo FROM aero_nacional
UNION
SELECT codigo FROM aero_internacional;

/*Listado de Aeropuertos (códigos) no encontrados en tablas externas. Según la lógica antes mencionada, no serán tenidos en cuenta*/
SELECT a.codigo FROM (
	SELECT aeropuerto AS codigo from vuelos
	UNION
	SELECT origen_destino from vuelos) a
LEFT JOIN (
	SELECT codigo FROM aero_nacional
	UNION
	SELECT codigo FROM aero_internacional) b ON a.codigo=b.codigo
WHERE b.codigo IS NULL;

/*Creamos una columna auxiliar en tabla "Vuelos" donde calificaremos como "Válido" o "No Válido" el código de aeropuerto u origen/destino */
ALTER TABLE vuelos ADD codigo_valido VARCHAR(20);

WITH cte as (
	SELECT a.codigo FROM (SELECT aeropuerto AS codigo from vuelos
	UNION
	SELECT origen_destino from vuelos) a
	LEFT JOIN (SELECT codigo FROM aero_nacional
	UNION
	SELECT codigo FROM aero_internacional) b ON a.codigo=b.codigo
	WHERE b.codigo IS NULL)
UPDATE vuelos 
SET codigo_valido = 
	CASE 
		WHEN aeropuerto IN (SELECT * FROM cte) OR origen_destino IN (SELECT * FROM cte) THEN "No valido" 
		ELSE "Valido"
        END;
        
/* Existen 25.403 movimientos que no pueden vincularse a códigos de aeropuertos conocidos */
SELECT codigo_valido, COUNT(*) FROM vuelos
GROUP BY 1;

/* 6.2) Códigos de aeropuertos de tabla "aero_nacional" que no tienen movimientos registrados en tabla "Vuelos": */
SELECT a.codigo FROM (
	SELECT DISTINCT codigo FROM aero_nacional) a
LEFT JOIN (
	SELECT aeropuerto AS codigo from vuelos
	UNION
	SELECT origen_destino from vuelos) b ON a.codigo=b.codigo
WHERE b.codigo IS NULL;

/* Procedemos a eliminarlos de la tabla: */
with CTE as (
	SELECT a.codigo FROM (
		SELECT DISTINCT codigo FROM aero_nacional) a
	LEFT JOIN (
		SELECT aeropuerto AS codigo from vuelos
		UNION
		SELECT origen_destino from vuelos) b ON a.codigo=b.codigo
	WHERE b.codigo IS NULL)
DELETE FROM aero_nacional WHERE codigo IN (SELECT * FROM cte);

/* 6.3) Códigos de aeropuertos de tabla "aero_internacional" que no tienen movimientos registrados en tabla "Vuelos": */
SELECT a.codigo FROM (
	SELECT DISTINCT codigo FROM aero_internacional) a
LEFT JOIN (
	SELECT aeropuerto AS codigo from vuelos
	UNION
	SELECT origen_destino from vuelos) b ON a.codigo=b.codigo
WHERE b.codigo IS NULL;

/* Procedemos a eliminarlos de la tabla: */
with CTE as (
	SELECT a.codigo FROM (SELECT DISTINCT codigo FROM aero_internacional) a
	LEFT JOIN (
		SELECT aeropuerto AS codigo from vuelos
		UNION
		SELECT origen_destino from vuelos) b ON a.codigo=b.codigo
	WHERE b.codigo IS NULL)
DELETE FROM aero_internacional WHERE codigo IN (SELECT * FROM cte);

/* 7) Análisis de columna "aerolinea": a priori se observan 2.126 aerolíneas distintas. */
SELECT 
	AEROLINEA, 
    COUNT(*) 
FROM VUELOS
GROUP BY 1
ORDER BY 2 DESC;

/* 7.1) Actualizamos valores: aquellos records con aerolinea = 0 o vacío, se le imputa N/A. */
UPDATE vuelos 
SET aerolinea = CASE
        WHEN aerolinea = '0' OR aerolinea = '' THEN "N/A"
        ELSE aerolinea
    END;

/* 7.2) Importamos tabla externa "Aerolinea_agrupada" con la opción "Import Wizard" para corregir y agrupar algunas aerolíneas. 
Hacemos un UPDATE de la tabla "Vuelos" mediante un JOIN con "Aerolineas Agrupadas*/
ALTER TABLE vuelos
ADD aerolinea_agrupada VARCHAR(100);

/* Creamos un INDEX en ambas tablas para que el update sea más rapido: */
ALTER TABLE vuelos ADD INDEX (aerolinea);
ALTER TABLE aerolinea_agrupada ADD INDEX (aerolinea);

UPDATE vuelos v 
LEFT JOIN aerolinea_agrupada aa
	ON v.aerolinea = aa.aerolinea
SET v.aerolinea_agrupada = aa.aerolinea_agrupada;

/* Luego del UPDATE, la cantidad de aerolineas agrupadas es de 2053 */
SELECT 
	COUNT(distinct aerolinea), 
	COUNT(distinct aerolinea_agrupada) 
FROM vuelos;

/* 7.3) Analizamos el número de aerolineas por cantidad de movimientos que presenta cada una (excluyendo N/A), y el porcentaje sobre el total que
representan */
SELECT 
  movimientos, 
  cantidad_aerolineas, 
  (SUM(cantidad_aerolineas) OVER(ORDER BY movimientos ASC)) AS suma_aerol_acumulada,
  ROUND(((SUM(cantidad_aerolineas) OVER(ORDER BY movimientos ASC) / SUM(cantidad_aerolineas) OVER ()) * 100), 2)  AS porcentaje_acumulado_aerolineas,
  (SUM(cantidad_aerolineas*movimientos) OVER(ORDER BY movimientos ASC)) AS suma_movimientos_acumulada,
  ROUND(((SUM(cantidad_aerolineas*movimientos) OVER(ORDER BY movimientos ASC) / SUM(cantidad_aerolineas*movimientos) OVER ()) * 100), 2) AS porcentaje_acumulado_movimientos
FROM 
  (SELECT 
	a.movimientos, 
	COUNT(a.movimientos) as cantidad_aerolineas 
  FROM (
	SELECT 
		aerolinea,
		COUNT(*) AS movimientos
    FROM vuelos
    WHERE aerolinea != "N/A"
	GROUP BY aerolinea
	ORDER BY 2 DESC) a
GROUP BY a.movimientos
ORDER BY 1) a
ORDER BY 
  movimientos;
  
/* Observamos que el 87.2% de las aerolíneas presentan <30 movimientos, y el 93.1% presenta <100 en todo el período analizado 2019-2022,
 lo cual nos indica la altísima variabilidad del dato. Al mismo tiempo, ese 87.2% de aerolineas generan 9.075 movimientos (0.87% del total), un valor ínfimo. 
 Para simplificar la columna, agruparemos a todas las aerolineas que presentan menos de 30 movimientos bajo el nombre "Otros". */
UPDATE vuelos v
        LEFT JOIN
    (SELECT 
        aerolinea_agrupada, COUNT(*) AS movimientos
    FROM
        vuelos
    GROUP BY 1) a ON v.aerolinea_agrupada = a.aerolinea_agrupada 
SET 
    v.aerolinea_agrupada = CASE
        WHEN a.movimientos < 30 THEN 'Otros'
        ELSE v.aerolinea_agrupada
    END;
  
/* Luego del UPDATE, la cantidad de aerolineas agrupadas es de 252. */
SELECT 
	COUNT(distinct aerolinea), 
	COUNT(distinct aerolinea_agrupada) 
FROM vuelos;

/* 8) Cambio de formato VARCHAR a INT la columna "Pasajeros"
 8.1) Se encuentran algunos valores decimales, por lo que primero reemplazamos la coma por el punto. */
UPDATE vuelos SET pasajeros = REPLACE(pasajeros, ",", ".");

/* 8.2) Modificamos el tipo de dato a INT.*/
ALTER TABLE vuelos MODIFY COLUMN pasajeros INT;

/* 8.3) Aquellas filas con "Pasajeros" igual a 0, la convertimos a NULL para que no interfiera en las queries posteriores en los cálculos de promedios. */
UPDATE VUELOS SET pasajeros= IF(pasajeros=0, NULL, pasajeros);

/* 9) Analizamos la columna "tipo_dato": el 94.7% de los datos son definitivos. */
SELECT 
    tipo_dato,
    COUNT(*) AS movimientos,
    ROUND((COUNT(*) / (SELECT COUNT(*) FROM vuelos) * 100), 2) AS porcentaje
FROM vuelos
GROUP BY 1
ORDER BY 2 DESC;

##################################################################
##################################################################
##################################################################

/* Consultando los datos, encontramos un error en el Dataset original. La cantidad de pasajeros en vuelos domésticos de 2019 está duplicada.*/

UPDATE vuelos 
SET 
    pasajeros = CASE
        WHEN
            tipo_vuelo = 'Domestico'
                AND YEAR(fecha) = 2019
        THEN
            pasajeros / 2
        ELSE pasajeros
    END;
