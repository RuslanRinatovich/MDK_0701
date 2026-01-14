### 🔙 📚 🔜 Навигация по курсу

| [Предыдущее занятие](../LESSONS/PR13_2.MD) | &nbsp; | [Следующее занятие](../LESSONS/PR13_3.MD) |
|:--------------------------------------:|:------:|:-------------------------------------:|
| 🏠 [Практика №13.2](../LESSONS/PR13_2.MD) | 📖 [Содержание](../README.MD) | 💻 [Практика №13.3](../LESSONS/PR13_3.MD) |

---
# **Лекция 13.3. Продвинутые техники создания админ-процедур**


⏱️ **Продолжительность:** 90 минут

---

## **📖 Часть 1. Введение в продвинутые техники**

### **🔹 Что мы уже умеем?**
1. Создавать простые процедуры с PRINT и SELECT
2. Использовать переменные (DECLARE, SET)
3. Работать с параметрами (входные, OUTPUT)
4. Применять SET NOCOUNT ON

### **🔹 Что нового узнаем сегодня?**
1. **Динамический SQL** — создание запросов "на лету"
2. **Обработка ошибок** — TRY...CATCH блоки  
3. **Временные таблицы** — хранение промежуточных данных
4. **Практические админ-процедуры** — реальные примеры

---

## **📖 Часть 2. Динамический SQL**

### **🔹 Что такое динамический SQL?**
Это SQL-запросы, которые собираются в строковой переменной и выполняются во время работы процедуры.

### **🔹 Зачем нужен динамический SQL?**
1. Когда имена таблиц или баз неизвестны заранее
2. Для создания гибких фильтров и условий
3. Когда нужно менять структуру запроса в зависимости от параметров

### **🔹 Простой пример динамического SQL:**
```sql
CREATE PROCEDURE usp_SimpleDynamic
    @TableName NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Создаем SQL запрос в переменной
    DECLARE @SQL NVARCHAR(MAX);
    SET @SQL = 'SELECT TOP 10 * FROM ' + @TableName;
    
    -- Выполняем динамический SQL
    PRINT 'Выполняется запрос: ' + @SQL;
    EXEC sp_executesql @SQL;
END
GO

-- Использование:
EXEC usp_SimpleDynamic @TableName = 'sys.databases';
EXEC usp_SimpleDynamic @TableName = 'sys.tables';
```

### **🔹 Безопасный динамический SQL:**
```sql
CREATE PROCEDURE usp_SafeDynamic
    @DatabaseName NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Проверяем существование базы
    IF NOT EXISTS (SELECT 1 FROM sys.databases WHERE name = @DatabaseName)
    BEGIN
        PRINT 'Ошибка: база ' + @DatabaseName + ' не существует';
        RETURN;
    END
    
    -- Безопасное формирование запроса с QUOTENAME
    DECLARE @SQL NVARCHAR(MAX);
    SET @SQL = 'USE ' + QUOTENAME(@DatabaseName) + ';
               SELECT COUNT(*) AS TableCount FROM sys.tables';
    
    -- Выполняем
    EXEC sp_executesql @SQL;
END
GO
```

### **🔹 Динамический SQL с параметрами:**
```sql
CREATE PROCEDURE usp_DynamicWithParams
    @MinRows INT = 0
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @SQL NVARCHAR(MAX);
    DECLARE @Params NVARCHAR(MAX);
    
    -- SQL с параметром
    SET @SQL = '
        SELECT name, 
               (SELECT SUM(rows) FROM sys.partitions 
                WHERE object_id = t.object_id) AS RowCount
        FROM sys.tables t
        WHERE (SELECT SUM(rows) FROM sys.partitions 
               WHERE object_id = t.object_id) >= @MinRowsParam
        ORDER BY RowCount DESC';
    
    -- Определяем параметры
    SET @Params = '@MinRowsParam INT';
    
    -- Выполняем с передачей параметра
    EXEC sp_executesql @SQL, @Params, @MinRowsParam = @MinRows;
END
GO
```

---

## **📖 Часть 3. Обработка ошибок TRY...CATCH**

### **🔹 Зачем обрабатывать ошибки?**
1. Чтобы процедура не падала полностью при ошибке
2. Чтобы записывать ошибки в журнал
3. Чтобы возвращать понятные сообщения пользователю
4. Для отладки сложных процедур

### **🔹 Блок TRY...CATCH:**
```sql
BEGIN TRY
    -- Код, который может вызвать ошибку
    -- Например: деление на ноль, неверный запрос
END TRY
BEGIN CATCH
    -- Код, который выполняется при ошибке
    -- Можно получить информацию об ошибке
END CATCH
```

### **🔹 Простой пример обработки ошибок:**
```sql
CREATE PROCEDURE usp_SafeDivision
    @A INT,
    @B INT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Пытаемся выполнить деление
        DECLARE @Result DECIMAL(10,2);
        SET @Result = @A * 1.0 / @B;
        
        PRINT 'Результат деления: ' + CAST(@Result AS VARCHAR);
    END TRY
    BEGIN CATCH
        -- Если произошла ошибка
        PRINT 'ОШИБКА! Невозможно выполнить деление';
        PRINT 'Код ошибки: ' + CAST(ERROR_NUMBER() AS VARCHAR);
        PRINT 'Сообщение: ' + ERROR_MESSAGE();
        PRINT 'Строка с ошибкой: ' + CAST(ERROR_LINE() AS VARCHAR);
    END CATCH
END
GO

-- Тестируем:
EXEC usp_SafeDivision @A = 10, @B = 2;  -- Работает
EXEC usp_SafeDivision @A = 10, @B = 0;  -- Ошибка, но не падает
```

### **🔹 Функции для работы с ошибками:**
```sql
-- В блоке CATCH можно использовать:
ERROR_NUMBER()      -- Номер ошибки
ERROR_MESSAGE()     -- Текст ошибки
ERROR_SEVERITY()    -- Серьезность (10-25)
ERROR_STATE()       -- Состояние
ERROR_LINE()        -- Номер строки с ошибкой
ERROR_PROCEDURE()   -- Имя процедуры, где ошибка
```

### **🔹 Полный пример с логированием ошибок:**
```sql
CREATE PROCEDURE usp_ComplexProcedure
    @DatabaseName NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @StartTime DATETIME = GETDATE();
    DECLARE @ErrorNumber INT = 0;
    DECLARE @ErrorMessage NVARCHAR(4000);
    
    BEGIN TRY
        -- Проверяем существование базы
        IF NOT EXISTS (SELECT 1 FROM sys.databases WHERE name = @DatabaseName)
            RAISERROR('База данных не существует', 16, 1);
        
        -- Получаем информацию о базе
        DECLARE @SQL NVARCHAR(MAX);
        SET @SQL = 'USE ' + QUOTENAME(@DatabaseName) + ';
                   SELECT COUNT(*) FROM sys.tables';
        
        -- Выполняем динамический SQL
        EXEC sp_executesql @SQL;
        
        PRINT 'Операция выполнена успешно за ' + 
              CAST(DATEDIFF(MILLISECOND, @StartTime, GETDATE()) AS VARCHAR) + ' мс';
    END TRY
    BEGIN CATCH
        -- Сохраняем информацию об ошибке
        SET @ErrorNumber = ERROR_NUMBER();
        SET @ErrorMessage = ERROR_MESSAGE();
        
        -- Выводим информацию об ошибке
        PRINT 'ОШИБКА В ПРОЦЕДУРЕ usp_ComplexProcedure';
        PRINT 'Время: ' + CONVERT(VARCHAR, GETDATE(), 120);
        PRINT 'База: ' + @DatabaseName;
        PRINT 'Код ошибки: ' + CAST(@ErrorNumber AS VARCHAR);
        PRINT 'Сообщение: ' + @ErrorMessage;
        
        -- Можно залогировать в таблицу
        -- INSERT INTO ErrorLog (ErrorTime, ProcedureName, ErrorMessage)
        -- VALUES (GETDATE(), 'usp_ComplexProcedure', @ErrorMessage);
        
        -- Возвращаем код ошибки
        RETURN @ErrorNumber;
    END CATCH
    
    RETURN 0;  -- Успех
END
GO
```

---

## **📖 Часть 4. Временные таблицы в процедурах**

### **🔹 Что такое временные таблицы?**
Таблицы, которые существуют только во время выполнения сессии или процедуры.

### **🔹 Два типа временных таблиц:**

1. **Локальные временные таблицы** (начинаются с #)
   ```sql
   CREATE TABLE #TempTable (
       ID INT,
       Name NVARCHAR(100)
   );
   -- Существует только в текущем соединении
   -- Автоматически удаляется при закрытии соединения
   ```

2. **Глобальные временные таблицы** (начинаются с ##)
   ```sql
   CREATE TABLE ##GlobalTemp (
       ID INT
   );
   -- Видны всем соединениям
   -- Удаляются, когда все соединения ссылающиеся на них закрываются
   ```

### **🔹 Пример использования временной таблицы:**
```sql
CREATE PROCEDURE usp_UseTempTable
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Создаем временную таблицу
    CREATE TABLE #DatabaseInfo (
        DatabaseName NVARCHAR(100),
        TableCount INT,
        SizeMB DECIMAL(10,2)
    );
    
    -- Заполняем данными
    INSERT INTO #DatabaseInfo (DatabaseName, TableCount, SizeMB)
    SELECT 
        d.name,
        (SELECT COUNT(*) FROM sys.tables WHERE is_ms_shipped = 0),
        (SELECT CAST(SUM(size) * 8 / 1024.0 AS DECIMAL(10,2))
         FROM sys.master_files WHERE database_id = d.database_id)
    FROM sys.databases d
    WHERE d.state = 0;
    
    -- Используем данные из временной таблицы
    PRINT '=== ОТЧЕТ ПО БАЗАМ ДАННЫХ ===';
    SELECT * FROM #DatabaseInfo ORDER BY SizeMB DESC;
    
    -- Анализируем
    DECLARE @TotalSize DECIMAL(10,2);
    SELECT @TotalSize = SUM(SizeMB) FROM #DatabaseInfo;
    PRINT 'Общий размер всех баз: ' + CAST(@TotalSize AS VARCHAR) + ' МБ';
    
    -- Временная таблица удалится автоматически
    -- Но можно удалить явно:
    -- DROP TABLE #DatabaseInfo;
END
GO
```

### **🔹 Временная таблица с индексом:**
```sql
CREATE PROCEDURE usp_TempTableWithIndex
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Создаем временную таблицу
    CREATE TABLE #LargeTables (
        TableID INT IDENTITY PRIMARY KEY,
        SchemaName NVARCHAR(100),
        TableName NVARCHAR(100),
        RowCount BIGINT,
        SizeMB DECIMAL(10,2)
    );
    
    -- Создаем индекс для ускорения сортировки
    CREATE INDEX IX_Size ON #LargeTables(SizeMB DESC);
    
    -- Заполняем данными
    INSERT INTO #LargeTables (SchemaName, TableName, RowCount, SizeMB)
    SELECT 
        s.name,
        t.name,
        SUM(p.rows),
        CAST(SUM(a.total_pages) * 8 / 1024.0 AS DECIMAL(10,2))
    FROM sys.tables t
    JOIN sys.schemas s ON t.schema_id = s.schema_id
    JOIN sys.partitions p ON t.object_id = p.object_id
    JOIN sys.allocation_units a ON p.partition_id = a.container_id
    WHERE t.is_ms_shipped = 0
    GROUP BY s.name, t.name;
    
    -- Используем
    SELECT TOP 10 * FROM #LargeTables ORDER BY SizeMB DESC;
    
    -- Статистика
    PRINT 'Всего таблиц в временной таблице: ' + 
          CAST(@@ROWCOUNT AS VARCHAR);
END
GO
```

---

## **📖 Часть 5. Таблица переменных**

### **🔹 Что такое табличная переменная?**
Альтернатива временным таблицам, хранится в памяти.

```sql
DECLARE @TableVar TABLE (
    ID INT,
    Name NVARCHAR(100),
    Age INT
);
```

### **🔹 Сравнение табличной переменной и временной таблицы:**

| Критерий | Табличная переменная (@Table) | Временная таблица (#Table) |
|----------|-------------------------------|----------------------------|
| **Хранение** | В памяти (обычно) | На диске (tempdb) |
| **Индексы** | Только первичный ключ | Любые индексы |
| **Статистика** | Нет статистики | Есть статистика |
| **Объем данных** | Маленькие объемы | Большие объемы |
| **Производительность** | Быстрее для малых данных | Лучше для больших данных |

### **🔹 Пример табличной переменной:**
```sql
CREATE PROCEDURE usp_UseTableVariable
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Объявляем табличную переменную
    DECLARE @UserInfo TABLE (
        UserID INT,
        UserName NVARCHAR(100),
        LoginTime DATETIME
    );
    
    -- Заполняем данными
    INSERT INTO @UserInfo (UserID, UserName, LoginTime)
    SELECT 
        session_id,
        login_name,
        login_time
    FROM sys.dm_exec_sessions
    WHERE is_user_process = 1;
    
    -- Используем
    SELECT * FROM @UserInfo ORDER BY LoginTime DESC;
    
    PRINT 'Активных пользователей: ' + CAST(@@ROWCOUNT AS VARCHAR);
END
GO
```

---

## **📖 Часть 6. Практические админ-процедуры**

### **🔹 Процедура проверки резервных копий:**
```sql
CREATE PROCEDURE adm_CheckBackups
    @DaysBack INT = 7  -- За сколько дней проверять
AS
BEGIN
    SET NOCOUNT ON;
    
    PRINT 'ПРОВЕРКА РЕЗЕРВНЫХ КОПИЙ';
    PRINT '=======================';
    PRINT 'Период: последние ' + CAST(@DaysBack AS VARCHAR) + ' дней';
    PRINT '';
    
    -- Временная таблица для результатов
    CREATE TABLE #BackupInfo (
        DatabaseName NVARCHAR(100),
        LastBackup DATETIME,
        HoursAgo INT,
        Status NVARCHAR(20)
    );
    
    -- Заполняем данными
    INSERT INTO #BackupInfo (DatabaseName, LastBackup, HoursAgo, Status)
    SELECT 
        d.name,
        MAX(b.backup_finish_date),
        DATEDIFF(HOUR, MAX(b.backup_finish_date), GETDATE()),
        CASE 
            WHEN MAX(b.backup_finish_date) IS NULL THEN 'НЕТ КОПИЙ'
            WHEN DATEDIFF(HOUR, MAX(b.backup_finish_date), GETDATE()) > 24 
            THEN 'СТАРАЯ'
            ELSE 'OK'
        END
    FROM sys.databases d
    LEFT JOIN msdb.dbo.backupset b ON d.name = b.database_name
        AND b.backup_finish_date > DATEADD(DAY, -@DaysBack, GETDATE())
    WHERE d.database_id > 4  -- Не системные
    GROUP BY d.name
    ORDER BY HoursAgo DESC;
    
    -- Показываем результаты
    SELECT * FROM #BackupInfo;
    
    -- Проверяем проблемы
    PRINT '';
    DECLARE @ProblemCount INT;
    SELECT @ProblemCount = COUNT(*) 
    FROM #BackupInfo 
    WHERE Status IN ('НЕТ КОПИЙ', 'СТАРАЯ');
    
    IF @ProblemCount > 0
        PRINT 'ВНИМАНИЕ! Найдено ' + CAST(@ProblemCount AS VARCHAR) + 
              ' баз с проблемами резервного копирования!';
    ELSE
        PRINT 'Все базы имеют свежие резервные копии.';
    
    DROP TABLE #BackupInfo;
END
GO
```

### **🔹 Процедура мониторинга дискового пространства:**
```sql
CREATE PROCEDURE adm_CheckDiskSpace
    @WarningGB INT = 10,   -- Предупреждение при < 10 ГБ
    @CriticalGB INT = 5    -- Критично при < 5 ГБ
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Создаем временную таблицу
    CREATE TABLE #DiskInfo (
        Drive CHAR(1),
        FreeMB INT
    );
    
    -- Получаем информацию о дисках
    INSERT INTO #DiskInfo
    EXEC xp_fixeddrives;
    
    -- Анализируем
    PRINT 'МОНИТОРИНГ ДИСКОВОГО ПРОСТРАНСТВА';
    PRINT '=================================';
    PRINT '';
    
    SELECT 
        Drive AS 'Диск',
        FreeMB / 1024 AS 'Свободно (ГБ)',
        CASE 
            WHEN FreeMB / 1024 < @CriticalGB THEN 'КРИТИЧЕСКИ'
            WHEN FreeMB / 1024 < @WarningGB THEN 'ПРЕДУПРЕЖДЕНИЕ'
            ELSE 'НОРМА'
        END AS 'Статус'
    FROM #DiskInfo
    ORDER BY Drive;
    
    -- Проверяем статусы
    DECLARE @CriticalCount INT, @WarningCount INT;
    
    SELECT @CriticalCount = COUNT(*)
    FROM #DiskInfo
    WHERE FreeMB / 1024 < @CriticalGB;
    
    SELECT @WarningCount = COUNT(*)
    FROM #DiskInfo
    WHERE FreeMB / 1024 < @WarningGB AND FreeMB / 1024 >= @CriticalGB;
    
    PRINT '';
    PRINT 'ИТОГО:';
    PRINT 'Дисков в критическом состоянии: ' + CAST(@CriticalCount AS VARCHAR);
    PRINT 'Дисков с предупреждением: ' + CAST(@WarningCount AS VARCHAR);
    
    -- Рекомендации
    PRINT '';
    PRINT 'РЕКОМЕНДАЦИИ:';
    IF @CriticalCount > 0
        PRINT '  СРОЧНО освободите место на критических дисках!';
    IF @WarningCount > 0
        PRINT '  Рекомендуется очистить диски с предупреждением';
    IF @CriticalCount = 0 AND @WarningCount = 0
        PRINT '  Все диски в норме, продолжайте мониторинг';
    
    DROP TABLE #DiskInfo;
END
GO
```

### **🔹 Процедура поиска больших таблиц:**
```sql
CREATE PROCEDURE adm_FindLargeObjects
    @DatabaseName NVARCHAR(100) = NULL,
    @MinSizeMB INT = 100,
    @ObjectType VARCHAR(20) = 'ALL'
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @SQL NVARCHAR(MAX);
    
    -- Если БД не указана, используем текущую
    IF @DatabaseName IS NULL
        SET @DatabaseName = DB_NAME();
    
    PRINT 'ПОИСК БОЛЬШИХ ОБЪЕКТОВ';
    PRINT 'База данных: ' + @DatabaseName;
    PRINT 'Минимальный размер: ' + CAST(@MinSizeMB AS VARCHAR) + ' МБ';
    PRINT '';
    
    BEGIN TRY
        SET @SQL = '
        USE [' + @DatabaseName + '];
        
        WITH ObjectSizes AS (
            SELECT 
                s.name AS SchemaName,
                o.name AS ObjectName,
                o.type_desc AS ObjectType,
                SUM(a.total_pages) * 8 / 1024.0 AS SizeMB
            FROM sys.objects o
            JOIN sys.schemas s ON o.schema_id = s.schema_id
            JOIN sys.partitions p ON o.object_id = p.object_id
            JOIN sys.allocation_units a ON p.partition_id = a.container_id
            WHERE o.is_ms_shipped = 0
            AND (@ObjectTypeParam = ''ALL'' OR o.type_desc = @ObjectTypeParam)
            GROUP BY s.name, o.name, o.type_desc
        )
        SELECT *
        FROM ObjectSizes
        WHERE SizeMB >= @MinSizeParam
        ORDER BY SizeMB DESC;';
        
        EXEC sp_executesql @SQL, 
            N'@MinSizeParam INT, @ObjectTypeParam VARCHAR(20)',
            @MinSizeParam = @MinSizeMB,
            @ObjectTypeParam = @ObjectType;
        
        PRINT '';
        PRINT 'Поиск завершён успешно';
    END TRY
    BEGIN CATCH
        PRINT 'ОШИБКА при поиске больших объектов:';
        PRINT ERROR_MESSAGE();
        PRINT 'Проверьте имя базы данных и параметры';
    END CATCH
END
GO
```

---

## **📖 Часть 7. Лучшие практики**

### **🔹 1. Всегда используйте SET NOCOUNT ON**
```sql
CREATE PROCEDURE usp_GoodProcedure
AS
BEGIN
    SET NOCOUNT ON;  -- Первая строка!
    -- Остальной код...
END
```

### **🔹 2. Обрабатывайте ошибки**
```sql
CREATE PROCEDURE usp_SafeProcedure
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Основной код
    END TRY
    BEGIN CATCH
        -- Обработка ошибок
        PRINT 'Ошибка: ' + ERROR_MESSAGE();
        RETURN -1;
    END CATCH
END
```

### **🔹 3. Используйте временные таблицы для сложных операций**
```sql
-- Вместо сложных вложенных запросов:
CREATE TABLE #TempResults (...);
INSERT INTO #TempResults SELECT ...;
-- Работайте с #TempResults
```

### **🔹 4. Комментируйте сложную логику**
```sql
-- Хорошо:
-- Этот блок вычисляет средний размер таблиц
-- для последующего анализа фрагментации
DECLARE @AvgSizeMB DECIMAL(10,2);
SELECT @AvgSizeMB = AVG(SizeMB) FROM #TableSizes;

-- Плохо:
DECLARE @x DECIMAL(10,2);
SELECT @x = AVG(s) FROM #t;
```

### **🔹 5. Тестируйте граничные случаи**
```sql
-- Тестируйте процедуру с:
EXEC usp_Test @Param = NULL;      -- NULL значения
EXEC usp_Test @Param = '';        -- Пустые строки  
EXEC usp_Test @Param = 0;         -- Нули
EXEC usp_Test @Param = -1;        -- Отрицательные значения
```

---

## **📋 Шпаргалка: Когда что использовать?**

| Ситуация | Что использовать | Пример |
|----------|------------------|--------|
| **Простой запрос** | Обычный SELECT | `SELECT * FROM таблица` |
| **Динамическое имя таблицы** | Динамический SQL | `EXEC sp_executesql @SQL` |
| **Опасные операции** | TRY...CATCH | `BEGIN TRY...END TRY` |
| **Промежуточные данные** | Временная таблица | `CREATE TABLE #Temp` |
| **Маленькие данные в памяти** | Табличная переменная | `DECLARE @Table TABLE` |
| **Сложные вычисления** | Несколько временных таблиц | Разбить на шаги |

---

## **🎯 Ключевые моменты для запоминания**

### **✅ 5 вещей, которые нужно запомнить:**

1. **Динамический SQL** — для гибких запросов с переменными именами объектов
2. **TRY...CATCH** — для обработки ошибок и отладки
3. **Временные таблицы (#)** — для хранения промежуточных результатов
4. **Табличные переменные (@)** — для маленьких данных в памяти
5. **SET NOCOUNT ON всегда** — первая строка каждой процедуры

### **❌ 5 частых ошибок:**

1. **Нет обработки ошибок** в опасных операциях
2. **Использование динамического SQL без проверки** — риск SQL-инъекций
3. **Большие данные в табличных переменных** — лучше временные таблицы
4. **Нет комментариев** в сложной логике
5. **Забывают удалять временные таблицы** — хотя они удаляются автоматически

---

## **📚 Резюме**

Сегодня вы узнали:
1. **Динамический SQL** — создание и выполнение запросов во время выполнения
2. **Обработку ошибок** — как делать процедуры устойчивыми к сбоям
3. **Временные таблицы** — для работы с промежуточными данными
4. **Практические примеры** — реальные админ-процедуры для ежедневного использования

**Помните:** Хорошая админ-процедура — это не только рабочая, но и безопасная, обрабатывающая ошибки и хорошо документированная!

---

### 🔙 📚 🔜 Навигация по курсу

| [Практика 13.2](../PRACT

---

### 🔙 📚 🔜 Навигация по курсу

| [Предыдущее занятие](../LESSONS/PR13_2.MD) | &nbsp; | [Следующее занятие](../LESSONS/PR13_3.MD) |
|:--------------------------------------:|:------:|:-------------------------------------:|
| 🏠 [Практика №13.2](../LESSONS/PR13_2.MD) | 📖 [Содержание](../README.MD) | 💻 [Практика №13.3](../LESSONS/PR13_3.MD) |

---
