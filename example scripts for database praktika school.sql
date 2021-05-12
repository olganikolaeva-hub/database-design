#------------------------------------------------------------------------------------------------------------------------
# СКРИПТЫ ХАРАКТЕРНЫХ ВЫБОРОК--------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------------------
-- 1. Какое количество подписчиков учится в онлайн-школе?
-- (отслеживание тенденции роста либо снижения количества подписчиков, проведение маркетингового анализа)
SELECT DATE_FORMAT(date_of_subscription,'%Y-%m'),
       count(user_subscription.user_id) as 'cnt_users',
       sum(subscription.price) as 'sum_users'
FROM user_subscription
INNER JOIN subscription on subscription.id = user_subscription.subscription_id
GROUP BY DATE_FORMAT(date_of_subscription,'%Y-%m')
ORDER BY DATE_FORMAT(date_of_subscription,'%Y-%m');

-- Какое распределение учащихся по типу подписок?
SELECT DATE_FORMAT(user_subscription.date_of_subscription, '%Y-%m'),
       subscription.subscription_name,
       count(user_subscription.user_id)
FROM user_subscription
INNER JOIN subscription on subscription.id = user_subscription.subscription_id
GROUP BY DATE_FORMAT(user_subscription.date_of_subscription, '%Y-%m'),
       subscription.subscription_name
ORDER BY DATE_FORMAT(user_subscription.date_of_subscription, '%Y-%m');

-- 2. Какой средний возраст пользователей онлайн-школы?
-- (позиционирование онлайн-школы,  настройка рекламных кампаний) 
SELECT subscription.subscription_name,
       ROUND(AVG(FLOOR(DATEDIFF(CURDATE(), user.birthday)/365))) as 'средний возраст пользователя'
FROM user
INNER JOIN user_subscription on user_subscription.user_id = user.id
INNER JOIN subscription on subscription.id = user_subscription.subscription_id
GROUP BY subscription.subscription_name
ORDER BY user_subscription.date_of_subscription;

-- 3. Насколько хорошо учатся ученики на наиболее популярных факультетах?
-- (оценка уровня вовлеченности подписчиков в изучение предметов)
SELECT top_3_faculty.faculty_name,
       AVG(grade_id) as 'avg_grade'
FROM (SELECT faculty.faculty_name,
       faculty.id as faculty_id,
       COUNT(user_faculty.user_id) as 'cnt_users'
FROM faculty
INNER JOIN user_faculty on user_faculty.faculty_id = faculty.id
GROUP BY faculty.faculty_name
ORDER BY COUNT(user_faculty.user_id) DESC
LIMIT 3) as top_3_faculty 
INNER JOIN subject on top_3_faculty.faculty_id = subject.faculty_id
INNER JOIN user_grade on user_grade.subject_id = subject.id
WHERE user_grade.date_of_grade >= CURDATE() - INTERVAL 90 day
GROUP BY top_3_faculty.faculty_name;

-- 4. Какая доля учеников оплачивает подписку повторно? На каком факультете обучаются ученики, которые продлевают подписку?
-- (отслеживание эффективности работы с клиентами, коэффициента удержания клиентов )
SELECT count(distinct user_subscription.user_id)/count(user_subscription.user_id) as '% Повторных подписок',
       DATE_FORMAT(min(user_faculty.start_of_study), '%Y-%m'),
       faculty.faculty_name
FROM user_subscription
INNER JOIN user_faculty on user_subscription.user_id = user_faculty.user_id
INNER JOIN faculty on faculty.id = user_faculty.faculty_id
GROUP BY faculty.faculty_name;

-- 5. Какая доля зарегистрированных пользователей оформляет подписку?
-- (отслеживание коэффициента конверсии) 
  SELECT count(user_subscription.user_id)/count(user.id)
  FROM user
  LEFT JOIN user_subscription on user_subscription.user_id = user.id;

#------------------------------------------------------------------------------------------------------------------------
# ПРЕДСТАВЛЕНИЯ ---------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------------------
-- 1. Какие факультеты наиболее популярны среди подписчиков?
CREATE OR REPLACE VIEW top_3_faculty AS
SELECT faculty.faculty_name,
       faculty.id,
       COUNT(user_faculty.user_id) as 'cnt_users'
FROM faculty
INNER JOIN user_faculty on user_faculty.faculty_id = faculty.id
GROUP BY faculty.faculty_name
ORDER BY COUNT(user_faculty.user_id) DESC
LIMIT 3;
COMMIT;

SELECT * FROM top_3_faculty;

-- 2. У кого из подписчиков сегодня День Рождения либо Окончание Подписки либо Пользователь не купил подписку, но
-- зарегистрировался и провел много времени на сайте школы?
-- (проведение акционных предложений)
CREATE OR REPLACE VIEW user_for_action AS
SELECT user.id,
       user.birthday as 'date',
       'birthday_today' as 'type_of_date'
FROM user
WHERE birthday + Interval FLOOR(DATEDIFF(CURDATE(), user.birthday)/365) year = CURDATE()
UNION
SELECT user_subscription.user_id,
       user_subscription.date_of_subscription + Interval subscription_days day as 'date',
       'end_of_subscription_today' as 'type_of_date'
FROM user_subscription
INNER JOIN subscription on subscription.id = user_subscription.subscription_id
WHERE user_subscription.date_of_subscription + Interval subscription_days day = CURDATE()
UNION 
SELECT clickstream.user_id,
       clickstream.date_of_clickstream as 'date',
       'active_clickstream_yesterday' as 'type_of_date'
FROM clickstream
LEFT JOIN user_subscription on user_subscription.user_id = clickstream.user_id
WHERE clickstream.cnt_videos = 0 and clickstream.cnt_clicks > 1 and date_of_clickstream  = curdate() - Interval 1 day;
COMMIT;

SELECT * FROM user_for_action;
#------------------------------------------------------------------------------------------------------------------------
# ПРОЦЕДУРЫ -------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------------------
-- 1. Создаем представление для удобства работы с действующими пользователями сервиса.
-- Условие: дата подписки пользователя + период подписки должна быть больше,
-- чем текущая дата. Представление должно обновляться ежедневно в рамках процедуры proc_current_user_subscription()
DELIMITER \\
CREATE PROCEDURE proc_current_user_subscription()
BEGIN
CREATE OR REPLACE VIEW current_user_subscription AS
SELECT user_subscription.user_id,
       subscription.id,
       subscription_name,
       subscription_days,
       price,
       max(date_of_subscription) as 'start_of_last_subscription',
       max(date_of_subscription) + Interval subscription_days day as 'end_of_subscription'
FROM user_subscription
INNER JOIN subscription on subscription.id = user_subscription.subscription_id
GROUP BY user_subscription.user_id,
       subscription.id,
       subscription_name,
       subscription_days,
       price
HAVING max(date_of_subscription) + Interval subscription_days day > CURDATE();
COMMIT;
END \\

-- Проверяем правильность созданной процедуры
CALL proc_current_user_subscription();
SELECT * FROM current_user_subscription; -- выгружаем текущих подписчиков из вью current_user_subscription

#------------------------------------------------------------------------------------------------------------------------
# ТРИГГЕРЫ --------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------------------
-- 1. Создаем триггер, проверяющий возможность пользователя воспользоваться бесплатной тестовой подпиской
delimiter //
CREATE TRIGGER check_subscription BEFORE INSERT on user_subscription
FOR EACH ROW BEGIN
SET @new_user = NEW.user_id;
SET @new_subscription = NEW.subscription_id;
 IF (SELECT user_id FROM user_subscription WHERE subscription_id = 1 and user_id = @new_user) IS NOT NULL AND @new_subscription = 1 THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INSERT canceled. This user has had test subscription already';
 END IF;
END //

-- проверка -------------------------------------------------------------------------------------------------------------
delimiter ;
INSERT INTO user_subscription
  (user_id, subscription_id, date_of_subscription)
VALUES
  (11, 1, CURDATE());
  