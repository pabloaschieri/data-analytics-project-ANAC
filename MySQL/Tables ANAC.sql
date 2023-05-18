#Tablas para cargar en Google CLOUD

#Tabla para mostrar calidad del DATASET
SELECT "Completos / Incompletos" AS eje, "No" as Tipo, totales-completos AS records FROM (SELECT COUNT(*) AS totales FROM vuelos_backup) a
CROSS JOIN (
SELECT COUNT(*) AS completos FROM vuelos) b
UNION
SELECT "Completos / Incompletos" AS eje, "Si" as Tipo, COUNT(*) AS Records FROM vuelos
UNION
SELECT "Válidos / No Válidos" AS eje, "No" as Tipo, COUNT(*) AS Records FROM vuelos
WHERE codigo_valido = "No valido"
UNION 
SELECT "Válidos / No Válidos" AS eje, "Si" as Tipo, COUNT(*) AS Records FROM vuelos
WHERE codigo_valido = "Valido"
UNION 
SELECT "Definitivos / Provisorios" AS eje, "No" as Tipo, COUNT(*) AS Records FROM vuelos
WHERE codigo_valido = "Valido" and tipo_dato="Provisorio"
UNION 
SELECT "Definitivos / Provisorios" AS eje, "Si" as Tipo, COUNT(*) AS Records FROM vuelos
WHERE codigo_valido = "Valido" and tipo_dato="Definitivo";

#Tabla Introduccion 1
SELECT 
    DATE_FORMAT(fecha, '%Y-%m') AS fecha,
    tipo_vuelo,
    clase_vuelo,
    SUM(pasajeros) AS Pasajeros,
    COUNT(movimiento) AS Movimientos
FROM
    vuelos
WHERE
    codigo_valido = 'Valido'
GROUP BY 1 , 2 , 3;

#Tabla Introducción 2
SELECT a.*, b.pasajeros_total, movimientos_total FROM(
	SELECT
		tipo_vuelo,
		aerolinea_agrupada, 
		sum(pasajeros),
		rank() OVER (PARTITION BY tipo_vuelo ORDER BY sum(pasajeros) DESC) as Ranking_pasajeros,
		count(movimiento) as movimientos,
		rank() OVER (PARTITION BY tipo_vuelo ORDER BY count(movimiento) DESC) as Ranking_movimientos
	FROM VUELOS
    WHERE codigo_valido="Valido" and (clase_vuelo="Regular" OR clase_vuelo="No regular")
	GROUP BY 1, 2
	ORDER BY 3 DESC) a
JOIN (
	SELECT
		tipo_vuelo,
		sum(pasajeros) as pasajeros_total,
		count(movimiento) as movimientos_total
	FROM VUELOS
    WHERE codigo_valido="valido" and (clase_vuelo="Regular" OR clase_vuelo="No regular")
	GROUP BY 1) b ON a.tipo_vuelo=b.tipo_vuelo
WHERE a.ranking_pasajeros < 6 OR a.ranking_movimientos < 6;

#Tabla Introducción 3
SELECT a.* FROM (SELECT 
	v.tipo_vuelo,
	v.aeropuerto,
    aero.denominacion,
    aero.ciudad,
    aero.pais as provincia_pais,
    aero.latitud,
    aero.longitud,
	sum(v.pasajeros) as pasajeros_total,
    rank() OVER (PARTITION BY tipo_vuelo ORDER BY sum(pasajeros) DESC) as Ranking_pasajeros,
	count(v.movimiento) as movimientos_total,
    rank() OVER (PARTITION BY tipo_vuelo ORDER BY count(movimiento) DESC) as Ranking_movimientos
FROM vuelos v
JOIN (SELECT codigo, denominacion, ciudad, pais, latitud, longitud FROM aero_internacional
	UNION
	SELECT codigo, denominacion, referencia, provincia, latitud, longitud FROM aero_nacional) aero
ON v.aeropuerto=aero.codigo
WHERE codigo_valido="valido" and (clase_vuelo="Regular" OR clase_vuelo="No regular")
GROUP BY 1, 2, 3, 4, 5, 6, 7) a
WHERE a.ranking_pasajeros < 11 OR a.ranking_movimientos < 11;

#Tabla Domestico
SELECT 
    DATE_FORMAT(v.fecha, '%Y-%m') AS fecha,
    v.aeropuerto,
    an.denominacion,
    an.referencia,
    an.provincia,
    v.aerolinea_agrupada AS Aerolinea,
    SUM(v.pasajeros) AS pasajeros,
    COUNT(v.movimiento) AS movimientos
FROM
    vuelos v
        JOIN
    aero_nacional an ON v.aeropuerto = an.codigo
WHERE
    tipo_vuelo = 'Domestico'
        AND (clase_vuelo = 'Regular'
        OR clase_vuelo = 'No regular')
        AND codigo_valido = 'Valido'
GROUP BY 1 , 2 , 3 , 4 , 5 , 6;

#Tabla Internacional
SELECT 
    DATE_FORMAT(v.fecha, '%Y-%m') AS fecha,
    v.aeropuerto,
    an.denominacion,
    an.referencia,
    an.provincia,
    v.aerolinea_agrupada AS Aerolinea,
    SUM(v.pasajeros) AS pasajeros,
    COUNT(v.movimiento) AS movimientos
FROM
    vuelos v
        JOIN
    aero_nacional an ON v.aeropuerto = an.codigo
WHERE
    tipo_vuelo = 'Internacional'
        AND (clase_vuelo = 'Regular'
        OR clase_vuelo = 'No regular')
        AND codigo_valido = 'Valido'
GROUP BY 1 , 2 , 3 , 4 , 5 , 6;

#Para la ultima tabla, vamos a crear un set de tablas intermedias para luego combinarlas.
#Creamos tabla con listado de aeropuertos unificado
CREATE TABLE aero_unificados AS SELECT codigo,
    denominacion,
    referencia AS ciudad,
    provincia AS provincia_pais,
    ROUND(latitud, 3) AS Latitud,
    ROUND(longitud, 3) AS Longitud,
    elevacion FROM
    aero_nacional 
UNION SELECT 
    codigo,
    denominacion,
    ciudad,
    pais,
    ROUND(latitud, 3) AS Latitud,
    ROUND(longitud, 3) AS Longitud,
    ' ' AS elevacion
FROM
    aero_internacional;


#Creamos tabla con listado de rutas
CREATE TABLE rutas AS
with cte AS (
	SELECT
		DATE_FORMAT(fecha, '%Y-%m') AS fecha,
        tipo_vuelo,
		CONCAT(LEAST(aeropuerto, origen_destino), ' - ', GREATEST(aeropuerto, origen_destino)) AS Ruta,
		aeropuerto AS origen,
		origen_destino AS destino,
        aerolinea_agrupada AS aerolinea,
		COUNT(CONCAT(LEAST(aeropuerto, origen_destino), ' - ', GREATEST(aeropuerto, origen_destino))) AS Movimientos,
        SUM(pasajeros) as pasajeros
	FROM 
		vuelos
	WHERE (clase_vuelo="Regular" OR clase_vuelo="No regular") AND codigo_valido="Valido"    
	GROUP BY 1, 2, 3, 4, 5, 6
	ORDER BY 7 DESC)
SELECT
	fecha,
    tipo_vuelo,
	ruta, 
	origen, 
    destino,
    aerolinea,
    SUM(movimientos) OVER(PARTITION BY fecha, tipo_vuelo, ruta, aerolinea) AS movimientos_ruta,
    SUM(pasajeros) OVER(PARTITION BY fecha, tipo_vuelo, ruta, aerolinea) AS pasajeros_ruta
FROM cte
GROUP BY 1, 2, 3, 4, 5, 6
ORDER BY 7 DESC;

#Creamos tabla con listado de rutas y su actuación en los últimos 6 meses
CREATE TABLE rutas_U6M AS
	with cte AS (
		SELECT
			tipo_vuelo,
			CONCAT(LEAST(aeropuerto, origen_destino), ' - ', GREATEST(aeropuerto, origen_destino)) AS Ruta,
			aeropuerto AS origen,
			COUNT(CONCAT(LEAST(aeropuerto, origen_destino), ' - ', GREATEST(aeropuerto, origen_destino))) AS Movimientos,
			SUM(pasajeros) as pasajeros
		FROM 
			vuelos
		WHERE (clase_vuelo="Regular" OR clase_vuelo="No regular") AND codigo_valido="Valido" AND fecha > "2022/10/01"  
		GROUP BY 1, 2, 3
		ORDER BY 5 DESC)
	SELECT
		tipo_vuelo,
		ruta, 
		origen, 
		SUM(movimientos) OVER(PARTITION BY tipo_vuelo, ruta) AS movimientos_ruta,
		SUM(pasajeros) OVER(PARTITION BY tipo_vuelo, ruta) AS pasajeros_ruta
	FROM cte
	GROUP BY 1, 2, 3
	ORDER BY 5 DESC;

#Creamos tabla con rutas y rankings
CREATE TABLE rutasU6M_rankings AS
SELECT *,
DENSE_RANK() OVER (PARTITION BY tipo_vuelo ORDER BY pasajeros_ruta DESC) AS rank_pax_tipovuelo,
DENSE_RANK() OVER (PARTITION BY tipo_vuelo ORDER BY movimientos_ruta DESC) AS rank_mov_tipovuelo,
DENSE_RANK() OVER (PARTITION BY origen ORDER BY pasajeros_ruta DESC) AS rank_pax_origen,
DENSE_RANK() OVER (PARTITION BY origen ORDER BY pasajeros_ruta DESC) AS rank_mov_origen
FROM rutas_u6m;

#Tabla final combinando las tablas anteriormente creadas.
SELECT 
    a.*,
    ROUND(111.111 * DEGREES(ACOS(LEAST(1.0, COS(RADIANS(a.latitud_origen)) * COS(RADIANS(a.latitud_destino)) * COS(RADIANS(a.longitud_origen - a.longitud_destino)) + SIN(RADIANS(a.latitud_origen)) * SIN(RADIANS(a.latitud_destino)))))) AS distancia_km
FROM
    (SELECT 
        r.*,
            a.rank_pax_tipovuelo,
            a.rank_mov_tipovuelo,
            a.rank_pax_origen,
            a.rank_mov_origen,
            c.denominacion AS denominacion_origen,
            c.ciudad AS ciudad_origen,
            c.provincia_pais AS provincia_pais_origen,
            ROUND(c.latitud, 2) AS Latitud_origen,
            ROUND(c.longitud, 2) AS longitud_origen,
            c.elevacion AS elevacion_origen,
            d.denominacion AS denominacion_destino,
            d.ciudad AS ciudad_destino,
            d.provincia_pais AS provincia_pais_destino,
            ROUND(d.latitud, 2) AS Latitud_destino,
            ROUND(d.longitud, 2) AS longitud_destino,
            d.elevacion AS elevacion_destino
    FROM
        rutas r
    LEFT JOIN rutasU6M_rankings a ON r.tipo_vuelo = a.tipo_vuelo
        AND r.ruta = a.ruta
        AND r.origen = a.origen
    LEFT JOIN aero_unificados c ON r.origen = c.codigo
    LEFT JOIN aero_unificados d ON r.destino = d.codigo) a;
