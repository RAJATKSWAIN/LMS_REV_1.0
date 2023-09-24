create or replace PACKAGE PKG_LMS_ERRORHANDELER AS
-- **************************************************************************************************************************
  --                  |                                                                                        		    *
  -- PACKAGE HEADER   | PKG_LMS_ERRORHANDELER                                                                  		    *
  --                  |                                                                                        		    *
  -- PURPOSE          | PKG_LMS_ERRORHANDELER IS DESIGNED TO HANDLE AND LOG ERRORS IN A LIBRARY MANAGEMENT SYSTEM (LMS).    *
  --                  |                                                                                        		    *
  --                  | DEFINES TWO ERROR LOGGING PROCEDURES: PR_LOG_AUTHOR_ERROR AND PR_LOG_BOOK_ERROR.              	    *
  --                  |                                                                                        		    *
  -- ***********************************************************************************************************************+
  -- PPROCEDURE NAMES           | PR_LOG_AUTHOR_ERROR AND PR_LOG_BOOK_ERROR.                                                *
  -- AUTHOR                     | SR CONSULTANTS                                                               		    *
  --                            |                                                                              		    *
  -- MODIFICATION LOG ------------------------------------------------------------------------------------------------------+
  -- VER NO     |    DATE       |      AUTHOR       |         MODIFICATION                                                  *
  --------------+---------------+-------------------+-----------------------------------------------------------------------+
  --															    * 
  -- ************************************************************************************************************************

    -- PROCEDURE TO LOG ERRORS FOR AUTHORS
    PROCEDURE PR_LOG_AUTHOR_ERROR(
        P_FNAME IN VARCHAR2,
        P_LNAME IN VARCHAR2,
        P_ERROR_CODE IN CHAR,
        P_ERROR_MESSAGE IN VARCHAR2
    );

    -- PROCEDURE TO LOG ERRORS FOR BOOKS
    PROCEDURE PR_LOG_BOOK_ERROR(
        P_BOOK_TITLE IN VARCHAR2,
        P_ERROR_CODE IN CHAR,
        P_ERROR_MESSAGE IN VARCHAR2
    );
	
	-- PROCEDURE TO LOG ERRORS FOR MEMBERS
	PROCEDURE PR_LOG_MEMBER_ERROR(
		P_FNAME IN VARCHAR2,
		P_LNAME IN VARCHAR2,
		P_ERROR_CODE IN VARCHAR2,
		P_ERRORMSG  IN VARCHAR2 
	);
END PKG_LMS_ERRORHANDELER;
