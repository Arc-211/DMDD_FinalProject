-- TransactionManagement2.sql
-- This file contains stored procedures and functions for transaction management in CRMS

-- Create sequence for automatic ID generation
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE user_id_seq';
    EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE officer_id_seq';
    EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE crime_id_seq';
    EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE category_id_seq';
    EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE status_id_seq';
    EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE victim_id_seq';
    EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE criminal_id_seq';
    EXCEPTION WHEN OTHERS THEN NULL;
END;
/

-- Create sequences
CREATE SEQUENCE user_id_seq START WITH 11 INCREMENT BY 1;
CREATE SEQUENCE officer_id_seq START WITH 11 INCREMENT BY 1;
CREATE SEQUENCE crime_id_seq START WITH 11 INCREMENT BY 1;
CREATE SEQUENCE category_id_seq START WITH 11 INCREMENT BY 1;
CREATE SEQUENCE status_id_seq START WITH 6 INCREMENT BY 1;
CREATE SEQUENCE victim_id_seq START WITH 6 INCREMENT BY 1;
CREATE SEQUENCE criminal_id_seq START WITH 6 INCREMENT BY 1;

-- Clean up existing packages and procedures
BEGIN
    EXECUTE IMMEDIATE 'DROP PACKAGE user_mgmt_pkg';
    EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP PACKAGE crime_mgmt_pkg';
    EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP PACKAGE officer_mgmt_pkg';
    EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP PROCEDURE register_criminal';
    EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP PROCEDURE register_victim';
    EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP PROCEDURE assign_crime_to_officer';
    EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP PROCEDURE update_crime_status';
    EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP FUNCTION get_officer_caseload';
    EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP FUNCTION get_crime_status';
    EXCEPTION WHEN OTHERS THEN NULL;
END;
/

-- 1. User Management Package
CREATE OR REPLACE PACKAGE user_mgmt_pkg AS
    -- Add a new user
    PROCEDURE add_user(
        p_username IN VARCHAR2,
        p_password IN VARCHAR2,
        p_firstname IN VARCHAR2,
        p_lastname IN VARCHAR2,
        p_role IN VARCHAR2,
        p_email IN VARCHAR2,
        p_mobile_no IN VARCHAR2,
        p_user_id OUT NUMBER
    );
    
    -- Update user info
    PROCEDURE update_user(
        p_user_id IN NUMBER,
        p_username IN VARCHAR2,
        p_firstname IN VARCHAR2,
        p_lastname IN VARCHAR2,
        p_role IN VARCHAR2,
        p_email IN VARCHAR2,
        p_mobile_no IN VARCHAR2
    );
    
    -- Change user password
    PROCEDURE change_password(
        p_user_id IN NUMBER,
        p_old_password IN VARCHAR2,
        p_new_password IN VARCHAR2,
        p_success OUT BOOLEAN
    );
    
    -- Delete a user
    PROCEDURE delete_user(
        p_user_id IN NUMBER
    );
    
    -- Authenticate a user
    FUNCTION authenticate_user(
        p_username IN VARCHAR2,
        p_password IN VARCHAR2
    ) RETURN NUMBER;
END user_mgmt_pkg;
/

CREATE OR REPLACE PACKAGE BODY user_mgmt_pkg AS
    -- Add a new user
    PROCEDURE add_user(
        p_username IN VARCHAR2,
        p_password IN VARCHAR2,
        p_firstname IN VARCHAR2,
        p_lastname IN VARCHAR2,
        p_role IN VARCHAR2,
        p_email IN VARCHAR2,
        p_mobile_no IN VARCHAR2,
        p_user_id OUT NUMBER
    ) IS
    BEGIN
        -- Generate a new user ID using the sequence
        SELECT user_id_seq.NEXTVAL INTO p_user_id FROM DUAL;
        
        -- Insert the new user
        INSERT INTO Users (
            User_ID, Username, Password, Firstname, Lastname, Role, Email, Mobile_No
        ) VALUES (
            p_user_id, p_username, p_password, p_firstname, p_lastname, p_role, p_email, p_mobile_no
        );
        
        COMMIT;
        
        DBMS_OUTPUT.PUT_LINE('User created successfully with ID: ' || p_user_id);
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE('Error: Username, Email, or Mobile_No already exists');
            RAISE_APPLICATION_ERROR(-20001, 'Username, Email, or Mobile_No already exists');
        WHEN OTHERS THEN
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
            RAISE;
    END add_user;
    
    -- Update user info
    PROCEDURE update_user(
        p_user_id IN NUMBER,
        p_username IN VARCHAR2,
        p_firstname IN VARCHAR2,
        p_lastname IN VARCHAR2,
        p_role IN VARCHAR2,
        p_email IN VARCHAR2,
        p_mobile_no IN VARCHAR2
    ) IS
    BEGIN
        UPDATE Users
        SET Username = p_username,
            Firstname = p_firstname,
            Lastname = p_lastname,
            Role = p_role,
            Email = p_email,
            Mobile_No = p_mobile_no
        WHERE User_ID = p_user_id;
        
        IF SQL%ROWCOUNT = 0 THEN
            DBMS_OUTPUT.PUT_LINE('User ID ' || p_user_id || ' not found');
            RAISE_APPLICATION_ERROR(-20002, 'User ID not found');
        ELSE
            COMMIT;
            DBMS_OUTPUT.PUT_LINE('User updated successfully');
        END IF;
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE('Error: Username, Email, or Mobile_No already exists');
            RAISE_APPLICATION_ERROR(-20001, 'Username, Email, or Mobile_No already exists');
        WHEN OTHERS THEN
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
            RAISE;
    END update_user;
    
    -- Change user password
    PROCEDURE change_password(
        p_user_id IN NUMBER,
        p_old_password IN VARCHAR2,
        p_new_password IN VARCHAR2,
        p_success OUT BOOLEAN
    ) IS
        v_password VARCHAR2(20);
    BEGIN
        -- Check if old password matches
        SELECT Password INTO v_password 
        FROM Users 
        WHERE User_ID = p_user_id;
        
        IF v_password = p_old_password THEN
            -- Update the password
            UPDATE Users
            SET Password = p_new_password
            WHERE User_ID = p_user_id;
            
            COMMIT;
            p_success := TRUE;
            DBMS_OUTPUT.PUT_LINE('Password changed successfully');
        ELSE
            p_success := FALSE;
            DBMS_OUTPUT.PUT_LINE('Old password does not match');
        END IF;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            p_success := FALSE;
            DBMS_OUTPUT.PUT_LINE('User ID not found');
        WHEN OTHERS THEN
            ROLLBACK;
            p_success := FALSE;
            DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
    END change_password;
    
    -- Delete a user
    PROCEDURE delete_user(
        p_user_id IN NUMBER
    ) IS
    BEGIN
        DELETE FROM Users
        WHERE User_ID = p_user_id;
        
        IF SQL%ROWCOUNT = 0 THEN
            DBMS_OUTPUT.PUT_LINE('User ID ' || p_user_id || ' not found');
            RAISE_APPLICATION_ERROR(-20002, 'User ID not found');
        ELSE
            COMMIT;
            DBMS_OUTPUT.PUT_LINE('User deleted successfully');
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
            RAISE;
    END delete_user;
    
    -- Authenticate a user
    FUNCTION authenticate_user(
        p_username IN VARCHAR2,
        p_password IN VARCHAR2
    ) RETURN NUMBER IS
        v_user_id NUMBER;
    BEGIN
        SELECT User_ID INTO v_user_id
        FROM Users
        WHERE Username = p_username AND Password = p_password;
        
        RETURN v_user_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN -1; -- Invalid credentials
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
            RETURN -2; -- Database error
    END authenticate_user;
END user_mgmt_pkg;
/

-- 2. Crime Management Package
CREATE OR REPLACE PACKAGE crime_mgmt_pkg AS
    -- Add a new crime category
    PROCEDURE add_category(
        p_category_name IN VARCHAR2,
        p_officer_id IN NUMBER,
        p_category_id OUT NUMBER
    );
    
    -- Report a new crime
    PROCEDURE report_crime(
        p_category_id IN NUMBER,
        p_created_by IN NUMBER,
        p_crime_desc IN VARCHAR2,
        p_date_reported IN DATE,
        p_officer_id IN NUMBER,
        p_crime_id OUT NUMBER
    );
    
    -- Link a victim to a crime
    PROCEDURE link_victim_to_crime(
        p_victim_id IN NUMBER,
        p_crime_id IN NUMBER
    );
    
    -- Link a criminal to a crime
    PROCEDURE link_criminal_to_crime(
        p_criminal_id IN NUMBER,
        p_crime_id IN NUMBER
    );
    
    -- Get crimes by category
    FUNCTION get_crimes_by_category(
        p_category_id IN NUMBER
    ) RETURN SYS_REFCURSOR;
    
    -- Get crimes by officer
    FUNCTION get_crimes_by_officer(
        p_officer_id IN NUMBER
    ) RETURN SYS_REFCURSOR;
END crime_mgmt_pkg;
/

CREATE OR REPLACE PACKAGE BODY crime_mgmt_pkg AS
    -- Add a new crime category
    PROCEDURE add_category(
        p_category_name IN VARCHAR2,
        p_officer_id IN NUMBER,
        p_category_id OUT NUMBER
    ) IS
    BEGIN
        -- Generate a new category ID using the sequence
        SELECT category_id_seq.NEXTVAL INTO p_category_id FROM DUAL;
        
        -- Insert the new category
        INSERT INTO Category (
            Category_ID, Category_name, Officer_ID
        ) VALUES (
            p_category_id, p_category_name, p_officer_id
        );
        
        COMMIT;
        
        DBMS_OUTPUT.PUT_LINE('Category created successfully with ID: ' || p_category_id);
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
            RAISE;
    END add_category;
    
    -- Report a new crime
    PROCEDURE report_crime(
        p_category_id IN NUMBER,
        p_created_by IN NUMBER,
        p_crime_desc IN VARCHAR2,
        p_date_reported IN DATE,
        p_officer_id IN NUMBER,
        p_crime_id OUT NUMBER
    ) IS
    BEGIN
        -- Generate a new crime ID using the sequence
        SELECT crime_id_seq.NEXTVAL INTO p_crime_id FROM DUAL;
        
        -- Insert the new crime
        INSERT INTO Crime (
            C_ID, Category_ID, Created_by, Created_at, 
            Updated_by, Updated_at, Crime_desc, Date_reported, Officer_ID
        ) VALUES (
            p_crime_id, p_category_id, p_created_by, CURRENT_TIMESTAMP, 
            NULL, NULL, p_crime_desc, p_date_reported, p_officer_id
        );
        
        -- Create initial status for the crime
        INSERT INTO Crime_Status (
            Status_ID, C_ID, Created_by, Updated_by, Crime_Status, Date_assigned, Date_closed
        ) VALUES (
            status_id_seq.NEXTVAL, p_crime_id, p_created_by, NULL, 'New', p_date_reported, NULL
        );
        
        COMMIT;
        
        DBMS_OUTPUT.PUT_LINE('Crime reported successfully with ID: ' || p_crime_id);
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
            RAISE;
    END report_crime;
    
    -- Link a victim to a crime
    PROCEDURE link_victim_to_crime(
        p_victim_id IN NUMBER,
        p_crime_id IN NUMBER
    ) IS
    BEGIN
        -- Check if the link already exists
        DECLARE
            v_count NUMBER;
        BEGIN
            SELECT COUNT(*) INTO v_count 
            FROM Victim_Crime 
            WHERE V_ID = p_victim_id AND C_ID = p_crime_id;
            
            IF v_count = 0 THEN
                -- Insert the new link
                INSERT INTO Victim_Crime (
                    V_ID, C_ID
                ) VALUES (
                    p_victim_id, p_crime_id
                );
                
                COMMIT;
                
                DBMS_OUTPUT.PUT_LINE('Victim linked to crime successfully');
            ELSE
                DBMS_OUTPUT.PUT_LINE('Victim is already linked to this crime');
            END IF;
        END;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
            RAISE;
    END link_victim_to_crime;
    
    -- Link a criminal to a crime
    PROCEDURE link_criminal_to_crime(
        p_criminal_id IN NUMBER,
        p_crime_id IN NUMBER
    ) IS
    BEGIN
        -- Check if the link already exists
        DECLARE
            v_count NUMBER;
        BEGIN
            SELECT COUNT(*) INTO v_count 
            FROM Crime_Criminal 
            WHERE CR_ID = p_criminal_id AND C_ID = p_crime_id;
            
            IF v_count = 0 THEN
                -- Insert the new link
                INSERT INTO Crime_Criminal (
                    C_ID, CR_ID
                ) VALUES (
                    p_crime_id, p_criminal_id
                );
                
                COMMIT;
                
                DBMS_OUTPUT.PUT_LINE('Criminal linked to crime successfully');
            ELSE
                DBMS_OUTPUT.PUT_LINE('Criminal is already linked to this crime');
            END IF;
        END;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
            RAISE;
    END link_criminal_to_crime;
    
    -- Get crimes by category
    FUNCTION get_crimes_by_category(
        p_category_id IN NUMBER
    ) RETURN SYS_REFCURSOR IS
        v_cursor SYS_REFCURSOR;
    BEGIN
        OPEN v_cursor FOR
            SELECT c.C_ID, c.Crime_desc, c.Date_reported, cs.Crime_Status, 
                   o.Firstname || ' ' || o.Lastname AS Officer_Name,
                   cs.Date_assigned, cs.Date_closed
            FROM Crime c
            JOIN Crime_Status cs ON c.C_ID = cs.C_ID
            JOIN Officer o ON c.Officer_ID = o.Officer_ID
            WHERE c.Category_ID = p_category_id
            ORDER BY c.Date_reported DESC;
            
        RETURN v_cursor;
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
            RAISE;
    END get_crimes_by_category;
    
    -- Get crimes by officer
    FUNCTION get_crimes_by_officer(
        p_officer_id IN NUMBER
    ) RETURN SYS_REFCURSOR IS
        v_cursor SYS_REFCURSOR;
    BEGIN
        OPEN v_cursor FOR
            SELECT c.C_ID, c.Crime_desc, c.Date_reported, 
                   cs.Crime_Status, cs.Date_assigned, cs.Date_closed,
                   cat.Category_name
            FROM Crime c
            JOIN Crime_Status cs ON c.C_ID = cs.C_ID
            JOIN Category cat ON c.Category_ID = cat.Category_ID
            WHERE c.Officer_ID = p_officer_id
            ORDER BY cs.Date_assigned DESC;
            
        RETURN v_cursor;
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
            RAISE;
    END get_crimes_by_officer;
END crime_mgmt_pkg;
/
