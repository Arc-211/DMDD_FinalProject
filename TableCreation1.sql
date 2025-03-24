-- Start with cleanup (dropping existing objects if they exist)
BEGIN
    DBMS_OUTPUT.PUT_LINE('Starting execution of CRMS SQL scripts...');
END;
/

-- Drop tables if they exist
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE VICTIM_CRIME CASCADE CONSTRAINTS';
    EXCEPTION WHEN OTHERS THEN NULL;
END;
/
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE CRIME_CRIMINAL CASCADE CONSTRAINTS';
    EXCEPTION WHEN OTHERS THEN NULL;
END;
/
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE CRIME_STATUS CASCADE CONSTRAINTS';
    EXCEPTION WHEN OTHERS THEN NULL;
END;
/
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE CRIME CASCADE CONSTRAINTS';
    EXCEPTION WHEN OTHERS THEN NULL;
END;
/
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE CATEGORY CASCADE CONSTRAINTS';
    EXCEPTION WHEN OTHERS THEN NULL;
END;
/
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE CRIMINAL CASCADE CONSTRAINTS';
    EXCEPTION WHEN OTHERS THEN NULL;
END;
/
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE OFFICER CASCADE CONSTRAINTS';
    EXCEPTION WHEN OTHERS THEN NULL;
END;
/
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE USERS CASCADE CONSTRAINTS';
    EXCEPTION WHEN OTHERS THEN NULL;
END;
/
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE VICTIM CASCADE CONSTRAINTS';
    EXCEPTION WHEN OTHERS THEN NULL;
END;
/

-- Create Users Table
CREATE TABLE Users (
    User_ID NUMBER PRIMARY KEY,
    Username VARCHAR2(20) NOT NULL,  -- Add Username column if needed
    Password VARCHAR2(20) NOT NULL,
    Firstname VARCHAR2(20) NOT NULL,
    Lastname VARCHAR2(20) NOT NULL,
    Role VARCHAR2(10) NOT NULL,
    Email VARCHAR2(100) NOT NULL UNIQUE,
    Mobile_No VARCHAR2(10) UNIQUE
);
ALTER TABLE Users
ADD CONSTRAINT chk_role CHECK (Role IN ('Admin', 'Officer', 'User'));

-- Create Officer Table
CREATE TABLE Officer (
    Officer_ID NUMBER PRIMARY KEY,
    Firstname VARCHAR2(100) NOT NULL,
    Lastname VARCHAR2(100) NOT NULL,
    Date_of_Birth DATE,
    Nationality VARCHAR2(50),
    Email VARCHAR2(100) UNIQUE,
    Created_by NUMBER,
    Created_at TIMESTAMP,
    Updated_by VARCHAR2(20),
    Updated_at TIMESTAMP,
    Mobile_No VARCHAR2(10) UNIQUE
);
ALTER TABLE Officer
ADD CONSTRAINT fk_created_by FOREIGN KEY (Created_by) REFERENCES Users(User_ID);


-- Create Category Table
CREATE TABLE Category (
    Category_ID NUMBER PRIMARY KEY,
    Category_name VARCHAR2(100) NOT NULL,
    Officer_ID NUMBER
);
ALTER TABLE Category
ADD CONSTRAINT fk_officer FOREIGN KEY (Officer_ID) REFERENCES Officer(Officer_ID);

-- Create Crime Table
CREATE TABLE Crime (
    C_ID NUMBER PRIMARY KEY,
    Category_ID NUMBER,
    Created_by NUMBER,
    Created_at TIMESTAMP,
    Updated_by VARCHAR2(20),
    Updated_at TIMESTAMP,
    Crime_desc VARCHAR2(500),
    Date_reported DATE,
    Officer_ID NUMBER
);
ALTER TABLE Crime
ADD CONSTRAINT fk_category FOREIGN KEY (Category_ID) REFERENCES Category(Category_ID);

ALTER TABLE Crime
ADD CONSTRAINT fk_crime_created_by FOREIGN KEY (Created_by) REFERENCES Users(User_ID);

ALTER TABLE Crime
ADD CONSTRAINT fk_crime_officer FOREIGN KEY (Officer_ID) REFERENCES Officer(Officer_ID);


-- Create Crime_Status Table
CREATE TABLE Crime_Status (
    Status_ID NUMBER PRIMARY KEY,
    C_ID NUMBER,
    Created_by NUMBER,
    Updated_by VARCHAR2(20),
    Crime_Status VARCHAR2(100),
    Date_assigned DATE,
    Date_closed DATE
);
ALTER TABLE Crime_status
ADD CONSTRAINT fk_crime FOREIGN KEY (C_ID) REFERENCES Crime(C_ID);

ALTER TABLE Crime_status
add   CONSTRAINT fk_crime_status_created_by FOREIGN KEY (Created_by) REFERENCES Users(User_ID);

-- Create Victim Table
CREATE TABLE Victim (
    V_ID NUMBER PRIMARY KEY,
    Firstname VARCHAR2(100) NOT NULL,
    Lastname VARCHAR2(100) NOT NULL,
    Date_of_Birth DATE,
    Email VARCHAR2(100) NOT NULL UNIQUE,
    Mobile_No VARCHAR2(10) UNIQUE,
    Created_by NUMBER,
    Created_at TIMESTAMP,
    Updated_by VARCHAR2(20),
    Updated_at TIMESTAMP
);
alter table Victim
ADD CONSTRAINT fk_victim_created_by FOREIGN KEY (Created_by) REFERENCES Users(User_ID);

-- Create Victim_Crime Table (Junction Table between Victim and Crime)
CREATE TABLE Victim_Crime (
    V_ID NUMBER,
    C_ID NUMBER,
    PRIMARY KEY (V_ID, C_ID)
);
ALTER TABLE Victim_Crime
ADD CONSTRAINT fk_victim FOREIGN KEY (V_ID) REFERENCES Victim(V_ID);
ALTER TABLE Victim_Crime
ADD CONSTRAINT fk_victim_Crime_crime FOREIGN KEY (C_ID) REFERENCES Crime(C_ID);
    
-- Create Crime_Criminal Table (Junction Table between Crime and Criminal)
CREATE TABLE Crime_Criminal (
    C_ID NUMBER,
    CR_ID NUMBER,
    PRIMARY KEY (C_ID, CR_ID)
);
ALTER TABLE Crime_Criminal
ADD CONSTRAINT fk_Crime_criminal_crime FOREIGN KEY (C_ID) REFERENCES Crime(C_ID);

-- Create Criminal Table
CREATE TABLE Criminal (
    CR_ID NUMBER PRIMARY KEY,
    Firstname VARCHAR2(100) NOT NULL,
    Lastname VARCHAR2(100) NOT NULL,
    Date_of_Birth DATE,
    Email VARCHAR2(100) NOT NULL UNIQUE,
    Mobile_No VARCHAR2(10) UNIQUE
);


-- Create Views

-- View 1: Crime Category Statistics
CREATE OR REPLACE VIEW Crime_Category_Statistics AS
SELECT 
    cat.Category_ID,
    cat.Category_name,
    COUNT(c.C_ID) AS Total_Crimes,
    COUNT(CASE WHEN cs.Date_closed IS NULL THEN 1 END) AS Open_Cases,
    COUNT(CASE WHEN cs.Date_closed IS NOT NULL THEN 1 END) AS Closed_Cases,
    ROUND(COUNT(CASE WHEN cs.Date_closed IS NOT NULL THEN 1 END) / 
          NULLIF(COUNT(c.C_ID), 0) * 100, 2) AS Closure_Rate
FROM 
    Category cat
LEFT JOIN 
    Crime c ON cat.Category_ID = c.Category_ID
LEFT JOIN 
    Crime_status cs ON c.C_ID = cs.C_ID
GROUP BY 
    cat.Category_ID, cat.Category_name
ORDER BY 
    Total_Crimes DESC;

-- View 2: Criminal Activity Report
CREATE OR REPLACE VIEW Criminal_Activity_Report AS
SELECT 
    cr.CR_ID,
    cr.Firstname || ' ' || cr.Lastname AS Criminal_Name,
    COUNT(cc.C_ID) AS Crime_Count,
    MIN(c.Date_reported) AS First_Crime_Date,
    MAX(c.Date_reported) AS Last_Crime_Date,
    LISTAGG(DISTINCT cat.Category_name, ', ') WITHIN GROUP (ORDER BY cat.Category_name) AS Crime_Categories
FROM 
    Criminal cr
JOIN 
    Crime_Criminal cc ON cr.CR_ID = cc.CR_ID
JOIN 
    Crime c ON cc.C_ID = c.C_ID
JOIN 
    Category cat ON c.Category_ID = cat.Category_ID
GROUP BY 
    cr.CR_ID, cr.Firstname, cr.Lastname
ORDER BY 
    Crime_Count DESC;    


-- View 3: Monthly Crime Trends
CREATE OR REPLACE VIEW Monthly_Crime_Trends AS
SELECT 
    TO_CHAR(c.Date_reported, 'YYYY-MM') AS Month,
    cat.Category_name,
    COUNT(c.C_ID) AS Crime_Count,
    ROUND(AVG(NVL(cs.Date_closed, SYSDATE) - cs.Date_assigned), 2) AS Avg_Days_To_Resolve
FROM 
    Crime c
JOIN 
    Category cat ON c.Category_ID = cat.Category_ID
LEFT JOIN 
    Crime_status cs ON c.C_ID = cs.C_ID
GROUP BY 
    TO_CHAR(c.Date_reported, 'YYYY-MM'), cat.Category_name
ORDER BY 
    Month DESC, Crime_Count DESC;

-- Insert sample data into Users table
INSERT INTO Users (User_ID, Username, Password, Firstname, Lastname, Role, Email, Mobile_No) 
VALUES (1, 'admin', 'adminpass', 'Admin', 'User', 'Admin', 'admin@example.com', '5551234567');
INSERT INTO Users (User_ID, Username, Password, Firstname, Lastname, Role, Email, Mobile_No) 
VALUES (2, 'officer1', 'officerpass', 'John', 'Doe', 'Officer', 'john.doe@example.com', '5552345678');
INSERT INTO Users (User_ID, Username, Password, Firstname, Lastname, Role, Email, Mobile_No) 
VALUES (3, 'user1', 'userpass', 'Jane', 'Smith', 'User', 'jane.smith@example.com', '5553456789');
INSERT INTO Users (User_ID, Username, Password, Firstname, Lastname, Role, Email, Mobile_No) 
VALUES (4, 'officer2', 'officerpass', 'Mark', 'Johnson', 'Officer', 'mark.johnson@example.com', '5554567890');
INSERT INTO Users (User_ID, Username, Password, Firstname, Lastname, Role, Email, Mobile_No) 
VALUES (5, 'user2', 'userpass', 'Emily', 'Davis', 'User', 'emily.davis@example.com', '5555678901');
INSERT INTO Users (User_ID, Username, Password, Firstname, Lastname, Role, Email, Mobile_No) 
VALUES (6, 'admin2', 'adminpass2', 'James', 'Brown', 'Admin', 'james.brown@example.com', '5556789012');
INSERT INTO Users (User_ID, Username, Password, Firstname, Lastname, Role, Email, Mobile_No) 
VALUES (7, 'officer3', 'officerpass3', 'Sarah', 'Wilson', 'Officer', 'sarah.wilson@example.com', '5557890123');
INSERT INTO Users (User_ID, Username, Password, Firstname, Lastname, Role, Email, Mobile_No) 
VALUES (8, 'user3', 'userpass3', 'David', 'Lee', 'User', 'david.lee@example.com', '5558901234');
INSERT INTO Users (User_ID, Username, Password, Firstname, Lastname, Role, Email, Mobile_No) 
VALUES (9, 'officer4', 'officerpass4', 'Sophia', 'Martinez', 'Officer', 'sophia.martinez@example.com', '5559012345');
INSERT INTO Users (User_ID, Username, Password, Firstname, Lastname, Role, Email, Mobile_No) 
VALUES (10, 'user4', 'userpass4', 'Lucas', 'Taylor', 'User', 'lucas.taylor@example.com', '5550123456');

-- Insert sample data into Officer table
INSERT INTO Officer (Officer_ID, Firstname, Lastname, Date_of_Birth, Nationality, Email, Created_by, Created_at, Updated_by, Updated_at, Mobile_No) 
VALUES (1, 'John', 'Doe', TO_DATE('1985-01-15', 'YYYY-MM-DD'), 'USA', 'john.doe@police.com', 2, CURRENT_TIMESTAMP, 'Admin', CURRENT_TIMESTAMP, '5551234567');
INSERT INTO Officer (Officer_ID, Firstname, Lastname, Date_of_Birth, Nationality, Email, Created_by, Created_at, Updated_by, Updated_at, Mobile_No) 
VALUES (2, 'Jane', 'Smith', TO_DATE('1990-03-22', 'YYYY-MM-DD'), 'Canada', 'jane.smith@police.com', 4, CURRENT_TIMESTAMP, 'Admin', CURRENT_TIMESTAMP, '5552345678');
INSERT INTO Officer (Officer_ID, Firstname, Lastname, Date_of_Birth, Nationality, Email, Created_by, Created_at, Updated_by, Updated_at, Mobile_No) 
VALUES (3, 'Mark', 'Johnson', TO_DATE('1987-05-30', 'YYYY-MM-DD'), 'UK', 'mark.johnson@police.com', 6, CURRENT_TIMESTAMP, 'Admin', CURRENT_TIMESTAMP, '5553456789');
INSERT INTO Officer (Officer_ID, Firstname, Lastname, Date_of_Birth, Nationality, Email, Created_by, Created_at, Updated_by, Updated_at, Mobile_No) 
VALUES (4, 'Sophia', 'Martinez', TO_DATE('1982-07-25', 'YYYY-MM-DD'), 'Australia', 'sophia.martinez@police.com', 3, CURRENT_TIMESTAMP, 'Admin', CURRENT_TIMESTAMP, '5554567890');
INSERT INTO Officer (Officer_ID, Firstname, Lastname, Date_of_Birth, Nationality, Email, Created_by, Created_at, Updated_by, Updated_at, Mobile_No) 
VALUES (5, 'Tom', 'Davis', TO_DATE('1989-09-10', 'YYYY-MM-DD'), 'USA', 'tom.davis@police.com', 2, CURRENT_TIMESTAMP, 'Admin', CURRENT_TIMESTAMP, '5555678901');
INSERT INTO Officer (Officer_ID, Firstname, Lastname, Date_of_Birth, Nationality, Email, Created_by, Created_at, Updated_by, Updated_at, Mobile_No) 
VALUES (6, 'Emily', 'Davis', TO_DATE('1992-11-17', 'YYYY-MM-DD'), 'Canada', 'emily.davis@police.com', 4, CURRENT_TIMESTAMP, 'Admin', CURRENT_TIMESTAMP, '5556789012');
INSERT INTO Officer (Officer_ID, Firstname, Lastname, Date_of_Birth, Nationality, Email, Created_by, Created_at, Updated_by, Updated_at, Mobile_No) 
VALUES (7, 'Lucas', 'Taylor', TO_DATE('1983-12-20', 'YYYY-MM-DD'), 'USA', 'lucas.taylor@police.com', 6, CURRENT_TIMESTAMP, 'Admin', CURRENT_TIMESTAMP, '5557890123');
INSERT INTO Officer (Officer_ID, Firstname, Lastname, Date_of_Birth, Nationality, Email, Created_by, Created_at, Updated_by, Updated_at, Mobile_No) 
VALUES (8, 'Sophia', 'Wilson', TO_DATE('1990-04-12', 'YYYY-MM-DD'), 'UK', 'sophia.wilson@police.com', 3, CURRENT_TIMESTAMP, 'Admin', CURRENT_TIMESTAMP, '5558901234');
INSERT INTO Officer (Officer_ID, Firstname, Lastname, Date_of_Birth, Nationality, Email, Created_by, Created_at, Updated_by, Updated_at, Mobile_No) 
VALUES (9, 'David', 'Lee', TO_DATE('1991-06-15', 'YYYY-MM-DD'), 'Canada', 'david.lee@police.com', 4, CURRENT_TIMESTAMP, 'Admin', CURRENT_TIMESTAMP, '5559012345');
INSERT INTO Officer (Officer_ID, Firstname, Lastname, Date_of_Birth, Nationality, Email, Created_by, Created_at, Updated_by, Updated_at, Mobile_No) 
VALUES (10, 'Shreya', 'Kini', TO_DATE('1994-08-10', 'YYYY-MM-DD'), 'USA', 'shreya.kini@police.com', 6, CURRENT_TIMESTAMP, 'Admin', CURRENT_TIMESTAMP, '5550123456');

-- Insert sample data into Category table
INSERT INTO Category (Category_ID, Category_name, Officer_ID) 
VALUES (1, 'Theft', 1);
INSERT INTO Category (Category_ID, Category_name, Officer_ID) 
VALUES (2, 'Assault', 2);
INSERT INTO Category (Category_ID, Category_name, Officer_ID) 
VALUES (3, 'Fraud', 3);
INSERT INTO Category (Category_ID, Category_name, Officer_ID) 
VALUES (4, 'Vandalism', 4);
INSERT INTO Category (Category_ID, Category_name, Officer_ID) 
VALUES (5, 'Murder', 5);
INSERT INTO Category (Category_ID, Category_name, Officer_ID) 
VALUES (6, 'Robbery', 6);
INSERT INTO Category (Category_ID, Category_name, Officer_ID) 
VALUES (7, 'Burglary', 7);
INSERT INTO Category (Category_ID, Category_name, Officer_ID) 
VALUES (8, 'Domestic Violence', 8);
INSERT INTO Category (Category_ID, Category_name, Officer_ID) 
VALUES (9, 'Drug Offense', 9);
INSERT INTO Category (Category_ID, Category_name, Officer_ID) 
VALUES (10, 'Shoplifting', 10);

-- Insert sample data into Crime table
INSERT INTO Crime (C_ID, Category_ID, Created_by, Created_at, Updated_by, Updated_at, Crime_desc, Date_reported, Officer_ID) 
VALUES (1, 1, 1, CURRENT_TIMESTAMP, NULL, NULL, 'Stolen car from parking lot', TO_DATE('2023-03-01', 'YYYY-MM-DD'), 1);
INSERT INTO Crime (C_ID, Category_ID, Created_by, Created_at, Updated_by, Updated_at, Crime_desc, Date_reported, Officer_ID) 
VALUES (2, 2, 2, CURRENT_TIMESTAMP, NULL, NULL, 'Physical assault in park', TO_DATE('2023-03-05', 'YYYY-MM-DD'), 2);
INSERT INTO Crime (C_ID, Category_ID, Created_by, Created_at, Updated_by, Updated_at, Crime_desc, Date_reported, Officer_ID) 
VALUES (3, 3, 3, CURRENT_TIMESTAMP, NULL, NULL, 'Fraudulent investment scheme', TO_DATE('2023-03-07', 'YYYY-MM-DD'), 3);
INSERT INTO Crime (C_ID, Category_ID, Created_by, Created_at, Updated_by, Updated_at, Crime_desc, Date_reported, Officer_ID) 
VALUES (4, 4, 4, CURRENT_TIMESTAMP, NULL, NULL, 'Vandalism of public property', TO_DATE('2023-03-10', 'YYYY-MM-DD'), 4);
INSERT INTO Crime (C_ID, Category_ID, Created_by, Created_at, Updated_by, Updated_at, Crime_desc, Date_reported, Officer_ID) 
VALUES (5, 5, 5, CURRENT_TIMESTAMP, NULL, NULL, 'Murder of business executive', TO_DATE('2023-03-15', 'YYYY-MM-DD'), 5);
INSERT INTO Crime (C_ID, Category_ID, Created_by, Created_at, Updated_by, Updated_at, Crime_desc, Date_reported, Officer_ID) 
VALUES (6, 6, 6, CURRENT_TIMESTAMP, NULL, NULL, 'Robbery at local bank', TO_DATE('2023-03-20', 'YYYY-MM-DD'), 6);
INSERT INTO Crime (C_ID, Category_ID, Created_by, Created_at, Updated_by, Updated_at, Crime_desc, Date_reported, Officer_ID) 
VALUES (7, 7, 7, CURRENT_TIMESTAMP, NULL, NULL, 'Burglary at residential home', TO_DATE('2023-03-25', 'YYYY-MM-DD'), 7);
INSERT INTO Crime (C_ID, Category_ID, Created_by, Created_at, Updated_by, Updated_at, Crime_desc, Date_reported, Officer_ID) 
VALUES (8, 8, 8, CURRENT_TIMESTAMP, NULL, NULL, 'Domestic violence dispute', TO_DATE('2023-03-30', 'YYYY-MM-DD'), 8);
INSERT INTO Crime (C_ID, Category_ID, Created_by, Created_at, Updated_by, Updated_at, Crime_desc, Date_reported, Officer_ID) 
VALUES (9, 9, 9, CURRENT_TIMESTAMP, NULL, NULL, 'Drug trafficking ring', TO_DATE('2023-04-01', 'YYYY-MM-DD'), 9);
INSERT INTO Crime (C_ID, Category_ID, Created_by, Created_at, Updated_by, Updated_at, Crime_desc, Date_reported, Officer_ID) 
VALUES (10, 10, 10, CURRENT_TIMESTAMP, NULL, NULL, 'Shoplifting incident at mall', TO_DATE('2023-04-05', 'YYYY-MM-DD'), 10);

-- Insert sample data into Crime_Status table
INSERT INTO Crime_Status (Status_ID, C_ID, Created_by, Updated_by, Crime_Status, Date_assigned, Date_closed)
VALUES (1, 1, 1, NULL, 'Investigating', TO_DATE('2023-03-01', 'YYYY-MM-DD'), NULL);
INSERT INTO Crime_Status (Status_ID, C_ID, Created_by, Updated_by, Crime_Status, Date_assigned, Date_closed)
VALUES (2, 2, 2, NULL, 'Closed', TO_DATE('2023-03-05', 'YYYY-MM-DD'), TO_DATE('2023-03-07', 'YYYY-MM-DD'));
INSERT INTO Crime_Status (Status_ID, C_ID, Created_by, Updated_by, Crime_Status, Date_assigned, Date_closed)
VALUES (3, 3, 3, NULL, 'Investigating', TO_DATE('2023-03-07', 'YYYY-MM-DD'), NULL);
INSERT INTO Crime_Status (Status_ID, C_ID, Created_by, Updated_by, Crime_Status, Date_assigned, Date_closed)
VALUES (4, 4, 4, NULL, 'Closed', TO_DATE('2023-03-10', 'YYYY-MM-DD'), TO_DATE('2023-03-12', 'YYYY-MM-DD'));
INSERT INTO Crime_Status (Status_ID, C_ID, Created_by, Updated_by, Crime_Status, Date_assigned, Date_closed)
VALUES (5, 5, 5, NULL, 'Investigating', TO_DATE('2023-03-15', 'YYYY-MM-DD'), NULL);


