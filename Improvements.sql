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
        
 