-- ExceptionTests.sql
-- This file contains test cases to demonstrate exception handling in the CRMS system

SET SERVEROUTPUT ON;

-- ===============================================================
-- TEST CASE 1: Exception handling for duplicate user information
-- ===============================================================
DECLARE
    v_user_id NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=======================================================');
    DBMS_OUTPUT.PUT_LINE('TEST CASE 1: Exception handling for duplicate user info');
    DBMS_OUTPUT.PUT_LINE('=======================================================');
    
    -- First create a test user
    BEGIN
        user_mgmt_pkg.add_user(
            p_username => 'exception_test1',
            p_password => 'test123',
            p_firstname => 'Exception',
            p_lastname => 'Test',
            p_role => 'Officer',
            p_email => 'exception.test1@example.com',
            p_mobile_no => '5551110001',
            p_user_id => v_user_id
        );
        DBMS_OUTPUT.PUT_LINE('Successfully created first test user with ID: ' || v_user_id);
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Error creating first test user: ' || SQLERRM);
    END;
    
    -- Try to create another user with the same username
    BEGIN
        DBMS_OUTPUT.PUT_LINE('Attempting to create user with duplicate username...');
        user_mgmt_pkg.add_user(
            p_username => 'exception_test1', -- Duplicate username
            p_password => 'test456',
            p_firstname => 'Another',
            p_lastname => 'User',
            p_role => 'Officer',
            p_email => 'another.user@example.com',
            p_mobile_no => '5551110002',
            p_user_id => v_user_id
        );
        DBMS_OUTPUT.PUT_LINE('ERROR: Created user with duplicate username - exception handling failed!');
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('EXPECTED EXCEPTION CAUGHT: ' || SQLERRM);
            DBMS_OUTPUT.PUT_LINE('Exception handling for duplicate username works correctly');
    END;
    
    -- Try to create another user with the same email
    BEGIN
        DBMS_OUTPUT.PUT_LINE('Attempting to create user with duplicate email...');
        user_mgmt_pkg.add_user(
            p_username => 'exception_test2',
            p_password => 'test456',
            p_firstname => 'Another',
            p_lastname => 'User',
            p_role => 'Officer',
            p_email => 'exception.test1@example.com', -- Duplicate email
            p_mobile_no => '5551110003',
            p_user_id => v_user_id
        );
        DBMS_OUTPUT.PUT_LINE('ERROR: Created user with duplicate email - exception handling failed!');
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('EXPECTED EXCEPTION CAUGHT: ' || SQLERRM);
            DBMS_OUTPUT.PUT_LINE('Exception handling for duplicate email works correctly');
    END;
    
    -- Try to create another user with the same mobile number
    BEGIN
        DBMS_OUTPUT.PUT_LINE('Attempting to create user with duplicate mobile number...');
        user_mgmt_pkg.add_user(
            p_username => 'exception_test3',
            p_password => 'test456',
            p_firstname => 'Another',
            p_lastname => 'User',
            p_role => 'Officer',
            p_email => 'another.user3@example.com',
            p_mobile_no => '5551110001', -- Duplicate mobile
            p_user_id => v_user_id
        );
        DBMS_OUTPUT.PUT_LINE('ERROR: Created user with duplicate mobile - exception handling failed!');
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('EXPECTED EXCEPTION CAUGHT: ' || SQLERRM);
            DBMS_OUTPUT.PUT_LINE('Exception handling for duplicate mobile works correctly');
    END;
END;
/

-- ===============================================================
-- TEST CASE 2: Exception handling for invalid role assignment
-- ===============================================================
DECLARE
    v_user_id NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=======================================================');
    DBMS_OUTPUT.PUT_LINE('TEST CASE 2: Exception handling for invalid user role');
    DBMS_OUTPUT.PUT_LINE('=======================================================');
    
    -- Try to create a user with an invalid role
    BEGIN
        DBMS_OUTPUT.PUT_LINE('Attempting to create user with invalid role...');
        user_mgmt_pkg.add_user(
            p_username => 'invalid_role_test',
            p_password => 'test123',
            p_firstname => 'Invalid',
            p_lastname => 'Role',
            p_role => 'SuperAdmin', -- Invalid role
            p_email => 'invalid.role@example.com',
            p_mobile_no => '5551110099',
            p_user_id => v_user_id
        );
        DBMS_OUTPUT.PUT_LINE('ERROR: Created user with invalid role - constraint check failed!');
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('EXPECTED EXCEPTION CAUGHT: ' || SQLERRM);
            DBMS_OUTPUT.PUT_LINE('Constraint check for valid roles works correctly');
    END;
END;
/

-- ===============================================================
-- TEST CASE 3: Exception handling for invalid IDs in procedures
-- ===============================================================
DECLARE
    v_non_existent_id NUMBER := 9999; -- Assuming this ID doesn't exist
BEGIN
    DBMS_OUTPUT.PUT_LINE('=======================================================');
    DBMS_OUTPUT.PUT_LINE('TEST CASE 3: Exception handling for invalid IDs');
    DBMS_OUTPUT.PUT_LINE('=======================================================');
    
    -- Try to update a non-existent user
    BEGIN
        DBMS_OUTPUT.PUT_LINE('Attempting to update non-existent user...');
        user_mgmt_pkg.update_user(
            p_user_id => v_non_existent_id,
            p_username => 'ghost_user',
            p_firstname => 'Ghost',
            p_lastname => 'User',
            p_role => 'User',
            p_email => 'ghost.user@example.com',
            p_mobile_no => '5551119999'
        );
        DBMS_OUTPUT.PUT_LINE('ERROR: Updated non-existent user - exception handling failed!');
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('EXPECTED EXCEPTION CAUGHT: ' || SQLERRM);
            DBMS_OUTPUT.PUT_LINE('Exception handling for invalid user ID works correctly');
    END;
    
    -- Try to link a victim to a non-existent crime
    BEGIN
        DBMS_OUTPUT.PUT_LINE('Attempting to link victim to non-existent crime...');
        crime_mgmt_pkg.link_victim_to_crime(
            p_victim_id => 1, -- Assuming this is a valid victim ID
            p_crime_id => v_non_existent_id
        );
        DBMS_OUTPUT.PUT_LINE('ERROR: Linked victim to non-existent crime - exception handling failed!');
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('EXPECTED EXCEPTION CAUGHT: ' || SQLERRM);
            DBMS_OUTPUT.PUT_LINE('Exception handling for invalid crime ID works correctly');
    END;
    
    -- Try to update status of a non-existent crime
    BEGIN
        DBMS_OUTPUT.PUT_LINE('Attempting to update status of non-existent crime...');
        update_crime_status(
            p_crime_id => v_non_existent_id,
            p_status => 'Closed',
            p_updated_by => 1
        );
        DBMS_OUTPUT.PUT_LINE('ERROR: Updated non-existent crime - exception handling failed!');
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('EXPECTED EXCEPTION CAUGHT: ' || SQLERRM);
            DBMS_OUTPUT.PUT_LINE('Exception handling for invalid crime ID works correctly');
    END;
END;
/

-- ===============================================================
-- TEST CASE 4: Authentication failure handling
-- ===============================================================
DECLARE
    v_result NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=======================================================');
    DBMS_OUTPUT.PUT_LINE('TEST CASE 4: Authentication failure handling');
    DBMS_OUTPUT.PUT_LINE('=======================================================');
    
    -- Test with invalid username
    DBMS_OUTPUT.PUT_LINE('Testing authentication with invalid username...');
    v_result := user_mgmt_pkg.authenticate_user('non_existent_user', 'password123');
    
    IF v_result = -1 THEN
        DBMS_OUTPUT.PUT_LINE('CORRECT BEHAVIOR: Authentication correctly failed with invalid username');
    ELSE
        DBMS_OUTPUT.PUT_LINE('ERROR: Authentication did not fail as expected');
    END IF;
    
    -- Create a test user for password testing
    DECLARE
        v_user_id NUMBER;
    BEGIN
        user_mgmt_pkg.add_user(
            p_username => 'auth_test_user',
            p_password => 'correct_password',
            p_firstname => 'Auth',
            p_lastname => 'Test',
            p_role => 'User',
            p_email => 'auth.test@example.com',
            p_mobile_no => '5552223333',
            p_user_id => v_user_id
        );
        DBMS_OUTPUT.PUT_LINE('Created test user for authentication testing');
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Note: Test user may already exist');
    END;
    
    -- Test with valid username but wrong password
    DBMS_OUTPUT.PUT_LINE('Testing authentication with valid username but wrong password...');
    v_result := user_mgmt_pkg.authenticate_user('auth_test_user', 'wrong_password');
    
    IF v_result = -1 THEN
        DBMS_OUTPUT.PUT_LINE('CORRECT BEHAVIOR: Authentication correctly failed with wrong password');
    ELSE
        DBMS_OUTPUT.PUT_LINE('ERROR: Authentication did not fail as expected');
    END IF;
    
    -- Test with valid username and password
    DBMS_OUTPUT.PUT_LINE('Testing authentication with valid username and password...');
    v_result := user_mgmt_pkg.authenticate_user('auth_test_user', 'correct_password');
    
    IF v_result > 0 THEN
        DBMS_OUTPUT.PUT_LINE('CORRECT BEHAVIOR: Authentication successful with valid credentials');
    ELSE
        DBMS_OUTPUT.PUT_LINE('ERROR: Authentication failed with valid credentials');
    END IF;
END;
/

-- ===============================================================
-- TEST CASE 5: Password change validation
-- ===============================================================
DECLARE
    v_success BOOLEAN;
    v_user_id NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=======================================================');
    DBMS_OUTPUT.PUT_LINE('TEST CASE 5: Password change validation');
    DBMS_OUTPUT.PUT_LINE('=======================================================');
    
    -- Create a test user if not exists
    BEGIN
        user_mgmt_pkg.add_user(
            p_username => 'pwd_test_user',
            p_password => 'initial_password',
            p_firstname => 'Password',
            p_lastname => 'Test',
            p_role => 'User',
            p_email => 'pwd.test@example.com',
            p_mobile_no => '5553334444',
            p_user_id => v_user_id
        );
        DBMS_OUTPUT.PUT_LINE('Created test user for password testing');
    EXCEPTION
        WHEN OTHERS THEN
            -- User may already exist, get the user ID
            SELECT User_ID INTO v_user_id
            FROM Users
            WHERE Username = 'pwd_test_user';
            DBMS_OUTPUT.PUT_LINE('Using existing test user for password testing');
    END;
    
    -- Try to change password with incorrect old password
    DBMS_OUTPUT.PUT_LINE('Attempting to change password with incorrect old password...');
    user_mgmt_pkg.change_password(
        p_user_id => v_user_id,
        p_old_password => 'wrong_old_password',
        p_new_password => 'new_password',
        p_success => v_success
    );
    
    IF NOT v_success THEN
        DBMS_OUTPUT.PUT_LINE('CORRECT BEHAVIOR: Password change failed with incorrect old password');
    ELSE
        DBMS_OUTPUT.PUT_LINE('ERROR: Password changed with incorrect old password!');
    END IF;
    
    -- Change password with correct old password
    DBMS_OUTPUT.PUT_LINE('Changing password with correct old password...');
    user_mgmt_pkg.change_password(
        p_user_id => v_user_id,
        p_old_password => 'initial_password',
        p_new_password => 'new_password',
        p_success => v_success
    );
    
    IF v_success THEN
        DBMS_OUTPUT.PUT_LINE('CORRECT BEHAVIOR: Password changed successfully with correct old password');
        
        -- Verify new password works for authentication
        DECLARE
            v_auth_result NUMBER;
        BEGIN
            v_auth_result := user_mgmt_pkg.authenticate_user('pwd_test_user', 'new_password');
            
            IF v_auth_result > 0 THEN
                DBMS_OUTPUT.PUT_LINE('CORRECT BEHAVIOR: Authentication successful with new password');
            ELSE
                DBMS_OUTPUT.PUT_LINE('ERROR: Authentication failed with new password');
            END IF;
        END;
    ELSE
        DBMS_OUTPUT.PUT_LINE('ERROR: Password change failed with correct old password');
    END IF;
END;
/

-- ===============================================================
-- TEST CASE 6: Date validation in crime reporting
-- ===============================================================
DECLARE
    v_crime_id NUMBER;
    v_future_date DATE := SYSDATE + 30; -- 30 days in the future
BEGIN
    DBMS_OUTPUT.PUT_LINE('=======================================================');
    DBMS_OUTPUT.PUT_LINE('TEST CASE 6: Date validation in crime reporting');
    DBMS_OUTPUT.PUT_LINE('=======================================================');
    
    -- Attempt to report a crime with a future date
    DBMS_OUTPUT.PUT_LINE('Attempting to report a crime with a future date...');
    
    BEGIN
        crime_mgmt_pkg.report_crime(
            p_category_id => 1, -- Assuming category ID 1 exists
            p_created_by => 1, -- Assuming user ID 1 exists
            p_crime_desc => 'Test crime with future date',
            p_date_reported => v_future_date, -- Future date
            p_officer_id => 1, -- Assuming officer ID 1 exists
            p_crime_id => v_crime_id
        );
        
        -- Check if the system allowed the future date
        IF v_crime_id IS NOT NULL THEN
            DBMS_OUTPUT.PUT_LINE('WARNING: System allowed reporting a crime with a future date.');
            DBMS_OUTPUT.PUT_LINE('Consider adding date validation to prevent future dates.');
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('EXCEPTION CAUGHT: ' || SQLERRM);
            IF INSTR(UPPER(SQLERRM), 'DATE') > 0 THEN
                DBMS_OUTPUT.PUT_LINE('CORRECT BEHAVIOR: System prevented reporting a crime with a future date');
            ELSE
                DBMS_OUTPUT.PUT_LINE('Exception occurred but may not be related to date validation');
            END IF;
    END;
END;
/

-- ===============================================================
-- TEST CASE 7: Foreign key violations
-- ===============================================================
DECLARE
    v_crime_id NUMBER;
    v_non_existent_category NUMBER := 9999; -- Assuming this category doesn't exist
    v_non_existent_officer NUMBER := 9999;  -- Assuming this officer doesn't exist
BEGIN
    DBMS_OUTPUT.PUT_LINE('=======================================================');
    DBMS_OUTPUT.PUT_LINE('TEST CASE 7: Foreign key violations');
    DBMS_OUTPUT.PUT_LINE('=======================================================');
    
    -- Attempt to report a crime with non-existent category
    DBMS_OUTPUT.PUT_LINE('Attempting to report a crime with non-existent category...');
    BEGIN
        crime_mgmt_pkg.report_crime(
            p_category_id => v_non_existent_category,
            p_created_by => 1, -- Assuming user ID 1 exists
            p_crime_desc => 'Test crime with invalid category',
            p_date_reported => SYSDATE,
            p_officer_id => 1, -- Assuming officer ID 1 exists
            p_crime_id => v_crime_id
        );
        DBMS_OUTPUT.PUT_LINE('ERROR: Created crime with non-existent category - FK constraint failed!');
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('EXPECTED EXCEPTION CAUGHT: ' || SQLERRM);
            DBMS_OUTPUT.PUT_LINE('Foreign key constraint for category works correctly');
    END;
    
    -- Attempt to assign a crime to a non-existent officer
    DBMS_OUTPUT.PUT_LINE('Attempting to report a crime with non-existent officer...');
    BEGIN
        crime_mgmt_pkg.report_crime(
            p_category_id => 1, -- Assuming category ID 1 exists
            p_created_by => 1, -- Assuming user ID 1 exists
            p_crime_desc => 'Test crime with invalid officer',
            p_date_reported => SYSDATE,
            p_officer_id => v_non_existent_officer,
            p_crime_id => v_crime_id
        );
        DBMS_OUTPUT.PUT_LINE('ERROR: Created crime with non-existent officer - FK constraint failed!');
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('EXPECTED EXCEPTION CAUGHT: ' || SQLERRM);
            DBMS_OUTPUT.PUT_LINE('Foreign key constraint for officer works correctly');
    END;
END;
/

-- ===============================================================
-- TEST CASE 8: Data validation constraints
-- ===============================================================
DECLARE
    v_user_id NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=======================================================');
    DBMS_OUTPUT.PUT_LINE('TEST CASE 8: Data validation constraints');
    DBMS_OUTPUT.PUT_LINE('=======================================================');
    
    -- Test with invalid email format
    DBMS_OUTPUT.PUT_LINE('Attempting to create user with invalid email format...');
    BEGIN
        user_mgmt_pkg.add_user(
            p_username => 'email_test_user',
            p_password => 'test123',
            p_firstname => 'Email',
            p_lastname => 'Test',
            p_role => 'User',
            p_email => 'not_an_email_address', -- Invalid email format
            p_mobile_no => '5554443333',
            p_user_id => v_user_id
        );
        DBMS_OUTPUT.PUT_LINE('System allowed invalid email format - consider adding email validation');
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('EXCEPTION CAUGHT: ' || SQLERRM);
            IF INSTR(UPPER(SQLERRM), 'EMAIL') > 0 THEN
                DBMS_OUTPUT.PUT_LINE('CORRECT BEHAVIOR: System prevented invalid email format');
            ELSE
                DBMS_OUTPUT.PUT_LINE('Exception occurred but may not be related to email validation');
            END IF;
    END;
    
    -- Test with invalid mobile number format
    DBMS_OUTPUT.PUT_LINE('Attempting to create user with invalid mobile number format...');
    BEGIN
        user_mgmt_pkg.add_user(
            p_username => 'mobile_test_user',
            p_password => 'test123',
            p_firstname => 'Mobile',
            p_lastname => 'Test',
            p_role => 'User',
            p_email => 'mobile.test@example.com',
            p_mobile_no => 'abc1234567', -- Non-numeric mobile
            p_user_id => v_user_id
        );
        DBMS_OUTPUT.PUT_LINE('System allowed non-numeric mobile number - consider adding validation');
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('EXCEPTION CAUGHT: ' || SQLERRM);
            IF INSTR(UPPER(SQLERRM), 'MOBILE') > 0 OR INSTR(UPPER(SQLERRM), 'PHONE') > 0 THEN
                DBMS_OUTPUT.PUT_LINE('CORRECT BEHAVIOR: System prevented invalid mobile format');
            ELSE
                DBMS_OUTPUT.PUT_LINE('Exception occurred but may not be related to mobile validation');
            END IF;
    END;
    
    -- Test with empty required fields
    DBMS_OUTPUT.PUT_LINE('Attempting to create user with empty required fields...');
    BEGIN
        user_mgmt_pkg.add_user(
            p_username => 'empty_fields_user',
            p_password => 'test123',
            p_firstname => '', -- Empty required field
            p_lastname => 'Test',
            p_role => 'User',
            p_email => 'empty.test@example.com',
            p_mobile_no => '5557778888',
            p_user_id => v_user_id
        );
        DBMS_OUTPUT.PUT_LINE('System allowed empty firstname - consider adding validation');
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('EXCEPTION CAUGHT: ' || SQLERRM);
            DBMS_OUTPUT.PUT_LINE('System prevented empty required field');
    END;
END;
/

-- ===============================================================
-- TEST CASE 9: Transaction integrity with rollback
-- ===============================================================
DECLARE
    v_category_id NUMBER;
    v_crime_id NUMBER;
    v_user_id NUMBER;
    v_victim_id NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=======================================================');
    DBMS_OUTPUT.PUT_LINE('TEST CASE 9: Transaction integrity and rollback');
    DBMS_OUTPUT.PUT_LINE('=======================================================');
    
    -- Create a test category for our transaction test
    BEGIN
        crime_mgmt_pkg.add_category(
            p_category_name => 'Test Transaction Category',
            p_officer_id => 1, -- Assuming officer ID 1 exists
            p_category_id => v_category_id
        );
        DBMS_OUTPUT.PUT_LINE('Created test category with ID: ' || v_category_id);
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Error creating test category: ' || SQLERRM);
            RETURN; -- Skip the test if we can't set up properly
    END;
    
    -- Test transaction integrity - multi-step operation that should fail and roll back
    DBMS_OUTPUT.PUT_LINE('Testing transaction integrity with a multi-step operation...');
    
    -- Start a transaction (this would normally be inside a procedure, but we'll do it explicitly here)
    SAVEPOINT before_transaction;
    
    BEGIN
        -- Step 1: Report a crime (should succeed)
        crime_mgmt_pkg.report_crime(
            p_category_id => v_category_id,
            p_created_by => 1, -- Assuming user ID 1 exists
            p_crime_desc => 'Test transaction crime',
            p_date_reported => SYSDATE,
            p_officer_id => 1, -- Assuming officer ID 1 exists
            p_crime_id => v_crime_id
        );
        DBMS_OUTPUT.PUT_LINE('Step 1: Crime reported successfully with ID: ' || v_crime_id);
        
        -- Step 2: Register a victim (should succeed)
        register_victim(
            p_firstname => 'Transaction',
            p_lastname => 'Victim',
            p_dob => TO_DATE('1980-01-01', 'YYYY-MM-DD'),
            p_email => 'transaction.victim@example.com',
            p_mobile_no => '5559998888',
            p_created_by => 1, -- Assuming user ID 1 exists
            p_victim_id => v_victim_id
        );
        DBMS_OUTPUT.PUT_LINE('Step 2: Victim registered successfully with ID: ' || v_victim_id);
        
        -- Step 3: Link victim to crime (but use an invalid crime ID to force failure)
        DBMS_OUTPUT.PUT_LINE('Step 3: Attempting to link victim to invalid crime ID (should fail)...');
        crime_mgmt_pkg.link_victim_to_crime(
            p_victim_id => v_victim_id,
            p_crime_id => 9999 -- Invalid crime ID to force failure
        );
        
        -- Should not reach here if transaction integrity works
        DBMS_OUTPUT.PUT_LINE('ERROR: Transaction did not fail as expected!');
        ROLLBACK TO before_transaction;
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('EXPECTED EXCEPTION CAUGHT: ' || SQLERRM);
            DBMS_OUTPUT.PUT_LINE('Transaction failed and will be rolled back');
            ROLLBACK TO before_transaction;
            
            -- Verify that the crime and victim were not created due to rollback
            DECLARE
                v_count NUMBER;
            BEGIN
                SELECT COUNT(*) INTO v_count FROM Crime WHERE Crime_desc = 'Test transaction crime';
                IF v_count = 0 THEN
                    DBMS_OUTPUT.PUT_LINE('CORRECT BEHAVIOR: Crime was successfully rolled back');
                ELSE
                    DBMS_OUTPUT.PUT_LINE('WARNING: Crime was not rolled back - transaction integrity issue');
                END IF;
                
                SELECT COUNT(*) INTO v_count FROM Victim WHERE Email = 'transaction.victim@example.com';
                IF v_count = 0 THEN
                    DBMS_OUTPUT.PUT_LINE('CORRECT BEHAVIOR: Victim was successfully rolled back');
                ELSE
                    DBMS_OUTPUT.PUT_LINE('WARNING: Victim was not rolled back - transaction integrity issue');
                END IF;
            END;
    END;
END;
/

-- ===============================================================
-- TEST CASE 10: Status transition validation
-- ===============================================================
DECLARE
    v_crime_id NUMBER;
    v_category_id NUMBER := 1; -- Assuming category ID 1 exists
    v_user_id NUMBER := 1; -- Assuming user ID 1 exists
    v_officer_id NUMBER := 1; -- Assuming officer ID 1 exists
BEGIN
    DBMS_OUTPUT.PUT_LINE('=======================================================');
    DBMS_OUTPUT.PUT_LINE('TEST CASE 10: Status transition validation');
    DBMS_OUTPUT.PUT_LINE('=======================================================');
    
    -- Report a new crime for status testing
    crime_mgmt_pkg.report_crime(
        p_category_id => v_category_id,
        p_created_by => v_user_id,
        p_crime_desc => 'Status transition test crime',
        p_date_reported => SYSDATE,
        p_officer_id => v_officer_id,
        p_crime_id => v_crime_id
    );
    DBMS_OUTPUT.PUT_LINE('Created test crime with ID: ' || v_crime_id);
    
    -- Verify initial status
    DBMS_OUTPUT.PUT_LINE('Verifying initial status...');
    DECLARE
        v_status VARCHAR2(100);
    BEGIN
        SELECT Crime_Status INTO v_status FROM Crime_Status WHERE C_ID = v_crime_id;
        DBMS_OUTPUT.PUT_LINE('Initial status: ' || v_status);
    END;
    
    -- Test invalid status transition (from New directly to Closed, skipping Investigating)
    DBMS_OUTPUT.PUT_LINE('Attempting invalid status transition (New → Closed)...');
    BEGIN
        update_crime_status(
            p_crime_id => v_crime_id,
            p_status => 'Closed',
            p_updated_by => v_user_id,
            p_date_closed => SYSDATE
        );
        
        -- Check if system allowed the invalid transition
        DECLARE
            v_status VARCHAR2(100);
        BEGIN
            SELECT Crime_Status INTO v_status FROM Crime_Status WHERE C_ID = v_crime_id;
            IF v_status = 'Closed' THEN
                DBMS_OUTPUT.PUT_LINE('System allowed direct transition from New to Closed');
                DBMS_OUTPUT.PUT_LINE('Consider implementing state transition validation');
            ELSE
                DBMS_OUTPUT.PUT_LINE('System prevented invalid transition - current status: ' || v_status);
            END IF;
        END;
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('EXCEPTION CAUGHT: ' || SQLERRM);
            IF INSTR(UPPER(SQLERRM), 'STATUS') > 0 OR INSTR(UPPER(SQLERRM), 'TRANSITION') > 0 THEN
                DBMS_OUTPUT.PUT_LINE('CORRECT BEHAVIOR: System prevented invalid status transition');
            ELSE
                DBMS_OUTPUT.PUT_LINE('Exception occurred but may not be related to status transition');
            END IF;
    END;
    
    -- Valid transition - change to Investigating first
    DBMS_OUTPUT.PUT_LINE('Performing valid transition (New → Investigating)...');
    BEGIN
        update_crime_status(
            p_crime_id => v_crime_id,
            p_status => 'Investigating',
            p_updated_by => v_user_id
        );
        
        DECLARE
            v_status VARCHAR2(100);
        BEGIN
            SELECT Crime_Status INTO v_status FROM Crime_Status WHERE C_ID = v_crime_id;
            DBMS_OUTPUT.PUT_LINE('Status updated to: ' || v_status);
        END;
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Error updating status: ' || SQLERRM);
    END;
    
    -- Now try the valid transition to Closed
    DBMS_OUTPUT.PUT_LINE('Performing valid transition (Investigating → Closed)...');
    BEGIN
        update_crime_status(
            p_crime_id => v_crime_id,
            p_status => 'Closed',
            p_updated_by => v_user_id,
            p_date_closed => SYSDATE
        );
        
        DECLARE
            v_status VARCHAR2(100);
        BEGIN
            SELECT Crime_Status INTO v_status FROM Crime_Status WHERE C_ID = v_crime_id;
            DBMS_OUTPUT.PUT_LINE('Status successfully updated to: ' || v_status);
        END;
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Error updating status: ' || SQLERRM);
    END;
END;
/

COMMIT; CRMS system

SET SERVEROUTPUT ON;
