CREATE OR REPLACE PROCEDURE PR_RETURN_BOOK(
    P_BORROW_ID IN LMS_BORROWEDBOOKS.BORROW_ID%TYPE,
    P_MESSAGE   OUT VARCHAR2)
AS
 -- *********************************************************************************************************************+
 --                 |                                                                                                    *
 -- PACKAGE HEADER  | PKG_LMS_AUTOTRNS                                                                                   *
 --                 |                                                                                                    *
 -- PURPOSE         | WORKFLOW FOR PR_BOOK_TRANSACTION PROCEDURE                                                         *
 --                 | STEP 1: RETRIEVE BORROW INFORMATION                                                                *
 --	                |         RETRIEVE INFORMATION ABOUT THE BORROW RECORD USING THE PROVIDED P_BORROW_ID.               *
 --	                |         FETCH DATA SUCH AS V_BORROW_ID, V_BOOK_ID, V_MEMBER_ID, V_RETURN_DATE, V_FNAME,            *
 --	                |         V_LNAME, AND V_TITLE.                                                                      *
 --                 |                                                                                                    *
 --                 | STEP 2: CHECK IF BOOK IS ALREADY RETURNED                                                          *
 --	                |         CHECK IF THE BOOK ASSOCIATED WITH THE BORROW RECORD HAS ALREADY BEEN RETURNED.             *
 --	                |         IF THE BOOK IS RETURNED, DISPLAY A MESSAGE WITH DETAILS INCLUDING THE RETURN DATE          *
 --	                |         AND MEMBER'S NAME.                                                                         *
 --                 | STEP 3: UPDATE BORROWED BOOK RECORD                                                                *
 --	                |         IF THE BOOK IS NOT RETURNED, SET THE V_RETURN_DATE TO THE CURRENT DATE.                    *
 --	                |         UPDATE THE BORROWED BOOK RECORD WITH THE RETURN DATE.                                      *
 --	                |                                                                                                    *
 -- 				| STEP 4: UPDATE BOOK STATUS                                                                         *
 --					| 		  GET THE CURRENT BOOK STATUS (V_BOOK_STATUS) AND THE NUMBER OF AVAILABLE COPIES (V_BOOK_CNT)*
 --					| 		  FOR THE RETURNED BOOK.                                                                     *
 --					| 		  IF THE BOOK WAS MARKED AS 'BORROWED', UPDATE ITS STATUS TO 'AVAILABLE' AND                 *
 --					| 		  INCREMENT THE NUMBER OF AVAILABLE COPIES.                                                  *
 --				    |                                                                                                    *
 --					| STEP 5: COMMIT TRANSACTION                                                                         *
 --					| 		  COMMIT THE TRANSACTION TO SAVE THE CHANGES TO THE DATABASE.                                *
 --					| STEP 6: FINALIZE MESSAGE                                                                           *
 --					| 		  DISPLAY A SUCCESS MESSAGE INDICATING THAT THE BOOK HAS BEEN SUCCESSFULLY RETURNED,         *
 --					| 		  ALONG WITH BOOK AND MEMBER DETAILS.                                                        *
 --					| 		                                                                                             *
 --					| EXCEPTION HANDLING:                                                                                *
 --					| 		  HANDLE SCENARIOS WHERE THE BORROW RECORD IS NOT FOUND.                                     *
 --					| 		  HANDLE CASES OF INVALID INPUT OR INVALID BORROW ID.                                        *
 --					| 		  HANDLE ANY OTHER UNEXPECTED ERRORS AND DISPLAY ERROR MESSAGES.                             *
 --				    |                                                                                                    *
 --                 |                                                                                                    *
 --				    |               	                                                		                         *
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
  V_BOOK_ID   LMS_BORROWEDBOOKS.BOOK_ID%TYPE;
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
  P_MESSAGE :='INVALID  INPUT. PLEASE PROVIDE A VALID BORROW ID.';
  DBMS_OUTPUT.PUT_LINE('xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx');
  DBMS_OUTPUT.PUT_LINE (P_MESSAGE);
  DBMS_OUTPUT.PUT_LINE('xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx');
WHEN OTHERS THEN
  DBMS_OUTPUT.PUT_LINE('AN ERROR OCCURRED: ' || SQLERRM);
END PR_RETURN_BOOK;
/
