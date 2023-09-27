CREATE OR REPLACE PROCEDURE PR_BOOK_TRANSACTION(
    P_TITLE       IN LMS_BOOKS.TITLE%TYPE,
    P_FNAME       IN LMS_MEMBERS.FNAME%TYPE,
    P_LNAME       IN LMS_MEMBERS.LNAME%TYPE,
    P_MOBILE_NO   IN LMS_MEMBERS.MOBILE_NO%TYPE
) 
AS
  -- *********************************************************************************************************************+
  --                 |                                                                                                    *
  -- PACKAGE HEADER  |                                                                                                    *
  --                 |                                                                                                    *
  -- PURPOSE         | THIS SCRIPT INSERTS BOOK TRANSACTION  INFORMATION INTO THE LMS_AUTHORS TABLE.                      *
  --                 | CHECK MEMBER:                                                                                      *
  --                 | 		IT CHECKS IF THE MEMBER IS PRESENT IN THE LMS_MEMBERS TABLE.                                  *
  --                 |  	IF NOT FOUND, IT INSERTS MEMBER INFORMATION AND RETRIEVES THE GENERATED MEMBER ID AND CODE.   *
  --                 |  	                                                                                    	      *
  --                 | CHECK BOOKS:                                                                                       *
  --                 | 		VERIFIES IF THE REQUESTED BOOK IS PRESENT IN THE LMS_BOOKS TABLE AND AVAILABLE.               *
  --                 | 		IF THE BOOK IS UNAVAILABLE, IT DISPLAYS A MESSAGE AND MARKS IT AS 'N'.                        *
  --                 | 		RETRIEVES BOOK DETAILS, INCLUDING THE BOOK ID, AUTHOR CODE, AND AVAILABLE BOOK COUNT.         *
  --                 | 			                                                                                          *
  --                 | TRANSACTION:                                                                                       *
  --                 | 		IF THE BOOK IS AVAILABLE, A UNIQUE BORROW ID IS GENERATED.                                    *
  --                 | 		A NEW RECORD IS INSERTED INTO LMS_BORROWEDBOOKS TO RECORD THE TRANSACTION.                    *
  --                 | 		THE TRANSACTION IS COMMITTED TO SAVE THE DATA.                                                *
  --                 |                                                                                                    *
  --                 | SUCCESS FLAG:                                                                                      *
  --                 | 		CHECKS IF THE DATA INSERTION INTO LMS_BORROWEDBOOKS WAS SUCCESSFUL.                           *
  --                 | 		IF SUCCESSFUL, IT DISPLAYS A SUCCESS MESSAGE AND UPDATES THE BOOK COUNT.                      *
  --                 |                                                                                                    *
  --                 | EXCEPTION HANDLING:                                                                                *
  --                 | 		HANDLES EXCEPTIONS LIKE MEMBER NOT FOUND, BOOK NOT FOUND, OR OTHER ERRORS.                    *
  --                 | 		PROVIDES APPROPRIATE ERROR MESSAGES FOR DEBUGGING.                                            *
  --                 |                                                                                                    *
  --				 |							                                       			                          *
  -- *********************************************************************************************************************+
  -- *********************************************************************************************************************+
  -- PPROCEDURE NAME            | PR_BOOK_TRANSACTION                                                                     *
  -- AUTHOR                     | SR CONSULTANTS                                                                          *
  --                            |                                                                                         *
  -- MODIFICATION LOG ----------------------------------------------------------------------------------------------------+
  -- VER NO     |    DATE       |      AUTHOR       |         MODIFICATION                                                *
  --------------+---------------+-------------------+---------------------------------------------------------------------+
  -- 1.00       | 31-JUL-2021   |  RAJAT K. SWAIN   |     FIRST VERSION                                                   *
  -- 1.10       | 31-AUG-2021   |  RAJAT K. SWAIN   |     ENHANCING TO PREVENT DUPLICATE BOOK BORROWING                   *
  -- *********************************************************************************************************************+
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
  -- CONVERT INPUT PARAMETERS TO UPPERCASE FOR CONSISTENCY
  VP_FNAME := UPPER(P_FNAME);
  VP_LNAME := UPPER(P_LNAME);
  VP_TITLE := UPPER(P_TITLE);
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
/
