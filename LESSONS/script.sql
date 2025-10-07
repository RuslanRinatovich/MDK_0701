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
