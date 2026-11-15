# Tarea 6 - Arquitectura de Aplicaciones Big Data

**Caso de estudio:** Empresa "Sustancias Locas"
**Materia:** ET0155 Fundamentos de Big Data - G102
**Estudiantes:** Anderson Cañas Alcaraz, Samuel López Castañeda, Mauricio López Céspedes, Sebastián López Soto

## Contenido del repositorio

| Archivo | Descripción | Criterios de la rúbrica |
|---|---|---|
| `Informe-Tarea6-Arquitectura-BigData.docx` | Informe completo: gobierno de datos, conceptos de Big Data, arquitectura, diseño de la hoja de cálculo, diseño de la base de datos, conclusiones | 1, 2, 3, 4, 5, 6, 8 |
| `arquitectura-bigdata-sustancias-locas-CORREGIDO.png` | Diagrama de la arquitectura Big Data (sensores, servidor local, nube AWS, visualización) | 2 |
| `hoja-calculo-lecturas.xlsx` | Hoja de cálculo "lecturas": ejemplo de un sensor (1 día) y de la Fábrica A (1 hora) | 4 |
| `script-base-datos-monitoreo-produccion.sql` | Script de creación y poblamiento de la base de datos PostgreSQL "monitoreo-produccion" | 5, 6, 7 |
| `Intrucciones/` | Enunciado, caso de estudio, instructivo y rúbrica suministrados por el profesor | — |

## Base de datos "monitoreo-produccion"

El script crea 11 tablas (fábricas, líneas de producción, microcontroladores, sensores, productos, tipos de filtro, empleados, turnos, empleado-turno, clasificación de ppm y lecturas) y queda poblada con:

- 3 fábricas
- 12 líneas de producción
- 240 microcontroladores
- 240 sensores
- 720 lecturas con valores de ppm variados, clasificadas en los 4 niveles de alarma (Seguro, Vigilancia, Alerta, Crítico)
