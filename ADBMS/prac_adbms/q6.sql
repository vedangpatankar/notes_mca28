-- Q6: Create index and measure the performance of a query on the table.

-- ---------- 1. Setup: create the table and load 100 test rows ----------
drop table if exists students;

Create TABLE students(
    stud_id serial primary key,
    name varchar(100),
    department varchar(50),
    city varchar(50),
    marks int
);

insert into students (name, department, city, marks)
select 
    concat('student', generate_series),
    CASE
        when generate_series % 3 = 0 then 'MCA'
        when generate_series % 3 = 1 then 'MBA'
        else 'Mtech'
    end,
    CASE
        when generate_series % 3 = 0 then 'Delhi'
        when generate_series % 3 = 1 then 'Mumbai'
        else 'Pune'
    end,
    (random() * 100)::int
from generate_series(1, 100);


-- A sample of the generated data.
select * from students limit 5;

-- ---------- 2. Performance BEFORE creating the index ----------

explain analyze select * from students where marks > 90;

-- ---------- 3. Create the index ----------
create index idx_stud_marks on students(marks);

\d students
