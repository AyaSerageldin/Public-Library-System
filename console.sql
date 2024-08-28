CREATE DATABASE LIBRARY_SYSTEM;
USE LIBRARY_SYSTEM;

Create table if not exists Membership
( ID INT PRIMARY KEY NOT NULL UNIQUE AUTO_INCREMENT,
  Name VARCHAR(255) NOT NULL ,
  Duration TEXT NOT NULL ,
  Description TEXT);

CREATE TABLE IF NOT EXISTS Members
( ID INT PRIMARY KEY NOT NULL UNIQUE AUTO_INCREMENT,
  First_Name varchar(255) NOT NULL ,
  Last_Name varchar(255) NOT NULL ,
  Email varchar(255) NOT NULL ,
  Address varchar(255),
  Membership_Date Date NOT NULL ,
  Membership_Type INT NOT NULL ,
  CONSTRAINT Members_ibk_fk FOREIGN KEY (Membership_Type) REFERENCES Membership(ID));
Alter Table Members ADD COLUMN Phone_no varchar(255);


CREATE TABLE IF NOT EXISTS Authors
( ID INT NOT NULL UNIQUE PRIMARY KEY AUTO_INCREMENT,
  First_Name VARCHAR(255) NOT NULL ,
  Last_Name VARCHAR(255) NOT NULL ,
  Nationality VARCHAR(255) NOT NULL ,
  DateOfBirth DATE) ;

CREATE TABLE IF NOT EXISTS Publishers
( ID INT NOT NULL UNIQUE PRIMARY KEY AUTO_INCREMENT,
  First_Name VARCHAR(255) NOT NULL ,
  Last_Name VARCHAR(255) NOT NULL ,
  Phone_No VARCHAR(255),
  Email VARCHAR(255) NOT NULL ,
  Address VARCHAR(255),
  Website TEXT) ;
Alter TABLE Publishers
    RENAME Column First_Name to name;
Alter TABLE Publishers
    RENAME Column Last_Name to Contact_Person;


CREATE TABLE IF NOT EXISTS Genres
( ID INT NOT NULL PRIMARY KEY UNIQUE AUTO_INCREMENT,
  Name VARCHAR(255)NOT NULL ,
  Description TEXT);
ALTER TABLE Genres ADD COLUMN Category VARCHAR(255) NOT NULL ;

CREATE TABLE IF NOT EXISTS Books
( ID INT NOT NULL UNIQUE PRIMARY KEY AUTO_INCREMENT,
  Title VARCHAR(255) NOT NULL ,
  ISBN CHAR(13) UNIQUE NOT NULL ,
  PublicationDate DATE NOT NULL ,
  Language VARCHAR(255) NOT NULL ,
  Publisher_ID INT NOT NULL ,
  Genre_ID INT NOT NULL ,
  Stock INT NOT NULL ,

 CONSTRAINT Books_ibfk_2 FOREIGN KEY (Publisher_ID) REFERENCES Publishers(ID),
 CONSTRAINT Books_ibfk_3 FOREIGN KEY (Genre_ID) REFERENCES Genres(ID));


CREATE TABLE IF NOT EXISTS BooksAuthors
( BookID INT NOT NULL ,
  AuthorID INT NOT NULL,
  PRIMARY KEY (AuthorID,BookID),
  Constraint Books_Authors_7 FOREIGN KEY (BookID) REFERENCES Books(ID),
                             FOREIGN KEY (AuthorID) REFERENCES Authors(ID)
  );

CREATE TABLE Books_Vendors
( Book_ID INT NOT NULL,
  VENDOR_ID INT NOT NULL ,
  PRIMARY KEY (VENDOR_ID,Book_ID),
  CONSTRAINT Books_Vendors_ibfk_6
      FOREIGN KEY (Book_ID) REFERENCES Books(ID),
  FOREIGN KEY (VENDOR_ID) REFERENCES Vendors(ID)
);


CREATE TABLE IF NOT EXISTS Staff
(   ID           INT PRIMARY KEY UNIQUE AUTO_INCREMENT NOT NULL ,
    First_Name   varchar(255)           NOT NULL ,
    Last_Name    varchar(255)           NOT NULL ,
    Phone_No     varchar(255)           NOT NULL ,
    Email        varchar(255)           NOT NULL ,
    Address      varchar(255)           NOT NULL ,
    SupervisorID INT                        NULL ,

CONSTRAINT Staff_ibfk_1 FOREIGN KEY (SupervisorID) REFERENCES Staff(ID)
);
ALTER TABLE Staff add COLUMN Department varchar(255) NOT NULL ;
ALTER TABLE Staff add column Title varchar(255) NOT NULL;
ALTER  TABLE Staff ADD COLUMN Salary decimal(10,2) NOT NULL ;

CREATE TABLE IF NOT EXISTS Loan
( ID INT NOT NULL UNIQUE auto_increment ,
  BookID INT NOT NULL ,
  EmployeeID INT NOT NULL ,
  MemberID INT NOT NULL,
  Loan_Date Date not null ,
  Return_Date Date NULL ,
  Due_Date Date not null ,
  Fine_Amount decimal(10,2) NULL ,
  Fine_Paid Date NULL ,

  CONSTRAINT Loan_ibfk_1 FOREIGN KEY Loan(BookID) REFERENCES Books(ID),
  CONSTRAINT Loan_ibfk_2 FOREIGN KEY Loan(MemberID) REFERENCES Members(ID),
  CONSTRAINT loan_ibfk_3 FOREIGN KEY Loan(EmployeeID) REFERENCES Staff(ID)
  );

CREATE TABLE Vendors
( ID INT PRIMARY KEY UNIQUE AUTO_INCREMENT NOT NULL ,
  Name varchar(255) NOT NULL ,
  Address varchar(255) NULL ,
  Contact_Person varchar(255) NOT NULL ,
  Email varchar(255) NOT NULL ,
  Phone_no varchar(255) NOT NULL );


#SQL FUNCTIONS - TRIGGERS - QUERIES#

#CREATE VIEW THAT SHOWS THE COUNT OF BOOKS BELONGING TO A CERTAIN GENRE#
CREATE VIEW AvailableBooksPerGenre AS
SELECT Genres.Name AS Genre,Count(Books.Title) AS number_of_novels FROM Genres
    inner join Books on Genres.ID = Books.Genre_ID
GROUP BY Genres.Name ;

SELECT Books.Title AS BookName , Count(Loan.BookID) AS Loan_times
FROM Books inner join Loan on BookID=Books.ID
GROUP BY BookName;

#RETRIEVE MEMBERS DATA WITH THEIR MEMEBERSHIP_TYPE#
CREATE VIEW MEMBERSHIPS AS
(SELECT First_Name,Last_Name,Membership.Name,Duration
FROM Members JOIN Membership ON Membership_Type=Membership.ID);

#CREATE A VIEW TO DISPLAY BOOKS WITH THEIR AUTHORS#
CREATE VIEW Book_Author AS
( SELECT Books.Title, Books.Language, Books.Stock,
         group_concat(concat(First_Name,' ',Last_Name)
                      ORDER BY First_Name SEPARATOR ',')

   FROM Books JOIN BooksAuthors ON ID = BookID
               JOIN Authors ON Authors.ID = AuthorID
GROUP BY
    Books.ID, Books.Title, Books.Language, Books.Stock );

#ALL BOOKS DATA#
CREATE VIEW AllBooksData AS (
SELECT Books.Title, Books.Language, Books.Stock ,
       Publishers.name AS Publisher, V.Name AS Vendor,
       GROUP_CONCAT(CONCAT(Authors.First_Name, ' ', Authors.Last_Name)
       ORDER BY Authors.First_Name SEPARATOR ', ') AS AUTHOR



FROM Books JOIN Publishers ON Publisher_ID = Publishers.ID
           JOIN BooksAuthors ON Books.ID = BookID
           JOIN Authors ON Authors.ID = AuthorID

           JOIN Books_Vendors BV on Books.ID = BV.Book_ID
           JOIN Vendors V on BV.VENDOR_ID = V.ID

GROUP BY Books.ID, Books.Title, Books.Language, Books.Stock,Publisher, Vendor);

#DISPLAY THE SUPERVISOR NAMES FOR EACH EMPLOYEE#
CREATE VIEW EMPLOYEE_SUPERVISOR AS
    (
      SELECT  E.First_Name , E.Last_Name , E.Title,E.Department,
             CONCAT(S.First_Name,' ',S.Last_Name) AS SupervisorName
          FROM Staff E LEFT JOIN Staff S ON E.SupervisorID=S.ID
          ORDER BY E.Department

    );


CREATE TRIGGER after_loan_insert
    AFTER INSERT ON Loan
    FOR EACH ROW
BEGIN
    UPDATE Books
    SET Stock = Stock - 1
    WHERE Books.ID = NEW.BookID;
END;

Select ID,Title,Stock from Books WHERE ID=5;

INSERT INTO Loan(BookID, EmployeeID, MemberID, Loan_Date, Due_Date)
VALUES (5,2,2,'2024-07-03','2024-07-19');

SELECT ID,Title,Stock FROM Books WHERE ID=5;


CREATE TRIGGER after_loan_update
    AFTER UPDATE ON Loan
    FOR EACH ROW
BEGIN
    IF NEW.Return_Date IS NOT NULL AND OLD.Return_Date IS NULL THEN
        UPDATE Books
        SET Stock = Stock + 1
        WHERE Books.ID = NEW.BookID;
    END IF;
END;

Select ID,Title,Stock from Books WHERE ID=5;

UPDATE Loan set Return_Date = '2024-07-12' Where BookID=5;

SELECT ID,Title,Stock FROM Books WHERE ID=5;



#CALCULATE FINES FOR DELAYED BOOK RETURNS#
#Function to Calculate Fine#
CREATE FUNCTION Calculate_Fine(Return_Date DATE, Due_Date DATE)
Returns DECIMAL(10,2)
DETERMINISTIC
BEGIN
 DECLARE Fine_amount Decimal(10,2);
 Declare Late_Days int;

 #Calculate the number of late days#
 SET Late_Days= datediff(Return_Date,Due_Date);

 #Fine_Computation#
     IF Late_Days > 0 THEN
         SET Fine_amount = Late_Days*2;
     Else SET Fine_amount =0;
     end IF;

RETURN Fine_amount;
end;
CREATE TRIGGER CalculateFineUponUpdate
        BEFORE INSERT ON Loan
        FOR EACH ROW
    BEGIN
        IF NEW.Return_Date IS NOT NULL THEN
            SET NEW.Fine_Amount = Calculate_Fine(NEW.Return_Date, NEW.Due_Date);
        END IF;
    END;

#GRANT PERMISSIONS TO ONE USER TO ADD UPDATE OR DELETE THE MEMBERSHIP TABLE#
CREATE ROLE Membership_Manager;
GRANT INSERT, UPDATE, DELETE ON Membership TO Membership_Manager;

CREATE USER 'Manager'@'Localhost' IDENTIFIED BY '123456';
GRANT Membership_Manager to 'Manager'@'Localhost';

SHOW GRANTS FOR Membership_Manager;
SHOW GRANTS FOR 'Manager'@'Localhost';












#TESTING THE TRIGGER & FUNCTION#
#UPDATE LIBRARY_SYSTEM.Loan
#SET Return_Date = '2024-06-29'
#WHERE ID = 1;
#SELECT Loan.Due_Date,Loan.Return_Date, Fine_Amount from Loan where ID=1;




