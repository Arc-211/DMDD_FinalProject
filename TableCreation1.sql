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
