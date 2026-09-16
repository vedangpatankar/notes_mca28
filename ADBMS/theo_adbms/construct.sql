CREATE TYPE name_type AS (
    first_name varchar(20),
    last_name  varchar(20)
);

CREATE TYPE addr_type AS (
    city  varchar(30),
    state varchar(30),
    pin   char(6)
);

CREATE TYPE student_type AS (
    stud_id   int,
    stud_name name_type,
    stud_addr addr_type,
    course    varchar(20)
);

CREATE TABLE student_tab OF student_type;

-- Insert function: builds the structured values and inserts one student
CREATE OR REPLACE FUNCTION add_student(
    p_id         int,
    p_first_name varchar,
    p_last_name  varchar,
    p_city       varchar,
    p_state      varchar,
    p_pin        char,
    p_course     varchar
)
RETURNS void AS $$
BEGIN
    INSERT INTO student_tab
    VALUES (p_id,
            ROW(p_first_name, p_last_name),
            ROW(p_city, p_state, p_pin),
            p_course);
END;
$$ LANGUAGE plpgsql;

-- insertion code
SELECT add_student(1, 'Vidit',  'Kulshrestha', 'Pune',   'Maharashtra', '411038', 'MCA');
SELECT add_student(2, 'Tony',   'Stark',       'Mumbai', 'Maharashtra', '400001', 'MCA');
SELECT add_student(3, 'Doctor', 'Strange',     'Delhi',  'Delhi',       '110001', 'MCA');
COMMIT;


SELECT * FROM student_tab;

SELECT stud_id,
       (stud_name).first_name || ' ' || (stud_name).last_name AS full_name,
       (stud_addr).city,
       (stud_addr).state,
       (stud_addr).pin,
       course
FROM   student_tab
ORDER  BY stud_id;
