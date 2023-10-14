CREATE OR REPLACE PROCEDURE PR_INSERT_AUTHOR(
    P_FNAME IN LMS_AUTHORS.FNAME%TYPE,
    P_LNAME IN LMS_AUTHORS.LNAME%TYPE )
AS
  -- ************************************************************************************************************
  --                 |                                                                                          *
  -- PACKAGE HEADER  |                                                                                          *
  --                 |                                                                                          *
  -- PURPOSE         | THIS SCRIPT INSERTS AUTHORS INFORMATION INTO THE LMS_AUTHORS TABLE.                      *
  --                 |                                                                                          *
  --                 | IT CHECKS FOR DUPLICATE AUTHORS AND LOGS ERRORS IN THE LMS_ERRORLOGS TABLE.              *
  --                 |                                                                                          *
  -- ***********************************************************************************************************+
  -- PPROCEDURE NAME            | PR_INSERT_AUTHOR                                                              *
  -- AUTHOR                     | SR CONSULTANTS                                                                *
  --                            |                                                                               *
  -- MODIFICATION LOG ------------------------------------------------------------------------------------------+
  -- VER NO     |    DATE       |      AUTHOR       |         MODIFICATION                                      *
  --------------+---------------+-------------------+-----------------------------------------------------------+
  -- 1.00       | 31-JUL-2021   |  RAJAT K. SWAIN   |     FIRST VERSION                                         *
  -- 1.10       | 10-SEP-2021   |  RAJAT K. SWAIN   |     COUNTY_CODE ENRTY ADDED                               *
  -- 1.20       | 16-OCT-2021   |  RAJAT K. SWAIN   |     LOWER MAIL_ID REQUIRED                                *
  -- 1.30       | 11-SEP-2023   |  RAJAT K. SWAIN   |     DATA SUCESSFUL INSERT MASSAGE                         *
  -- 1.40       | 11-SEP-2023   |  RAJAT K. SWAIN   |     DATA SUCESSFUL INSERT MASSAGE                         *
  -- 1.50       | 17-SEP-2023   |  RAJAT K. SWAIN   |     ENHANCEMENT: TRIMMING INPUT PARAMETERS FOR CONSISTENCY*
  -- 1.60       | 27-SEP-2023   |  RAJAT K. SWAIN   |     ENHANCEMENT: GENERATING EMAIL ID FROM NAME            *
  -- 1.70       | 06-OCT-2022   |  RAJAT K. SWAIN   |     FNAME AND LNAME ARE MANDATORY PARAMETERS.             *
  -- ************************************************************************************************************
  -- DECLARE VARIABLES
  VP_FNAME       VARCHAR2(50);
  VP_LNAME       VARCHAR2(50);
  V_AUTHOR_ID    NUMBER;
  V_COUNTRY      VARCHAR2(50);
  V_MAIL_ID      VARCHAR2 (50);
  V_MAIL_DOMAIN  VARCHAR2(50);
  V_ATHR_CODE    CONSTANT CHAR(4)  := 'ATHR';
  V_ERROR_CODE   CONSTANT CHAR(14) := 'INSRT_ATHR_ERR'; -- INSERT AUTHOR ERRORS
  V_ERRORMSG     VARCHAR2(100)     := 'AUTHOR WITH THE SAME NAME ALREADY EXISTS.';
  V_SUCCESS_FLAG NUMBER; --ADDED THE VERIABLE FOR CHECK DATA INSERTION SUCESSFUL +1.40V
  V_MFNAME       VARCHAR2(50); --ADDED THIS VARIABLE FOR MAIL_ID +1.60V
  V_MLNAME       VARCHAR2(50); --ADDED THIS VARIABLE FOR MAIL_ID +1.60V
BEGIN
  /* BEGIN 1.70*/
  -- CHECK IF BOTH P_FNAME AND P_LNAME ARE NOT NULL
  IF P_FNAME IS NULL OR P_LNAME IS NULL THEN
  RAISE_APPLICATION_ERROR(-20001, 'BOTH FNAME AND LNAME ARE MANDATORY PARAMETERS AND CANNOT BE NULL.');
  V_ERRORMSG:= SQLERRM;
  RETURN;
  END IF;
  /* END 1.70*/

  -- CONVERT INPUT PARAMETERS TO UPPERCASE FOR CONSISTENCY
  /* BEGIN 1.50*/
  SELECT TRIM(P_FNAME), TRIM(P_LNAME) INTO VP_FNAME,VP_LNAME FROM DUAL;
  /* END 1.50*/
  VP_FNAME := UPPER(VP_FNAME);
  VP_LNAME := UPPER(VP_LNAME);
  
  BEGIN
    -- CHECK IF AN AUTHOR WITH THE SAME FIRST NAME AND LAST NAME ALREADY EXISTS
    SELECT AUTHOR_ID
    INTO V_AUTHOR_ID
    FROM LMS_AUTHORS
    WHERE FNAME = VP_FNAME
    AND LNAME   = VP_LNAME;
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    V_AUTHOR_ID := NULL; -- SET V_AUTHOR_ID TO NULL TO INDICATE THAT NO RECORD WAS FOUND
  END;
  -- GENERATE A COUNTRY BASED ON THE FIRST 3 CHARACTERS OF THE FIRST NAME USING REGEXP
	IF REGEXP_LIKE(SUBSTR(VP_FNAME, 1, 3), '^(ABHI|AMA|ANA|ASH|BAN|CHA|CHI|DEV|DHI|ELA|ESH|FRE|GAN|HAR|IND|ISH|JAY|JOH|KAR|KAV|LAK|MAN|MIS|NIK|NIS|OLI|POO|PRA|PRI|RAD|RAJ|RAK|RAM|SAN|SAR|SHR|SID|SRI|TAS|TRI|VAR|VIN)', 'i') THEN
	V_COUNTRY := 'INDIA';
	ELSIF REGEXP_LIKE(SUBSTR(VP_FNAME, 1, 3), '^(ALB|BRI|CHR|DAV|EDD|ELI|ERI|FLO|GEO|GRE|HAN|JAC|JAN|JOH|JOS|MAR|MAT|NAT|NIC|OLI|OSC|PAT|PAU|PAU|RIC|ROB|SAR|STE|THO|TOB|TOM|WIL)', 'i') THEN
	V_COUNTRY := 'UNITED KINGDOM';
	ELSIF REGEXP_LIKE(SUBSTR(VP_FNAME, 1, 3), '^(ADA|ANN|ASH|BAR|BOB|CAR|CAT|DAV|DOR|ELI|EVA|GRA|HAR|JEN|JIL|JOH|JOS|KAT|LAU|LEO|MAR|MEL|NAT|NEL|ROB|SAM|SAR|SOP|SUE|TAS|TOM|VIC)', 'i') THEN
	V_COUNTRY := 'USA';
	ELSE
	V_COUNTRY := 'NEED TO UPDATE'; -- PROVIDE A DEFAULT VALUE IF NONE OF THE CONDITIONS MATCH
	END IF;
  
  -- GENERATE A RANDOM MAIL DOMAIN
  /* BEGIN 1.60*/
  SELECT RTRIM(REPLACE(VP_FNAME, ' ', ''),'.'),TRIM(VP_LNAME) INTO V_MFNAME,V_MLNAME  FROM DUAL;
  /* END 1.60*/
  IF DBMS_RANDOM.VALUE(0, 1)    <= 0.3333 THEN
    V_MAIL_DOMAIN               := LOWER('@GMAIL.COM');
  ELSIF DBMS_RANDOM.VALUE(0, 1) <= 0.6666 THEN
    V_MAIL_DOMAIN               := LOWER('@YAHOO.COM');
  ELSE
    V_MAIL_DOMAIN := LOWER('@REDIFFMAIL.COM');
  END IF;
  -- CREATE THE MAIL ID AS FNAME.LNAME + RANDOM MAIL DOMAIN
  V_MAIL_ID      := LOWER(V_MFNAME) || '.' || LOWER(V_MLNAME) || V_MAIL_DOMAIN;
  IF V_AUTHOR_ID IS NULL THEN
    -- GENERATE A UNIQUE AUTHOR_ID USING THE EXISTING SEQUENCE
    SELECT AUTHOR_ID_SEQ.NEXTVAL
    INTO V_AUTHOR_ID
    FROM DUAL;
    -- INSERT THE DATA INTO THE LMS_AUTHORS TABLE
    INSERT
    INTO LMS_AUTHORS
      (
        AUTHOR_ID,
        FNAME,
        LNAME,
        MAIL_ID,
        AUTHOR_CODE,
        COUNTRY
      )
      VALUES
      (
        V_AUTHOR_ID,
        VP_FNAME,
        VP_LNAME,
        V_MAIL_ID,
        V_ATHR_CODE
        || V_AUTHOR_ID,
        V_COUNTRY
      );
    -- COMMIT THE TRANSACTION
    COMMIT;
    -- CHECK IF THE DATA WAS INSERTED SUCCESSFULLY  --2.00V START(RK)
    BEGIN
      SELECT 1
      INTO V_SUCCESS_FLAG
      FROM DUAL
      WHERE EXISTS
        ( SELECT 1 FROM LMS_AUTHORS WHERE AUTHOR_ID = V_AUTHOR_ID
        );
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      -- DATA NOT FOUND; HANDLE THIS CASE
      DBMS_OUTPUT.PUT_LINE('DATA WAS NOT INSERTED SUCCESSFULLY.');
    WHEN OTHERS THEN
      -- HANDLE OTHER EXCEPTIONS AS NEEDED
      DBMS_OUTPUT.PUT_LINE('ERROR: ' || SQLERRM);
    END; --2.00V END (RK)
    -- DISPLAY A SUCCESS MESSAGE
    DBMS_OUTPUT.PUT_LINE('AUTHOR INSERTED SUCCESSFULLY.');
  ELSE
    -- PRINT A MESSAGE IF AN AUTHOR WITH THE SAME NAME ALREADY EXISTS
    DBMS_OUTPUT.PUT_LINE('AUTHOR WITH THE SAME NAME ALREADY EXISTS.');
    -- LOG THE ERROR USING PR_LOG_ERROR (YOU NEED TO IMPLEMENT THIS PROCEDURE)
    PKG_LMS_ERRORHANDELER.PR_LOG_AUTHOR_ERROR(VP_FNAME, VP_LNAME, V_ERROR_CODE, V_ERRORMSG);
  END IF;
EXCEPTION
WHEN OTHERS THEN
  -- HANDLE EXCEPTIONS APPROPRIATELY, E.G., LOG THE ERROR MESSAGE
  DBMS_OUTPUT.PUT_LINE('ERROR: ' || SQLERRM);
  V_ERRORMSG :=SQLERRM; --1.70v
  -- LOG THE ERROR USING PR_LOG_ERROR (YOU NEED TO IMPLEMENT THIS PROCEDURE)
  PKG_LMS_ERRORHANDELER.PR_LOG_AUTHOR_ERROR(VP_FNAME, VP_LNAME, V_ERROR_CODE, V_ERRORMSG);
END PR_INSERT_AUTHOR;