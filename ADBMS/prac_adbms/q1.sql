-- =============================================================================
-- Q1) Write down Stored Procedure for inserting, updating values in the table
-- =============================================================================
--
-- Run:  psql "postgresql://postgres:postgres@127.0.0.1:54422/postgres" -f q1.sql
-- =============================================================================


-- Reset first so the whole file can be re-run as many times as you like.
-- (CREATE TABLE has no "OR REPLACE" -- only functions/procedures do -- which is
--  why tables need DROP ... IF EXISTS or CREATE TABLE IF NOT EXISTS instead.)
drop table if exists student cascade;

create table student(
    stud_id   INT Primary Key,
    stud_name VARCHAR(50),
    course    VARCHAR(50),
    marks     INT
);


-- -----------------------------------------------------------------------------
-- Procedure 1: insert a student
-- -----------------------------------------------------------------------------
create or replace procedure insert_stud(     -- OR REPLACE: re-runnable
    p_stud_id   INT,                         -- all four are IN parameters
    p_stud_name VARCHAR(50),                 -- (IN is the default mode)
    p_course    VARCHAR(50),
    p_marks     INT
)
language plpgsql                             -- plain SQL has no IF/loops/vars
as $$                                        -- dollar quoting: body as a string
begin                                        -- a PL/pgSQL BLOCK, not a txn
    insert into student(stud_id, stud_name, course, marks)
    values (p_stud_id, p_stud_name, p_course, p_marks);
end;
$$;

-- -----------------------------------------------------------------------------
-- Procedure 2: update a student
-- -----------------------------------------------------------------------------
create or replace procedure update_stud(
    p_stud_id INT,                           -- which row (the key)
    p_course  VARCHAR(50),                   -- what changes
    p_marks   INT
)
language plpgsql
as $$
begin
    update student
    set course = p_course,
        marks  = p_marks
    where stud_id = p_stud_id;
end;
$$;


-- CALL is the only way to invoke a procedure. It returns no result set --
-- psql just echoes "CALL".
call insert_stud(1, 'Jake Peralta', 'MCA', 78);
call insert_stud(2, 'Amy Santiago', 'MCA', 98);
call insert_stud(3, 'Rosa Diaz',    'MBA', 85);

call update_stud(1, 'MCA', 88);

select * from student order by stud_id;

