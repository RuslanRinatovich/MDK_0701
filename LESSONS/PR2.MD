Предыдущее занятие | &nbsp; | Следующее занятие
:----------------:|:----------:|:----------------:
[Лекция 3](LESSON3.MD)| [Содержание](../README.MD) | [Лекция 4](LESSON4.MD)

### **Практическая работа №2: Управление экземпляром и базами данных в MS SQL Server**

**Цель работы:** Закрепить теоретические знания об архитектуре MS SQL Server. Приобрести практические навыки управления состоянием экземпляра сервера, изучения структуры баз данных и их файлов с помощью различных инструментов.

**Необходимое ПО:**
*   **ВСЯ РАБОТА ВЫПОЛНЯЕТСЯ В ВАШЕЙ ВИРТУАЛЬНОЙ МАШИНЕ**
*   Виртуальная машина VirtualBox с установленной Windows 10
*   MS SQL Server (желательно Express или Developer Edition)
*   SQL Server Management Studio (SSMS)

---

### **Ход работы**

#### **Часть 1: Управление экземпляром сервера (15 минут)**

**Задача 1.1: Изучение состояния экземпляра через Службы Windows**
1.  Откройте оснастку «Службы» (Win + R -> `services.msc`).
2.  Найдите в списке службу для вашего экземпляра SQL Server (например, `SQL Server (MSSQLSERVER)` или `SQL Server (SQLEXPRESS)`).
3.  Определите ее **состояние** (Выполняется/Остановлена) и **тип запуска**.
4.  Запишите название службы, состояние и тип запуска в отчёт.

**Задача 1.2: Использование SQL Server Configuration Manager**
1.  Запустите **SQL Server Configuration Manager**.
2.  Перейдите в узел «Службы SQL Server».
3.  Убедитесь, что состояние вашей службы совпадает с наблюдением из Задачи 1.1.
4.  Щелкните правой кнопкой мыши по службе и исследуйте вкладки «Свойств» (например, «Вход в систему»). Запишите, от имени какой учетной записи запущена служба.

**Задача 1.3: Остановка и запуск экземпляра из командной строки**
1.  Откройте **командную строку (cmd) от имени администратора**.
2.  Чтобы остановить экземпляр, выполните команду (подставив имя своей службы):
    ```bash
    net stop "SQL Server (MSSQLSERVER)"
    ```
3.  Вернитесь в SSMS и попробуйте подключиться к серверу. Опишите реакцию системы.
4.  Запустите экземпляр обратно через командную строку:
    ```bash
    net start "SQL Server (MSSQLSERVER)"
    ```
5.  Убедитесь в SSMS, что подключение восстановилось.

---

#### **Часть 2: Изучение системных и пользовательских баз данных (20 минут)**

**Задача 2.1: Обзор баз данных в SSMS**
1.  Подключитесь к вашему экземпляру SQL Server в SSMS.
2.  В **Обозревателе объектов** разверните узел «Базы данных».
3.  Изучите список системных баз (`master`, `model`, `msdb`, `tempdb`). Найдите пользовательские базы (например, `University` или создайте новую для эксперимента, выполнив `CREATE DATABASE TestDB;`).

**Задача 2.2: Анализ баз данных с помощью sys.databases**
1.  Откройте новое окно запроса.
2.  Выполните запрос к системному представлению `sys.databases`:
    ```sql
    SELECT 
        name AS 'Database Name',
        database_id AS 'DB ID',
        state_desc AS 'State',
        recovery_model_desc AS 'Recovery Model',
        compatibility_level AS 'Compatibility Level',
        user_access_desc AS 'User Access',
        create_date
    FROM sys.databases
    ORDER BY database_id;
    ```
3.  Проанализируйте результат. Ответьте на вопросы:
    *   Какой `database_id` у базы `master`? А у вашей пользовательской базы?
    *   В каком состоянии находятся все базы данных?
    *   Какая модель восстановления используется для базы `model` и для вашей пользовательской базы?

---

#### **Часть 3: Исследование физической структуры баз данных (25 минут)**

**Задача 3.1: Получение информации о файлах всех БД через sys.master_files**
1.  Выполните следующий запрос, чтобы увидеть файлы всех баз данных экземпляра:
    ```sql
    SELECT 
        DB_NAME(database_id) AS 'Database Name',
        name AS 'Logical File Name',
        type_desc AS 'File Type',
        physical_name AS 'Physical File Path',
        (size * 8.0 / 1024) AS 'Size (MB)', -- Конвертация страниц в МБ
        CASE max_size
            WHEN -1 THEN 'Unlimited'
            WHEN 0 THEN 'No Growth'
            ELSE CAST((max_size * 8.0 / 1024) AS VARCHAR) + ' MB'
        END AS 'Max Size'
    FROM sys.master_files
    ORDER BY [Database Name], [File Type];
    ```
2.  Найдите файлы для базы `master` и вашей пользовательской базы. Запишите их логические имена, типы и физические пути на диске.

**Задача 3.2: Детальный анализ файлов конкретной пользовательской базы**
1.  Переключите контекст на вашу пользовательскую базу данных (например, `University` или `TestDB`):
    ```sql
    USE University; -- Замените на имя вашей БД
    ```
2.  Изучите файлы, используя представление `sys.database_files`:
    ```sql
    SELECT 
        name AS 'Logical File Name',
        type_desc AS 'File Type',
        physical_name AS 'Physical File Path',
        (size * 8.0 / 1024) AS 'Size (MB)',
        state_desc AS 'File State'
    FROM sys.database_files;
    ```
3.  Сравните результат с выводом из `sys.master_files` для этой же базы. Что общего и в чем разница?

**Задача 3.3: Исследование файловых групп**
1.  В контексте вашей пользовательской базы выполните запрос к `sys.filegroups`:
    ```sql
    SELECT 
        name AS 'Filegroup Name',
        type_desc AS 'Type',
        is_default AS 'Is Default'
    FROM sys.filegroups;
    ```
2.  Определите, какая файловая группа является группой по умолчанию для этой базы данных.

---

#### **Часть 4: Использование встроенных отчетов и устаревших методов (10 минут)**

**Задача 4.1: Встроенные отчеты SSMS**
1.  В **Обозревателе объектов** щелкните правой кнопкой мыши по вашей пользовательской базе данных.
2.  Выберите **Отчеты** -> **Стандартные отчеты** -> **Использование дискового пространства**.
3.  Визуально проанализируйте отчет. Сравните данные о размере данных и журнала с цифрами, полученными в Части 3.

**Задача 4.2: Использование устаревшей процедуры sp_helpdb**
1.  Выполните системную процедуру для просмотра информации о всех базах:
    ```sql
    EXEC sp_helpdb;
    ```
2.  Выполните процедуру для получения детальной информации о вашей базе:
    ```sql
    EXEC sp_helpdb 'University'; -- Замените на имя вашей БД
    ```
3.  Оцените удобство этого метода по сравнению с запросами к системным представлениям.

---

### **Содержание отчета**
Создайте документ формата docx. 
Отправьте отчет через гугл-форму [Сдать практическую работу 2](https://forms.gle/F95pDeeq8Yr9Xi7f6) 

Отчет должен содержать:
1.  **Титульный лист** (Тема, ФИО, группа).
2.  **Цель работы**.
3.  **Ответы на вопросы** из всех задач (например, имя службы, состояние БД, модель восстановления, пути к файлам и т.д.).
4.  **SQL-код** всех запросов, которые вы выполняли.
5.  **Скриншоты** ключевых результатов (например, результат запроса к `sys.master_files`, окно служб, отчет SSMS).
6.  **Выводы** по работе: что нового узнали, с какими инструментами управления научились работать, какие возникли трудности.

**Критерии оценки:**
*   Полнота выполнения всех задач.
*   Правильность и аккуратность оформления отчета.
*   Понимание и правильная интерпретация полученных результатов.
*   Умение использовать различные инструменты (SSMS, командная строка, системные представления) для решения поставленных задач.



#### СКРИПТ БД University

```sql

-- Создание базы данных University
CREATE DATABASE University;
GO

USE University;
GO

-- 1. Таблица факультетов
CREATE TABLE Faculties (
    FacultyID INT IDENTITY(1,1) PRIMARY KEY,
    FacultyName NVARCHAR(100) NOT NULL,
    DeanName NVARCHAR(100),
    Building NVARCHAR(50)
);
GO

-- 2. Таблица кафедр
CREATE TABLE Departments (
    DepartmentID INT IDENTITY(1,1) PRIMARY KEY,
    DepartmentName NVARCHAR(100) NOT NULL,
    FacultyID INT NOT NULL,
    HeadName NVARCHAR(100),
    FOREIGN KEY (FacultyID) REFERENCES Faculties(FacultyID)
);
GO

-- 3. Таблица преподавателей
CREATE TABLE Teachers (
    TeacherID INT IDENTITY(1,1) PRIMARY KEY,
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    Email NVARCHAR(100),
    Phone NVARCHAR(20),
    DepartmentID INT NOT NULL,
    HireDate DATE,
    Salary DECIMAL(10,2),
    FOREIGN KEY (DepartmentID) REFERENCES Departments(DepartmentID)
);
GO

-- 4. Таблица студентов
CREATE TABLE Students (
    StudentID INT IDENTITY(1,1) PRIMARY KEY,
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    Email NVARCHAR(100),
    Phone NVARCHAR(20),
    FacultyID INT NOT NULL,
    EnrollmentYear INT,
    BirthDate DATE,
    FOREIGN KEY (FacultyID) REFERENCES Faculties(FacultyID)
);
GO

-- 5. Таблица курсов
CREATE TABLE Courses (
    CourseID INT IDENTITY(1,1) PRIMARY KEY,
    CourseName NVARCHAR(100) NOT NULL,
    CourseCode NVARCHAR(20) NOT NULL,
    Credits INT NOT NULL,
    DepartmentID INT NOT NULL,
    Description NVARCHAR(500),
    FOREIGN KEY (DepartmentID) REFERENCES Departments(DepartmentID)
);
GO

-- 6. Таблица оценок (связь студентов и курсов)
CREATE TABLE Grades (
    GradeID INT IDENTITY(1,1) PRIMARY KEY,
    StudentID INT NOT NULL,
    CourseID INT NOT NULL,
    TeacherID INT NOT NULL,
    Grade DECIMAL(4,2) NOT NULL,
    ExamDate DATE NOT NULL,
    Semester INT NOT NULL,
    FOREIGN KEY (StudentID) REFERENCES Students(StudentID),
    FOREIGN KEY (CourseID) REFERENCES Courses(CourseID),
    FOREIGN KEY (TeacherID) REFERENCES Teachers(TeacherID)
);
GO

-- Заполнение таблицы Faculties тестовыми данными
INSERT INTO Faculties (FacultyName, DeanName, Building) VALUES
('Факультет информатики и вычислительной техники', 'Иванов А.С.', 'Главный корпус'),
('Факультет экономики', 'Петрова М.И.', 'Корпус Б'),
('Факультет иностранных языков', 'Сидорова О.Л.', 'Корпус В');
GO

-- Заполнение таблицы Departments тестовыми данными
INSERT INTO Departments (DepartmentName, FacultyID, HeadName) VALUES
('Кафедра программирования', 1, 'Козлов Д.В.'),
('Кафедра сетевых технологий', 1, 'Николаев П.С.'),
('Кафедра экономической теории', 2, 'Васильева Т.К.'),
('Кафедра английского языка', 3, 'Морозова Л.М.');
GO

-- Заполнение таблицы Teachers тестовыми данными
INSERT INTO Teachers (FirstName, LastName, Email, Phone, DepartmentID, HireDate, Salary) VALUES
('Алексей', 'Смирнов', 'a.smirnov@university.ru', '+79161234567', 1, '2015-09-01', 75000),
('Мария', 'Кузнецова', 'm.kuznetsova@university.ru', '+79161234568', 1, '2018-02-15', 68000),
('Дмитрий', 'Попов', 'd.popov@university.ru', '+79161234569', 2, '2016-11-10', 72000),
('Ольга', 'Лебедева', 'o.lebedeva@university.ru', '+79161234570', 3, '2014-03-20', 71000),
('Сергей', 'Новиков', 's.novikov@university.ru', '+79161234571', 4, '2019-08-25', 65000);
GO

-- Заполнение таблицы Students тестовыми данными
INSERT INTO Students (FirstName, LastName, Email, Phone, FacultyID, EnrollmentYear, BirthDate) VALUES
('Иван', 'Петров', 'i.petrov@edu.university.ru', '+79161234572', 1, 2022, '2003-05-15'),
('Елена', 'Сидорова', 'e.sidorova@edu.university.ru', '+79161234573', 1, 2022, '2004-02-20'),
('Андрей', 'Васильев', 'a.vasiliev@edu.university.ru', '+79161234574', 2, 2021, '2002-11-10'),
('Наталья', 'Михайлова', 'n.mikhailova@edu.university.ru', '+79161234575', 2, 2023, '2005-07-30'),
('Александр', 'Фёдоров', 'a.fedorov@edu.university.ru', '+79161234576', 1, 2021, '2002-12-05'),
('Татьяна', 'Морозова', 't.morozova@edu.university.ru', '+79161234577', 3, 2022, '2003-09-18');
GO

-- Заполнение таблицы Courses тестовыми данными
INSERT INTO Courses (CourseName, CourseCode, Credits, DepartmentID, Description) VALUES
('Базы данных', 'DB101', 4, 1, 'Основы проектирования и работы с базами данных'),
('Веб-программирование', 'WEB201', 5, 1, 'Создание веб-приложений и сайтов'),
('Сетевые технологии', 'NET301', 4, 2, 'Основы построения компьютерных сетей'),
('Экономическая теория', 'ECO101', 3, 3, 'Основы экономических знаний'),
('Деловой английский', 'ENG201', 3, 4, 'Английский язык для профессионального общения'),
('Операционные системы', 'OS202', 4, 1, 'Изучение принципов работы операционных систем');
GO

-- Заполнение таблицы Grades тестовыми данными
INSERT INTO Grades (StudentID, CourseID, TeacherID, Grade, ExamDate, Semester) VALUES
(1, 1, 1, 4.5, '2023-12-20', 1),
(1, 2, 2, 4.0, '2023-12-25', 1),
(2, 1, 1, 5.0, '2023-12-20', 1),
(2, 3, 3, 4.5, '2023-12-22', 1),
(3, 4, 4, 4.0, '2023-12-18', 1),
(4, 4, 4, 3.5, '2023-12-18', 1),
(5, 1, 1, 4.5, '2023-12-20', 1),
(5, 6, 2, 5.0, '2023-12-28', 1),
(6, 5, 5, 4.5, '2023-12-15', 1),
(1, 6, 2, 4.0, '2024-05-20', 2),
(2, 2, 2, 5.0, '2024-05-22', 2);
GO

-- Проверка созданных таблиц и данных
SELECT 
    (SELECT COUNT(*) FROM Faculties) AS FacultiesCount,
    (SELECT COUNT(*) FROM Departments) AS DepartmentsCount,
    (SELECT COUNT(*) FROM Teachers) AS TeachersCount,
    (SELECT COUNT(*) FROM Students) AS StudentsCount,
    (SELECT COUNT(*) FROM Courses) AS CoursesCount,
    (SELECT COUNT(*) FROM Grades) AS GradesCount;
```


---
**Лицензия:** [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/)  
**Автор:** Руслан Ринатович Сафиулин  
**Дата:** 07.10.2025

---

Предыдущее занятие | &nbsp; | Следующее занятие
:----------------:|:----------:|:----------------:
[Лекция 3](LESSON3.MD) | [Содержание](../README.MD) | [Лекция 4](LESSON4.MD)