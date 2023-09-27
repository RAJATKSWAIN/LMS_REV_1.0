create or replace PROCEDURE PR_INSERT_MEMBER(
    P_FNAME     IN LMS_MEMBERS.FNAME%TYPE,
    P_LNAME     IN LMS_MEMBERS.LNAME%TYPE,
    P_MOBILE_NO IN LMS_MEMBERS.MOBILE_NO%TYPE )
AS
  -- *********************************************************************************************************************+
  --                 |                                                                                                    *
  -- PACKAGE HEADER  |                                                                                                    *
  --                 |                                                                                                    *
  -- PURPOSE         | WORKFLOW HEADLINES FOR PR_INSERT_MEMBER PROCEDURE                                                  *
  --                 |                                                                                                    *
  --                 | STEP 1: PARAMETER CONVERSION AND VALIDATION                                                        *
  --                 |   - CONVERT INPUT PARAMETERS TO UPPERCASE FOR CONSISTENCY.                                         *
  --                 |   - CHECK IF A MEMBER WITH THE SAME FIRST NAME AND LAST NAME ALREADY EXISTS.                       *
  --                 |                                                                                                    *
  --                 | STEP 2: MEMBER INSERTION                                                                           *
  --                 |   - GENERATE A UNIQUE MEMBER ID USING THE EXISTING SEQUENCE.                                       *
  --                 |   - CREATE THE MEMBER'S MAIL ID AS FNAME.LNAME + RANDOM MAIL DOMAIN.                               *
  --                 |   - INSERT THE NEW MEMBER'S DATA INTO THE LMS_MEMBERS TABLE.                                       *
  --                 |   - COMMIT THE TRANSACTION.                                                                        *
  --                 |                                                                                                    *
  --                 | STEP 3: DATA INSERTION VERIFICATION                                                                *
  --                 |   - CHECK IF THE DATA WAS INSERTED SUCCESSFULLY INTO THE LMS_MEMBERS TABLE.                        *
  --                 |   - HANDLE ANY EXCEPTIONS OR ERRORS DURING DATA INSERTION VERIFICATION.                            *
  --                 |                                                                                                    *
  --                 | STEP 4: EXCEPTION HANDLING                                                                         *
  --                 |   - HANDLE ANY OTHER EXCEPTIONS OR ERRORS THAT MAY OCCUR DURING THE PROCEDURE.                     *
  --                 |                                                                                                    *
  --                 | END OF PR_INSERT_MEMBER PROCEDURE                                                                  *
  --                 |                                                                                                    *
  --                 |                                                                                                    *
  --                 |                                                                                                    *
  --				 |								   		                                                			  *
  -- *********************************************************************************************************************+
  -- *********************************************************************************************************************+
  -- PPROCEDURE NAME            | PR_INSERT_MEMBER                                                                        *
  -- AUTHOR                     | SR CONSULTANTS                                                                          *
  --                            |                                                                                         *
  -- MODIFICATION LOG ----------------------------------------------------------------------------------------------------+
  -- VER NO     |    DATE       |      AUTHOR       |         MODIFICATION                                                *
  --------------+---------------+-------------------+---------------------------------------------------------------------+
  -- 1.00       | 31-JUL-2021   |  RAJAT K. SWAIN   |     FIRST VERSION                                                   *
  -- 1.10       | 17-SEP-2023   |  RAJAT K. SWAIN   |     ENHANCEMENT: TRIMMING INPUT PARAMETERS FOR CONSISTENCY          *
  -- 1.20       | 27-SEP-2023   |  RAJAT K. SWAIN   |     ENHANCEMENT: GENERATING EMAIL ID FROM NAME                      *
  -- *********************************************************************************************************************+
  -- DECLARE VARIABLES
  VP_FNAME       VARCHAR2(50);
  VP_LNAME       VARCHAR2(50);
  V_MEMBER_ID    NUMBER;
  V_MAIL_ID      VARCHAR2(100);
  V_MAIL_DOMAIN  CONSTANT CHAR(11) :='@rsmail.com';
  V_MEMBER_CODE  CONSTANT CHAR(3)  := 'MBR';
  V_ERROR_CODE   CONSTANT CHAR(14) := 'INSERT_MBR_ERR';
  V_ERRORMSG     VARCHAR2(100)     := 'MEMBER WITH THE SAME FIRST NAME AND LAST NAME ALREADY EXISTS.';
  V_SUCCESS_FLAG NUMBER;
  V_MFNAME       VARCHAR2(50); --ADDED THIS VARIABLE FOR MAIL_ID +1.20V
  V_MLNAME       VARCHAR2(50); --ADDED THIS VARIABLE FOR MAIL_ID +1.20V
BEGIN
    /* BEGIN 1.10*/
  SELECT TRIM(P_FNAME), TRIM(P_LNAME) INTO VP_FNAME,VP_LNAME FROM DUAL;
    /* END 1.10*/
  -- CONVERT INPUT PARAMETERS TO UPPERCASE FOR CONSISTENCY
  VP_FNAME := UPPER(VP_FNAME);
  VP_LNAME := UPPER(VP_LNAME);
  -- CHECK IF A MEMBER WITH THE SAME FIRST NAME AND LAST NAME ALREADY EXISTS
  BEGIN
    SELECT MEMBER_ID
    INTO V_MEMBER_ID
    FROM LMS_MEMBERS
    WHERE FNAME = VP_FNAME
    AND LNAME   = VP_LNAME;
    -- IF A MEMBER WITH THE SAME FIRST NAME AND LAST NAME EXISTS IT GO TO  ERROR
    IF V_MEMBER_ID IS NOT NULL THEN
      PKG_LMS_ERRORHANDELER.PR_LOG_MEMBER_ERROR(VP_FNAME,VP_LNAME,V_ERROR_CODE,V_ERRORMSG );
      DBMS_OUTPUT.PUT_LINE('A MEMBER WITH THE SAME FIRST NAME AND LAST NAME ALREADY EXISTS.');
    END IF;
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    V_MEMBER_ID := NULL;
  END;
  -- IF NO MEMBER WITH THE SAME FIRST NAME AND LAST NAME EXISTS, INSERT THE NEW MEMBER
  IF V_MEMBER_ID IS NULL THEN
    -- GENERATE A UNIQUE MEMBER_ID USING THE EXISTING SEQUENCE
    SELECT MEMBER_ID_SEQ.NEXTVAL
    INTO V_MEMBER_ID
    FROM DUAL;
    -- CREATE THE MAIL ID AS FNAME.LNAME + RANDOM MAIL DOMAIN
    /* BEGIN 1.20*/
   SELECT RTRIM(REPLACE(VP_FNAME, ' ', ''),'.'),TRIM(VP_LNAME) INTO V_MFNAME,V_MLNAME  FROM DUAL;
   /* END 1.20*/
    V_MAIL_ID := LOWER(V_MFNAME) || '.' || LOWER(V_MLNAME) || V_MAIL_DOMAIN;
    -- INSERT THE DATA INTO THE LMS_MEMBERS TABLE
    INSERT
    INTO LMS_MEMBERS
      (
        MEMBER_ID,
        FNAME,
        LNAME,
        MOBILE_NO,
        MAIL_ID,
        MEMBER_CODE
      )
      VALUES
      (
        V_MEMBER_ID,
        VP_FNAME,
        VP_LNAME,
        P_MOBILE_NO,
        V_MAIL_ID,
        V_MEMBER_CODE
        ||V_MEMBER_ID
      );
    COMMIT;
    -- CHECK IF THE DATA WAS INSERTED SUCCESSFULLY  --2.00V START(RK)
    BEGIN
      SELECT 1
      INTO V_SUCCESS_FLAG
      FROM DUAL
      WHERE EXISTS
        ( SELECT 1 FROM LMS_MEMBERS WHERE MEMBER_ID = V_MEMBER_ID
        );
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      -- DATA NOT FOUND; HANDLE THIS CASE
      DBMS_OUTPUT.PUT_LINE('DATA WAS NOT INSERTED SUCCESSFULLY.');
    WHEN OTHERS THEN
      -- HANDLE OTHER EXCEPTIONS AS NEEDED
      DBMS_OUTPUT.PUT_LINE('ERROR: ' || SQLERRM);
    END; --2.00V END (RK)
    DBMS_OUTPUT.PUT_LINE('NEW MEMBER INSERTED SUCCESSFULLY.');
  END IF;
EXCEPTION
WHEN OTHERS THEN
  DBMS_OUTPUT.PUT_LINE('ERROR: ' || SQLERRM);
  -- LOG THE ERROR USING YOUR ERROR HANDLING PROCEDURE IF NEEDED
  PKG_LMS_ERRORHANDELER.PR_LOG_MEMBER_ERROR(P_FNAME,P_LNAME,V_ERROR_CODE,V_ERRORMSG );
END PR_INSERT_MEMBER;
/
