DROP TABLE IF EXISTS Transactions;

CREATE TABLE IF NOT EXISTS 
  Transactions (
    transaction_ts TIMESTAMP NOT NULL,
    user_id BIGINT not NULL,
    transaction_id BIGINT not NULL,
    item varchar(255) not NULL
  );

INSERT INTO Transactions (transaction_ts, user_id, transaction_id, item)
VALUES 
  ('2016-06-18 13:46:51.0', 13811335,   1322361417, 'glove'),
  ('2016-06-18 17:29:25.0', 13811335,   3729362318, 'hat'),
  ('2016-06-18 23:07:12.0', 13811335,   1322363995, 'vase'),
  ('2016-06-19 07:14:56.0', 13811335,   7482365143, 'cup'),
  ('2016-06-19 21:59:40.0', 13811335,   1322369619, 'mirror'),
  ('2016-06-17 12:39:46.0', 3378024101, 9322351612, 'dress'),
  ('2016-06-17 20:22:17.0', 3378024101, 9322353031, 'vase'),
  ('2016-06-20 11:29:02.0', 3378024101, 6928364072, 'tie'),
  ('2016-06-20 18:59:48.0', 13811335,   1322375547, 'mirror');


/*
a)	Выведите для каждого пользователя первое наименование, которое он заказал (первое по времени)

Комментарий: в такой таблице возможны инварианты как: упорядочено по возрастанию по времени транзакции, для 
каждого пользователя его записи упорядочены по возрастанию времени транзакции и другие. На их основании возможно
можно было бы придумать эффективные алгоритмы. Но их у нас нет, поэтому решаем задачу в общем виде: дана эта таблица,
в которой строчки в любом порядке. Небольшой поиск в интернете привел к следующему: https://stackoverflow.com/a/7630564
*/

-- SELECT DISTINCT ON (user_id), item
-- FROM Transactions
-- ORDER BY transaction_ts;
/*
Я бы остановился на этом ^^^ решении. Оно уже оптимизировано для PostgreSQL и подходит для того,
чтобы получить данные за хорошее время. Основная задача обычно все-таки в дальнейшем анализе. Но
попросили написать "наиболее оптимальный SQL запрос" (наверное, имея в виду под "оптимальным" быстрый).

Если немного подумать, то можно предположить, что уникальных user_id гораздо меньше чем записей. Это дает почву
для более эффективного алгоритма:
*/

/*
Для лучшей скорости чтения инициализируем мультистолбцовый индекс:
*/
CREATE INDEX transactions_combo_covering_idx
ON Transactions (user_id, transaction_ts NULLS LAST) INCLUDE (item);

/*
Дальше делаем recursive CTE with LATERAL join https://stackoverflow.com/a/25536748. Утверждается, что это самый
эффективный алгоритм на PostgreSQL и работает он гораздо быстрее прошлого решения с DISTINCT ON в случае, если
уникальных user_id заметно меньше числа строчек.
*/
WITH RECURSIVE cte AS
  (
    (
      SELECT user_id, item
      FROM Transactions
      ORDER BY user_id, transaction_ts NULLS LAST
      LIMIT 1
    )
    UNION ALL
    SELECT l.*
    FROM cte c
    CROSS JOIN LATERAL
      (
        SELECT l.user_id, l.item
        FROM Transactions l
        WHERE l.user_id > c.user_id
        ORDER BY l.user_id, l.transaction_ts NULLS LAST
        LIMIT 1
      ) l
  )
TABLE cte
ORDER BY user_id;
/*
Однако, если бы у нас была таблица со списком уникальных user_id, то можно было бы еще ускорить этот алгоритм. Но
в рамках тестового задания у нас ее нет или не предполагается, поэтому я решил остановиться на алгоритме выше.
*/


/*
b)	Посчитайте сколько транзакций в среднем делает каждый пользователь в течении 72х часов с момента первой транзакции

Комментарий: немного эффективнее будет уже на этапе построения recursive CTE находить то, что нам нужно.
Но асимптотически это не изменит время работы. Сейчас оно O(len(transactions) * log(len(unique_users))).
*/

WITH RECURSIVE cte AS
  (
    (
      SELECT user_id, transaction_ts
      FROM Transactions
      ORDER BY user_id, transaction_ts NULLS LAST
      LIMIT 1
    )
    UNION ALL
    SELECT l.*
    FROM cte c
    CROSS JOIN LATERAL
      (
        SELECT l.user_id, l.transaction_ts
        FROM Transactions l
        WHERE l.user_id > c.user_id
        ORDER BY l.user_id, l.transaction_ts NULLS LAST
        LIMIT 1
      ) l
  )

SELECT user_id, COUNT(transaction_id)
FROM Transactions
WHERE transaction_ts BETWEEN (SELECT transaction_ts FROM cte WHERE cte.user_id = Transactions.user_id) AND (SELECT transaction_ts FROM cte WHERE cte.user_id = Transactions.user_id) + '72 hours'::interval
GROUP BY user_id;