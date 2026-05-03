# dbops-project 
### 1. Подключение к PostgreSQL
```
psql -h localhost -p 5432 -U user -d user
```
### 2. Создаём отдельную базу данных:
```
CREATE DATABASE store;
```
### 3. Создаём нового пользователя:
```
CREATE USER pavel WITH PASSWORD '12gammaSTR!';
```
### 4. Выдаём пользователю `pavel` права на базу данных `store`:
```
GRANT ALL PRIVILEGES ON DATABASE store TO pavel;
```
### 5. Назначаем пользователя `pavel` владельцем базы данных `store`:
```
ALTER DATABASE store OWNER TO pavel;
```
### 6. Подключаемся к базе данных `store`:
```
\c store
```
### 7. Выдаём пользователю `pavel` права на использование и создание объектов в схеме `public`:
```
GRANT USAGE, CREATE ON SCHEMA public TO pavel;
```
### 8. Назначаем пользователя `pavel` владельцем схемы `public`:
```
ALTER SCHEMA public OWNER TO pavel;
```

### 9. Запрос для подсчёта проданных сосисок за последние 7 дней
Для получения количества проданных сосисок по каждому дню за последнюю неделю используется соединение таблиц `orders` и `order_product`.
Учитываются только заказы со статусом `shipped`.
```
SELECT
    o.date_created,
    SUM(op.quantity) AS total_sausages_sold
FROM orders AS o
JOIN order_product AS op
    ON o.id = op.order_id
WHERE o.status = 'shipped'
  AND o.date_created > NOW() - INTERVAL '7 DAY'
GROUP BY o.date_created
ORDER BY o.date_created;
```
### 10. Оптимизация запроса с помощью индексов
#### Созданные индексы
```
CREATE INDEX order_product_order_id_idx
ON order_product(order_id);

CREATE INDEX orders_status_date_idx
ON orders(status, date_created);
```
Индекс `order_product_order_id_idx` создан для ускорения соединения таблиц `orders` и `order_product` по полю `order_id`.

Индекс `orders_status_date_idx` создан для ускорения фильтрации заказов по статусу `shipped` и дате создания заказа `date_created`.

#### Сравнение производительности запроса
Для проверки использовался запрос из п. 9

#### Результат выполнения запроса
```text
date_created | total_sausages_sold
-------------+--------------------
2026-04-27   | 951268
2026-04-28   | 945688
2026-04-29   | 934847
2026-04-30   | 938967
2026-05-01   | 948290
2026-05-02   | 945015
2026-05-03   | 531886
```
#### Время выполнения до создания индексов
Обычное выполнение запроса с включённым `\timing`:
```text
Time: 2752.548 ms
```
Фрагмент `EXPLAIN ANALYZE` до создания индексов:
```text
Parallel Hash Join
  Hash Cond: (op.order_id = o.id)
  -> Parallel Seq Scan on order_product op
  -> Parallel Hash
       -> Parallel Seq Scan on orders o
            Filter: ((status)::text = 'shipped'::text)
                    AND (date_created > (CURRENT_DATE - '7 days'::interval))

Planning Time: 1.233 ms
Execution Time: 2394.608 ms
```
До создания индексов PostgreSQL выполнял последовательное параллельное сканирование таблиц `orders` и `order_product`.
#### Время выполнения после создания индексов
Обычное выполнение запроса с включённым `\timing`:
```text
Time: 1870.841 ms
```
Фрагмент `EXPLAIN ANALYZE` после создания индексов:

```text
Parallel Hash Join
  Hash Cond: (op.order_id = o.id)
  -> Parallel Seq Scan on order_product op
  -> Parallel Hash
       -> Parallel Bitmap Heap Scan on orders o
            Recheck Cond: ((status)::text = 'shipped'::text)
                          AND (date_created > (CURRENT_DATE - '7 days'::interval))
            -> Bitmap Index Scan on orders_status_date_idx
                 Index Cond: ((status)::text = 'shipped'::text)
                             AND (date_created > (CURRENT_DATE - '7 days'::interval))

Planning Time: 0.468 ms
Execution Time: 2472.232 ms
```
После создания индексов PostgreSQL начал использовать индекс `orders_status_date_idx` для отбора заказов по статусу и дате.

#### Вывод
После создания индексов обычное время выполнения запроса сократилось с `2752.548 ms` до `1870.841 ms`, то есть примерно на `32%`.
При этом `EXPLAIN ANALYZE` показывает, что индекс `orders_status_date_idx` используется для фильтрации таблицы `orders`.
Таблица `order_product` всё ещё читается через `Parallel Seq Scan`, так как PostgreSQL выбирает параллельное сканирование большой таблицы как более выгодный план для данного объёма данных.
