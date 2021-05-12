#Проектирование БД онлайн-школы PRAKTIKA.SCHOOL: https://www.praktika.school/
CREATE DATABASE IF NOT EXISTS praktika_school;
USE praktika_school;

-- 1. Таблица, соответствующая сущности “Пользователь” -------------------------------------------------------------------
CREATE TABLE user (
id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT "Идентификатор пользователя",
first_name VARCHAR(100) NOT NULL COMMENT "Имя пользователя",
last_name VARCHAR(100) NOT NULL COMMENT "Фамилия пользователя",
birthday DATE NOT NULL COMMENT "Дата рождения пользователя",
email VARCHAR(100) NOT NULL UNIQUE COMMENT "Почта",
phone VARCHAR(10) NOT NULL UNIQUE COMMENT "Телефон",
created_at DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT "Время создания строки",  
updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT "Время обновления строки",
KEY index_of_user_lastname(last_name) COMMENT "Индекс на фамилию пользователя",
KEY index_of_user_firstname(first_name) COMMENT "Индекс на имя пользователя",
KEY index_of_user_birthday(birthday) COMMENT "Индекс на дату рождения пользователя"
);
-- Ограничение на формат значений, хранящихся в атрибуте "Телефон"
ALTER TABLE user ADD CONSTRAINT `phone_check` CHECK (REGEXP_LIKE(phone, '[0-9]{10}'));

-- 2. Таблица, соответствующая сущности “Подписка” ------------------------------------------------------------------------
CREATE TABLE subscription (
id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT "Идентификатор подписки",
subscription_name VARCHAR(100) NOT NULL COMMENT "Название подписки",
subscription_days INT NOT NULL COMMENT "Количество дней действия подписки",
price FLOAT COMMENT "Цена подписки",
created_at DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT "Время создания строки",  
updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT "Время обновления строки",
UNIQUE KEY index_of_subscription_name(subscription_name) COMMENT "Индекс на название подписки"
);

-- 3. Таблица, соответствующая сущности “Факультет” ----------------------------------------------------------------------
CREATE TABLE faculty (
id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT "Идентификатор факультета",
faculty_name VARCHAR(100) NOT NULL COMMENT "Название факультета",
days_of_study INT NOT NULL COMMENT "Количество дней обучения",
created_at DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT "Время создания строки",  
updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT "Время обновления строки",
UNIQUE KEY index_of_faculty(faculty_name) COMMENT "Индекс на название факультета"
);

-- 4. Таблица, соответствующая сущности “Предмет” ----------------------------------------------------------------------
CREATE TABLE subject (
id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT "Идентификатор предмета",
faculty_id  INT UNSIGNED NOT NULL COMMENT "Ссылка на идентификатор факультета",
subject_name VARCHAR(100) NOT NULL COMMENT "Название предмета",
subject_author VARCHAR(100) NOT NULL COMMENT "ФИО преподавателя",
subject_about VARCHAR(500) NOT NULL COMMENT "Описание преподавателя",
created_at DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT "Время создания строки",  
updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT "Время обновления строки"
);

-- Создание внешнего ключа для связи с таблицей Факультет-----------------------------------------------------------------
ALTER TABLE subject ADD CONSTRAINT fk_subject_faculty FOREIGN KEY (faculty_id) REFERENCES faculty (id);

-- 5. Таблица, соответствующая сущности "Оценка" -------------------------------------------------------------------------
CREATE TABLE grade (
id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT "Идентификатор оценки",
description VARCHAR(100) NOT NULL UNIQUE,
created_at DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT "Время создания строки",  
updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT "Время обновления строки"
);

-- 6. Таблица для хранения сущности "Кликстрим" -------------------------------------------------------------------------
CREATE TABLE clickstream (
id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT "Идентификатор кликстрима",
user_id INT UNSIGNED NOT NULL COMMENT "Идентификатор пользователя",
cnt_minutes INT UNSIGNED COMMENT "Кол-во минут, проведенных на странице",
cnt_clicks INT UNSIGNED COMMENT "Кол-во совершенных кликов",
cnt_videos INT UNSIGNED COMMENT "Кол-во просмотренных видео",
date_of_clickstream DATE NOT NULL COMMENT "Дата кликстрима",
created_at DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT "Время создания строки",  
updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT "Время обновления строки"
);

-- Создание внешнего ключа для связи с таблицей Пользователь--------------------------------------------------------------
ALTER TABLE clickstream ADD CONSTRAINT fk_clickstream FOREIGN KEY (user_id) REFERENCES user (id);

-- 7. Таблица для хранения сущности "Урок"----------------------------------------------------------------------
CREATE TABLE topic (
id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT "Идентификатор урока",
topic_name VARCHAR(100) NOT NULL COMMENT "Название урока",
subject_id INT UNSIGNED NOT NULL COMMENT "Ссылка на идентификатор предмета",
created_at DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT "Время создания строки",  
updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT "Время обновления строки"
);

-- Создание внешнего ключа для таблицы subjects (таким образом урок связывается с предметом)-------------------------------
ALTER TABLE topic ADD CONSTRAINT fk_subject_topic FOREIGN KEY (subject_id) REFERENCES subject (id);

-- 8. Таблица для связи сущностей "Пользователь" - "Подписка"-------------------------------------------------------------
CREATE TABLE user_subscription (
id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT "Идентификатор связи",
user_id INT UNSIGNED NOT NULL COMMENT "Ссылка на идентификатор пользователя", 
subscription_id INT UNSIGNED NOT NULL COMMENT "Ссылка на идентификатор подписки",
date_of_subscription DATE NOT NULL COMMENT "Дата начала подписки",
created_at DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT "Время создания строки",  
updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT "Время обновления строки"
);

-- Создание внешнего ключа для таблицы user_subscription  (таким образом подписка связывается с пользователем)------------
ALTER TABLE user_subscription ADD CONSTRAINT fk_user_subscription FOREIGN KEY (user_id) REFERENCES user (id);
ALTER TABLE user_subscription ADD CONSTRAINT fk_subscription FOREIGN KEY (subscription_id) REFERENCES subscription (id);

-- 9. Таблица для связи сущностей "Пользователь" - "Факультет" ----------------------------------------------------------
CREATE TABLE user_faculty (
id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT "Идентификатор связи Пользователь-Факультет",
user_id INT UNSIGNED NOT NULL COMMENT "Идентификатор пользователя",
faculty_id INT UNSIGNED NOT NULL COMMENT "Идентификатор факультета",
start_of_study DATETIME COMMENT "Дата поступления на факультет",
created_at DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT "Время создания строки",  
updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT "Время обновления строки"
);

-- Создание внешних ключей для таблицы user_faculty-----------------------------------------------------------------------
ALTER TABLE user_faculty ADD CONSTRAINT fk_user_id FOREIGN KEY (user_id) REFERENCES user (id);
ALTER TABLE user_faculty ADD CONSTRAINT fk_faculty_id FOREIGN KEY (faculty_id) REFERENCES faculty (id);

-- 10. Таблица для связи сущностей "Оценка" - "Пользователь" - "Предмет"---------------------------------------------------
CREATE TABLE user_grade (
user_id INT UNSIGNED NOT NULL COMMENT "Идентификатор пользователя",
subject_id INT UNSIGNED NOT NULL COMMENT "Идентификатор предмета",
grade_id INT UNSIGNED NOT NULL COMMENT "Оценка за предмет",
date_of_grade DATETIME COMMENT "Дата получения оценки",
created_at DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT "Время создания строки",  
updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT "Время обновления строки",
primary key (user_id,subject_id,grade_id)
);

-- Создание внешнего ключа для таблицы user_grade ------------------------------------------------------------------------
ALTER TABLE user_grade ADD CONSTRAINT fk_user_grade_id FOREIGN KEY (user_id) REFERENCES user (id);
ALTER TABLE user_grade ADD CONSTRAINT fk_subject_grade_id FOREIGN KEY (subject_id) REFERENCES subject (id);
ALTER TABLE user_grade ADD CONSTRAINT fk_grade_id FOREIGN KEY (grade_id) REFERENCES grade (id);