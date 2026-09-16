-- =============================================================================
-- Q2) Write down stored procedures to accept input values as a parameter
--     and update values of the tables
-- =============================================================================
--
-- ONE-BREATH ANSWER
--   Same machinery as Q1, sharper point: `update_salary` changes ONE row by
--   primary key, `update_dept` puts the parameter in the WHERE clause so a
--   single CALL can change MANY rows. A parameter can drive the WHERE clause,
--   not just the SET list.
--
-- Run:  psql "postgresql://postgres:postgres@127.0.0.1:54422/postgres" -f q2.sql
-- =============================================================================


drop table if exists employee cascade;

create table employee(
    emp_id   INT Primary Key,
    emp_name VARCHAR(50),
    dept     VARCHAR(50),
    salary   INT
);

insert into employee values
(1, 'Ted Mosby',         'Architect', 50000),
(2, 'Marshall Eriksen',  'Legal',     60000),
(3, 'Barney Stinson',    'Please',    90000),
(4, 'Robin Scherbatsky', 'News',      55000);


-- -----------------------------------------------------------------------------
-- Procedure 1: parameter targets ONE row  (WHERE on the primary key)
-- -----------------------------------------------------------------------------
create or replace procedure update_salary(
    p_emp_id INT,                            -- identifies the row
    p_salary INT                             -- the new value
)
language plpgsql
as $$
begin
    update employee
    set salary = p_salary
    where emp_id = p_emp_id;                 -- PK -> at most 1 row
end;
$$;

-- -----------------------------------------------------------------------------
-- Procedure 2: parameter targets MANY rows (WHERE on a non-key column)
-- -----------------------------------------------------------------------------
-- This is the real point of Q2. The parameter is in the WHERE clause, so how
-- many rows change depends on the DATA, not on the number of arguments.
create or replace procedure update_dept(
    p_old_dept VARCHAR(50),                  -- the search value
    p_new_dept VARCHAR(50)                   -- the replacement value
)
language plpgsql
as $$
begin
    update employee
    set dept = p_new_dept
    where dept = p_old_dept;                 -- non-key -> 0, 1 or many rows
end;
$$;


call update_salary(1, 65000);                -- Ted: 50000 -> 65000
call update_dept('Please', 'Marketing');     -- every 'Please' row -> 'Marketing'

select * from employee order by emp_id;


-- #############################################################################
-- WHY EVERY PARAMETER IS PREFIXED WITH p_
-- #############################################################################
--
-- PL/pgSQL substitutes its own variables into SQL. If a parameter has the same
-- name as a column, the reference is ambiguous. PostgreSQL rejects it outright
-- -- try this to see it for yourself:
--
--   create or replace procedure bad_update(emp_id int, salary int)
--   language plpgsql as $$
--   begin
--       update employee set salary = salary where emp_id = emp_id;
--   end; $$;
--
--   call bad_update(1, 99);
--
--   ERROR:  column reference "emp_id" is ambiguous
--   DETAIL: It could refer to either a PL/pgSQL variable or a table column.
--
-- Worth saying in the viva: in a language WITHOUT that check, the condition
-- would silently become `true` for every row and update the whole table. The
-- p_ prefix is a habit that makes the collision impossible.
--
-- #############################################################################
-- VIVA Q&A
-- #############################################################################
--
-- Q: What is the difference between your Q1 and your Q2?
-- A: Q1 demonstrates the two DML shapes -- one procedure that inserts, one
--    that updates. Q2 is specifically about PARAMETERS DRIVING BEHAVIOUR:
--    update_salary(1, 65000) targets one row by primary key, while
--    update_dept('Please','Marketing') puts the parameter in the WHERE clause,
--    so one CALL can modify any number of rows.
--
-- Q: What happens if no row matches?
-- A: Nothing, and NO error. UPDATE affecting zero rows is a success. If you
--    need to know, read the row count inside the procedure:
--
--       declare v_n int;
--       begin
--           update employee set salary = p_salary where emp_id = p_emp_id;
--           get diagnostics v_n = row_count;
--           if v_n = 0 then
--               raise exception 'No employee with id %', p_emp_id;
--           end if;
--       end;
--
--    GET DIAGNOSTICS ... = ROW_COUNT is the idiom; expect it as a follow-up.
--
-- Q: Can you call a procedure with named arguments?
-- A: Yes -- CALL update_dept(p_new_dept => 'Marketing', p_old_dept => 'Please');
--    Named ("=>") notation lets you reorder arguments and is much safer when a
--    procedure takes several parameters of the same type.
--
-- Q: Can parameters have defaults?
-- A: Yes -- p_salary INT DEFAULT 0. Defaulted parameters must come last.
--
-- Q: Is the UPDATE inside the procedure atomic?
-- A: Yes. A single UPDATE statement is atomic -- update_dept either changes all
--    matching rows or none. If the procedure ran several statements and you
--    wanted them atomic together, that is what the surrounding transaction (or
--    an explicit COMMIT inside the procedure) is for.
--
-- Q: Could a trigger do this instead?
-- A: No, and this is the useful contrast. A trigger cannot be handed
--    'Please' and 'Marketing' -- it takes no arguments from a caller. A
--    trigger reacts to a change; a procedure performs one. See the table
--    below.
--
-- #############################################################################
-- TABLE: STORED PROCEDURE vs TRIGGER          <- most likely comparison asked
-- #############################################################################
-- One-sentence answer: a procedure runs because someone CALLS it; a trigger
-- runs because something HAPPENED to a table.
--
--   Aspect            | Stored procedure            | Trigger
--   ------------------+-----------------------------+--------------------------
--   Invocation        | explicit - you write CALL   | implicit - the server
--                     |                             | fires it on an event
--   Bound to          | nothing; callable anywhere  | one table + specific
--                     |                             | events
--   Parameters        | yes, supplied per call      | none from the caller;
--                     |                             | only fixed TG_ARGV values
--                     |                             | set at CREATE TRIGGER
--   Sees NEW / OLD    | no                          | yes - its whole advantage
--   Can be bypassed   | yes - nothing forces a      | no, for ordinary DML on
--                     | caller to use it            | that table
--   Transaction ctrl  | can COMMIT / ROLLBACK       | cannot - runs inside the
--                     |                             | firing statement
--   Return value      | none (values via INOUT)     | returns a row or NULL;
--                     |                             | only meaningful for
--                     |                             | BEFORE ROW
--   Object in PG      | a PROCEDURE (prokind='p')   | a FUNCTION ... RETURNS
--                     |                             | trigger + a TRIGGER that
--                     |                             | binds it to a table
--   Typical use       | a business operation, a     | enforce a rule, audit a
--                     | batch job, reusable logic   | change, derive a column
--   These labs        | Q1, Q2                      | Q3, Q4, Q5
--
-- Next: q3.sql introduces triggers -- note that a trigger is TWO objects.
-- =============================================================================
