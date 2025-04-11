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

