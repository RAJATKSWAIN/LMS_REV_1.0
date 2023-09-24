# LMS_REV_1.0 - Library Management System

!![Alt text](logo_lms_7.png)

LMS_REV_1.0 is a comprehensive Library Management System designed to efficiently manage library resources, including books, members, authors, and transactions. It incorporates robust exception handling and version history tracking, making it a powerful tool for library administrators and users.

## Features

- Member Management : Register and manage member profiles, authentication, and privileges.
- Author Management : Maintain an author database with author profiles and books authored.
- Book Management   : Catalog books with detailed information, track availability, and location.
- Transactions      : Record and manage book checkouts and returns, calculate fines, generate receipts.
- Exception Handling: Gracefully handle errors and exceptions within the system.
- Version History   : Maintain a log of system updates and changes.


## Member Management:<br>
			The system allows the registration and management of library members.
			It ensures consistency in member data by converting input parameters to uppercase.
			It checks if a member with the same first name and last name already exists.
			Generates a unique member ID and mail ID for each registered member.
## Author Management:<br>
			Authors can be registered and managed in the system.
			The system generates a unique author ID, mail ID, and country for each registered author.
			It checks for duplicate authors with the same first name and last name.
## Book Management:   
			The system manages book records, including titles, availability, and book counts.
			It verifies the availability of books and provides appropriate messages.
			Book transactions (borrowing and returning) are handled, updating book counts and statuses accordingly.
## Transactions:<br>
			The system records book transactions, including borrowing and returning.
			It generates unique transaction IDs and maintains transaction records.
			It verifies if books are already returned and handles returned books, updating book counts and statuses.
## Exception Handling:<br>
			The project includes comprehensive exception handling to manage errors, such as data not found or invalid input.
			Error messages and logging mechanisms are in place to track and handle exceptions.
## Version History:<br>
			The project includes version history to document changes and enhancements made over time.
			Overall, the Library Management System (LMS) is designed to automate and streamline library operations, ensuring data consistency, 
			transaction management, and error handling. It provides a structured and efficient approach to managing library resources and member interactions.

## Installation

1. **Clone the Repository:**
   ```sh
   git clone https://github.com/RAJATKSWAIN/LMS_VER_1.0.git
   cd lms_rev_1.0
