-- =============================================================================
-- Q1) Write down Stored Procedure for inserting, updating values in the table
-- =============================================================================
--
-- ONE-BREATH ANSWER
--   Two PL/pgSQL procedures on `student`. `insert_stud` takes four IN
--   parameters and inserts a row; `update_stud` takes the key plus the columns
--   that change and updates that row. Both are created with
--   CREATE OR REPLACE PROCEDURE and invoked with CALL.
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


-- #############################################################################
-- ANATOMY -- learn this as a shape, not as text
-- #############################################################################
--
--   CREATE OR REPLACE PROCEDURE name(p_a INT, p_b VARCHAR)
--   LANGUAGE plpgsql
--   AS $$
--   DECLARE
--       v_local INT;        -- optional local variables
--   BEGIN
--       ... procedural body ...
--   END;
--   $$;
--
--   CALL name(1, 'x');
--
-- CREATE OR REPLACE .. lets you re-run the script without dropping first.
-- LANGUAGE plpgsql ..... PostgreSQL's procedural language. Adds IF, loops,
--                        variables and exceptions on top of SQL. Without it
--                        you could not write the IF in Q3/Q4/Q5.
-- $$ ... $$ ............ DOLLAR QUOTING. The body is sent to the server as a
--                        string literal. Inside it you write single quotes
--                        constantly, and escaping every one would be
--                        unreadable, so $$ delimits the string instead.
--                        It can be tagged: $fn$ ... $fn$
-- BEGIN ... END ........ a PL/pgSQL BLOCK. Common trap: this is NOT the same
--                        as "BEGIN;" in psql, which starts a transaction.
-- CALL ................. the only way to invoke a procedure. You cannot put a
--                        procedure inside a SELECT.
--
-- #############################################################################
-- VIVA Q&A
-- #############################################################################
--
-- Q: What is a stored procedure?
-- A: A named block of procedural code stored inside the database (in the
--    system catalog) and executed on the server. It takes parameters, does
--    work, and is invoked by name with CALL. Because it lives in the database
--    rather than the application, every client gets the same logic.
--
-- Q: What are the parameter modes?
-- A: IN       - the default; a value passed in. All of mine are IN.
--    INOUT    - passed in and returned back; how a procedure hands a value
--               to its caller.
--    OUT      - return only. In procedures from PostgreSQL 14 onwards;
--               earlier versions allowed INOUT only.
--    VARIADIC - a trailing array of arguments.
--    Check with:  \df insert_stud
--    -> IN p_stud_id integer, IN p_stud_name character varying, ...
--
-- Q: Does CALL return anything?
-- A: No result set -- psql just echoes "CALL". To get data back, use INOUT
--    parameters, or write a FUNCTION instead and SELECT from it. This is the
--    cleanest one-line difference between a procedure and a function.
--
-- Q: Are stored procedures precompiled?
-- A: Give both answers -- it reads as understanding, not recitation.
--    TEXTBOOK: yes; parsed and stored once, so repeated calls skip parsing
--      and planning, and the client sends one short CALL instead of many
--      statements.
--    PRECISE (PostgreSQL): the body is stored as text and validated at
--      creation. Each SQL statement inside is parsed and planned on its FIRST
--      execution IN A SESSION, then kept in that session's plan cache and
--      reused. So it is not compiled to machine code at CREATE time -- it is
--      cached per session after first use.
--
-- Q: Advantages of stored procedures?
-- A: * Less network traffic  - one round trip replaces many statements.
--    * Reuse / consistency   - every application shares one implementation.
--    * Security              - GRANT EXECUTE on the procedure without granting
--                              table access. With SECURITY DEFINER it runs
--                              with its OWNER's privileges, so a user can
--                              perform a controlled operation on a table they
--                              cannot touch directly.
--    * Performance           - cached plans, and logic runs next to the data.
--
-- Q: Disadvantages?
-- A: * Not portable  - PL/pgSQL, Oracle PL/SQL and T-SQL are different
--                      languages; migrating means rewriting.
--    * Poor tooling  - weak debugging, awkward to unit test, easy to change in
--                      production without the change reaching version control.
--    * Split logic   - business rules end up in two places, app and database.
--    * Scaling       - the DB server is the hardest tier to scale out, so
--                      moving CPU work into it is a considered trade-off.
--
-- Q: How do you drop one?
-- A: DROP PROCEDURE insert_stud(int, varchar, varchar, int);
--    The argument list is required whenever the name is OVERLOADED, because
--    the name alone does not identify the object.
--
-- Q: Can two procedures share a name?
-- A: Yes -- overloading. They must differ in argument types. That is also why
--    the catalog stores a signature, not just a name.
--
-- Q: Where is the procedure actually stored?
-- A: In the pg_proc system catalog, alongside functions. The `prokind` column
--    distinguishes them: 'p' procedure, 'f' function, 'a' aggregate,
--    'w' window. Run this to prove triggers are backed by FUNCTIONS, not
--    procedures:
--
--       select proname, prokind from pg_proc
--       where pronamespace = 'public'::regnamespace order by prokind;
--
--       check_duplicate_email | f     <- Q3 trigger function
--       check_score           | f     <- Q4 trigger function
--       check_delete_limit    | f     <- Q5 trigger function
--       insert_stud           | p     <- Q1 procedure
--       update_stud           | p
--
-- Q: What if you CALL insert_stud with an existing stud_id?
-- A: The procedure has no duplicate check, so the PRIMARY KEY raises the
--    error, not my code -- SQLSTATE 23505:
--
--       ERROR:  duplicate key value violates unique constraint "student_pkey"
--       DETAIL:  Key (stud_id)=(1) already exists.
--       CONTEXT: PL/pgSQL function insert_stud(...) line 3 at SQL statement
--
--    The CONTEXT line shows the failure travelled up through the procedure.
--    Constraints still apply inside procedural code -- a procedure does not
--    bypass them.
--
-- Q: Can a procedure control transactions?
-- A: Yes -- the headline reason procedures were added in PostgreSQL 11. A
--    procedure may issue COMMIT and ROLLBACK in its body; a function cannot.
--    Restriction: only when the procedure is NOT called inside an outer
--    transaction block. After an explicit BEGIN; it raises
--    "invalid transaction termination".
--
-- #############################################################################
-- TABLE: PROCEDURE vs FUNCTION
-- #############################################################################
-- One-sentence answer: a function returns a value and can be used inside a
-- query; a procedure performs work and can manage transactions.
--
--   Aspect             | Procedure                  | Function
--   -------------------+----------------------------+---------------------------
--   Called with        | CALL name(...)             | SELECT name(...), or in
--                      |                            | any expression
--   Return type        | none declared              | RETURNS is mandatory
--   Usable in a query  | no                         | yes - SELECT/WHERE/FROM
--   Transaction control| yes, COMMIT / ROLLBACK     | no
--   Can back a trigger | no                         | yes, if RETURNS TRIGGER
--   Added in           | PostgreSQL 11              | present from the start
--   Catalog            | pg_proc, prokind = 'p'     | pg_proc, prokind = 'f'
--
-- Next: q2.sql shows parameters driving the WHERE clause, and carries the
--       PROCEDURE vs TRIGGER comparison table.
-- =============================================================================
