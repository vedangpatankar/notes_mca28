-- =============================================================================
-- Q3) Write down DML trigger to raise the error while inserting
--     duplicate value in the table
-- =============================================================================
--
-- ONE-BREATH ANSWER
--   A BEFORE INSERT ... FOR EACH ROW trigger on `friends`. Before each
--   candidate row is written, check_duplicate_email() asks whether the table
--   already holds NEW.email. If it does, RAISE EXCEPTION aborts the statement;
--   otherwise RETURN NEW lets the insert proceed.
--
-- Run:  psql "postgresql://postgres:postgres@127.0.0.1:54422/postgres" -f q3.sql
--       (the last insert is MEANT to fail -- that is the demonstration)
-- =============================================================================


drop table if exists friends cascade;        -- cascade also drops the trigger

create table friends(
    id    INT Primary Key,
    name  VARCHAR(50),
    email VARCHAR(50)
);

insert into friends values
(1, 'Ross Geller',  'ross@friends.com'),
(2, 'Rachel Green', 'rachel@friends.com');


-- -----------------------------------------------------------------------------
-- OBJECT 1 of 2: the trigger FUNCTION
-- -----------------------------------------------------------------------------
-- Note "returns trigger" -- a pseudo-type. Such a function declares NO
-- arguments and can only be called by the trigger machinery, never by
-- SELECT check_duplicate_email().
create or replace function check_duplicate_email()
returns trigger
language plpgsql
as $$
begin
    -- NEW is the row being inserted. It is injected by the trigger machinery,
    -- not declared by us.
    if exists (select 1 from friends where email = new.email) then
        -- RAISE EXCEPTION aborts the statement and puts the transaction into
        -- an aborted state. % is the placeholder; args substitute in order.
        -- Default SQLSTATE for this is P0001.
        raise exception 'Duplicate email not allowed: %', new.email;
    end if;

    -- In a BEFORE ROW trigger, the returned row is what actually gets written.
    -- Returning NULL instead would SILENTLY SKIP this row (no error).
    return new;
end;
$$;

-- -----------------------------------------------------------------------------
-- OBJECT 2 of 2: the TRIGGER -- binds the function to a table and an event
-- -----------------------------------------------------------------------------
-- Redundant here (DROP TABLE ... CASCADE above already removed it, hence the
-- "does not exist, skipping" notice) but this IS the portable re-run pattern
-- when the table itself survives. CREATE OR REPLACE TRIGGER only exists from
-- PostgreSQL 14; functions have had CREATE OR REPLACE all along.
drop trigger if exists trg_duplicate_email on friends;

create trigger trg_duplicate_email
before insert on friends                     -- WHEN: before the row is written
for each row                                 -- LEVEL: once per affected row
execute function check_duplicate_email();    -- WHAT: EXECUTE FUNCTION, PG 11+
                                             -- (EXECUTE PROCEDURE = old spelling
                                             --  for the same thing)

-- allowed
insert into friends values (3, 'Chandler Bing', 'chandler@friends.com');
-- INSERT 0 1

-- rejected: email already present
insert into friends values (4, 'Joey Tribbiani', 'ross@friends.com');
-- ERROR:  Duplicate email not allowed: ross@friends.com
-- CONTEXT: PL/pgSQL function check_duplicate_email() line 4 at RAISE

select * from friends order by id;


-- #############################################################################
-- A TRIGGER IS TWO OBJECTS -- the most common misunderstanding
-- #############################################################################
--
--   -- object 1: the function (reusable, table-agnostic)
--   CREATE OR REPLACE FUNCTION fn_name()
--   RETURNS TRIGGER
--   LANGUAGE plpgsql
--   AS $$
--   BEGIN
--       IF <bad condition> THEN
--           RAISE EXCEPTION 'message: %', NEW.col;
--       END IF;
--       RETURN NEW;
--   END;
--   $$;
--
--   -- object 2: the trigger (binds function to table + event)
--   CREATE TRIGGER trg_name
--   BEFORE INSERT OR UPDATE ON tbl
--   FOR EACH ROW
--   EXECUTE FUNCTION fn_name();
--
-- If asked "is a trigger a procedure?" -- No. In PostgreSQL a trigger fires a
-- FUNCTION that returns type `trigger`. You cannot attach a PROCEDURE to a
-- table. The legacy keyword EXECUTE PROCEDURE is a historical spelling and
-- misleads people into thinking otherwise. Prove it with pg_proc.prokind:
-- check_duplicate_email is 'f', insert_stud is 'p'.
--
-- #############################################################################
-- NEW / OLD AVAILABILITY  -- the single most common one-line trigger question
-- #############################################################################
--
--   Event               | NEW                     | OLD
--   --------------------+-------------------------+--------------------------
--   INSERT              | the row being inserted  | NULL
--   UPDATE              | the proposed new row    | the row as it stands now
--   DELETE              | NULL                    | the row being deleted
--   Any statement-level | NULL                    | NULL
--
-- Memory hook: a deleted row has no future, an inserted row has no past.
-- Statement-level triggers have neither -- they use a transition table (Q5).
--
-- #############################################################################
-- TRAP 1 -- VERIFIED: this trigger fires on INSERT ONLY
-- #############################################################################
--
-- An UPDATE walks straight past it and creates the very duplicate the trigger
-- exists to prevent. Uncomment and run to see it:
--
--   update friends set email = 'ross@friends.com' where id = 2;
--
--    id |     name      |        email
--   ----+---------------+----------------------
--     1 | Ross Geller   | ross@friends.com
--     2 | Rachel Green  | ross@friends.com     <- duplicate, no error
--
-- Volunteering this before the examiner finds it turns a flaw into evidence
-- that you understand the mechanism. The lab asked for "while INSERTING", so
-- the code answers the question as written -- but you should know the gap.
--
-- #############################################################################
-- TRAP 2 -- so just add OR UPDATE? No.
-- #############################################################################
--
-- Extend the trigger to BEFORE INSERT OR UPDATE and the row now collides WITH
-- ITSELF, because it is already in the table when the check runs. An update
-- that does not even touch the email fails:
--
--   update friends set name = 'Rachel Greene' where id = 2;   -- email untouched
--   ERROR:  Duplicate email not allowed: ross@friends.com
--
-- The fix is to exclude the row being changed:
--
--   if exists (select 1 from friends
--              where email = new.email
--                and id   <> new.id) then
--
-- ...or skip the check when nothing relevant changed, with a WHEN clause on
-- the trigger itself:
--
--   create trigger trg_duplicate_email
--   before insert or update on friends
--   for each row when (NEW.email IS DISTINCT FROM OLD.email)
--   execute function check_duplicate_email();
--
-- #############################################################################
-- TRAP 3 -- this trigger is NOT safe under concurrency
-- #############################################################################
--
-- Two sessions inserting the same email at the same time each run
-- "SELECT ... WHERE email = NEW.email" against their OWN SNAPSHOT. Neither
-- sees the other's uncommitted row, both pass the check, both commit.
--
-- A UNIQUE INDEX is the only race-safe answer, because uniqueness is then
-- enforced by the index itself rather than by a read:
--
--   alter table friends add constraint uq_friends_email unique (email);
--
-- #############################################################################
-- VIVA Q&A
-- #############################################################################
--
-- Q: Why BEFORE rather than AFTER?
-- A: Because the point is to PREVENT the write. A BEFORE trigger runs while
--    the row is still a proposal, so rejecting it costs nothing. An AFTER
--    trigger runs once the row is already inserted -- raising there still rolls
--    everything back, but you have done the write and the index maintenance
--    first. BEFORE is also the only place you can modify or silently skip the
--    row.
--
-- Q: Why not just use a UNIQUE constraint?   <- expect this one
-- A: Because the lab asked for a trigger. Then concede the real answer, it
--    earns marks: UNIQUE(email) is genuinely the correct tool --
--      * declarative: the optimiser and catalog know the rule exists
--      * backed by a unique index, so the check is atomic and race-safe
--      * one line, and impossible to write incorrectly
--    Use a trigger when the rule CANNOT be declared: when it spans several
--    tables, needs a side effect such as an audit row, or depends on something
--    a constraint cannot see. (Full table in q4.sql.)
--
-- Q: Can a trigger query the table it is attached to?
-- A: In PostgreSQL yes -- this function does exactly that and runs fine. In
--    ORACLE it raises ORA-04091 "table is mutating", because a row trigger
--    there may not read the table being modified. Mentioning that contrast is
--    a strong answer if the examiner teaches from an Oracle textbook.
--
-- Q: What does RETURN NEW do?
-- A: In a BEFORE ROW trigger it is the row that actually gets written -- modify
--    NEW first and the modified version is stored. RETURN NULL cancels the
--    operation for that row, silently and with no error.
--
-- Q: Why is there a DROP TRIGGER IF EXISTS above the CREATE TRIGGER?
-- A: So the file can be re-run. CREATE OR REPLACE TRIGGER only exists from
--    PostgreSQL 14; the portable way is to drop first. (Functions have had
--    CREATE OR REPLACE all along, which is why the function above does not
--    need it.)
--
-- Q: Two triggers on the same event -- which fires first?
-- A: Alphabetical by trigger name. Verified: a trigger named `alpha` fires
--    before one named `zebra` on the same insert.
--
-- #############################################################################
-- TABLE: BEFORE vs AFTER
-- #############################################################################
--
--   Aspect             | BEFORE                      | AFTER
--   -------------------+-----------------------------+-------------------------
--   Timing             | row is still a proposal     | row written, constraints
--                      |                             | already checked
--   Can change NEW     | yes - the modified row is   | no; any change is
--                      | what gets stored            | discarded
--   Can skip a row     | yes - RETURN NULL skips it  | no; only RAISE
--                      | silently                    | EXCEPTION, which aborts
--                      |                             | everything
--   Return value used  | yes                         | ignored - RETURN NULL by
--                      |                             | convention
--   Transition tables  | not permitted               | permitted (see q5.sql)
--   Sees generated key | no - a serial value may not | yes
--                      | be assigned yet             |
--   Typical use        | validate, normalise, set a  | audit log, cascade,
--                      | default                     | cross-row checks
--   These labs         | Q3, Q4                      | Q5
--
-- Next: q4.sql -- same idea for a range check, plus SQLSTATE codes and the
--       full TRIGGER vs CONSTRAINT table.
-- =============================================================================
