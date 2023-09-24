CREATE OR REPLACE PACKAGE PKG_LMS_AUTOTRNS
  --*********************************************************************************************************************************************************
  -- PACKAGE     : PKG_LMS_AUTOTRNS                                                                                                                         *
  -- DESCRIPTION : THIS PACKAGE ENCAPSULATES PROCEDURES FOR AUTHOR, BOOK, MEMBER, AND BOOK TRANSACTION MANAGEMENT IN THE LMS (LIBRARY MANAGEMENT SYSTEM).   *
  -- AUTHOR      : RAJAT K.SWAIN                                                                                                                            *
  -- DATE        : 23-SEP-2021                                                                                                                              *
  ----------------------------------------------------------------------------------------------------------------------------------------------------------*
  -- PROCEDURES:                                                                                                                                            *
  -- - PR_INSERT_AUTHOR     : INSERTS AUTHOR INFORMATION INTO THE LMS_AUTHORS TABLE AND HANDLES DUPLICATE CHECKS.                                           *
  -- - PR_INSERT_BOOK       : INSERTS BOOK INFORMATION INTO THE LMS_BOOKS TABLE AND MANAGES BOOK AVAILABILITY.                                              *
  -- - PR_INSERT_MEMBER     : INSERTS MEMBER INFORMATION INTO THE LMS_MEMBERS TABLE AND ENSURES UNIQUENESS.                                                 *
  -- - PR_BOOK_TRANSACTION  : HANDLES BOOK BORROWING TRANSACTIONS, UPDATING RECORDS IN LMS_BORROWEDBOOKS AND BOOK AVAILABILITY.                             *
  --                                                                                                                                                        *
  -- USAGE: CALL THE APPROPRIATE PROCEDURE WITHIN THIS PACKAGE TO MANAGE AUTHORS, BOOKS, MEMBERS, AND BOOK TRANSACTIONS IN THE LMS.                         *
  --*********************************************************************************************************************************************************
AS
  -- AUTHOR MANAGEMENT PROCEDURES
  PROCEDURE PR_INSERT_AUTHOR(
      P_FNAME IN LMS_AUTHORS.FNAME%TYPE,
      P_LNAME IN LMS_AUTHORS.LNAME%TYPE );
  -- BOOK MANAGEMENT PROCEDURES
  PROCEDURE PR_INSERT_BOOK(
      P_FNAME        IN VARCHAR2,
      P_LNAME        IN VARCHAR2,
      P_TITLE        IN VARCHAR2,
      P_BOOK_GENER   IN VARCHAR2,
      P_PUBLISH_YEAR IN NUMBER );
  -- MEMBER MANAGEMENT PROCEDURES
  PROCEDURE PR_INSERT_MEMBER(
      P_FNAME     IN LMS_MEMBERS.FNAME%TYPE,
      P_LNAME     IN LMS_MEMBERS.LNAME%TYPE,
      P_MOBILE_NO IN LMS_MEMBERS.MOBILE_NO%TYPE );
  -- BOOK TRANSACTION PROCEDURE
  PROCEDURE PR_BOOK_TRANSACTION(
      P_TITLE     IN LMS_BOOKS.TITLE%TYPE,
      P_FNAME     IN LMS_MEMBERS.FNAME%TYPE,
      P_LNAME     IN LMS_MEMBERS.LNAME%TYPE,
      P_MOBILE_NO IN LMS_MEMBERS.MOBILE_NO%TYPE );
END PKG_LMS_AUTOTRNS;