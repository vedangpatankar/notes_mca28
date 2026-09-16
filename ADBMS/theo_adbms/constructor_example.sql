-- Constructor example

-- 1. Define a structured type
CREATE TYPE addr_type AS (
    city  varchar(30),
    pin   char(6)
);

-- 2. Use the type as a column
CREATE TABLE emp (
    emp_id   int,
    emp_name varchar(20),
    emp_addr addr_type
);

-- 3. Build the value with the constructor ROW(...)
INSERT INTO emp VALUES (101, 'Vidit', ROW('Pune','411038'));
INSERT INTO emp VALUES (102, 'Tony',  ROW('Mumbai','400001'));

-- 4. Display
SELECT * FROM emp;

SELECT emp_id,
       emp_name,
       (emp_addr).city,
       (emp_addr).pin
FROM   emp;
