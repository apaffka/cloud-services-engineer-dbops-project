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
