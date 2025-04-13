-- First, update the UPDATE_CRIME_STATUS procedure
CREATE OR REPLACE PROCEDURE update_crime_status(
    p_crime_id IN NUMBER,
    p_status IN VARCHAR2,
    p_updated_by IN NUMBER,
    p_date_closed IN DATE DEFAULT NULL
) IS
    v_current_status VARCHAR2(100);
    v_valid_transition BOOLEAN := FALSE;
BEGIN
    -- Get current status
    SELECT Crime_Status INTO v_current_status
    FROM Crime_Status
    WHERE C_ID = p_crime_id;
    
    -- Validate status transition
    CASE v_current_status
        WHEN 'New' THEN
            -- From New, can only go to Investigating
            IF p_status = 'Investigating' THEN
                v_valid_transition := TRUE;
            END IF;
        WHEN 'Investigating' THEN
            -- From Investigating, can go to Closed or back to New
            IF p_status IN ('Closed', 'New') THEN
                v_valid_transition := TRUE;
            END IF;
        WHEN 'Closed' THEN
            -- From Closed, can go back to Investigating
            IF p_status = 'Investigating' THEN
                v_valid_transition := TRUE;
            END IF;
        ELSE
            -- Unknown current status, reject transition
            v_valid_transition := FALSE;
    END CASE;
    
    -- Check if transition is valid
    IF NOT v_valid_transition THEN
        RAISE_APPLICATION_ERROR(-20013, 'Invalid status transition from ' || 
                               v_current_status || ' to ' || p_status);
    END IF;
    
    -- Update the crime status
    UPDATE Crime_Status
    SET Crime_Status = p_status,
        Updated_by = (SELECT Username FROM Users WHERE User_ID = p_updated_by),
        Date_closed = CASE 
                         WHEN p_status = 'Closed' THEN COALESCE(p_date_closed, CURRENT_DATE)
                         ELSE NULL -- Reset date_closed if reopening
                       END
    WHERE C_ID = p_crime_id;
    
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('Crime status updated from ' || v_current_status || ' to ' || p_status);
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error: Crime ID not found');
        RAISE_APPLICATION_ERROR(-20008, 'Crime ID not found');
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
        RAISE;
END update_crime_status;
/

-- Then, create the new procedure for transaction management
CREATE OR REPLACE PROCEDURE process_complete_crime_report(
    p_category_id IN NUMBER,
    p_created_by IN NUMBER,
    p_crime_desc IN VARCHAR2,
    p_date_reported IN DATE,
    p_officer_id IN NUMBER,
    p_victim_firstname IN VARCHAR2,
    p_victim_lastname IN VARCHAR2,
    p_victim_email IN VARCHAR2,
    p_victim_mobile IN VARCHAR2,
    p_success OUT BOOLEAN
) IS
    v_crime_id NUMBER;
    v_victim_id NUMBER;
BEGIN
    -- Start transaction implicitly
    -- Step 1: Report the crime
    crime_mgmt_pkg.report_crime(
        p_category_id => p_category_id,
        p_created_by => p_created_by,
        p_crime_desc => p_crime_desc,
        p_date_reported => p_date_reported,
        p_officer_id => p_officer_id,
        p_crime_id => v_crime_id
    );
    
    -- Step 2: Register the victim
    register_victim(
        p_firstname => p_victim_firstname,
        p_lastname => p_victim_lastname,
        p_dob => NULL, -- Optional field
        p_email => p_victim_email,
        p_mobile_no => p_victim_mobile,
        p_created_by => p_created_by,
        p_victim_id => v_victim_id
    );
    
    -- Step 3: Link victim to crime
    crime_mgmt_pkg.link_victim_to_crime(
        p_victim_id => v_victim_id,
        p_crime_id => v_crime_id
    );
    
    -- If we get here, everything succeeded
    COMMIT;
    p_success := TRUE;
    
EXCEPTION
    WHEN OTHERS THEN
        -- Log the error
        DBMS_OUTPUT.PUT_LINE('Error in process_complete_crime_report: ' || SQLERRM);
        -- Roll back all changes
        ROLLBACK;
        p_success := FALSE;
END;
/

-- First, update the USER_MGMT_PKG package body to add email and mobile validation

CREATE OR REPLACE PACKAGE BODY user_mgmt_pkg AS
    -- Add a new user with improved validation
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
        v_email_valid BOOLEAN;
        v_mobile_valid BOOLEAN;
    BEGIN
        -- Validate email format
        v_email_valid := REGEXP_LIKE(p_email, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');
        IF NOT v_email_valid THEN
            RAISE_APPLICATION_ERROR(-20010, 'Invalid email format');
        END IF;
        
        -- Validate mobile number (digits only)
        v_mobile_valid := REGEXP_LIKE(p_mobile_no, '^[0-9]{10}$');
        IF NOT v_mobile_valid THEN
            RAISE_APPLICATION_ERROR(-20011, 'Invalid mobile number format. Must be 10 digits');
        END IF;
        
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
        v_email_valid BOOLEAN;
        v_mobile_valid BOOLEAN;
    BEGIN
        -- Validate email format
        v_email_valid := REGEXP_LIKE(p_email, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');
        IF NOT v_email_valid THEN
            RAISE_APPLICATION_ERROR(-20010, 'Invalid email format');
        END IF;
        
        -- Validate mobile number (digits only)
        v_mobile_valid := REGEXP_LIKE(p_mobile_no, '^[0-9]{10}$');
        IF NOT v_mobile_valid THEN
            RAISE_APPLICATION_ERROR(-20011, 'Invalid mobile number format. Must be 10 digits');
        END IF;
        
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

-- Then, update the CRIME_MGMT_PKG package to add date validation

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
    
    -- Report a new crime with date validation
    PROCEDURE report_crime(
        p_category_id IN NUMBER,
        p_created_by IN NUMBER,
        p_crime_desc IN VARCHAR2,
        p_date_reported IN DATE,
        p_officer_id IN NUMBER,
        p_crime_id OUT NUMBER
    ) IS
    BEGIN
        -- Validate date isn't in the future
        IF p_date_reported > SYSDATE THEN
            RAISE_APPLICATION_ERROR(-20012, 'Crime cannot be reported with future date');
        END IF;
        
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