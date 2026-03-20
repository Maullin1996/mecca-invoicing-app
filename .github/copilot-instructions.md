Contexto del proyecto:

App Flutter offline llamada "Mecca".
Arquitectura simple por features.
No usar Clean Architecture.
No usar Firebase.
Persistencia local con SQLite.
Una sola persona usa la app.
No usar tests.
No agregar dependencias no autorizadas.

Estructura del proyecto:

lib/
  app/
  core/
    database/
  features/
    companies/
    jobs/
    pdf/

Reglas obligatorias:

1. Generar SOLO el archivo solicitado.
2. No crear archivos adicionales.
3. No modificar archivos existentes sin ser solicitado.
4. No mezclar UI con lógica de negocio.
5. Los modelos deben ser completamente inmutables.
6. No incluir lógica de negocio dentro de los modelos.
7. Las funciones de cálculo deben ser funciones puras en archivos separados.
8. Los nombres de campos deben coincidir exactamente con los nombres de columnas SQLite.
9. No agregar paquetes nuevos.
10. Mantener código simple y legible.
11. Todos los campos deben ser final.
12. Constructor const obligatorio.
13. Deben implementar:
   - copyWith()
   - toMap()
   - factory fromMap()

Reglas de negocio oficiales:

minutos_totales = saldo_empresa + minutos_trabajados_dia
horas_cobradas = floor(minutos_totales / 60)
nuevo_saldo = minutos_totales % 60
total_dia = horas_cobradas * valor_hora + valor_anexo

El PDF NO debe mostrar el saldo acumulado.

Tablas obligatorias:

Tabla companies:
- id (int, pk)
- name (text)
- minutes_balance (int)

Tabla jobs:
- id (int, pk)
- company_id (int, fk)
- date (text)
- start_time (text)
- end_time (text)
- minutes_worked (int)
- hours_charged (int)
- value_per_hour (double)
- extra_description (text)
- extra_value (double)
- total_day (double)

Objetivo: mantener consistencia y evitar sobre-ingeniería.