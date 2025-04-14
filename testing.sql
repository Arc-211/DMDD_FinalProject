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