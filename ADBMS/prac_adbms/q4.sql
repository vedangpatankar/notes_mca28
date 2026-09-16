-- =============================================================================
-- Q4) Write down DML trigger to raise the error violating Check Constraints
-- =============================================================================
--
-- ONE-BREATH ANSWER
--   BEFORE INSERT OR UPDATE ... FOR EACH ROW on `marks`. check_score() rejects
--   any NEW.score below 0 or above 100 and otherwise returns NEW. It is a
--   procedural re-implementation of CHECK (score BETWEEN 0 AND 100) -- and
--   unlike Q3 it DOES cover updates, which is correct: a range rule must hold
--   however the value arrives.
--
-- Run:  psql "postgresql://postgres:postgres@127.0.0.1:54422/postgres" -f q4.sql
--       (the last insert is MEANT to fail -- that is the demonstration)
-- =============================================================================


drop table if exists marks cascade;

create table marks(
    stud_id   INT Primary Key,
    stud_name VARCHAR(50),
    score     INT
);


create or replace function check_score()
returns trigger
language plpgsql
as $$
begin
    -- Boundary matters: the test is "> 100", not ">= 100", so 0 and 100 are
    -- both VALID. Examiners like boundary questions -- be ready to say so.
    if new.score < 0 or new.score > 100 then
        raise exception 'Score must be between 0 and 100, given %', new.score;
    end if;
    return new;
end;
$$;

-- Redundant after DROP TABLE ... CASCADE, but the portable re-run pattern
-- whenever the table survives. See the note in q3.sql.
drop trigger if exists trg_check_score on marks;

create trigger trg_check_score
before insert or update on marks             -- BOTH events: Q3 only had INSERT
for each row
execute function check_score();

-- allowed
insert into marks values (1, 'Sheldon Cooper',     100);   -- boundary: OK
insert into marks values (2, 'Leonard Hofstadter',  85);

-- rejected: score above 100
insert into marks values (3, 'Howard Wolowitz',    120);
-- ERROR:  Score must be between 0 and 100, given 120
-- CONTEXT: PL/pgSQL function check_score() line 4 at RAISE

select * from marks order by stud_id;


-- #############################################################################
-- VIVA Q&A
-- #############################################################################
--
-- Q: A CHECK constraint does this in one line. Why write a trigger?
-- A: Same honest structure as Q3: the lab asked for a trigger, and
--    CHECK (score BETWEEN 0 AND 100) is the right production answer. Then give
--    the cases where a trigger genuinely wins:
--      * A CHECK may only reference columns OF THE SAME ROW. It cannot consult
--        another table, another row, or a per-course table of valid ranges.
--      * A CHECK cannot produce a custom, business-readable message -- it
--        reports SQLSTATE 23514 check_violation plus the constraint name.
--      * A CHECK cannot CORRECT the value; a BEFORE trigger can clamp it
--        (new.score := 100) and let the row through.
--      * A CHECK cannot log the rejected attempt.
--
-- Q: After the failed insert, why are rows 1 and 2 still in the table?
-- A: Because psql runs in AUTOCOMMIT: each statement is its own transaction.
--    The first two inserts committed independently; only the third rolled
--    back. Run the same file as one transaction and nothing survives:
--
--       psql ... -f  q4.sql     # rows 1 and 2 remain
--       psql ... -1 -f q4.sql   # single transaction: all-or-nothing, empty
--
--    Same effect from wrapping the file in BEGIN; ... COMMIT;. This tests
--    whether you understand that the trigger aborts a STATEMENT, and the
--    TRANSACTION BOUNDARY decides how much of your script goes with it.
--
-- Q: What error code does RAISE EXCEPTION produce?
-- A: P0001 -- raise_exception, the generic PL/pgSQL user error. See it with
--    \set VERBOSITY verbose in psql:
--
--       ERROR:  P0001: Score must be between 0 and 100, given 500
--
--    You can choose your own code, which is how applications tell business
--    errors apart from system errors:
--
--       raise exception 'Score out of range: %', new.score
--           using errcode = '22003', hint = 'Scores run from 0 to 100.';
--
--    Constraint route gives the standard codes instead:
--       23505 unique_violation      23514 check_violation
--       23503 foreign_key_violation 23502 not_null_violation
--
-- Q: What are the RAISE levels?
-- A: DEBUG, LOG, INFO, NOTICE, WARNING, EXCEPTION. Only EXCEPTION aborts; the
--    rest emit a message and carry on. To make this trigger WARN instead of
--    reject, you change one keyword.
--
-- Q: How do you catch an error in PL/pgSQL?
-- A: begin ... exception when check_violation then ... end;
--    Each such block is a SUBTRANSACTION (an implicit SAVEPOINT), so it is not
--    free -- do not wrap a per-row loop in one carelessly.
--
-- Q: Could you write this more efficiently?
-- A: Yes -- put the condition in a WHEN clause on the trigger. WHEN is
--    evaluated BEFORE the function is entered, so the call is skipped entirely
--    rather than made and discarded:
--
--       create trigger trg_check_score
--       before insert or update on marks
--       for each row when (NEW.score < 0 or NEW.score > 100)
--       execute function raise_bad_score();
--
--    On a million-row insert that is a million function calls saved.
--
-- Q: How do you see the trigger on this table?
-- A: \d marks   -- prints columns, constraints AND triggers in one view. This
--    is the command to reach for when asked "show me your trigger"; you do not
--    have to remember a catalog query. (Catalog: pg_trigger, or
--    information_schema.triggers.)
--
-- Q: How would you temporarily switch it off?
-- A: alter table marks disable trigger trg_check_score;
--    ...or DISABLE TRIGGER ALL. Common during a bulk data load.
--
-- #############################################################################
-- TABLE: TRIGGER vs CONSTRAINT
-- #############################################################################
-- One-sentence answer: a constraint DECLARES WHAT MUST BE TRUE; a trigger
-- DESCRIBES WHAT TO DO when something happens. Prefer the constraint whenever
-- the rule can be expressed as one.
--
--   Aspect            | Constraint                  | Trigger
--   ------------------+-----------------------------+--------------------------
--   Style             | declarative                 | procedural
--   Scope             | CHECK: one row.             | anything reachable in
--                     | UNIQUE/FK: index-backed     | SQL - other tables,
--                     | across the table            | other rows
--   Safe concurrently | yes - enforced by the index | not automatically; a
--                     |                             | read-then-write check
--                     |                             | can race
--   Optimiser aware   | yes - can use it to         | no
--                     | eliminate work              |
--   Custom message    | no - standard SQLSTATE plus | yes, any text you like
--                     | the constraint name         |
--   Side effects      | impossible                  | possible - logging,
--                     |                             | cascading, correcting
--   Performance       | cheaper                     | a function call per row
--                     |                             | or per statement
--   These labs        | UNIQUE(email) replaces Q3;  | Q5 has NO constraint
--                     | CHECK (score BETWEEN 0 AND  | equivalent - a constraint
--                     | 100) replaces Q4            | cannot count the rows in
--                     |                             | a statement
--
-- The two declarative equivalents, worth being able to write on demand:
--
--   alter table friends add constraint uq_friends_email unique (email);
--   alter table marks   add constraint ck_marks_score
--       check (score between 0 and 100);
--
-- #############################################################################
-- TABLE: DML vs DDL TRIGGER
-- #############################################################################
--
--   Aspect      | DML trigger                    | DDL trigger
--   ------------+--------------------------------+---------------------------
--   Fires on    | INSERT, UPDATE, DELETE,        | CREATE, ALTER, DROP
--               | TRUNCATE                       |
--   Attached to | a table or a view              | the database or schema,
--               |                                | not a table
--   In Postgres | CREATE TRIGGER                 | called an EVENT TRIGGER:
--               |                                | CREATE EVENT TRIGGER ...
--               |                                | ON ddl_command_end
--   Purpose     | data integrity, audit of data  | schema-change audit,
--               | changes                        | preventing accidental DROP
--   These labs  | all three - Q3, Q4, Q5         | not covered; know only that
--               |                                | it exists and its PG name
--
-- A third kind: INSTEAD OF triggers attach only to VIEWS, only FOR EACH ROW,
-- and make a non-updatable view writable by translating the DML into
-- statements against the base tables.
--
-- Next: q5.sql -- the only one of the five that a row-level trigger physically
--       cannot solve.
-- =============================================================================
