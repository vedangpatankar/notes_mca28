-- =============================================================================
-- Q5) Write down DML trigger to raise the error when user deletes
--     more than one record from table
-- =============================================================================
--
-- ONE-BREATH ANSWER
--   An AFTER DELETE trigger on `waitress`, declared FOR EACH STATEMENT with
--   REFERENCING OLD TABLE AS deleted_rows. That clause hands the function a
--   TRANSITION TABLE -- a temporary relation holding every row the statement
--   removed. The function counts it and raises when the count exceeds one.
--
--   It MUST be statement-level: "how many rows" is a fact about the STATEMENT,
--   not about any single row.
--
-- Run:  psql "postgresql://postgres:postgres@127.0.0.1:54422/postgres" -f q5.sql
--       (the second delete is MEANT to fail -- that is the demonstration)
-- =============================================================================


drop table if exists waitress cascade;

create table waitress(
    id   INT Primary Key,
    name VARCHAR(50),
    city VARCHAR(50)
);

insert into waitress values
(1, 'Max Black',         'Brooklyn'),
(2, 'Caroline Channing', 'Brooklyn'),
(3, 'Han Lee',           'Brooklyn'),
(4, 'Oleg Golishevsky',  'Manhattan');


create or replace function check_delete_limit()
returns trigger
language plpgsql
as $$
declare
    deleted_count INT;
begin
    -- `deleted_rows` is the TRANSITION TABLE named in the CREATE TRIGGER
    -- below. It is queryable like any other relation and holds every row this
    -- one statement deleted. NEW and OLD are both NULL here -- a
    -- statement-level trigger has no "current row".
    select count(*) into deleted_count from deleted_rows;

    if deleted_count > 1 then
        raise exception 'Cannot delete more than 1 record at a time';
    end if;

    -- AFTER and statement-level triggers have their return value IGNORED.
    -- RETURN NULL is the convention for "nothing meaningful to return".
    return null;
end;
$$;

-- Redundant after DROP TABLE ... CASCADE, but the portable re-run pattern
-- whenever the table survives. See the note in q3.sql.
drop trigger if exists trg_delete_limit on waitress;

create trigger trg_delete_limit
after delete on waitress                     -- AFTER: required for transition
                                             -- tables, and logically necessary
referencing old table as deleted_rows        -- the transition table (PG 10+)
for each statement                           -- once per statement, NOT per row
execute function check_delete_limit();

-- allowed: deletes one row
delete from waitress where id = 4;
-- DELETE 1

-- rejected: deletes three rows
delete from waitress where city = 'Brooklyn';
-- ERROR:  Cannot delete more than 1 record at a time
-- ...all three Brooklyn rows survive; the earlier single delete stands

select * from waitress order by id;


-- #############################################################################
-- VIVA Q&A -- the core three
-- #############################################################################
--
-- Q: Why FOR EACH STATEMENT and not FOR EACH ROW?      <- heart of the question
-- A: A row-level trigger is invoked once per row and sees only that row -- it
--    has no idea whether it is the first of one or the first of a thousand.
--    "More than one record" is a property of the STATEMENT, so it can only be
--    evaluated by a trigger that fires once per statement.
--    The clumsy row-level workaround would be a counter in a temp table or
--    session variable that has to be reset somewhere -- fragile, and it breaks
--    as soon as two statements run in one transaction. The transition table is
--    the correct mechanism.
--
-- Q: Why AFTER and not BEFORE?
-- A: Two reasons, the first alone decisive:
--      1. PostgreSQL only permits transition tables on AFTER triggers.
--         REFERENCING OLD TABLE on a BEFORE trigger is a syntax error.
--      2. It is logically necessary anyway -- before the statement runs, the
--         set of rows it will delete does not exist yet. The count is only
--         knowable afterwards.
--
-- Q: If the rows are already deleted, how does raising help?  <- the follow-up
-- A: Because the deletes and the trigger are inside the SAME STATEMENT and the
--    same transaction. The exception aborts it and everything rolls back
--    atomically -- which is why all three Brooklyn rows are still there in the
--    output above.
--
-- #############################################################################
-- VIVA Q&A -- the rest
-- #############################################################################
--
-- Q: Why does the function RETURN NULL?
-- A: Because the return value of an AFTER trigger, and of ANY statement-level
--    trigger, is ignored. Only in a BEFORE ROW trigger does it matter -- there,
--    returning NULL cancels the operation for that row.
--
-- Q: What are NEW and OLD inside this function?
-- A: Both NULL. Statement-level triggers have no current row -- that is exactly
--    why the transition table exists. Referencing OLD.id here fails at runtime.
--
-- Q: What about a statement that deletes nothing?
-- A: The trigger STILL FIRES -- statement-level triggers run once per statement
--    even when zero rows are affected. count is 0, which is not > 1, so nothing
--    happens. A ROW-level trigger would not have fired at all. This difference
--    is a clean way to show you understand the two levels.
--
-- Q: Which PostgreSQL version introduced transition tables?
-- A: PostgreSQL 10. Before that, the standard approach was a row-level AFTER
--    trigger writing into a temp table plus a statement-level trigger reading
--    it -- exactly the pattern transition tables replaced.
--
-- Q: Is there a NEW TABLE too?
-- A: Yes -- REFERENCING NEW TABLE AS inserted_rows, for INSERT and UPDATE. You
--    may name both on an UPDATE trigger to compare before and after sets.
--
-- #############################################################################
-- TRAP -- VERIFIED: TRUNCATE bypasses this guard completely
-- #############################################################################
--
-- TRUNCATE is not DELETE. It does not fire DELETE triggers at all, so it
-- empties the table straight through the guard:
--
--   truncate waitress;
--   select count(*) from waitress;     --> 0, no error raised
--
-- Closing the hole needs a SECOND trigger. TRUNCATE triggers must be
-- statement-level, because there are no per-row events to fire on:
--
--   create or replace function block_truncate() returns trigger
--   language plpgsql as $$
--   begin
--       raise exception 'TRUNCATE is not permitted on %', TG_TABLE_NAME;
--   end; $$;
--
--   create trigger trg_no_truncate
--   before truncate on waitress
--   for each statement execute function block_truncate();
--
-- This is the single best thing to volunteer on Q5.
--
-- #############################################################################
-- TABLE: ROW-LEVEL vs STATEMENT-LEVEL
-- #############################################################################
-- One-sentence answer: a row trigger fires once per affected row and sees that
-- row; a statement trigger fires once per statement and sees the whole set.
--
--   Aspect             | FOR EACH ROW              | FOR EACH STATEMENT
--   -------------------+---------------------------+-------------------------
--   Fires              | once per affected row     | once per statement
--                      |                           | (the default if omitted)
--   Zero rows affected | never fires               | still fires once
--   NEW / OLD          | available                 | NULL - no current row
--   Transition tables  | available on AFTER        | available on AFTER - the
--                      |                           | usual way to use them
--   Can modify the row | yes, in a BEFORE trigger  | no
--   Cost on 10k rows   | 10,000 invocations        | 1 invocation
--   These labs         | Q3, Q4                    | Q5
--
-- #############################################################################
-- REFERENCE: context variables available in ANY trigger function
-- #############################################################################
--
--   TG_OP         'INSERT' | 'UPDATE' | 'DELETE' | 'TRUNCATE'
--                 -- how ONE function can serve several events
--   TG_WHEN       'BEFORE' | 'AFTER' | 'INSTEAD OF'
--   TG_LEVEL      'ROW' | 'STATEMENT'
--   TG_NAME       the trigger's name (one function, several triggers)
--   TG_TABLE_NAME the table -- how one audit function serves a whole schema
--   TG_ARGV[]     constant args given in CREATE TRIGGER, as text
--
-- One function handling all three events -- a very likely "write it now" task:
--
--   create or replace function audit_marks() returns trigger
--   language plpgsql as $$
--   begin
--       insert into marks_audit(op, stud_id, changed_at)
--       values (TG_OP, coalesce(new.stud_id, old.stud_id), now());
--       return null;                        -- AFTER trigger: value ignored
--   end; $$;
--
--   create trigger trg_audit_marks
--   after insert or update or delete on marks
--   for each row execute function audit_marks();
--
-- coalesce(new.x, old.x) is the idiom that makes one function work for all
-- three events -- it picks whichever record exists.
--
-- #############################################################################
-- TABLE: THE SAME TRIGGER IN THREE DATABASES
-- #############################################################################
-- Relevant to this folder: trigger.sql is written in MySQL syntax and will NOT
-- run on PostgreSQL. SIGNAL SQLSTATE '45000' and DELIMITER are both MySQL
-- constructs with no PostgreSQL equivalent; 45000 means "unhandled
-- user-defined exception", the counterpart of PostgreSQL's P0001.
--
--                    | PostgreSQL        | Oracle             | MySQL
--   -----------------+-------------------+--------------------+-----------------
--   Structure        | separate FUNCTION | body inline in the | body inline in
--                    | + TRIGGER         | trigger            | the trigger
--   Language         | PL/pgSQL          | PL/SQL             | SQL/PSM
--   Row reference    | NEW / OLD         | :NEW / :OLD        | NEW / OLD
--                    |                   | (colon)            |
--   Raise an error   | RAISE EXCEPTION   | RAISE_APPLICATION_ | SIGNAL SQLSTATE
--                    | 'msg'             | ERROR(-20001,'msg')| '45000' SET
--                    |                   |                    | MESSAGE_TEXT=..
--   Statement-level  | yes               | yes                | NO - row-level
--   triggers         |                   |                    | only, so Q5 is
--                    |                   |                    | not expressible
--   Read same table  | allowed           | blocked, ORA-04091 | blocked
--                    |                   | mutating table     |
--   Body delimiter   | $$ ... $$         | BEGIN ... END;     | DELIMITER //
--
-- #############################################################################
-- RAPID FIRE -- answer in one sentence and stop
-- #############################################################################
--
-- What does $$ mean?            Dollar quoting -- delimits the body as a string
--                               literal so inner single quotes need no escaping.
-- Is PL/pgSQL case sensitive?   No for keywords and unquoted identifiers (they
--                               fold to lower case); yes inside string literals.
-- List procedures?              \df  (functions and procedures), \df+ for source.
-- List triggers?                \d marks  shows a table's triggers. Catalog:
--                               pg_trigger, information_schema.triggers.
-- Drop a trigger?               DROP TRIGGER trg_check_score ON marks;  -- the
--                               table is required: names are scoped per table.
-- Same trigger name on two      Yes. Trigger names are unique per TABLE, not per
--   tables?                     schema -- unlike procedure names.
-- Disable a trigger?            ALTER TABLE marks DISABLE TRIGGER trg_check_score;
--                               (or DISABLE TRIGGER ALL) -- used in bulk loads.
-- CREATE OR REPLACE TRIGGER?    Yes, from PostgreSQL 14. Portable way is to drop
--                               first, which is what these files do.
-- Firing order?                 Alphabetical by trigger name.
-- Can a trigger fire another?   Yes, cascading and even recursive. Bounded by
--                               max_stack_depth; unguarded recursion is a hazard.
-- Can a trigger call a          Yes, but it cannot COMMIT there -- it is inside
--   procedure?                  the firing statement's transaction.
-- Can a trigger take            Not from the caller. Fixed text args at CREATE
--   parameters?                 TRIGGER time, read as TG_ARGV[0].
-- Trigger vs cursor?            Unrelated. A cursor walks a result set row by
--                               row; a trigger is event-driven code.
-- What is SECURITY DEFINER?     The routine runs with its OWNER's privileges,
--                               not the caller's.
-- Do triggers fire on COPY?     Yes -- COPY ... FROM fires INSERT triggers, which
--                               is why bulk loads often disable them first.
-- Do triggers fire on TRUNCATE? Only statement-level TRUNCATE triggers. DELETE
--                               triggers do not -- see the trap above.
--
-- =============================================================================
