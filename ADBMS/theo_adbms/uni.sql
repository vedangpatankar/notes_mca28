-- Constructors and Objects in SQL
--
-- Class       : a structured type (CREATE TYPE ... AS). It only describes the
--               attributes, it does not hold any data.
-- Constructor : the tuple constructor ROW(value1, value2, ...). It takes the
--               attribute values in order and builds one value of the type.
-- Object      : the value produced by the constructor. It is an instance of
--               the type with all its attributes filled in.
-- Object table: a table created with CREATE TABLE ... OF type. Every row of
--               the table is one object of that type.

-- 1. Class Student with attributes student_name and roll_number
CREATE TYPE student_type AS (
    student_name varchar(50),
    roll_number  int
);

-- 2. Class Teacher with attributes teacher_name and subject
CREATE TYPE teacher_type AS (
    teacher_name varchar(50),
    subject      varchar(50)
);

-- 3. Class University with attributes uni_id, student and teacher
--    student is an object of student_type and teacher is an object of teacher_type
CREATE TYPE university_type AS (
    uni_id  int,
    student student_type,
    teacher teacher_type
);

-- 4. Object table university
--    Each row stored in this table is one university_type object
CREATE TABLE university OF university_type;

-- 5. Create objects using the constructor and store them in the object table
--    ROW('Vidit Kulshrestha', 101) is the constructor call for Student.
--    It creates a student_type object with student_name = 'Vidit Kulshrestha'
--    and roll_number = 101.
--    ROW('Dr. Kulkarni', 'ADBMS') is the constructor call for Teacher.
--    It creates a teacher_type object with teacher_name = 'Dr. Kulkarni'
--    and subject = 'ADBMS'.
--    The whole row (1, student object, teacher object) is one university object.
INSERT INTO university VALUES (1, ROW('Vidit Kulshrestha', 101), ROW('Dr. Kulkarni', 'ADBMS'));
INSERT INTO university VALUES (2, ROW('Tony Stark', 102),        ROW('Dr. Banner', 'DCN'));
INSERT INTO university VALUES (3, ROW('Doctor Strange', 103),    ROW('Dr. Wong', 'Java'));
COMMIT;

-- 6. Display the objects
--    Each row is printed as a whole object, and the nested student and
--    teacher objects are shown in brackets
SELECT * FROM university;

-- 7. Display the attributes of each object
--    (student).student_name reads the student_name attribute
--    of the student object stored in the row
SELECT uni_id,
       (student).student_name,
       (student).roll_number,
       (teacher).teacher_name,
       (teacher).subject
FROM   university
ORDER  BY uni_id;
