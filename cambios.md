# Cambios realizados

## Nuevo modelo intermediate

Se ha creado el fichero [int_payment_status_summary.sql](models/intermediate/int_payment_status_summary.sql).

Este modelo contiene la lógica de cálculo solicitada:

- lee los pedidos desde `stg_orders`;
- lee los pagos desde `stg_payments`;
- relaciona ambos conjuntos mediante `order_id`;
- suma el importe recibido por combinación de estado y método de pago;
- cuenta cuántos pagos forman cada combinación.

El resultado contiene las columnas `status`, `payment_method`, `total_amount` y `payment_count`.

Este modelo se ha definido como una vista en la capa `intermediate`. Una vista contiene la consulta de agregación sin guardar una copia física independiente de los datos. Por ello, cada consulta recalcula el resultado a partir de las tablas staging.

La documentación de las columnas y sus tipos se ha añadido en [schema.yml](models/intermediate/schema.yml).

Los tipos reales utilizados son:

| Columna | Tipo |
|---|---|
| `status` | `varchar` |
| `payment_method` | `varchar` |
| `total_amount` | `double` |
| `payment_count` | `bigint` |

## Nuevo modelo marts

Se ha creado el fichero [payment_status_summary.sql](models/marts/payment_status_summary.sql).

Este modelo representa los resultados finales solicitados. Su SQL se ha mantenido sencillo:

- proyecta las cuatro columnas finales;
- lee los datos desde `int_payment_status_summary`;
- no repite la lógica de agregación ni la unión entre pedidos y pagos.

La documentación y los tipos del modelo final se han añadido a [schema.yml](models/marts/schema.yml). La descripción detallada del modelo, su relación y el significado de los métodos de pago se han añadido a [docs.md](models/marts/docs.md).

## Tests

Se han añadido tests genéricos de dbt y un test SQL personalizado.

Los tests comprueban:

- que `status`, `payment_method`, `total_amount` y `payment_count` no sean nulos;
- que `status` sólo tenga uno de los estados válidos:
  `placed`, `shipped`, `completed`, `return_pending` y `returned`;
- que `payment_method` sólo tenga uno de los métodos válidos:
  `credit_card`, `coupon`, `bank_transfer` y `gift_card`;
- que los valores de `status` tengan relación con `stg_orders.status`;
- que los valores de `payment_method` tengan relación con `stg_payments.payment_method`;
- que cada combinación de `status` y `payment_method` sea única.

El test de unicidad se encuentra en [assert_payment_status_summary_unique.sql](tests/assert_payment_status_summary_unique.sql).

Este test agrupa los resultados por `status` y `payment_method` y falla si alguna combinación aparece más de una vez:

```sql
having count(*) > 1
```

Los mismos tests básicos y valores aceptados también se aplican al modelo intermediate. De este modo se detecta antes una alteración en los datos agregados.

## Estrategia de actualización

El modelo de marts utiliza una tabla incremental:

```sql
materialized='incremental'
incremental_strategy='delete+insert'
unique_key=['status', 'payment_method']
```

La clave única está formada por `status` y `payment_method`. En cada ejecución:

1. dbt calcula la agrupación de pedidos y pagos.
2. elimina las combinaciones existentes identificadas por la clave compuesta.
3. inserta nuevamente sus resultados actualizados.

Esta opción es adecuada porque los datos deben mantenerse disponibles como resultado agregado y no conviene recalcular completamente la vista para cada consulta.

Además, el proyecto no dispone de una columna temporal como `updated_at`. Por ello, no puede procesar únicamente los pagos modificados desde la ejecución anterior y utiliza una reconstrucción incremental basada en las combinaciones de estado y método de pago.

Si se necesitan datos completamente reconstruidos, puede ejecutarse:

```powershell
dbt run --select payment_status_summary --full-refresh
```
