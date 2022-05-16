-- Create tables
DROP TABLE Project;
DROP TABLE Game;
DROP TABLE Team;
DROP TABLE Employee;

CREATE TABLE Game (
    ID                NUMBER PRIMARY KEY,
    name              VARCHAR2(20) NOT NULL,
    release           DATE,
    costOfDevelopment NUMBER CHECK(costOfDevelopment > 0) NOT NULL
);

CREATE TABLE Team (
    ID            NUMBER PRIMARY KEY,
    name          VARCHAR2(20) NOT NULL,
    nextMilestone DATE
);

CREATE TABLE Project (
    gameID  NUMBER REFERENCES Game(ID),
    teamID  NUMBER REFERENCES Team(ID),
    PRIMARY KEY(gameID, teamID),
    active  NUMBER NOT NULL CHECK(active=1 or active=0)
);

CREATE TABLE Employee (
    ID          NUMBER PRIMARY KEY,
    firstName   VARCHAR2(20) NOT NULL,
    lastName    VARCHAR2(20) NOT NULL,
    jobTitle    VARCHAR2(20) NOT NULL,
    startDate   DATE NOT NULL,
    endDate     DATE,
    salary      NUMBER CHECK(salary >= 1500) NOT NULL,
    teamID      REFERENCES Team(ID) ON DELETE SET NULL
);


-- Insert into tables

-- Game table
INSERT INTO Game VALUES(1, 'Warcraft',   to_date('2004.10.01', 'YYYY.MM.DD'), 63);
INSERT INTO Game VALUES(2, 'Diablo',     to_date('1997.01.01', 'YYYY.MM.DD'), 40);
INSERT INTO Game VALUES(3, 'Overwatch',  to_date('2016.04.20', 'YYYY.MM.DD'), 38);
INSERT INTO Game VALUES(4, 'Hearthstone',to_date('2014.08.11', 'YYYY.MM.DD'), 40);
INSERT INTO Game VALUES(5, 'StarCraft',  to_date('1998.07.02', 'YYYY.MM.DD'), 36);

SELECT * FROM Game;

-- Team table
INSERT INTO Team VALUES(1, 'Graphics', NULL);
INSERT INTO Team VALUES(2, 'Physics',  to_date('2022.09.21', 'YYYY.MM.DD'));
INSERT INTO Team VALUES(3, 'AI',       to_date('2022.09.21', 'YYYY.MM.DD'));
INSERT INTO Team VALUES(4, 'Sound',    to_date('2022.06.11', 'YYYY.MM.DD'));
INSERT INTO Team VALUES(5, 'UI',       to_date('2022.07.02', 'YYYY.MM.DD'));

SELECT * FROM Team;

-- Project table
INSERT INTO Project (gameID, teamID, active)
SELECT Game.ID as gameID, Team.ID as teamID, (CASE WHEN game.ID = 5 THEN 0 ELSE 1 END)
FROM Game CROSS JOIN Team;

SELECT * From Project;

-- Employee table
-- Graphics Team
INSERT INTO Employee VALUES(1, 'Nicolas', 'Russel','Programmer', to_date('2001.09.21', 'YYYY.MM.DD'), NULL, 9000,  1);
INSERT INTO Employee VALUES(2, 'Dustin',  'Coney', 'Programmer', to_date('2004.10.20', 'YYYY.MM.DD'), NULL, 7000,  1);
INSERT INTO Employee VALUES(3, 'Mike', 'McGregor', 'Researcher', to_date('2002.01.20', 'YYYY.MM.DD'), NULL, 10000, 1);
-- Physics Team
INSERT INTO Employee VALUES(4, 'John', 'Jones','Researcher', to_date('2004.12.20', 'YYYY.MM.DD'), NULL, 9000, 2);
INSERT INTO Employee VALUES(5, 'Lucas', 'Miller','Programmer', to_date('2014.10.20', 'YYYY.MM.DD'), NULL, 7000, 2);
INSERT INTO Employee VALUES(6, 'Robert', 'Garcia','Consultant', to_date('2009.10.20', 'YYYY.MM.DD'), NULL, 17000, 2);
-- AI Team
INSERT INTO Employee VALUES(7, 'James', 'Davis','Researcher',  to_date('2015.08.20', 'YYYY.MM.DD'), NULL, 10000, 3);
INSERT INTO Employee VALUES(8, 'William', 'Martinez','Programmer', to_date('2010.10.20', 'YYYY.MM.DD'), NULL, 10000, 3);
INSERT INTO Employee VALUES(9, 'Charles', 'Taylor','Researcher', to_date('2003.09.20', 'YYYY.MM.DD'), NULL, 12000, 3);
-- Sound Team
INSERT INTO Employee VALUES(10, 'Mark', 'Lee', 'Sound Engineer', to_date('2014.10.20', 'YYYY.MM.DD'), NULL, 7000, 4);
INSERT INTO Employee VALUES(11, 'George', 'Jackson','Team Lead', to_date('2020.10.21', 'YYYY.MM.DD'), NULL, 8000, 4);
INSERT INTO Employee VALUES(12, 'Samuel', 'Lewis', 'Consultant', to_date('2019.10.22', 'YYYY.MM.DD'), NULL, 9000, 4);
-- UI Team
INSERT INTO Employee VALUES(13, 'Patrick', 'Allen','Programmer', to_date('2004.10.20', 'YYYY.MM.DD'), NULL, 7000, 5);
INSERT INTO Employee VALUES(14, 'Adam', 'Scott','Programmer', to_date('2004.10.20', 'YYYY.MM.DD'), NULL, 6000, 5);
INSERT INTO Employee VALUES(15, 'Henry', 'Carter','QA', to_date('2004.10.20', 'YYYY.MM.DD'), NULL, 8000, 5);


SELECT * FROM Employee;
-- Query tables

set serveroutput on;


CREATE OR REPLACE PROCEDURE listTeamsAndEmployees(game varchar2)
AS
    cursor teamCursor is 
        SELECT t.name AS teamname FROM Team t 
        JOIN Project p ON t.ID = p.teamID 
        JOIN Game g ON p.gameID = g.ID 
        WHERE g.name = game;
    team teamCursor%rowtype;
    
    cursor employeeCursor is SELECT t.name AS teamname, e.firstName as fname, e.lastName  as lname
         FROM Employee e 
         JOIN Team t ON e.teamID = t.ID 
         JOIN Project p ON t.id = p.teamID 
         JOIN Game g ON p.gameID = g.ID
         WHERE g.name = game;
    employee employeeCursor%rowtype;
    
    gameExists NUMBER;
    invalidGame EXCEPTION;
BEGIN
    SELECT Count(*) INTO gameExists FROM Game Where Game.name = game;
    if gameExists = 0 then
        raise invalidGame;
    end if;
    dbms_output.put_line('TEAMS:');
    for team in teamCursor loop
        dbms_output.put_line(team.teamname);
    end loop;
    dbms_output.put_line('TEAM MEMBERS:');
    for employee in employeeCursor loop
        dbms_output.put_line(employee.fname || ' ' || employee.lName || '('  || employee.teamname || ')');
    end loop;

EXCEPTION
    WHEN invalidGame THEN
        dbms_output.put_line('Given game does not exist.');
END;
/

execute listTeamsAndEmployees('Warcraft');
execute listTeamsAndEmployees('Need for Speed');


CREATE OR REPLACE FUNCTION raiseDevSalaryAndGetHighestEarner(teamname varchar2)
RETURN VARCHAR2 AS
    cursor c is SELECT * FROM Employee e JOIN Team t ON e.teamID = t.ID where t.name = teamname for update;
    employee c%rowtype;

    type emp_table is table of Employee.firstName%type;
    e_table emp_table := emp_table();
    max_name varchar2(20);
    max_salary number := -1;
    curr_salary number;
BEGIN
    for employee in c loop
        update Employee set salary = salary * 1.1 where current of c;
    end loop;
    
    SELECT e.firstName
    BULK COLLECT INTO e_table
    FROM Employee e JOIN Team t ON e.teamID = t.ID where t.name = teamname;
    
    for i in 1..e_table.count loop
        SELECT e.salary INTO curr_salary FROM Employee e WHERE e.firstName = e_table(i);
        if curr_salary > max_salary then
            max_salary := curr_salary;
            max_name := e_table(i);
        end if;
    end loop;
    return max_name;
END;
/

declare
    maxName varchar(20);
begin
    maxName := raiseDevSalaryAndGetHighestEarner('AI');
    dbms_output.put_line(maxName);
end;   
/

SELECT * FROM Employee e JOIN Team t ON e.teamID = t.ID where t.name = 'AI';

CREATE OR REPLACE TRIGGER team_count
before insert on Employee
for each row
declare
    t_count number;
    t_id    number;
begin
    t_id := :new.teamID;
    SELECT COUNT(*) INTO t_count FROM Employee e JOIN Team t
    ON e.teamID = t.ID WHERE t.ID = t_id;
    dbms_output.put_line(t_count + 1);
end;
/

INSERT INTO Employee 
VALUES(16, 'Smith', 'Adam','QA', to_date('2022.01.20', 'YYYY.MM.DD'), NULL, 8000, 5);

DELETE FROM Employee WHERE Employee.firstName = 'Smith';

SELECT * FROM Employee WHERE Employee.teamID = 5;