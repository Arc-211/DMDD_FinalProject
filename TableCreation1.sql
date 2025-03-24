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