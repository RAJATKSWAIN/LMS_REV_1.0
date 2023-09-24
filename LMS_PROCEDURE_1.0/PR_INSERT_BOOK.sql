CREATE OR REPLACE PROCEDURE PR_INSERT_BOOK(
    P_FNAME        IN VARCHAR2,
    P_LNAME        IN VARCHAR2,
    P_TITLE        IN VARCHAR2,
    P_BOOK_GENER   IN VARCHAR2,
    P_PUBLISH_YEAR IN NUMBER
	 )
AS
  -- ************************************************************************************************************
  --                  |                                                                                         *
  -- PACKAGE HEADER   |                                                                                         *
  --                  |                                                                                         *
  -- PURPOSE          | THIS SCRIPT INSERTS BOOKS INFORMATION INTO THE LMS_BOOKS TABLE.                         *
  --                  |                                                                                         *
  --                  | IT CHECKS FOR DUPLICATE BOOKS AND LOGS ERRORS IN THE LMS_ERRORLOGS TABLE.               *
  --                  |                                                                                         *
  -- ***********************************************************************************************************+
  -- PPROCEDURE NAME            | PR_INSERT_BOOKS                                                               *
  -- AUTHOR                     | SR CONSULTANTS                                                                *
  --                            |                                                                               *
  -- MODIFICATION LOG ------------------------------------------------------------------------------------------+
  -- VER NO     |    DATE       |      AUTHOR       |         MODIFICATION                                      *
  --------------+---------------+-------------------+-----------------------------------------------------------+
  -- 1.00       | 31-JUL-2021   |  RAJAT K. SWAIN   |     FIRST VERSION                                         *
  -- 1.10       | 10-SEP-2021   |  RAJAT K. SWAIN   |     COUNTY_CODE ENRTY MISSED                              *
  -- 1.30       | 16-OCT-2021   |  RAJAT K. SWAIN   |     LOWER MAIL_ID REQUIRED                                *
  -- 1.40       | 11-AUG-2023   |  RAJAT K. SWAIN   |     ADDED A NEW COLUMN TO LMS_BOOKS                       *
  -- 1.50       | 01-SEP-2023   |  RAJAT K. SWAIN   |     ADDED A NEW COLUMN TO LMS_BOOKS                       *
  -- 1.60       | 17-SEP-2023   |  RAJAT K. SWAIN   |     ENHANCEMENT: TRIMMING INPUT PARAMETERS FOR CONSISTENCY*
  -- ***********************************************************************************************************+
  -- DECLARE VARIABLES
  V_AUTHOR_ID    NUMBER;
  V_AUTHOR_CODE  VARCHAR2(25);
  V_BOOK_ID      NUMBER;
  V_ERROR_CODE   CONSTANT CHAR(14) := 'INSRT_BOOK_ERR';
  V_ERRORMSG     VARCHAR2(100)     := 'BOOK WITH THE SAME TITLE ALREADY EXISTS.';
  V_SUCCESS_FLAG NUMBER;
  VP_TITLE       VARCHAR2(100);
  VP_BOOK_GENER  VARCHAR2(100);
  VP_FNAME       VARCHAR2(100);--1.60.1+
  VP_LNAME       VARCHAR2(100);--1.60.1+

BEGIN
  /* BEGIN 1.60*/
  SELECT TRIM(P_TITLE), TRIM(P_BOOK_GENER) INTO VP_TITLE,VP_BOOK_GENER FROM DUAL;
  /* END 1.60*/
  --1.60.1+
  SELECT TRIM(P_FNAME), TRIM(P_LNAME) INTO VP_FNAME,VP_LNAME FROM DUAL; 
  VP_FNAME := UPPER(VP_FNAME);
  VP_LNAME := UPPER(VP_LNAME);
  --1.60.1+
  VP_TITLE      :=UPPER(VP_TITLE);
  VP_BOOK_GENER :=UPPER(VP_BOOK_GENER);
  -- CHECK IF THE AUTHOR EXISTS OR INSERT THE AUTHOR IF NOT
  BEGIN
    SELECT AUTHOR_ID,
      AUTHOR_CODE
    INTO V_AUTHOR_ID,
      V_AUTHOR_CODE
    FROM LMS_AUTHORS
    WHERE FNAME = VP_FNAME     --UPPER(P_FNAME)1.60.1+
    AND LNAME   = VP_LNAME;    --UPPER(P_LNAME)1.60.1+
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    -- AUTHOR DOESN'T EXIST, SO INSERT THE AUTHOR
    PR_INSERT_AUTHOR(VP_FNAME, VP_LNAME);
    -- RETRIEVE THE GENERATED AUTHOR_ID
    SELECT AUTHOR_ID,
      AUTHOR_CODE
    INTO V_AUTHOR_ID,
      V_AUTHOR_CODE
    FROM LMS_AUTHORS
    WHERE FNAME = VP_FNAME     --UPPER(P_FNAME)1.60.1+
    AND LNAME   = VP_LNAME;    --UPPER(P_LNAME)1.60.1+
  END;
  -- GENERATE AUTHOR_CODE BASED ON AUTHOR_ID
  SELECT AUTHOR_CODE
  INTO V_AUTHOR_CODE
  FROM LMS_AUTHORS
  WHERE AUTHOR_ID = V_AUTHOR_ID;
  BEGIN
    -- CHECK IF A BOOK WITH THE SAME TITLE ALREADY EXISTS
    SELECT BOOK_ID
    INTO V_BOOK_ID
    FROM LMS_BOOKS
    WHERE TITLE = VP_TITLE;     --P_TITLE 1.60.1+
  IF V_BOOK_ID IS NOT NULL THEN 
    UPDATE LMS_BOOKS SET BOOK_NOS = BOOK_NOS+1,
                          STATUS='Y'  --1.60
    WHERE BOOK_ID=V_BOOK_ID;
    COMMIT;
  END IF;
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    V_BOOK_ID := NULL; -- SET V_BOOK_ID TO NULL TO INDICATE THAT NO RECORD WAS FOUND
  END;
  IF V_BOOK_ID IS NULL THEN
    -- GENERATE A UNIQUE BOOK_ID USING THE EXISTING SEQUENCE
    SELECT BOOK_ID_SEQ.NEXTVAL
    INTO V_BOOK_ID
    FROM DUAL;
    -- INSERT THE DATA INTO THE LMS_BOOKS TABLE
    INSERT
    INTO LMS_BOOKS
      (
        BOOK_ID,
        AUTHOR_ID,
        TITLE,
        BOOK_GENER,
        AUTHOR_CODE,
		    PUBLISH_YEAR
      )
      VALUES
      (
        V_BOOK_ID,
        V_AUTHOR_ID,
        VP_TITLE,
        VP_BOOK_GENER,
        V_AUTHOR_CODE,
		    P_PUBLISH_YEAR
      );
    -- COMMIT THE TRANSACTION
    COMMIT;
    -- CHECK IF THE DATA WAS INSERTED SUCCESSFULLY
    BEGIN
      SELECT 1
      INTO V_SUCCESS_FLAG
      FROM DUAL
      WHERE EXISTS
        ( SELECT 1 FROM LMS_BOOKS WHERE BOOK_ID = V_BOOK_ID
        );
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      -- DATA NOT FOUND; HANDLE THIS CASE
      DBMS_OUTPUT.PUT_LINE('DATA WAS NOT INSERTED SUCCESSFULLY.');
    WHEN OTHERS THEN
      -- HANDLE OTHER EXCEPTIONS AS NEEDED
      DBMS_OUTPUT.PUT_LINE('ERROR: ' || SQLERRM);
    END;
    -- DISPLAY A SUCCESS MESSAGE
    DBMS_OUTPUT.PUT_LINE('BOOK INSERTED SUCCESSFULLY.');
  ELSE
    -- PRINT A MESSAGE IF A BOOK WITH THE SAME TITLE ALREADY EXISTS
    DBMS_OUTPUT.PUT_LINE('BOOK WITH THE SAME TITLE ALREADY EXISTS.');
    DBMS_OUTPUT.PUT_LINE('BOOK WITH THE SAME TITLE ALREADY EXISTS SO WE UPDATED THE BOOK_NO.');
    -- LOG THE ERROR USING PR_LOG_ERROR (YOU NEED TO IMPLEMENT THIS PROCEDURE)
    --PKG_LMS_ERRORHANDELER.PR_LOG_BOOK_ERROR(VP_TITLE, V_ERROR_CODE, V_ERRORMSG);
  END IF;
EXCEPTION
WHEN OTHERS THEN
  -- HANDLE EXCEPTIONS APPROPRIATELY, E.G., LOG THE ERROR MESSAGE
  DBMS_OUTPUT.PUT_LINE('ERROR: ' || SQLERRM);
  -- LOG THE ERROR USING PR_LOG_ERROR (YOU NEED TO IMPLEMENT THIS PROCEDURE)
  PKG_LMS_ERRORHANDELER.PR_LOG_BOOK_ERROR(VP_TITLE, V_ERROR_CODE, V_ERRORMSG);
END PR_INSERT_BOOK;