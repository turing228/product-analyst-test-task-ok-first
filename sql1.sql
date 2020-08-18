DROP TABLE IF EXISTS Employees;
DROP TABLE IF EXISTS Departments;

CREATE TABLE IF NOT EXISTS 
  Departments (
    id SERIAL PRIMARY KEY,
    name varchar(255) not NULL
  );

INSERT INTO Departments (name)
VALUES ('Finance'), ('Operations'), ('Deployment');

CREATE TABLE IF NOT EXISTS 
  Employees (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    Dep_id INTEGER,
    Manager_id INTEGER,
    Salary INTEGER,
    FOREIGN KEY(Dep_id) REFERENCES Departments(id)
  );

INSERT INTO Employees (name, Dep_id, Manager_id, Salary)
VALUES 
    ('John Smith', 1, NULL, 2000),
    ('Jack Smith', NULL, 1, 1500),
    ('Becky Smith', 1, 2, 2000),
    ('Rebecca Smith', 2, 2, 700),
    ('Sonny Smith', 3, 1, 3000)
    ;
 

/* 
a)	Для каждого сотрудника найти его департамент, включая тех, у кого департамента нет

Комментарий: у тех, кого нет департамента, в качестве Dep_id и Dep_name будет Null
*/
SELECT Employees.id AS id, Employees.name AS name, Employees.Dep_id AS Dep_id, Departments.name as Dep_name
FROM Employees
LEFT OUTER JOIN Departments
ON Employees.Dep_id=Departments.id;


/*
b)	Найти наибольшую зарплату по департаментам и отсортировать департаменты 
по убыванию максимальной зарплаты

Комментарий: "пустой департамент" (Null) будет в выводе
*/

SELECT Departments.id AS id, Departments.name AS name, Salaries.BiggestSalary AS BiggestSalary
FROM Departments
FULL OUTER JOIN 
  (
    SELECT Dep_id, MAX(Salary) AS BiggestSalary
    FROM Employees
    GROUP BY Dep_id
  ) Salaries
ON Departments.id=Salaries.Dep_id
ORDER BY Salaries.BiggestSalary;


/*
c)	Посчитать среднюю зарплату команды в группировке по менеджерам. (в таблице Employees 
Manager_id!=id)

Комментарий: сотрудники без менеджера объединены в одну группировку с manager_id = Null
*/

SELECT Manager_id, AVG(Salary) AS AverageSalary
FROM Employees
GROUP BY Manager_id
ORDER BY Manager_id;