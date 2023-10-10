CREATE OR REPLACE  PACKAGE BODY PKG_LMS_AUTOTRNS 

AS

PROCEDURE PR_INSERT_AUTHOR(
    P_FNAME IN LMS_AUTHORS.FNAME%TYPE,
    P_LNAME IN LMS_AUTHORS.LNAME%TYPE )
AS
  -- *****************************************************************************************************************************
  --                 |                                                                                                    	 *
  -- PACKAGE HEADER  |  PKG_LMS_AUTOTRNS                                                                                   	 *
  --                 |                                                                                                           *
  -- PURPOSE         |  WORKFLOW HEADLINES FOR PR_INSERT_AUTHOR PROCEDURE             		                                 *
  --                 |               							                                         *
  --                 |  STEP 1:PARAMETER CONVERSION AND VALIDATION          					                 *
  --                 |       CONVERT INPUT PARAMETERS TO UPPERCASE FOR CONSISTENCY.          	                                 *
  --                 |       CHECK IF AN AUTHOR WITH THE SAME FIRST NAME AND LAST NAME ALREADY EXISTS.               	         *
  --                 |               							                                         *
  --                 |  STEP 2:DETERMINE AUTHOR'S COUNTRY   						                         *
  --                 |       GENERATE THE AUTHOR'S COUNTRY BASED ON THE FIRST 3 CHARACTERS OF THE FIRST NAME USING REGEXP.       *
  --                 |               							                                         *
  --                 |  STEP 3:GENERATE MAIL ID             				                                         *
  --                 |        GENERATE A RANDOM MAIL DOMAIN BASED ON PROBABILITY.    		                                 *
  --                 |        CREATE THE AUTHOR'S MAIL ID AS FNAME.LNAME + RANDOM MAIL DOMAIN.      		                 *
  --                 |      							                                                 *
  --                 |  STEP 4:AUTHOR INSERTION   							                         *
  --                 |       GENERATE A UNIQUE AUTHOR ID USING THE EXISTING SEQUENCE.  			                         *
  --                 |       INSERT THE NEW AUTHOR'S DATA INTO THE LMS_AUTHORS TABLE.     			                 *
  --                 |       COMMIT THE TRANSACTION.      						                         *
  --                 |               			                                                 			 *
  --                 |  STEP 5:DATA INSERTION VERIFICATION              			                                 *
  --                 |       CHECK IF THE DATA WAS INSERTED SUCCESSFULLY INTO THE LMS_AUTHORS TABLE.   			         *
  --                 |       HANDLE ANY EXCEPTIONS OR ERRORS DURING DATA INSERTION VERIFICATION.               	                 *
  --                 |                                                                                                        	 *
  --                 |  STEP 6:DUPLICATE AUTHOR HANDLING                                                                      	 *
  --		     |	     HANDLE THE CASE WHERE AN AUTHOR WITH THE SAME NAME ALREADY EXISTS.                                  *
  --		     |       LOG THE ERROR USING PR_LOG_AUTHOR_ERROR PROCEDURE.                                                  *
  --                 |                                                                                                        	 *
  --                 |  STEP 7:EXCEPTION HANDLING                                                                             	 *
  --                 |       HANDLE ANY OTHER EXCEPTIONS OR ERRORS THAT MAY OCCUR DURING THE PROCEDURE.                          *
  --		     |		         			                                                                 *
  --                 |   END OF PR_INSERT_AUTHOR PROCEDURE.                                                                      *
  --*****************************************************************************************************************************+
  -- ****************************************************************************************************************************+
  -- PPROCEDURE NAME            | PR_INSERT_AUTHOR                                                                               *
  -- AUTHOR                     | SR CONSULTANTS                                                                                 *
  --                            |                                                                                                *
  -- MODIFICATION LOG -----------------------------------------------------------------------------------------------------------+
  -- VER NO     |    DATE       |      AUTHOR       |         MODIFICATION                                                       *
  --------------+---------------+-------------------+----------------------------------------------------------------------------+
  -- 1.00       | 31-JUL-2021   |  RAJAT K. SWAIN   |     FIRST VERSION                                                          *
  -- 1.10       | 11-AUG-2021   |  RAJAT K. SWAIN   |     ENHANCEMENT: TRIMMING INPUT PARAMETERS FOR CONSISTENCY                 *
  -- 1.20       | 01-SEP-2021   |  RAJAT K. SWAIN   |     ENHANCEMENT: GENERATING EMAIL ID FROM NAME                             *
  -- 1.30       | 06-OCT-2022   |  RAJAT K. SWAIN   |     FNAME AND LNAME ARE MANDATORY PARAMETERS.                              *
  -- ****************************************************************************************************************************+

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
   /* BEGIN 1.30*/
  -- CHECK IF BOTH P_FNAME AND P_LNAME ARE NOT NULL
    IF P_FNAME IS NULL OR P_LNAME IS NULL THEN
    RAISE_APPLICATION_ERROR(-20001, 'BOTH P_FNAME AND P_LNAME ARE MANDATORY PARAMETERS AND CANNOT BE NULL.');
    V_ERRORMSG:= SQLERRM ;
    RETURN ;
    END IF;
   /* END 1.30*/
  -- CONVERT INPUT PARAMETERS TO UPPERCASE FOR CONSISTENCY
  /* BEGIN 1.20*/
  SELECT TRIM(P_FNAME), TRIM(P_LNAME) INTO VP_FNAME,VP_LNAME FROM DUAL;
  /* END 1.20*/
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
  /* BEGIN 1.30*/
  SELECT RTRIM(REPLACE(VP_FNAME, ' ', ''),'.'),TRIM(VP_LNAME) INTO V_MFNAME,V_MLNAME  FROM DUAL;
  /* END 1.30*/
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
  V_ERRORMSG:= SQLERRM ;
  -- LOG THE ERROR USING PR_LOG_ERROR (YOU NEED TO IMPLEMENT THIS PROCEDURE)
  PKG_LMS_ERRORHANDELER.PR_LOG_AUTHOR_ERROR(VP_FNAME, VP_LNAME, V_ERROR_CODE, V_ERRORMSG);
END PR_INSERT_AUTHOR;

PROCEDURE PR_INSERT_BOOK(
    P_FNAME        IN VARCHAR2,
    P_LNAME        IN VARCHAR2,
    P_TITLE        IN VARCHAR2,
    P_BOOK_GENER   IN VARCHAR2,
    P_PUBLISH_YEAR IN NUMBER
	 )
AS
 -- ************************************************************************************************************************
 --                 |                                                                                                      *
 -- PACKAGE HEADER  |  PKG_LMS_AUTOTRNS                                                                                    *
 --                 |                                                                                                      *
 -- PURPOSE         |  WORKFLOW HEADLINES FOR PR_INSERT_BOOK PROCEDURE                                                     *
 --                 |                                                                                                      *
 --                 |  STEP 1: PARAMETER CONVERSION AND VALIDATION                                                         *
 --                 |          CONVERT INPUT PARAMETERS TO UPPERCASE FOR CONSISTENCY.                                      *
 --                 |                                                                                                      *
 --                 |  STEP 2: CHECK AUTHOR EXISTENCE                                                                      *
 --                 |          CHECK IF THE AUTHOR EXISTS IN THE LMS_AUTHORS TABLE.                                        *
 --                 |          IF NOT, INSERT THE AUTHOR USING PR_INSERT_AUTHOR AND RETRIEVE THE GENERATED AUTHOR_ID.      *
 --                 |                                                                                                      *
 --                 |  STEP 3: GENERATE AUTHOR CODE                                                                        *
 --                 |          GENERATE THE AUTHOR_CODE BASED ON THE AUTHOR_ID.                                            *
 --                 |                                                                                                      *
 --                 |  STEP 4: CHECK DUPLICATE BOOK                                                                        *
 --                 |          CHECK IF A BOOK WITH THE SAME TITLE ALREADY EXISTS IN THE LMS_BOOKS TABLE.                  *
 --                 |          IF FOUND, UPDATE THE BOOK_NOS.                                                              *
 --                 |                                                                                                      *
 --                 |  STEP 5: BOOK INSERTION                                                                              *
 --                 |          GENERATE A UNIQUE BOOK_ID USING THE EXISTING SEQUENCE.                                      *
 --                 |          INSERT THE NEW BOOK'S DATA INTO THE LMS_BOOKS TABLE.                                        *
 --                 |          COMMIT THE TRANSACTION.                                                                     *
 --                 |                                                                                                      *
 --                 |  STEP 6: DATA INSERTION VERIFICATION                                                                 *
 --                 |          CHECK IF THE DATA WAS INSERTED SUCCESSFULLY INTO THE LMS_BOOKS TABLE.                       *
 --		    |	       HANDLE ANY EXCEPTIONS OR ERRORS DURING DATA INSERTION VERIFICATION.                         *
 --	            |                                                                                                      *
 --                 |  STEP 7: DUPLICATE BOOK HANDLING                                                                     *
 --                 |          HANDLE THE CASE WHERE A BOOK WITH THE SAME TITLE ALREADY EXISTS.                            *
 --                 |          LOG THE ERROR USING PR_LOG_BOOK_ERROR PROCEDURE.                                            *
 --	            |	                                                                                                   *
 --                 |  STEP 8: EXCEPTION HANDLING                                                                          *
 --                 |          HANDLE ANY OTHER EXCEPTIONS OR ERRORS THAT MAY OCCUR DURING THE PROCEDURE.                  *
 --                 |                                                                                                      *
 --                 |  END OF PR_INSERT_BOOK PROCEDURE.                                                                    *
 --                 |                                                                                                      *
 --*************************************************************************************************************************
 -- ************************************************************************************************************************
 -- PPROCEDURE NAME            | PR_INSERT_BOOK                                                                            *
 -- AUTHOR                     | SR CONSULTANTS                                                                            *
 --                            |                                                                                           *
 -- MODIFICATION LOG ------------------------------------------------------------------------------------------------------*
 -- VER NO     |    DATE       |      AUTHOR       |         MODIFICATION                                                  *
 --------------+---------------+-------------------+-----------------------------------------------------------------------*
 -- 1.00       | 31-JUL-2021   |  RAJAT K. SWAIN   |     FIRST VERSION                                                     *
 -- 1.10       | 17-SEP-2023   |  RAJAT K. SWAIN   |     ENHANCEMENT: TRIMMING INPUT PARAMETERS FOR CONSISTENCY            *
 -- 1.20       | 06-OCT-2022   |  RAJAT K. SWAIN   |     MANDATORY PARAMETERS CAN NOT NULL.                                *
 -- ************************************************************************************************************************

  -- DECLARE VARIABLES
  V_AUTHOR_ID    NUMBER;
  V_AUTHOR_CODE  VARCHAR2(25);
  V_BOOK_ID      NUMBER;
  V_ERROR_CODE   CONSTANT CHAR(14) := 'INSRT_BOOK_ERR';
  V_ERRORMSG     VARCHAR2(100)     := 'BOOK WITH THE SAME TITLE ALREADY EXISTS.';
  V_SUCCESS_FLAG NUMBER;
  VP_TITLE       VARCHAR2(100);
  VP_BOOK_GENER  VARCHAR2(100);
  VP_FNAME       VARCHAR2(50);  --1.10v
  VP_LNAME       VARCHAR2(50);  --1.10v
  
BEGIN
    /* BEGIN 1.20*/
 -- CHECK IF ANY OF THE REQUIRED PARAMETERS ARE NULL
  IF P_FNAME IS NULL OR P_LNAME IS NULL OR P_TITLE IS NULL OR P_BOOK_GENER IS NULL OR P_PUBLISH_YEAR IS NULL THEN
 -- HANDLE THE ERROR BY LOGGING IT
    RAISE_APPLICATION_ERROR(-20001, 'EVERY PARAMETERS ARE MANDATORY');
    V_ERRORMSG:= SQLERRM;
    RETURN;
  END IF;
    /* END 1.20*/
   /* BEGIN 1.10*/
  SELECT TRIM(P_TITLE), TRIM(P_BOOK_GENER) INTO VP_TITLE,VP_BOOK_GENER FROM DUAL;
   
  SELECT TRIM(P_FNAME), TRIM(P_LNAME) INTO VP_FNAME,VP_LNAME FROM DUAL;
  VP_FNAME := UPPER(VP_FNAME);
  VP_LNAME := UPPER(VP_LNAME);
  
   /* END 1.10*/
  VP_TITLE      :=UPPER(VP_TITLE);
  VP_BOOK_GENER :=UPPER(VP_BOOK_GENER);
  
  -- CHECK IF THE AUTHOR EXISTS OR INSERT THE AUTHOR IF NOT
  BEGIN
    SELECT AUTHOR_ID,
      AUTHOR_CODE
    INTO V_AUTHOR_ID,
      V_AUTHOR_CODE
    FROM LMS_AUTHORS
    WHERE FNAME = VP_FNAME			--UPPER(P_FNAME) 1.10v
    AND LNAME   = VP_LNAME;			--UPPER(P_LNAME) 1.10v
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    -- AUTHOR DOESN'T EXIST, SO INSERT THE AUTHOR
    PR_INSERT_AUTHOR(VP_FNAME, VP_LNAME);  --1.10v
    -- RETRIEVE THE GENERATED AUTHOR_ID
    SELECT AUTHOR_ID,
      AUTHOR_CODE
    INTO V_AUTHOR_ID,
      V_AUTHOR_CODE
    FROM LMS_AUTHORS
    WHERE FNAME = VP_FNAME         		--1.10v
    AND LNAME   = VP_LNAME;        		--1.10v
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
    WHERE TITLE = VP_TITLE ;             --1.10v;
  IF V_BOOK_ID IS NOT NULL THEN 
    UPDATE LMS_BOOKS SET BOOK_NOS = BOOK_NOS+1,
						 STATUS   ='Y'  --1.10v
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
    PKG_LMS_ERRORHANDELER.PR_LOG_BOOK_ERROR(VP_TITLE, V_ERROR_CODE, V_ERRORMSG);
  END IF;
EXCEPTION
WHEN OTHERS THEN
  -- HANDLE EXCEPTIONS APPROPRIATELY, E.G., LOG THE ERROR MESSAGE
  DBMS_OUTPUT.PUT_LINE('ERROR: ' || SQLERRM);
  V_ERRORMSG:= SQLERRM;
  -- LOG THE ERROR USING PR_LOG_ERROR (YOU NEED TO IMPLEMENT THIS PROCEDURE)
  PKG_LMS_ERRORHANDELER.PR_LOG_BOOK_ERROR(VP_TITLE, V_ERROR_CODE, V_ERRORMSG);
END PR_INSERT_BOOK;

PROCEDURE PR_INSERT_MEMBER(
    P_FNAME     IN LMS_MEMBERS.FNAME%TYPE,
    P_LNAME     IN LMS_MEMBERS.LNAME%TYPE,
    P_MOBILE_NO IN LMS_MEMBERS.MOBILE_NO%TYPE )
AS
  -- *********************************************************************************************************************+
  --                 |                                                                                                    *
  -- PACKAGE HEADER  | PKG_LMS_AUTOTRNS                                                                                   *
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
  --		             |						                                  			                                                *
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
  -- 1.30       | 06-OCT-2022   |  RAJAT K. SWAIN   |     FNAME AND LNAME ARE MANDATORY PARAMETERS.                       *
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
   /* BEGIN 1.30*/
  -- CHECK IF BOTH P_FNAME AND P_LNAME ARE NOT NULL
    IF P_FNAME IS NULL OR P_LNAME IS NULL THEN
    RAISE_APPLICATION_ERROR(-20001, 'BOTH FNAME AND LNAME ARE MANDATORY PARAMETERS AND CANNOT BE NULL.');
    V_ERRORMSG:= SQLERRM;
    END IF;
   /* END 1.30*/
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
  V_ERRORMSG:= SQLERRM ;
  PKG_LMS_ERRORHANDELER.PR_LOG_MEMBER_ERROR(P_FNAME,P_LNAME,V_ERROR_CODE,V_ERRORMSG );
END PR_INSERT_MEMBER;
PROCEDURE PR_BOOK_TRANSACTION(
    P_TITLE       IN LMS_BOOKS.TITLE%TYPE,
    P_FNAME       IN LMS_MEMBERS.FNAME%TYPE,
    P_LNAME       IN LMS_MEMBERS.LNAME%TYPE,
    P_MOBILE_NO   IN LMS_MEMBERS.MOBILE_NO%TYPE
) 
AS

  -- *****************************************************************************************************************************
  --                 |                                                                                                    	 *
  -- PACKAGE HEADER  |  PKG_LMS_AUTOTRNS                                                                                   	 *
  --                 |                                                                                                    	 *
  -- PURPOSE         |  WORKFLOW FOR PR_BOOK_TRANSACTION PROCEDURE                                                               *
  --                 |                                                                                                           *
  --                 |  STEP 1: PARAMETER CONVERSION AND VALIDATION                                                              *
  --                 |     CONVERT INPUT PARAMETERS TO UPPERCASE FOR CONSISTENCY.                                                *
  --                 |                                                                                                           *
  --                 |  STEP 2: RETRIEVE ISSUE DATE                                                                              *
  --                 |     GET THE CURRENT DATE AS THE ISSUE DATE.                                                               *
  --                 |                                                                                                           *
  --                 |  STEP 3: CHECK MEMBER EXISTENCE                                                                           *
  --                 |     CHECK IF THE MEMBER IS PRESENT IN THE LMS_MEMBERS TABLE.                                              *
  --                 |     IF NOT FOUND, INSERT MEMBER INFORMATION AND RETRIEVE THE GENERATED MEMBER_ID AND MEMBER_CODE.         *
  --                 |                                                                                                           *
  --                 |  STEP 4: CHECK BOOK EXISTENCE AND AVAILABILITY                                                            *
  --                 |     VERIFY IF THE REQUESTED BOOK IS PRESENT IN THE LMS_BOOKS TABLE AND AVAILABLE.                         *
  --                 |     IF FOUND BUT UNAVAILABLE, DISPLAY A MESSAGE AND UPDATE THE STATUS TO 'N'.                             *
  --                 |                                                                                                           *
  --                 |  STEP 5: BOOK TRANSACTION                                                                                 *
  --                 |     IF THE BOOK IS AVAILABLE, GENERATE A UNIQUE BORROW_ID USING THE EXISTING SEQUENCE.                    *
  --                 |     CREATE A NEW RECORD IN LMS_BORROWEDBOOKS TO RECORD THE BOOK TRANSACTION.                              *
  --                 |     SET ISSUE_DATE TO THE CURRENT DATE AND RETURN_DATE TO NULL INITIALLY.                                 *
  --                 |                                                                                                           *
  --                 |  STEP 6: DATA INSERTION VERIFICATION                                                                      *
  --                 |     CHECK IF THE DATA WAS INSERTED SUCCESSFULLY INTO LMS_BORROWEDBOOKS.                                   *
  --		     |	   IF SUCCESSFUL, DISPLAY A SUCCESS MESSAGE AND UPDATE THE BOOK COUNT.                                   *
  --		     |                                                                                                           *
  --                 |  STEP 7: UPDATE BOOK COUNT                                                                                *
  --                 |     DECREMENT THE BOOK_NOS FOR THE BORROWED BOOK.                                                         *
  --                 |                                                                                                           *
  --		     |	STEP 8: DISPLAY TRANSACTION SUMMARY                                                                      *
  --                 |     DISPLAY A SUMMARY OF THE BOOK TRANSACTION, INCLUDING THE SUCCESS MESSAGE.                             *
  --                 |                                                                                                           *
  --                 |  STEP 9: CHECK UPDATED BOOK COUNT                                                                         *
  --                 |     CHECK THE UPDATED BOOK COUNT AFTER THE BOOK IS ISSUED TO THE MEMBER.                                  *
  --                 |                                                                                                           *
  --                 |  STEP 10: EXCEPTION HANDLING                                                                              *
  --                 |      HANDLE EXCEPTIONS, SUCH AS MEMBER NOT FOUND, BOOK NOT FOUND, OR OTHER ERRORS.                        *
  --                 |      PROVIDE APPROPRIATE ERROR MESSAGES FOR DEBUGGING.                                                    *
  --                 |                                                                                                           *
  --                 |  END OF PR_BOOK_TRANSACTION PROCEDURE                                                                     *
  --                 |                                                                                                           *
  --		     |                                                                                                           *
  --*****************************************************************************************************************************+
  -- ****************************************************************************************************************************+
  -- PPROCEDURE NAME            | PR_BOOK_TRANSACTION                                                                            *
  -- AUTHOR                     | SR CONSULTANTS                                                                                 *
  --                            |                                                                                                *
  -- MODIFICATION LOG -----------------------------------------------------------------------------------------------------------+
  -- VER NO     |    DATE       |      AUTHOR       |         MODIFICATION                                                       *
  --------------+---------------+-------------------+----------------------------------------------------------------------------+
  -- 1.00       | 31-JUL-2021   |  RAJAT K. SWAIN   |     FIRST VERSION                                                          *
  -- 1.10       | 17-SEP-2021   |  RAJAT K. SWAIN   |     ENHANCING TO PREVENT DUPLICATE BOOK BORROWING                          *
  -- 1.20       | 19-SEP-2023   |  RAJAT K. SWAIN   |     ENHANCEMENT: TRIMMING INPUT PARAMETERS FOR CONSISTENCY                 *
  -- ****************************************************************************************************************************+
-- DECLARE VARIABLES
V_MEMBER_ID   NUMBER;
V_BOOK_ID     NUMBER;
V_MEMBER_CODE VARCHAR2(100);
V_BOOK_CNT    NUMBER :=0;
VP_FNAME      VARCHAR2(50);
VP_LNAME      VARCHAR2(50);
VP_TITLE LMS_BOOKS.TITLE%TYPE;
V_STATUS CHAR;
V_AUTHOR_CODE LMS_AUTHORS.AUTHOR_CODE%TYPE;
V_BORROW_ID    NUMBER;
V_ISSUE_DATE   DATE;
V_SUCCESS_FLAG NUMBER;
BEGIN
    /* BEGIN 1.20*/
  SELECT TRIM(P_TITLE),TRIM(P_FNAME),TRIM(P_LNAME) INTO VP_TITLE,VP_FNAME,VP_LNAME FROM DUAL;
  /* END 1.20*/

  -- CONVERT INPUT PARAMETERS TO UPPERCASE FOR CONSISTENCY
  VP_FNAME := UPPER(VP_FNAME);
  VP_LNAME := UPPER(VP_LNAME);
  VP_TITLE := UPPER(VP_TITLE);
  -- RETRIEVE THE CURRENT DATE AS THE ISSUE DATE
  SELECT TO_CHAR(SYSDATE, 'DD-MON-YYYY')
  INTO V_ISSUE_DATE
  FROM DUAL;
  -- CHECK IF THE MEMBER IS PRESENT IN LMS_MEMBERS.
  BEGIN
    SELECT MEMBER_ID,
      MEMBER_CODE
    INTO V_MEMBER_ID,
      V_MEMBER_CODE
    FROM LMS_MEMBERS
    WHERE FNAME = VP_FNAME
    AND LNAME   = VP_LNAME;
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    -- MEMBER NOT FOUND, INSERT THE MEMBER INFO.
    PR_INSERT_MEMBER(VP_FNAME, VP_LNAME, P_MOBILE_NO);
    -- RETRIEVE THE GENERATED MEMBER_ID.
    SELECT MEMBER_ID,
      MEMBER_CODE
    INTO V_MEMBER_ID,
      V_MEMBER_CODE
    FROM LMS_MEMBERS
    WHERE FNAME = VP_FNAME
    AND LNAME   = VP_LNAME;
  END;
  -- CHECK IF THE BOOK TITLE IS PRESENT IN LMS_BOOKS AND AVAILABLE.
  BEGIN
    SELECT BOOK_ID,
      AUTHOR_CODE,
      STATUS
    INTO V_BOOK_ID,
      V_AUTHOR_CODE,
      V_STATUS
    FROM LMS_BOOKS
    WHERE TITLE = VP_TITLE;
    -- CHECK THE BOOK_COUNT WITH THE LOGIC OF STATUS='Y'
    IF V_STATUS = 'Y' THEN
      SELECT BOOK_NOS INTO V_BOOK_CNT FROM LMS_BOOKS WHERE TITLE = VP_TITLE;
      --IF THE BOOK_COUNT IS ZERO THEN IT SHOULD BE UPDATE THE STATUS AND GIVE AND MESSAGE
      IF V_BOOK_CNT = 0 THEN
        UPDATE LMS_BOOKS SET STATUS = 'N' WHERE BOOK_ID = V_BOOK_ID;
        DBMS_OUTPUT.PUT_LINE ('THE BOOK :--> '||'"'||VP_TITLE ||'"'||'  STATUS WAS Y SO WE UPDATED TO  N.......!');
        COMMIT;
        -- PRINT THE HEADING AND COUNT
        DBMS_OUTPUT.PUT_LINE ('-------------------------------------------------------------------------------------------------');
        DBMS_OUTPUT.PUT_LINE ('THE BOOK WITH THIS TITLE :-->'||'"'||VP_TITLE ||'"'||' IS CURRENTLY NOT AVAILABLE IN THE LIBRARY.');
        DBMS_OUTPUT.PUT_LINE ('--------------------------------------------------------------------------------------------------');
        -- PRINT THE HEADING AND COUNT
        DBMS_OUTPUT.PUT_LINE ('NUMBER OF AVAILABLE BOOKS FOR TITLE :->' ||'"'||VP_TITLE ||'"'|| ':--> ' || V_BOOK_CNT||' '||'nos');
      END IF;
    END IF;
    IF V_STATUS = 'N' THEN
      SELECT BOOK_NOS INTO V_BOOK_CNT FROM LMS_BOOKS WHERE TITLE = VP_TITLE;
      -- PRINT THE HEADING AND COUNT
      DBMS_OUTPUT.PUT_LINE ('======================================================================================================');
      DBMS_OUTPUT.PUT_LINE ('THE BOOK WITH THIS TITLE :-->'||'"'||VP_TITLE ||'"'||' IS CURRENTLY NOT AVAILABLE IN THE LIBRARY.');
      DBMS_OUTPUT.PUT_LINE ('NUMBER OF AVAILABLE BOOKS FOR TITLE :->' || '"'||VP_TITLE ||'"'|| ':--> ' || V_BOOK_CNT||' '||'nos');
      DBMS_OUTPUT.PUT_LINE ('======================================================================================================');
    END IF;
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    -- BOOK NOT FOUND; HANDLE THIS CASE
    DBMS_OUTPUT.PUT_LINE ('-----------------------------------------------------------------------------------------');
    DBMS_OUTPUT.PUT_LINE ('THE BOOK WITH THIS TITLE '||'"'||VP_TITLE ||'"'||'  IS NOT FOUND IN THE LIBRARY.');
    DBMS_OUTPUT.PUT_LINE ('------------------------------------------------------------------------------------------');
  WHEN OTHERS THEN
    -- HANDLE OTHER EXCEPTIONS AS NEEDED
    DBMS_OUTPUT.PUT_LINE('ERROR: ' || SQLERRM);
  END;
  
  /*BEGIN 1.10 */
    -- CHECK IF THE MEMBER HAS ALREADY BORROWED THE SAME BOOK (TITLE).
  BEGIN
    SELECT 1
    INTO V_SUCCESS_FLAG
    FROM LMS_BORROWEDBOOKS BB
    JOIN LMS_BOOKS B ON BB.BOOK_ID = B.BOOK_ID
    WHERE BB.MEMBER_ID = V_MEMBER_ID
    AND B.TITLE = VP_TITLE
    AND BB.RETURN_DATE IS NULL;

    -- IF THE SELECT STATEMENT SUCCEEDS, IT MEANS THE MEMBER HAS ALREADY BORROWED THE SAME BOOK.
    -- YOU CAN HANDLE THIS CASE WITH APPROPRIATE LOGIC OR RAISE AN EXCEPTION.
    -- FOR EXAMPLE, YOU CAN RAISE AN EXCEPTION OR DISPLAY A MESSAGE.
    -- RAISE_APPLICATION_ERROR(-20001, 'MEMBER ' || V_MEMBER_CODE || ' HAS ALREADY BORROWED A COPY OF ' || VP_TITLE);
    DBMS_OUTPUT.PUT_LINE('MEMBER ' || V_MEMBER_CODE || ' HAS ALREADY BORROWED A COPY OF ' || VP_TITLE);
    RETURN;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      -- THIS MEANS THE MEMBER DOES NOT HAVE AN OPEN TRANSACTION FOR THE SAME BOOK, WHICH IS WHAT WE WANT.
      NULL; -- NO NEED TO TAKE ANY ACTION.
  END;
   /*END 1.10 */
   
  -- IF THE BOOK IS AVAILABLE, PROCEED WITH THE TRANSACTION
  IF V_STATUS = 'Y' AND V_BOOK_CNT > 0 THEN
    -- GENERATE A UNIQUE BORROW_ID USING THE EXISTING SEQUENCE
    SELECT BORROW_ID_SEQ.NEXTVAL
    INTO V_BORROW_ID
    FROM DUAL;
    -- CREATE A NEW RECORD IN LMS_BORROWEDBOOKS TO RECORD THE BOOK TRANSACTION
    INSERT
    INTO LMS_BORROWEDBOOKS
      (
        BORROW_ID,
        MEMBER_ID,
        BOOK_ID,
        AUTHOR_CODE,
        MEMBER_CODE,
        ISSUE_DATE,
        RETURN_DATE
      )
      VALUES
      (
        V_BORROW_ID,
        V_MEMBER_ID,
        V_BOOK_ID,
        V_AUTHOR_CODE, -- YOU CAN SET AUTHOR_CODE AS NEEDED
        V_MEMBER_CODE,
        V_ISSUE_DATE, -- SET ISSUE_DATE TO THE CURRENT DATE
        NULL          -- SET RETURN_DATE TO NULL INITIALLY
      );
    COMMIT;
    -- CHECK IF THE DATA WAS INSERTED SUCCESSFULLY
    SELECT 1
    INTO V_SUCCESS_FLAG
    FROM DUAL
    WHERE EXISTS
      ( SELECT 1 FROM LMS_BORROWEDBOOKS WHERE BORROW_ID = V_BORROW_ID
      );
    -- DISPLAY A SUCCESS MESSAGE
    IF V_SUCCESS_FLAG = 1 THEN
      DBMS_OUTPUT.PUT_LINE ('TRANSACTION SUMMARY...');
      DBMS_OUTPUT.PUT_LINE ('**********************************************************************');
      DBMS_OUTPUT.PUT_LINE ('BOOK TRANSACTION SUCCESSFUL. ENJOY YOUR READING! '||VP_TITLE);
      DBMS_OUTPUT.PUT_LINE ('**********************************************************************');
      -- UPDATE BOOK_COUNT LOGIC (BOOK_NOS-1).
      UPDATE LMS_BOOKS
      SET BOOK_NOS  = V_BOOK_CNT - 1
      WHERE BOOK_ID = V_BOOK_ID;
      COMMIT;
    END IF;
    --CHECK THE BOOK_COUNT AFTER ISSUED TO MEMBER
    SELECT BOOK_NOS
    INTO V_BOOK_CNT
    FROM LMS_BOOKS
    WHERE TITLE = VP_TITLE;
    DBMS_OUTPUT.PUT_LINE ('-------------------------------------------------------------------------------');
    DBMS_OUTPUT.PUT_LINE('NUMBER OF AVAILABLE BOOKS FOR TITLE :->' || '"'||VP_TITLE ||'"'|| ':--> ' || V_BOOK_CNT||' '||'nos');
    DBMS_OUTPUT.PUT_LINE ('--------------------------------------------------------------------------------');
  END IF;
EXCEPTION
WHEN OTHERS THEN
  DBMS_OUTPUT.PUT_LINE('AN ERROR OCCURRED: ' || SQLERRM);
END PR_BOOK_TRANSACTION;

PROCEDURE PR_RETURN_BOOK(
    P_BORROW_ID IN LMS_BORROWEDBOOKS.BORROW_ID%TYPE,
    P_MESSAGE   OUT VARCHAR2)
AS

 -- *********************************************************************************************************************+
 --                 |                                                                                                    *
 -- PACKAGE HEADER  | PKG_LMS_AUTOTRNS                                                                                   *
 --                 |                                                                                                    *
 -- PURPOSE         | WORKFLOW FOR PR_BOOK_TRANSACTION PROCEDURE                                                         *
 --                 | STEP 1: RETRIEVE BORROW INFORMATION                                                                *
 --	            |         RETRIEVE INFORMATION ABOUT THE BORROW RECORD USING THE PROVIDED P_BORROW_ID.               *
 --	            |         FETCH DATA SUCH AS V_BORROW_ID, V_BOOK_ID, V_MEMBER_ID, V_RETURN_DATE, V_FNAME,            *
 --	            |         V_LNAME, AND V_TITLE.                                                                      *
 --                 |                                                                                                    *
 --                 | STEP 2: CHECK IF BOOK IS ALREADY RETURNED                                                          *
 --	            |         CHECK IF THE BOOK ASSOCIATED WITH THE BORROW RECORD HAS ALREADY BEEN RETURNED.             *
 --	            |         IF THE BOOK IS RETURNED, DISPLAY A MESSAGE WITH DETAILS INCLUDING THE RETURN DATE          *
 --	            |         AND MEMBER'S NAME.                                                                         *
 --                 | STEP 3: UPDATE BORROWED BOOK RECORD                                                                *
 --	            |         IF THE BOOK IS NOT RETURNED, SET THE V_RETURN_DATE TO THE CURRENT DATE.                    *
 --	            |         UPDATE THE BORROWED BOOK RECORD WITH THE RETURN DATE.                                      *
 --	            |                                                                                                    *
 -- 		    | STEP 4: UPDATE BOOK STATUS                                                                         *
 --		    | 	      GET THE CURRENT BOOK STATUS (V_BOOK_STATUS) AND THE NUMBER OF AVAILABLE COPIES (V_BOOK_CNT)*
 --		    | 	      FOR THE RETURNED BOOK.                                                                     *
 --		    | 	     IF THE BOOK WAS MARKED AS 'BORROWED', UPDATE ITS STATUS TO 'AVAILABLE' AND                  *
 --		    | 	     INCREMENT THE NUMBER OF AVAILABLE COPIES.                                                   *
 --		    |                                                                                                    *
 --		    | STEP 5: COMMIT TRANSACTION                                                                         *
 --		    | 	      COMMIT THE TRANSACTION TO SAVE THE CHANGES TO THE DATABASE.                                *
 --		    | STEP 6: FINALIZE MESSAGE                                                                           *
 --		    | 	      DISPLAY A SUCCESS MESSAGE INDICATING THAT THE BOOK HAS BEEN SUCCESSFULLY RETURNED,         *
 --		    | 	      ALONG WITH BOOK AND MEMBER DETAILS.                                                        *
 --		    | 		                                                                                         *
 --		    | EXCEPTION HANDLING:                                                                                *
 --		    | 	      HANDLE SCENARIOS WHERE THE BORROW RECORD IS NOT FOUND.                                     *
 --		    | 	      HANDLE CASES OF INVALID INPUT OR INVALID BORROW ID.                                        *
 --		    | 	      HANDLE ANY OTHER UNEXPECTED ERRORS AND DISPLAY ERROR MESSAGES.                             *
 --		    |                                                                                                    *
 --                 |                                                                                                    *
 --		    |    	                                                		                         *
 -- **********************************************************************************************************************
 -- *********************************************************************************************************************+
 -- PPROCEDURE NAME            | PR_RETURN_BOOK                                                                          *
 -- AUTHOR                     | SR CONSULTANTS                                                                          *
 --                            |                                                                                         *
 -- MODIFICATION LOG ----------------------------------------------------------------------------------------------------+
 -- VER NO     |    DATE       |      AUTHOR       |         MODIFICATION                                                *
 --------------+---------------+-------------------+---------------------------------------------------------------------+
 -- 1.00       | 31-JUL-2021   |  RAJAT K. SWAIN   |     FIRST VERSION                                                   *
 -- *********************************************************************************************************************+

  -- DECLARE VARIABLES
  V_FNAME VARCHAR2(100);
  V_LNAME VARCHAR2(100);
  V_TITLE VARCHAR2(100);
  V_BORROW_ID LMS_BORROWEDBOOKS.BORROW_ID%TYPE;
  V_BOOK_ID LMS_BORROWEDBOOKS.BOOK_ID%TYPE;
  V_MEMBER_ID LMS_BORROWEDBOOKS.MEMBER_ID%TYPE;
  V_RETURN_DATE DATE;
  V_BOOK_STATUS CHAR;
  V_BOOK_CNT LMS_BOOKS.BOOK_NOS%TYPE;
BEGIN
  -- RETRIEVE INFORMATION ABOUT THE BORROW RECORD
SELECT LMB.BORROW_ID,
  LMB.BOOK_ID,
  LMB.MEMBER_ID,
  LMB.RETURN_DATE,
  LMM.FNAME,
  LMM.LNAME,
  LBB.TITLE
INTO V_BORROW_ID,
  V_BOOK_ID,
  V_MEMBER_ID,
  V_RETURN_DATE,
  V_FNAME,
  V_LNAME,
  V_TITLE
FROM LMS_BORROWEDBOOKS LMB ,
  LMS_MEMBERS LMM,
  LMS_BOOKS LBB
WHERE LMB.MEMBER_ID=LMM.MEMBER_ID
AND LMB.MEMBER_CODE=LMM.MEMBER_CODE
AND LMB.BOOK_ID    =LBB.BOOK_ID
AND LMB.BORROW_ID  = P_BORROW_ID;
  -- CHECK IF THE BOOK IS ALREADY RETURNED
  IF V_RETURN_DATE IS NOT NULL THEN
    P_MESSAGE := 'THIS BOOK :-->'||V_TITLE||' HAS ALREADY BEEN RETURNED BY THE  '||'"'||V_FNAME||'  '||V_LNAME ||'"'||'  '|| TO_CHAR(V_RETURN_DATE, 'DD-MON-YYYY');
    DBMS_OUTPUT.PUT_LINE('***********************************************************************************************************');
    DBMS_OUTPUT.PUT_LINE(P_MESSAGE);
    DBMS_OUTPUT.PUT_LINE('***********************************************************************************************************');
  ELSE
    -- SET THE RETURN DATE TO THE CURRENT DATE
    SELECT TO_CHAR(SYSDATE,'DD-MON-YYYY')
    INTO V_RETURN_DATE
    FROM DUAL;
    -- UPDATE THE BORROWED BOOK RECORD WITH THE RETURN DATE
    UPDATE LMS_BORROWEDBOOKS
    SET RETURN_DATE = V_RETURN_DATE
    WHERE BORROW_ID = P_BORROW_ID;
    -- GET THE CURRENT BOOK STATUS
    SELECT STATUS,
      BOOK_NOS
    INTO V_BOOK_STATUS,
      V_BOOK_CNT
    FROM LMS_BOOKS
    WHERE BOOK_ID = V_BOOK_ID;
    -- IF THE BOOK STATUS WAS 'BORROWED', UPDATE IT TO 'AVAILABLE'
    IF V_BOOK_STATUS = 'N' AND V_BOOK_CNT =0 THEN
      UPDATE LMS_BOOKS
      SET STATUS        = 'Y',
        BOOK_NOS        = BOOK_NOS + 1
      WHERE BOOK_ID     = V_BOOK_ID;
    ELSIF V_BOOK_STATUS = 'Y' AND V_BOOK_CNT >0 THEN
      UPDATE LMS_BOOKS
      SET STATUS    = 'Y',
        BOOK_NOS    = BOOK_NOS + 1
      WHERE BOOK_ID = V_BOOK_ID;
    END IF;
    -- COMMIT THE TRANSACTION
    COMMIT;
    P_MESSAGE := 'BOOK WITH-->'|| V_TITLE|| ' AND THIS MEMBER ' ||'"'||V_FNAME||'  '||V_LNAME ||'"'|| ' HAS BEEN SUCCESSFULLY RETURNED.';
    DBMS_OUTPUT.PUT_LINE('##################################################################################');
    DBMS_OUTPUT.PUT_LINE(P_MESSAGE);
    DBMS_OUTPUT.PUT_LINE('##################################################################################');
  END IF;
EXCEPTION
WHEN NO_DATA_FOUND THEN
  DBMS_OUTPUT.PUT_LINE('BORROW RECORD NOT FOUND.');
  P_MESSAGE :='BORROW RECORD NOT FOUND.';
WHEN VALUE_ERROR THEN
  P_MESSAGE :='INVALID INPUT. PLEASE PROVIDE A VALID BORROW ID.';
  DBMS_OUTPUT.PUT_LINE('xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx');
  DBMS_OUTPUT.PUT_LINE (P_MESSAGE);
  DBMS_OUTPUT.PUT_LINE('xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx');
WHEN OTHERS THEN
  DBMS_OUTPUT.PUT_LINE('AN ERROR OCCURRED: ' || SQLERRM);
END PR_RETURN_BOOK;


END PKG_LMS_AUTOTRNS;
/
