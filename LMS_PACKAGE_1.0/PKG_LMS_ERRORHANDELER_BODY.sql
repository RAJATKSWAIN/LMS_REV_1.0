CREATE OR REPLACE PACKAGE BODY PKG_LMS_ERRORHANDELER
AS
  -- ***********************************************************************************************************************+
  --                  |                                                                                                     *
  -- PACKAGE HEADER   | PKG_LMS_ERRORHANDELER BOBY                                                                          *
  --                  |                                                                                                     *
  -- PURPOSE          | PKG_LMS_ERRORHANDELER IS DESIGNED TO HANDLE AND LOG ERRORS IN A LIBRARY MANAGEMENT SYSTEM (LMS).    *
  --                  |                                                                                                     *
  --                  | DEFINES TWO ERROR LOGGING PROCEDURES: PR_LOG_AUTHOR_ERROR AND PR_LOG_BOOK_ERROR.                    *
  --                  | ====================================================================================================+
  --                  | PR_LOG_AUTHOR_ERROR PROCEDURE:                                                                      *
  --                  |   1.LOGS ERRORS RELATED TO AUTHORS.                                                                 *
  --                  |   2.INPUTS INCLUDE AUTHOR'S FIRST AND LAST NAME, ERROR CODE, AND ERROR MESSAGE.                     *
  --                  |   3.GENERATES A UNIQUE ERROR ID FOR EACH ERROR.                                                     *
  --                  |   4.USES AUTONOMOUS TRANSACTIONS FOR ERROR LOGGING.                                                 *
  --                  |   5.RECORDS INCLUDE AUTHOR DETAILS, ERROR MESSAGE, TIMESTAMP, AND ERROR CODE.                       *
  --                  | PR_LOG_BOOK_ERROR PROCEDURE:                                                                        *
  --                  |   1.LOGS ERRORS RELATED TO BOOKS.                                                                   *
  --                  |   2.INPUTS INCLUDE BOOK TITLE, ERROR CODE, AND ERROR MESSAGE.                                       *
  --                  |   3.SIMILAR STRUCTURE TO PR_LOG_AUTHOR_ERROR.                                                       *
  --                  |   3.AUTONOMOUS TRANSACTIONS:                                                                        *
  --                  | PROCEDURE TO LOG ERRORS FOR MEMBERS:                                                                *
  --                  |   1.LOGS ERRORS RELATED TO MEMBERS.                                                                 *
  --                  |   2.INPUTS INCLUDE MEMBER'S FIRST AND LAST NAME, ERROR CODE, AND ERROR MESSAGE.                     *
  --                  |   3.GENERATES A UNIQUE ERROR ID FOR EACH ERROR.                                                     *
  --                  |   4.USES AUTONOMOUS TRANSACTIONS FOR ERROR LOGGING.                                                 *
  --                  |   5.RECORDS INCLUDE MEMBER DETAILS, ERROR MESSAGE, TIMESTAMP, AND ERROR CODE.                       *
  --                  |                                                                                                     *
  --                  |                                                                                                     *
  --                  |                                                                                                     *
  -- ***********************************************************************************************************************+
  -- PPROCEDURE NAMES           | PR_LOG_AUTHOR_ERROR AND PR_LOG_BOOK_ERROR.                                                *
  -- AUTHOR                     | SR CONSULTANTS                                                                            *
  --                            |                                                                                           *
  -- MODIFICATION LOG ------------------------------------------------------------------------------------------------------+
  -- VER NO     |    DATE       |      AUTHOR       |         MODIFICATION                                                  *
  --------------+---------------+-------------------+-----------------------------------------------------------------------+
  --            |               |                   |                                                                       *
  -- ***********************************************************************************************************************+
  -- DECLARE VARIABLES
  V_SYSTIME TIMESTAMP;
  -- PROCEDURE TO LOG ERRORS FOR AUTHORS
  PROCEDURE PR_LOG_AUTHOR_ERROR(
      P_FNAME         IN VARCHAR2,
      P_LNAME         IN VARCHAR2,
      P_ERROR_CODE    IN CHAR,
      P_ERROR_MESSAGE IN VARCHAR2 )
  IS
    V_ERROR_ID NUMBER;
    V_SYSTIME  TIMESTAMP;
    PRAGMA AUTONOMOUS_TRANSACTION;
  BEGIN
    SELECT TO_CHAR(SYSTIMESTAMP, 'DD-MON-YYYY HH:MI:SS AM')
    INTO V_SYSTIME
    FROM DUAL;
    SELECT ERROR_ID_SEQ.NEXTVAL INTO V_ERROR_ID FROM DUAL;
    INSERT
    INTO LMS_ERRORLOGS
      (
        ERROR_ID,
        ERROR_MESSAGE,
        ERROR_TIMESTAMP,
        ERROR_CODE
      )
      VALUES
      (
        V_ERROR_ID,
        P_FNAME
        || ' '
        || P_LNAME
        || ':--> '
        || P_ERROR_MESSAGE,
        V_SYSTIME,
        P_ERROR_CODE
        || V_ERROR_ID
      );
    COMMIT;
  END PR_LOG_AUTHOR_ERROR;
-- PROCEDURE TO LOG ERRORS FOR BOOKS
  PROCEDURE PR_LOG_BOOK_ERROR
    (
      P_BOOK_TITLE    IN VARCHAR2,
      P_ERROR_CODE    IN CHAR,
      P_ERROR_MESSAGE IN VARCHAR2
    )
  IS
    V_ERROR_ID NUMBER;
    V_SYSTIME  TIMESTAMP;
    PRAGMA AUTONOMOUS_TRANSACTION;
  BEGIN
    SELECT TO_CHAR(SYSTIMESTAMP, 'DD-MON-YYYY HH:MI:SS AM')
    INTO V_SYSTIME
    FROM DUAL;
    SELECT ERROR_ID_SEQ.NEXTVAL INTO V_ERROR_ID FROM DUAL;
    INSERT
    INTO LMS_ERRORLOGS
      (
        ERROR_ID,
        ERROR_MESSAGE,
        ERROR_TIMESTAMP,
        ERROR_CODE
      )
      VALUES
      (
        V_ERROR_ID,
        P_BOOK_TITLE
        || ':--> '
        || P_ERROR_MESSAGE,
        V_SYSTIME,
        P_ERROR_CODE
        || V_ERROR_ID
      );
    COMMIT;
  END PR_LOG_BOOK_ERROR;
-- PROCEDURE TO LOG ERRORS FOR MEMBERS
  PROCEDURE PR_LOG_MEMBER_ERROR
    (
      P_FNAME         IN VARCHAR2,
      P_LNAME         IN VARCHAR2,
      P_ERROR_CODE    IN CHAR,
      P_ERROR_MESSAGE IN VARCHAR2
    )
  IS
    V_ERROR_ID NUMBER;
    V_SYSTIME  TIMESTAMP;
    PRAGMA AUTONOMOUS_TRANSACTION;
  BEGIN
    SELECT TO_CHAR(SYSTIMESTAMP, 'DD-MON-YYYY HH:MI:SS AM')
    INTO V_SYSTIME
    FROM DUAL;
    SELECT ERROR_ID_SEQ.NEXTVAL INTO V_ERROR_ID FROM DUAL;
    INSERT
    INTO LMS_ERRORLOGS
      (
        ERROR_ID,
        ERROR_MESSAGE,
        ERROR_TIMESTAMP,
        ERROR_CODE
      )
      VALUES
      (
        V_ERROR_ID,
        P_FNAME
        || ' '
        || P_LNAME
        || ':--> '
        || P_ERROR_MESSAGE,
        V_SYSTIME,
        P_ERROR_CODE
        || V_ERROR_ID
      );
    COMMIT;
  END PR_LOG_MEMBER_ERROR;
END PKG_LMS_ERRORHANDELER;