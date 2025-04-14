# DMDD_FinalProject

Crime Rate Management System (CRMS)
A comprehensive database system designed for law enforcement agencies to manage crime data, track investigations, and generate analytical reports.
Table of Contents

System Overview
Project Files
Installation Instructions
Running the Scripts
Business Flow Demonstration
Key Features
Database Schema

System Overview
The Crime Rate Management System (CRMS) provides a centralized database for law enforcement agencies to track crimes, manage investigations, and analyze crime patterns. The system features user authentication, role-based access control, comprehensive audit trails, and advanced analytical reporting capabilities.
Project Files
This project consists of the following key files:

TableCreation1.sql: Database tables, constraints, and initial sample data
TransactionManagement2.sql: Stored procedures, packages, functions, and triggers
AdditionalViews.sql: Advanced analytical reporting views

Installation Instructions
Prerequisites

Oracle Database (11g or higher)
Oracle SQL Developer or another SQL client with Oracle connectivity

Setup Process

Database User Creation (Optional)
If using a new schema/user:
sqlCREATE USER crms_user IDENTIFIED BY password;
GRANT CONNECT, RESOURCE, CREATE VIEW, CREATE PROCEDURE, CREATE SEQUENCE TO crms_user;
ALTER USER crms_user QUOTA UNLIMITED ON USERS;

Connect to Database
Connect to your Oracle database using SQL Developer or another client with the appropriate credentials.

Running the Scripts
Step 1: Create Database Tables and Initial Data

Open TableCreation1.sql in Oracle SQL Developer or your SQL client.
Execute the entire script.
This script will:

Drop any existing tables (with error handling if they don't exist)
Create all required tables with appropriate constraints
Create initial analytical views
Insert sample data for testing


Verify successful execution:
sqlSELECT table_name FROM user_tables;
-- Should show 9 tables: USERS, OFFICER, CATEGORY, CRIME, CRIME_STATUS, VICTIM, CRIMINAL, VICTIM_CRIME, CRIME_CRIMINAL

SELECT view_name FROM user_views WHERE view_name LIKE 'CRIME%' OR view_name LIKE 'CRIMINAL%' OR view_name LIKE 'MONTHLY%';
-- Should show 3 views: CRIME_CATEGORY_STATISTICS, CRIMINAL_ACTIVITY_REPORT, MONTHLY_CRIME_TRENDS


Step 2: Create Transaction Management Components

Open TransactionManagement2.sql in your SQL client.
Execute the entire script.
This script will:

Create sequences for ID generation
Create packages for user, crime, and officer management
Create standalone procedures and functions
Create triggers for audit logging


Verify successful execution:
sqlSELECT object_name, object_type 
FROM user_objects 
WHERE object_type IN ('PACKAGE', 'PACKAGE BODY', 'PROCEDURE', 'FUNCTION', 'TRIGGER');
-- Should list all created procedures, packages, functions, and triggers


Step 3: Create Analytical Views

Open AdditionalViews.sql in your SQL client.
Execute the entire script.
This script will create 7 additional analytical views for comprehensive reporting.
Verify successful execution:
sqlSELECT view_name FROM user_views;
-- Should list all 10 views (3 from step 1 + 7 from this step)


Step 4: Grant Permissions (If Needed)
If multiple users need access to the system, run the following:
sql-- For each user that needs access:
GRANT EXECUTE ON user_mgmt_pkg TO username;
GRANT EXECUTE ON crime_mgmt_pkg TO username;
GRANT EXECUTE ON officer_mgmt_pkg TO username;
GRANT SELECT ON Crime_Category_Statistics TO username;
-- Add additional grants as needed
Business Flow Demonstration
The CRMS implements multiple business flows that model the real-world processes in law enforcement. The following scripts demonstrate the main flows:
1. User Registration and Authentication Flow
sql-- 1.1 Admin creates a new user account
DECLARE
    v_user_id NUMBER;
BEGIN
    user_mgmt_pkg.add_user(
        p_username => 'officer_demo',
        p_password => 'secure_pwd',
        p_firstname => 'Jane',
        p_lastname => 'Smith',
        p_role => 'Officer',  -- Role assigned during creation
        p_email => 'jane.smith@police.com',
        p_mobile_no => '5551234567',
        p_user_id => v_user_id
    );
    DBMS_OUTPUT.PUT_LINE('New user created with ID: ' || v_user_id);
END;
/

-- 1.2 User authentication
DECLARE
    v_user_id NUMBER;
BEGIN
    v_user_id := user_mgmt_pkg.authenticate_user('officer_demo', 'secure_pwd');
    
    IF v_user_id > 0 THEN
        DBMS_OUTPUT.PUT_LINE('Authentication successful. User ID: ' || v_user_id);
        -- System would now retrieve role and grant appropriate access
    ELSE
        DBMS_OUTPUT.PUT_LINE('Authentication failed.');
    END IF;
END;
/

-- 1.3 Admin creates officer profile (professional details)
DECLARE
    v_officer_id NUMBER;
BEGIN
    officer_mgmt_pkg.add_officer(
        p_firstname => 'Jane',
        p_lastname => 'Smith',
        p_dob => TO_DATE('1985-06-12', 'YYYY-MM-DD'),
        p_nationality => 'USA',
        p_email => 'jane.smith@police.com',
        p_created_by => 1, -- Admin user ID
        p_mobile_no => '5551234567',
        p_officer_id => v_officer_id
    );
    DBMS_OUTPUT.PUT_LINE('Officer profile created with ID: ' || v_officer_id);
END;
/
2. Crime Reporting and Initial Processing Flow
sql-- 2.1 Report a new crime
DECLARE
    v_crime_id NUMBER;
BEGIN
    crime_mgmt_pkg.report_crime(
        p_category_id => 1, -- Theft
        p_created_by => 2, -- Officer user ID
        p_crime_desc => 'Laptop stolen from university library',
        p_date_reported => SYSDATE,
        p_officer_id => 2, -- Assigned investigating officer
        p_crime_id => v_crime_id
    );
    DBMS_OUTPUT.PUT_LINE('Crime reported with ID: ' || v_crime_id);
END;
/

-- 2.2 Register a victim
DECLARE
    v_victim_id NUMBER;
BEGIN
    register_victim(
        p_firstname => 'Alex',
        p_lastname => 'Johnson',
        p_dob => TO_DATE('1995-08-20', 'YYYY-MM-DD'),
        p_email => 'alex.johnson@example.com',
        p_mobile_no => '5559876543',
        p_created_by => 2, -- Officer user ID
        p_victim_id => v_victim_id
    );
    DBMS_OUTPUT.PUT_LINE('Victim registered with ID: ' || v_victim_id);
END;
/

-- 2.3 Link victim to crime
BEGIN
    crime_mgmt_pkg.link_victim_to_crime(
        p_victim_id => 6, -- Use actual victim ID from previous step
        p_crime_id => 11  -- Use actual crime ID from previous step
    );
    DBMS_OUTPUT.PUT_LINE('Victim linked to crime successfully');
END;
/
3. Investigation Management Flow
sql-- 3.1 Update case status to investigating
BEGIN
    update_crime_status(
        p_crime_id => 11, -- Use actual crime ID
        p_status => 'Investigating',
        p_updated_by => 2 -- Officer ID
    );
    DBMS_OUTPUT.PUT_LINE('Status updated to Investigating');
END;
/

-- 3.2 Register a suspect
DECLARE
    v_criminal_id NUMBER;
BEGIN
    register_criminal(
        p_firstname => 'John',
        p_lastname => 'Doe',
        p_dob => TO_DATE('1988-03-15', 'YYYY-MM-DD'),
        p_email => 'john.doe@example.com',
        p_mobile_no => '5551112222',
        p_criminal_id => v_criminal_id
    );
    DBMS_OUTPUT.PUT_LINE('Criminal registered with ID: ' || v_criminal_id);
END;
/

-- 3.3 Link suspect to crime
BEGIN
    crime_mgmt_pkg.link_criminal_to_crime(
        p_criminal_id => 6, -- Use actual criminal ID from previous step
        p_crime_id => 11    -- Use actual crime ID
    );
    DBMS_OUTPUT.PUT_LINE('Criminal linked to crime successfully');
END;
/

-- 3.4 Reassign case to different officer
BEGIN
    assign_crime_to_officer(
        p_crime_id => 11, -- Use actual crime ID
        p_officer_id => 3, -- Different officer ID
        p_assigned_by => 1 -- Admin user ID
    );
    DBMS_OUTPUT.PUT_LINE('Case reassigned successfully');
END;
/

-- 3.5 Close the case
BEGIN
    update_crime_status(
        p_crime_id => 11, -- Use actual crime ID
        p_status => 'Closed',
        p_updated_by => 3, -- Officer ID
        p_date_closed => SYSDATE
    );
    DBMS_OUTPUT.PUT_LINE('Case closed successfully');
END;
/
4. Complete End-to-End Transaction
The system also supports handling multi-step operations as a single transaction:
sql-- 4.1 Process complete crime report in one transaction
DECLARE
    v_success BOOLEAN;
BEGIN
    process_complete_crime_report(
        p_category_id => 2, -- Assault
        p_created_by => 2, -- Officer ID
        p_crime_desc => 'Assault at downtown bar',
        p_date_reported => SYSDATE,
        p_officer_id => 2, -- Investigating officer
        p_victim_firstname => 'Mark',
        p_victim_lastname => 'Wilson',
        p_victim_email => 'mark.wilson@example.com',
        p_victim_mobile => '5553334444',
        p_success => v_success
    );
    
    IF v_success THEN
        DBMS_OUTPUT.PUT_LINE('Complete crime report processed successfully');
    ELSE
        DBMS_OUTPUT.PUT_LINE('Failed to process complete crime report');
    END IF;
END;
/
5. Analytical Reporting Queries
sql-- 5.1 View officer performance metrics
SELECT * FROM Officer_Performance_Statistics;

-- 5.2 View high priority cases
SELECT * FROM High_Priority_Cases;

-- 5.3 View detailed crime information
SELECT * FROM Detailed_Crime_Report
WHERE Crime_ID = 11; -- Use actual crime ID

-- 5.4 Analyze case aging patterns
SELECT * FROM Case_Aging_Analysis;

-- 5.5 View criminal history
SELECT * FROM Criminal_History
WHERE Criminal_Name = 'John Doe';

-- 5.6 Monitor user activity
SELECT * FROM User_Activity_Report;
Key Features
User Management

Role-based access control (Admin, Officer, User)
Secure authentication process
User profile management

Crime Management

Comprehensive crime recording
Category classification
Officer assignment
Status tracking

Investigation Tracking

Investigation status workflow
Case assignment and reassignment
Case resolution and closure

Resource Management

Officer caseload tracking
Performance metrics
Workload distribution analysis

Analytical Reporting

Crime trend analysis
Officer performance evaluation
Case prioritization
Aging case identification

Security Features

Role-based access control
Comprehensive audit trails
Data validation
Transaction integrity

Database Schema
The system consists of 9 primary tables:

USERS: Authentication and access control
OFFICER: Law enforcement personnel details
CATEGORY: Crime classification types
CRIME: Core crime incident records
CRIME_STATUS: Investigation status tracking
VICTIM: Victim information
CRIMINAL: Criminal/suspect information
VICTIM_CRIME: Junction table linking victims to crimes
CRIME_CRIMINAL: Junction table linking criminals to crimes

Relationships are established through foreign key constraints to maintain referential integrity.
