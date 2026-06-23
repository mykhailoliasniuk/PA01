--tables--
create DATABASE PA01;

use PA01;

CREATE TABLE IF NOT EXISTS departments (
    department_id SERIAL PRIMARY KEY,
    department_name VARCHAR(100),
    budget DECIMAL(12, 2)
);

CREATE TABLE IF NOT EXISTS professors (
    professor_id SERIAL PRIMARY KEY,
    professor_name VARCHAR(100),
    degree VARCHAR(50),
    department_id INT REFERENCES departments(department_id)
);

CREATE TABLE IF NOT EXISTS courses (
    course_id SERIAL PRIMARY KEY,
    course_name VARCHAR(150),
    credits INT,
    professor_id INT REFERENCES professors(professor_id)
);

CREATE TABLE IF NOT EXISTS students (
    student_id SERIAL PRIMARY KEY,
    student_name VARCHAR(100),
    enrollment_year INT
);

CREATE TABLE IF NOT EXISTS enrollments (
    enrollment_id SERIAL PRIMARY KEY,
    student_id INT REFERENCES students(student_id),
    course_id INT REFERENCES courses(course_id),
    enroll_date DATE,
    final_grade INT
);
--imported tables from fabricate tonic--

--main--
select 
	s.student_name,
	d.department_name,
	p.professor_name,
	count(distinct c.course_id) as number_of_courses,
	avg(e.final_grade) as averege_grade
from students s 
join enrollments e 
	on s.student_id = e.student_id
join courses c 
	on e.course_id = c.course_id 
join professors p 
	on c.professor_id = p.professor_id
join departments d 
	on p.department_id = d.department_id 
where e.final_grade >= 60
group by 
	s.student_name ,
	p.professor_name ,
	d.department_name 
order by averege_grade desc;

--cte--
with StudentStat as (
	select 
		s.student_id ,
		s.student_name ,
		avg(e.final_grade) as avg_grade
	from students s 
	join enrollments e 
		on s.student_id = e.student_id
	group by 
		s.student_id,
		s.student_name 
)
--union--
select 
	student_name as name,
	round(avg_grade::numeric, 2) as avg_grade,
	'Student' as role,
	case
    		when avg_grade < 60 then 'failed'
    		when avg_grade < 70 then 'f'
    		when avg_grade < 75 then 'e'
    		when avg_grade < 80 then 'd'
    		when avg_grade < 85 then 'c'
    		when avg_grade < 90 then 'b'
    		else 'a'
		end as grade
from StudentStat

union all

select 
	p.professor_name,
	null::numeric as avg_grade,
	'Professor' as role,
	null as grade
from professors p
order by role desc;