DROP TABLE IF EXISTS Purchases;

CREATE TABLE IF NOT EXISTS 
  Purchases (
    user_id INTEGER not NULL,
    user_gender varchar(255) not NULL,
    items INTEGER not NULL CHECK (items >= 0),
    price INTEGER not NULL CHECK (price >= 0)
  );
  
INSERT INTO Purchases (user_id, user_gender, items, price)
VALUES 
  (101, 'f', 3, 100), 
  (102, 'female', 0, 0), 
  (103, 'm', 0, 0),
  (101, 'f', 2, 100),
  (105, 'male', 2, 100),
  (103, 'm', 0, 0);


/* 
a)	Посчитайте доход с женской аудитории (доход = сумма price*items)

Комментарий: по куску исходной таблицы видно, что user_gender обозначается по-разному, наверное, даже просто string,
а не enum. По-хорошему, чтобы понять какие user_gender означают женщин, нужно вывести все уникальные user_gender и 
посмотреть глазами. В рамках же базового тестового задания поверим, что женский пол всегда начинается с 'f' или 'F',
а мужской -- с 'm' или 'M'.
*/

SELECT SUM(items * price)
FROM Purchases
WHERE lower(user_gender) like 'f%';


/* 
b)	Сравните доход по группе мужчин и женщин

Комментарий: вообще можно посчитать доход по группам сразу за один проход таблицы (считывая строчку проверять какой 
гендер и увеличивать соответсвующую переменную) (тогда время работы будет в два раза меньше, но асимптотически - 
такое же), но, чтобы понять как это сделать на SQL, нужно погуглить. При решении реальных задач на аналитику время 
работы текущего запроса нормальное и основная задача все-таки в дальнейшей аналитике.

Комментарий 2: вероятность того, что на реальных данных доходы по группам совпадут практически 0, так что разбор
этого случая тут просто так (однако, вердикт будет точным).

Комментарий 3: "сравнить" можно понимать по-разному, но в рамках тестового имелось в виду, наверное, понять 
знак между этими двумя числами (>, < или =).
*/

WITH male_revenue AS (
  SELECT SUM(items * price)
  FROM Purchases
  WHERE lower(user_gender) like 'm%'
), female_revenue AS (
  SELECT SUM(items * price)
  FROM Purchases
  WHERE lower(user_gender) like 'f%'
)
SELECT 
  CASE 
    WHEN male_revenue > female_revenue THEN 'Revenue for men is higher than for women'
    WHEN male_revenue = female_revenue THEN 'Revenue for men is the same as for women'
    WHEN male_revenue < female_revenue THEN 'Revenue for men is lower than for women'
  END
FROM male_revenue, female_revenue;


/*
c)	Посчитайте кол-во уникальный пользователей-мужчин, заказавших более чем три наименования (суммарно за все заказы).
*/

SELECT COUNT(user_id)
FROM (
  SELECT user_id
  FROM Purchases
  WHERE lower(user_gender) like 'm%'
  GROUP BY user_id
  HAVING SUM(items) > 3
  ) as Men_Items;


/*
d)	Выведите 3 user_id мужчин с наибольшими затратами

Комментарий: если мужчин меньше 3, то в выводе будет столько строчек, сколько есть мужчин
*/

SELECT user_id
FROM (
  SELECT user_id
  FROM Purchases
  WHERE lower(user_gender) like 'm%'
  GROUP BY user_id
  ORDER BY SUM(items * price) DESC
  ) as Men_Items
LIMIT 3;