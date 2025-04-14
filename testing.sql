-- Enable server output to see messages
SET SERVEROUTPUT ON;

-- ===============================
-- 1. USER MANAGEMENT TESTING
-- ===============================

-- Create a new test user
DECLARE
    v_user_id NUMBER;
BEGIN
    user_mgmt_pkg.add_user(
        p_username => 'test_officer99',
        p_password => 'test123',
        p_firstname => 'Test',
        p_lastname => 'Officer',
        p_role => 'Officer',
        p_email => 'test.officer99@example.com',
        p_mobile_no => '5559999999',
        p_user_id => v_user_id
    );
    DBMS_OUTPUT.PUT_LINE('New user created with ID: ' || v_user_id);
END;
/

-- Verify user creation
SELECT User_ID, Username, Firstname, Lastname, Role, Email 
FROM Users 
WHERE Username = 'test_officer99';

-- Test authentication
DECLARE
    v_result NUMBER;
BEGIN
    v_result := user_mgmt_pkg.authenticate_user('test_officer99', 'test123');
    
    DBMS_OUTPUT.PUT_LINE('----------------------------------------');
    DBMS_OUTPUT.PUT_LINE('AUTHENTICATION TEST');
    DBMS_OUTPUT.PUT_LINE('----------------------------------------');
    IF v_result > 0 THEN
        DBMS_OUTPUT.PUT_LINE('RESULT: SUCCESS ✓');
        DBMS_OUTPUT.PUT_LINE('Authenticated User ID: ' || v_result);
    ELSE
        DBMS_OUTPUT.PUT_LINE('RESULT: FAILED ✗');
        DBMS_OUTPUT.PUT_LINE('Invalid credentials.');
    END IF;
    DBMS_OUTPUT.PUT_LINE('----------------------------------------');
END;
/

-- Update user information
DECLARE
    v_user_id NUMBER;
BEGIN
    -- Get the user ID first
    SELECT User_ID INTO v_user_id
    FROM Users 
    WHERE Username = 'test_officer99';
    
    user_mgmt_pkg.update_user(
        p_user_id => v_user_id,
        p_username => 'test_officer99',
        p_firstname => 'Test',
        p_lastname => 'Officer Updated',
        p_role => 'Officer',
        p_email => 'test.officer99@example.com',
        p_mobile_no => '5559999999'
    );
    DBMS_OUTPUT.PUT_LINE('User updated successfully');
END;
/

-- Verify user update
SELECT User_ID, Username, Firstname, Lastname, Role, Email 
FROM Users 
WHERE Username = 'test_officer99';

-- ===============================
-- 2. OFFICER MANAGEMENT TESTING
-- ===============================

-- Create an officer
DECLARE
    v_officer_id NUMBER;
    v_admin_id NUMBER := 1; -- Assuming admin user ID is 1
BEGIN
    officer_mgmt_pkg.add_officer(
        p_firstname => 'Test',
        p_lastname => 'Officer',
        p_dob => TO_DATE('1990-01-15', 'YYYY-MM-DD'),
        p_nationality => 'USA',
        p_email => 'test.officer99@example.com',
        p_created_by => v_admin_id,
        p_mobile_no => '5559999999',
        p_officer_id => v_officer_id
    );
    DBMS_OUTPUT.PUT_LINE('New officer created with ID: ' || v_officer_id);
END;
/

-- Verify officer creation
SELECT Officer_ID, Firstname, Lastname, Nationality, Email, Created_by
FROM Officer 
WHERE Email = 'test.officer99@example.com';

-- Update officer information
DECLARE
    v_officer_id NUMBER;
BEGIN
    -- Get the officer ID first
    SELECT Officer_ID INTO v_officer_id
    FROM Officer 
    WHERE Email = 'test.officer99@example.com';
    
    officer_mgmt_pkg.update_officer(
        p_officer_id => v_officer_id,
        p_firstname => 'Test',
        p_lastname => 'Officer',
        p_dob => TO_DATE('1990-01-15', 'YYYY-MM-DD'),
        p_nationality => 'Canada', -- Changed from USA
        p_email => 'test.officer99@example.com',
        p_updated_by => 'Admin',
        p_mobile_no => '5559999999'
    );
    DBMS_OUTPUT.PUT_LINE('Officer updated successfully');
END;
/

-- Verify officer update
SELECT Officer_ID, Firstname, Lastname, Nationality, Email, Updated_by
FROM Officer 
WHERE Email = 'test.officer99@example.com';

-- ===============================
-- 3. CRIME CATEGORY MANAGEMENT
-- ===============================

-- Add a new crime category
DECLARE
    v_category_id NUMBER;
    v_officer_id NUMBER;
BEGIN
    -- Get the officer ID first
    SELECT Officer_ID INTO v_officer_id
    FROM Officer 
    WHERE Email = 'test.officer99@example.com';
    
    crime_mgmt_pkg.add_category(
        p_category_name => 'Cybercrime99',
        p_officer_id => v_officer_id,
        p_category_id => v_category_id
    );
    DBMS_OUTPUT.PUT_LINE('New category created with ID: ' || v_category_id);
END;
/

-- Verify category creation
SELECT Category_ID, Category_name, Officer_ID 
FROM Category 
WHERE Category_name = 'Cybercrime99';

-- ===============================
-- 4. CRIME REPORTING TESTING
-- ===============================

-- Report a new crime
DECLARE
    v_crime_id NUMBER;
    v_category_id NUMBER;
    v_user_id NUMBER;
    v_officer_id NUMBER;
BEGIN
    -- Get the necessary IDs first
    SELECT Category_ID INTO v_category_id
    FROM Category 
    WHERE Category_name = 'Cybercrime99';
    
    SELECT User_ID INTO v_user_id
    FROM Users 
    WHERE Username = 'test_officer99';
    
    SELECT Officer_ID INTO v_officer_id
    FROM Officer 
    WHERE Email = 'test.officer99@example.com';
    
    crime_mgmt_pkg.report_crime(
        p_category_id => v_category_id,
        p_created_by => v_user_id,
        p_crime_desc => 'Credit card data stolen through phishing website',
        p_date_reported => SYSDATE,
        p_officer_id => v_officer_id,
        p_crime_id => v_crime_id
    );
    DBMS_OUTPUT.PUT_LINE('New crime reported with ID: ' || v_crime_id);
END;
/

-- Verify crime creation
SELECT c.C_ID, c.Crime_desc, TO_CHAR(c.Date_reported, 'YYYY-MM-DD') AS Date_Reported, 
       cat.Category_name, o.Firstname || ' ' || o.Lastname AS Officer_Name
FROM Crime c
JOIN Category cat ON c.Category_ID = cat.Category_ID
JOIN Officer o ON c.Officer_ID = o.Officer_ID
WHERE cat.Category_name = 'Cybercrime99';

-- Check crime status
SELECT cs.C_ID, cs.Crime_Status, TO_CHAR(cs.Date_assigned, 'YYYY-MM-DD') AS Date_Assigned
FROM Crime_Status cs
JOIN Crime c ON cs.C_ID = c.C_ID
JOIN Category cat ON c.Category_ID = cat.Category_ID
WHERE cat.Category_name = 'Cybercrime99';

-- ===============================
-- 5. VICTIM MANAGEMENT TESTING
-- ===============================

-- Register a victim
DECLARE
    v_victim_id NUMBER;
    v_user_id NUMBER;
BEGIN
    -- Get the user ID first
    SELECT User_ID INTO v_user_id
    FROM Users 
    WHERE Username = 'test_officer99';
    
    register_victim(
        p_firstname => 'John',
        p_lastname => 'Victim99',
        p_dob => TO_DATE('1980-11-20', 'YYYY-MM-DD'),
        p_email => 'john.victim99@example.com',
        p_mobile_no => '5558889999',
        p_created_by => v_user_id,
        p_victim_id => v_victim_id
    );
    DBMS_OUTPUT.PUT_LINE('New victim registered with ID: ' || v_victim_id);
END;
/

-- Verify victim creation
SELECT V_ID, Firstname, Lastname, Email, Mobile_No
FROM Victim
WHERE Email = 'john.victim99@example.com';

-- Link victim to crime
DECLARE
    v_crime_id NUMBER;
    v_victim_id NUMBER;
BEGIN
    -- Get the cybercrime ID
    SELECT c.C_ID INTO v_crime_id
    FROM Crime c
    JOIN Category cat ON c.Category_ID = cat.Category_ID
    WHERE cat.Category_name = 'Cybercrime99'
    AND ROWNUM = 1;
    
    -- Get the victim ID
    SELECT V_ID INTO v_victim_id
    FROM Victim
    WHERE Email = 'john.victim99@example.com';
    
    crime_mgmt_pkg.link_victim_to_crime(
        p_victim_id => v_victim_id,
        p_crime_id => v_crime_id
    );
    DBMS_OUTPUT.PUT_LINE('Victim linked to crime ID: ' || v_crime_id);
END;
/

-- Verify victim-crime relationship
SELECT v.V_ID, v.Firstname || ' ' || v.Lastname AS Victim_Name, 
       c.C_ID, c.Crime_desc, cat.Category_name
FROM Victim v
JOIN Victim_Crime vc ON v.V_ID = vc.V_ID
JOIN Crime c ON vc.C_ID = c.C_ID
JOIN Category cat ON c.Category_ID = cat.Category_ID
WHERE v.Email = 'john.victim99@example.com';

-- ===============================
-- 6. CRIMINAL MANAGEMENT TESTING
-- ===============================

-- Register a criminal
DECLARE
    v_criminal_id NUMBER;
BEGIN
    register_criminal(
        p_firstname => 'James',
        p_lastname => 'Criminal99',
        p_dob => TO_DATE('1992-06-15', 'YYYY-MM-DD'),
        p_email => 'james.criminal99@example.com',
        p_mobile_no => '5557779999',
        p_criminal_id => v_criminal_id
    );
    DBMS_OUTPUT.PUT_LINE('New criminal registered with ID: ' || v_criminal_id);
END;
/

-- Verify criminal creation
SELECT CR_ID, Firstname, Lastname, Email, Mobile_No
FROM Criminal
WHERE Email = 'james.criminal99@example.com';

-- Link criminal to crime
DECLARE
    v_crime_id NUMBER;
    v_criminal_id NUMBER;
BEGIN
    -- Get the cybercrime ID
    SELECT c.C_ID INTO v_crime_id
    FROM Crime c
    JOIN Category cat ON c.Category_ID = cat.Category_ID
    WHERE cat.Category_name = 'Cybercrime99'
    AND ROWNUM = 1;
    
    -- Get the criminal ID
    SELECT CR_ID INTO v_criminal_id
    FROM Criminal
    WHERE Email = 'james.criminal99@example.com';
    
    crime_mgmt_pkg.link_criminal_to_crime(
        p_criminal_id => v_criminal_id,
        p_crime_id => v_crime_id
    );
    DBMS_OUTPUT.PUT_LINE('Criminal linked to crime ID: ' || v_crime_id);
END;
/

-- Verify criminal-crime relationship
SELECT cr.CR_ID, cr.Firstname || ' ' || cr.Lastname AS Criminal_Name, 
       c.C_ID, c.Crime_desc, cat.Category_name
FROM Criminal cr
JOIN Crime_Criminal cc ON cr.CR_ID = cc.CR_ID
JOIN Crime c ON cc.C_ID = c.C_ID
JOIN Category cat ON c.Category_ID = cat.Category_ID
WHERE cr.Email = 'james.criminal99@example.com';

-- ===============================
-- 7. CASE MANAGEMENT TESTING
-- ===============================

-- Update crime status
DECLARE
    v_crime_id NUMBER;
    v_user_id NUMBER;
BEGIN
    -- Get the cybercrime ID
    SELECT c.C_ID INTO v_crime_id
    FROM Crime c
    JOIN Category cat ON c.Category_ID = cat.Category_ID
    WHERE cat.Category_name = 'Cybercrime99'
    AND ROWNUM = 1;
    
    -- Get the user ID
    SELECT User_ID INTO v_user_id
    FROM Users 
    WHERE Username = 'test_officer99';
    
    update_crime_status(
        p_crime_id => v_crime_id,
        p_status => 'Investigating',
        p_updated_by => v_user_id
    );
    DBMS_OUTPUT.PUT_LINE('Crime status updated to Investigating');
END;
/

-- Verify status update
SELECT c.C_ID, c.Crime_desc, cs.Crime_Status, 
       TO_CHAR(cs.Date_assigned, 'YYYY-MM-DD') AS Date_Assigned, 
       TO_CHAR(cs.Date_closed, 'YYYY-MM-DD') AS Date_Closed
FROM Crime c
JOIN Crime_Status cs ON c.C_ID = cs.C_ID
JOIN Category cat ON c.Category_ID = cat.Category_ID
WHERE cat.Category_name = 'Cybercrime99';

-- Reassign the case to another officer
DECLARE
    v_crime_id NUMBER;
    v_officer_id NUMBER := 2; -- Assuming officer ID 2 exists
    v_admin_id NUMBER := 1;   -- Assuming admin user ID is 1
BEGIN
    -- Get the cybercrime ID
    SELECT c.C_ID INTO v_crime_id
    FROM Crime c
    JOIN Category cat ON c.Category_ID = cat.Category_ID
    WHERE cat.Category_name = 'Cybercrime99'
    AND ROWNUM = 1;
    
    assign_crime_to_officer(
        p_crime_id => v_crime_id,
        p_officer_id => v_officer_id,
        p_assigned_by => v_admin_id
    );
    DBMS_OUTPUT.PUT_LINE('Crime reassigned to officer ID: ' || v_officer_id);
END;
/

-- Verify reassignment
SELECT c.C_ID, c.Crime_desc, o.Firstname || ' ' || o.Lastname AS Assigned_Officer,
       cs.Crime_Status, TO_CHAR(cs.Date_assigned, 'YYYY-MM-DD') AS Date_Assigned
FROM Crime c
JOIN Officer o ON c.Officer_ID = o.Officer_ID
JOIN Crime_Status cs ON c.C_ID = cs.C_ID
JOIN Category cat ON c.Category_ID = cat.Category_ID
WHERE cat.Category_name = 'Cybercrime99';

-- Close the case
DECLARE
    v_crime_id NUMBER;
    v_officer_id NUMBER := 2; -- Same officer who was assigned
BEGIN
    -- Get the cybercrime ID
    SELECT c.C_ID INTO v_crime_id
    FROM Crime c
    JOIN Category cat ON c.Category_ID = cat.Category_ID
    WHERE cat.Category_name = 'Cybercrime99'
    AND ROWNUM = 1;
    
    update_crime_status(
        p_crime_id => v_crime_id,
        p_status => 'Closed',
        p_updated_by => v_officer_id,
        p_date_closed => SYSDATE
    );
    DBMS_OUTPUT.PUT_LINE('Crime closed successfully');
END;
/

-- Verify case closure
SELECT c.C_ID, c.Crime_desc, cs.Crime_Status, 
       TO_CHAR(cs.Date_assigned, 'YYYY-MM-DD') AS Date_Assigned, 
       TO_CHAR(cs.Date_closed, 'YYYY-MM-DD') AS Date_Closed,
       TRUNC(cs.Date_closed - cs.Date_assigned) AS Days_To_Resolve
FROM Crime c
JOIN Crime_Status cs ON c.C_ID = cs.C_ID
JOIN Category cat ON c.Category_ID = cat.Category_ID
WHERE cat.Category_name = 'Cybercrime99';

-- ===============================
-- 8. ANALYTICAL REPORTS TESTING
-- ===============================

-- Officer Performance Statistics
SELECT * FROM Officer_Performance_Statistics 
WHERE ROWNUM <= 5;

-- Crime Category Statistics
SELECT * FROM Crime_Category_Statistics
WHERE ROWNUM <= 5;

-- Detailed Crime Report
SELECT Crime_ID, Crime_Category, Description, Status, 
       Assigned_Officer, Victim_Count, Criminal_Count
FROM Detailed_Crime_Report 
WHERE Crime_Category = 'Cybercrime99';

-- High Priority Cases
SELECT Crime_ID, Crime_Category, Description, Status, Days_Open, Priority
FROM High_Priority_Cases
WHERE ROWNUM <= 5;

-- Criminal History
SELECT * FROM Criminal_History 
WHERE Criminal_Name LIKE '%Criminal99%';

-- Case Aging Analysis
SELECT * FROM Case_Aging_Analysis
WHERE ROWNUM <= 5;

-- User Activity Report
SELECT * FROM User_Activity_Report
WHERE Username = 'test_officer99';

-- ===============================
-- 9. ADVANCED FUNCTIONS TESTING
-- ===============================

-- Officer caseload function
SELECT 
    o.Officer_ID,
    o.Firstname || ' ' || o.Lastname AS Officer_Name,
    get_officer_caseload(o.Officer_ID) AS Current_Caseload
FROM Officer o
ORDER BY Current_Caseload DESC;

-- Crime status function
SELECT 
    c.C_ID, 
    c.Crime_desc,
    get_crime_status(c.C_ID) AS Current_Status
FROM Crime c
WHERE ROWNUM <= 5;