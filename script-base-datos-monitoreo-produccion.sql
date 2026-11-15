-- ============================================================
-- Base de datos "monitoreo-produccion"
-- Tarea 6 - Unidad 3 - Caso de estudio "Sustancias Locas"
-- ET0155 Fundamentos de Big Data - G102
-- NOTA: Este script fue diseñado y revisado, pero por falta de
-- tiempo no se alcanzó a ejecutar y verificar en pgAdmin antes
-- de la entrega. Queda pendiente correrlo y poblarlo.
-- ============================================================

-- Activamos PostGIS para poder guardar latitud/longitud como un punto geográfico real.
-- Si el motor no tiene PostGIS instalado, reemplazar las columnas GEOGRAPHY(POINT)
-- por dos columnas NUMERIC(9,6): latitud y longitud.
CREATE EXTENSION IF NOT EXISTS postgis;

-- Catálogo de fábricas (A, B, C)
CREATE TABLE fabricas (
    id_fabrica    CHAR(1) PRIMARY KEY,   -- 'A', 'B', 'C'
    nombre        VARCHAR(50) NOT NULL,
    direccion     VARCHAR(100),
    ubicacion     GEOGRAPHY(POINT)       -- lat/long de la fábrica
);

-- Líneas de producción: 4 por cada fábrica (A1..A4, B1..B4, C1..C4)
CREATE TABLE lineas_produccion (
    id_linea      VARCHAR(5) PRIMARY KEY,  -- 'A1', 'A2', ...
    id_fabrica    CHAR(1) REFERENCES fabricas(id_fabrica),
    nombre        VARCHAR(50)
);

-- Microcontroladores ESP8266: 20 por línea
CREATE TABLE microcontroladores (
    id_microcontrolador VARCHAR(10) PRIMARY KEY, -- 'A1M01', ...
    id_linea             VARCHAR(5) REFERENCES lineas_produccion(id_linea),
    modelo               VARCHAR(30) DEFAULT 'ESP8266',
    fecha_instalacion    DATE
);

-- Sensores MQ-135: 1 por microcontrolador
CREATE TABLE sensores (
    id_sensor           VARCHAR(10) PRIMARY KEY, -- 'A1S01', ...
    id_microcontrolador VARCHAR(10) REFERENCES microcontroladores(id_microcontrolador),
    modelo              VARCHAR(30) DEFAULT 'MQ-135',
    fecha_calibracion   DATE
);

-- Productos químicos (benceno y otros)
CREATE TABLE productos (
    id_producto   SERIAL PRIMARY KEY,
    nombre        VARCHAR(50) NOT NULL,
    es_toxico     BOOLEAN DEFAULT FALSE
);

-- Tipos de filtro (incluye los costosos de última generación)
CREATE TABLE tipos_filtro (
    id_tipo_filtro      SERIAL PRIMARY KEY,
    nombre              VARCHAR(50),
    duracion_estimada_dias INT,       -- proveedor dice 15 días
    costo_usd           NUMERIC(10,2) -- ~300 dólares
);

-- Empleados
CREATE TABLE empleados (
    id_empleado   SERIAL PRIMARY KEY,
    nombre        VARCHAR(80),
    cargo         VARCHAR(30) -- 'Operario' o 'Supervisor'
);

-- Turnos de 8 horas
CREATE TABLE turnos (
    id_turno      SERIAL PRIMARY KEY,
    nombre        VARCHAR(20),
    hora_inicio   TIME,
    hora_fin      TIME
);

-- Qué empleado trabajó qué turno, en qué fecha y fábrica
CREATE TABLE empleado_turno (
    id_empleado   INT REFERENCES empleados(id_empleado),
    id_turno      INT REFERENCES turnos(id_turno),
    id_fabrica    CHAR(1) REFERENCES fabricas(id_fabrica),
    fecha         DATE,
    PRIMARY KEY (id_empleado, id_turno, id_fabrica, fecha)
);

-- Clasificación de peligrosidad del benceno (propuesta según Anexo A: normas OSHA/NIOSH)
-- OJO: verificar contra la tabla del Anexo A del instructivo por si trae valores distintos.
CREATE TABLE clasificacion_ppm (
    id_clasificacion SERIAL PRIMARY KEY,
    nivel            VARCHAR(20),   -- 'Seguro','Vigilancia','Alerta','Crítico'
    ppm_min          NUMERIC(6,3),
    ppm_max          NUMERIC(6,3),
    accion           VARCHAR(100)
);

-- La tabla principal: lecturas de los sensores
-- (debe tener igual o más columnas que la hoja de cálculo "lecturas")
CREATE TABLE lecturas (
    id_lectura       BIGSERIAL PRIMARY KEY,
    id_sensor        VARCHAR(10) REFERENCES sensores(id_sensor),
    fecha            DATE NOT NULL,
    hora             TIME NOT NULL,
    ppm_benceno      NUMERIC(6,3) NOT NULL,
    ubicacion        GEOGRAPHY(POINT),        -- lat/long del sensor
    id_clasificacion INT REFERENCES clasificacion_ppm(id_clasificacion),
    recibido_en      TIMESTAMP DEFAULT now()  -- cuándo llegó al servidor
);

-- ============================================================
-- POBLAMIENTO (datos de ejemplo / simulados)
-- ============================================================

-- 3 fábricas
INSERT INTO fabricas (id_fabrica, nombre, direccion, ubicacion) VALUES
 ('A','Fábrica A','Zona Industrial 1', ST_GeogFromText('POINT(-75.60 6.25)')),
 ('B','Fábrica B','Zona Industrial 2', ST_GeogFromText('POINT(-75.61 6.26)')),
 ('C','Fábrica C','Zona Industrial 3', ST_GeogFromText('POINT(-75.62 6.27)'));

-- 4 líneas por fábrica (12 en total)
INSERT INTO lineas_produccion (id_linea, id_fabrica, nombre)
SELECT f.id_fabrica || n, f.id_fabrica, 'Línea ' || f.id_fabrica || n
FROM fabricas f, generate_series(1,4) AS n;

-- 20 microcontroladores por línea (240 en total)
INSERT INTO microcontroladores (id_microcontrolador, id_linea, fecha_instalacion)
SELECT l.id_linea || 'M' || lpad(n::text,2,'0'), l.id_linea, CURRENT_DATE
FROM lineas_produccion l, generate_series(1,20) AS n;

-- 1 sensor por microcontrolador (240 en total)
INSERT INTO sensores (id_sensor, id_microcontrolador, fecha_calibracion)
SELECT replace(m.id_microcontrolador,'M','S'), m.id_microcontrolador, CURRENT_DATE
FROM microcontroladores m;

-- Productos químicos de la fábrica
INSERT INTO productos (nombre, es_toxico) VALUES
 ('Benceno', true),
 ('Tolueno', true),
 ('Xileno', false);

-- Tipos de filtro
INSERT INTO tipos_filtro (nombre, duracion_estimada_dias, costo_usd) VALUES
 ('Filtro estándar (actual)', 7, 120.00),
 ('Filtro alta eficiencia (nuevo proveedor)', 15, 300.00);

-- Empleados de ejemplo
INSERT INTO empleados (nombre, cargo) VALUES
 ('Carlos Pérez', 'Operario'),
 ('Laura Gómez', 'Operario'),
 ('Andrés Ruiz', 'Supervisor'),
 ('María Torres', 'Operario'),
 ('Juan Díaz', 'Supervisor'),
 ('Sofía Londoño', 'Operario');

-- Los 3 turnos de 8 horas del caso de estudio
INSERT INTO turnos (nombre, hora_inicio, hora_fin) VALUES
 ('Turno 1', '08:00', '16:00'),
 ('Turno 2', '16:00', '00:00'),
 ('Turno 3', '00:00', '08:00');

-- Empleado-turno de ejemplo
INSERT INTO empleado_turno (id_empleado, id_turno, id_fabrica, fecha) VALUES
 (1, 1, 'A', CURRENT_DATE),
 (2, 2, 'A', CURRENT_DATE),
 (3, 3, 'A', CURRENT_DATE),
 (4, 1, 'B', CURRENT_DATE),
 (5, 2, 'B', CURRENT_DATE),
 (6, 3, 'B', CURRENT_DATE);

-- Clasificación de ppm (según Anexo A - verificar contra el PDF por si trae una tabla distinta)
INSERT INTO clasificacion_ppm (nivel, ppm_min, ppm_max, accion) VALUES
 ('Seguro',      0.000,  0.100, 'Ninguna, monitoreo normal'),
 ('Vigilancia',  0.101,  1.000, 'Revisar sensor y filtro'),
 ('Alerta',      1.001, 10.000, 'Detener línea de producción'),
 ('Crítico',    10.001, 999.999,'Detener fábrica, llamar bomberos/defensa civil');

-- Muestra representativa de lecturas (no el volumen real diario, solo para probar la estructura)
INSERT INTO lecturas (id_sensor, fecha, hora, ppm_benceno, id_clasificacion)
SELECT
    s.id_sensor,
    CURRENT_DATE,
    (CURRENT_TIME - (random()*8*3600)::int * interval '1 second')::time, -- hora simulada
    v.ppm,                                                                -- valor simulado de ppm
    (SELECT c.id_clasificacion FROM clasificacion_ppm c
     WHERE v.ppm BETWEEN c.ppm_min AND c.ppm_max LIMIT 1)                 -- clasificación según el ppm real
FROM sensores s
CROSS JOIN generate_series(1,3) AS i                 -- 3 lecturas de muestra por sensor
CROSS JOIN LATERAL (SELECT round((random()*12)::numeric,3) AS ppm) AS v; -- ppm aleatorio entre 0 y 12

-- Verificación rápida (correr después de los inserts)
SELECT
  (SELECT COUNT(*) FROM fabricas)            AS fabricas,      -- esperado: 3
  (SELECT COUNT(*) FROM lineas_produccion)   AS lineas,        -- esperado: 12
  (SELECT COUNT(*) FROM microcontroladores)  AS microcontroladores, -- esperado: 240
  (SELECT COUNT(*) FROM sensores)            AS sensores,      -- esperado: 240
  (SELECT COUNT(*) FROM clasificacion_ppm)   AS clasificacion, -- esperado: 4
  (SELECT COUNT(*) FROM lecturas)            AS lecturas;      -- esperado: 720
