/* =========================================================
   HOTEL MANAGEMENT SYSTEM
   SQL SERVER DATABASE
   Author: Ayman Ahmed Al-Khobaji
   ========================================================= */

------------------------------------------------------------
-- 1. CREATE DATABASE
------------------------------------------------------------

IF DB_ID('HotelManagementDB') IS NULL
BEGIN
    CREATE DATABASE HotelManagementDB;
END
GO

USE HotelManagementDB;
GO

------------------------------------------------------------
-- 2. DROP TABLES IF THEY EXIST
--    This allows the script to be re-run during development.
------------------------------------------------------------
------------------------------------------------------------
-- 3. ROLES
------------------------------------------------------------

CREATE TABLE Roles
(
    RoleID INT IDENTITY(1,1) PRIMARY KEY,
    RoleName NVARCHAR(50) NOT NULL UNIQUE,
    Description NVARCHAR(255)
);
GO

------------------------------------------------------------
-- 4. USERS
------------------------------------------------------------

CREATE TABLE Users
(
    UserID INT IDENTITY(1,1) PRIMARY KEY,
    Username NVARCHAR(50) NOT NULL UNIQUE,
    PasswordHash NVARCHAR(255) NOT NULL,
    EmployeeID INT NULL,
    RoleID INT NOT NULL,
    IsActive BIT NOT NULL DEFAULT 1,
    CreatedAt DATETIME NOT NULL DEFAULT GETDATE()
);
GO

------------------------------------------------------------
-- 5. EMPLOYEES
------------------------------------------------------------

CREATE TABLE Employees
(
    EmployeeID INT IDENTITY(1,1) PRIMARY KEY,
    EmployeeName NVARCHAR(150) NOT NULL,
    Gender NVARCHAR(10) NOT NULL,
    JobTitle NVARCHAR(100) NOT NULL,
    PhoneNumber NVARCHAR(20) NOT NULL,
    Email NVARCHAR(100),
    Address NVARCHAR(255),
    HireDate DATE NOT NULL,
    Salary DECIMAL(10,2) NOT NULL,
    IsActive BIT NOT NULL DEFAULT 1,

    CONSTRAINT CK_Employees_Gender
        CHECK (Gender IN ('Male', 'Female')),

    CONSTRAINT CK_Employees_Salary
        CHECK (Salary >= 0)
);
GO

------------------------------------------------------------
-- 6. ROOM TYPES
------------------------------------------------------------

CREATE TABLE RoomTypes
(
    RoomTypeID INT IDENTITY(1,1) PRIMARY KEY,
    TypeName NVARCHAR(100) NOT NULL UNIQUE,
    Description NVARCHAR(255),
    BasePrice DECIMAL(10,2) NOT NULL,
    Capacity INT NOT NULL,
    HasAirConditioner BIT NOT NULL DEFAULT 1,

    CONSTRAINT CK_RoomTypes_BasePrice
        CHECK (BasePrice >= 0),

    CONSTRAINT CK_RoomTypes_Capacity
        CHECK (Capacity > 0)
);
GO

------------------------------------------------------------
-- 7. ROOMS
------------------------------------------------------------

CREATE TABLE Rooms
(
    RoomID INT IDENTITY(1,1) PRIMARY KEY,
    RoomNumber NVARCHAR(20) NOT NULL UNIQUE,
    FloorNumber INT NOT NULL,
    Price DECIMAL(10,2) NOT NULL,
    Status NVARCHAR(30) NOT NULL DEFAULT 'Available',
    NumberOfBeds INT NOT NULL,
    RoomTypeID INT NOT NULL,

    CONSTRAINT FK_Rooms_RoomTypes
        FOREIGN KEY (RoomTypeID)
        REFERENCES RoomTypes(RoomTypeID),

    CONSTRAINT CK_Rooms_Price
        CHECK (Price >= 0),

    CONSTRAINT CK_Rooms_Beds
        CHECK (NumberOfBeds > 0),

    CONSTRAINT CK_Rooms_Status
        CHECK
        (
            Status IN
            (
                'Available',
                'Reserved',
                'Occupied',
                'Maintenance',
                'Cleaning'
            )
        )
);
GO

------------------------------------------------------------
-- 8. GUESTS
------------------------------------------------------------

CREATE TABLE Guests
(
    GuestID INT IDENTITY(1,1) PRIMARY KEY,
    GuestName NVARCHAR(150) NOT NULL,
    Gender NVARCHAR(10) NOT NULL,
    Nationality NVARCHAR(50) NOT NULL,
    PersonalCardType NVARCHAR(50) NOT NULL,
    PersonalCardNumber NVARCHAR(50) NOT NULL UNIQUE,
    PhoneNumber NVARCHAR(20) NOT NULL,
    Email NVARCHAR(100),
    Address NVARCHAR(255),
    CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),

    CONSTRAINT CK_Guests_Gender
        CHECK (Gender IN ('Male', 'Female'))
);
GO

------------------------------------------------------------
-- 9. RESERVATIONS
------------------------------------------------------------

CREATE TABLE Reservations
(
    ReservationID INT IDENTITY(1,1) PRIMARY KEY,
    GuestID INT NOT NULL,
    RoomID INT NOT NULL,
    EmployeeID INT NULL,
    CheckInDate DATE NOT NULL,
    CheckOutDate DATE NOT NULL,
    Duration AS DATEDIFF(DAY, CheckInDate, CheckOutDate),
    NumberOfGuests INT NOT NULL,
    ReservationStatus NVARCHAR(30) NOT NULL DEFAULT 'Confirmed',
    Notes NVARCHAR(500),
    CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),

    CONSTRAINT FK_Reservations_Guests
        FOREIGN KEY (GuestID)
        REFERENCES Guests(GuestID),

    CONSTRAINT FK_Reservations_Rooms
        FOREIGN KEY (RoomID)
        REFERENCES Rooms(RoomID),

    CONSTRAINT FK_Reservations_Employees
        FOREIGN KEY (EmployeeID)
        REFERENCES Employees(EmployeeID),

    CONSTRAINT CK_Reservations_Dates
        CHECK (CheckOutDate > CheckInDate),

    CONSTRAINT CK_Reservations_Guests
        CHECK (NumberOfGuests > 0),

    CONSTRAINT CK_Reservations_Status
        CHECK
        (
            ReservationStatus IN
            (
                'Pending',
                'Confirmed',
                'CheckedIn',
                'CheckedOut',
                'Cancelled'
            )
        )
);
GO

------------------------------------------------------------
-- 10. INVOICES
------------------------------------------------------------

CREATE TABLE Invoices
(
    InvoiceID INT IDENTITY(1,1) PRIMARY KEY,
    ReservationID INT NOT NULL UNIQUE,
    InvoiceDate DATETIME NOT NULL DEFAULT GETDATE(),
    SubTotal DECIMAL(10,2) NOT NULL,
    TaxAmount DECIMAL(10,2) NOT NULL DEFAULT 0,
    DiscountAmount DECIMAL(10,2) NOT NULL DEFAULT 0,
    TotalAmount AS
        (SubTotal + TaxAmount - DiscountAmount),

    InvoiceStatus NVARCHAR(30) NOT NULL DEFAULT 'Unpaid',

    CONSTRAINT FK_Invoices_Reservations
        FOREIGN KEY (ReservationID)
        REFERENCES Reservations(ReservationID),

    CONSTRAINT CK_Invoices_Amounts
        CHECK
        (
            SubTotal >= 0
            AND TaxAmount >= 0
            AND DiscountAmount >= 0
            AND DiscountAmount <= SubTotal + TaxAmount
        ),

    CONSTRAINT CK_Invoices_Status
        CHECK
        (
            InvoiceStatus IN
            (
                'Unpaid',
                'PartiallyPaid',
                'Paid',
                'Cancelled'
            )
        )
);
GO

------------------------------------------------------------
-- 11. PAYMENTS
------------------------------------------------------------

CREATE TABLE Payments
(
    PaymentID INT IDENTITY(1,1) PRIMARY KEY,
    ReservationID INT NOT NULL,
    InvoiceID INT NULL,
    Amount DECIMAL(10,2) NOT NULL,
    PaymentDate DATETIME NOT NULL DEFAULT GETDATE(),
    PaymentMethod NVARCHAR(50) NOT NULL,
    TransactionID NVARCHAR(100),
    Notes NVARCHAR(255),

    CONSTRAINT FK_Payments_Reservations
        FOREIGN KEY (ReservationID)
        REFERENCES Reservations(ReservationID),

    CONSTRAINT FK_Payments_Invoices
        FOREIGN KEY (InvoiceID)
        REFERENCES Invoices(InvoiceID),

    CONSTRAINT CK_Payments_Amount
        CHECK (Amount > 0),

    CONSTRAINT CK_Payments_Method
        CHECK
        (
            PaymentMethod IN
            (
                'Cash',
                'Credit Card',
                'Debit Card',
                'Bank Transfer'
            )
        )
);
GO

------------------------------------------------------------
-- 12. SERVICES
------------------------------------------------------------

CREATE TABLE Services
(
    ServiceID INT IDENTITY(1,1) PRIMARY KEY,
    ServiceName NVARCHAR(100) NOT NULL UNIQUE,
    Description NVARCHAR(255),
    Price DECIMAL(10,2) NOT NULL,
    IsActive BIT NOT NULL DEFAULT 1,

    CONSTRAINT CK_Services_Price
        CHECK (Price >= 0)
);
GO

------------------------------------------------------------
-- 13. RESERVATION SERVICES
------------------------------------------------------------

CREATE TABLE ReservationServices
(
    ReservationServiceID INT IDENTITY(1,1) PRIMARY KEY,
    ReservationID INT NOT NULL,
    ServiceID INT NOT NULL,
    Quantity INT NOT NULL DEFAULT 1,
    ServiceDate DATETIME NOT NULL DEFAULT GETDATE(),
    UnitPrice DECIMAL(10,2) NOT NULL,
    Notes NVARCHAR(255),

    TotalPrice AS (Quantity * UnitPrice),

    CONSTRAINT FK_ReservationServices_Reservations
        FOREIGN KEY (ReservationID)
        REFERENCES Reservations(ReservationID),

    CONSTRAINT FK_ReservationServices_Services
        FOREIGN KEY (ServiceID)
        REFERENCES Services(ServiceID),

    CONSTRAINT CK_ReservationServices_Quantity
        CHECK (Quantity > 0),

    CONSTRAINT CK_ReservationServices_UnitPrice
        CHECK (UnitPrice >= 0)
);
GO

------------------------------------------------------------
-- 14. AMENITIES
------------------------------------------------------------

CREATE TABLE Amenities
(
    AmenityID INT IDENTITY(1,1) PRIMARY KEY,
    AmenityName NVARCHAR(100) NOT NULL UNIQUE,
    Description NVARCHAR(255)
);
GO

------------------------------------------------------------
-- 15. ROOM AMENITIES
------------------------------------------------------------

CREATE TABLE RoomAmenities
(
    RoomID INT NOT NULL,
    AmenityID INT NOT NULL,

    PRIMARY KEY (RoomID, AmenityID),

    CONSTRAINT FK_RoomAmenities_Rooms
        FOREIGN KEY (RoomID)
        REFERENCES Rooms(RoomID),

    CONSTRAINT FK_RoomAmenities_Amenities
        FOREIGN KEY (AmenityID)
        REFERENCES Amenities(AmenityID)
);
GO

------------------------------------------------------------
-- 16. ROOM STATUS HISTORY
------------------------------------------------------------

CREATE TABLE RoomStatusHistory
(
    HistoryID INT IDENTITY(1,1) PRIMARY KEY,
    RoomID INT NOT NULL,
    OldStatus NVARCHAR(30),
    NewStatus NVARCHAR(30) NOT NULL,
    ChangedByEmployeeID INT NULL,
    ChangedAt DATETIME NOT NULL DEFAULT GETDATE(),
    Reason NVARCHAR(255),

    CONSTRAINT FK_RoomStatusHistory_Rooms
        FOREIGN KEY (RoomID)
        REFERENCES Rooms(RoomID),

    CONSTRAINT FK_RoomStatusHistory_Employees
        FOREIGN KEY (ChangedByEmployeeID)
        REFERENCES Employees(EmployeeID)
);
GO

------------------------------------------------------------
-- 17. INSERT ROLES
------------------------------------------------------------

INSERT INTO Roles (RoleName, Description)
VALUES
('Administrator', 'Full system access'),
('Manager', 'Hotel management access'),
('Receptionist', 'Reservation and guest management'),
('Accountant', 'Payment and invoice management'),
('Employee', 'Basic employee access');
GO

------------------------------------------------------------
-- 18. INSERT EMPLOYEES
------------------------------------------------------------

INSERT INTO Employees
(
    EmployeeName,
    Gender,
    JobTitle,
    PhoneNumber,
    Email,
    Address,
    HireDate,
    Salary
)
VALUES
('Ahmed Mohammed Ali', 'Male', 'Hotel Manager',
 '771100001', 'ahmed.manager@hotel.com',
 'Sanaa, Yemen', '2024-01-15', 1200),

('Mohammed Saleh Hassan', 'Male', 'Receptionist',
 '771100002', 'mohammed.reception@hotel.com',
 'Sanaa, Yemen', '2024-03-10', 700),

('Sara Ibrahim Ahmed', 'Female', 'Receptionist',
 '771100003', 'sara.reception@hotel.com',
 'Sanaa, Yemen', '2024-04-20', 700),

('Khaled Ali Omar', 'Male', 'Accountant',
 '771100004', 'khaled.accountant@hotel.com',
 'Sanaa, Yemen', '2024-02-05', 900),

('Fatima Hassan Saleh', 'Female', 'Housekeeping',
 '771100005', 'fatima.housekeeping@hotel.com',
 'Sanaa, Yemen', '2024-05-01', 550);
GO

------------------------------------------------------------
-- 19. INSERT USERS
------------------------------------------------------------

INSERT INTO Users
(
    Username,
    PasswordHash,
    EmployeeID,
    RoleID
)
VALUES
(
    'admin',
    'CHANGE_THIS_PASSWORD_HASH',
    1,
    1
),
(
    'reception1',
    'CHANGE_THIS_PASSWORD_HASH',
    2,
    3
),
(
    'accountant1',
    'CHANGE_THIS_PASSWORD_HASH',
    4,
    4
);
GO

------------------------------------------------------------
-- 20. INSERT ROOM TYPES
------------------------------------------------------------

INSERT INTO RoomTypes
(
    TypeName,
    Description,
    BasePrice,
    Capacity,
    HasAirConditioner
)
VALUES
(
    'Standard Single Room',
    'Single bed with private bathroom and internet',
    30,
    1,
    1
),
(
    'Deluxe Single Room',
    'Large bed with balcony and view',
    45,
    1,
    1
),
(
    'Standard Double Room',
    'Two separate beds with interior view',
    55,
    2,
    1
),
(
    'Deluxe Double Room',
    'Large double bed with balcony and view',
    70,
    2,
    1
),
(
    'Family Triple Room',
    'Three separate beds suitable for families',
    85,
    3,
    1
),
(
    'Mini Suite',
    'Bedroom with a small living room',
    110,
    2,
    1
),
(
    'Family Suite',
    'Two bedrooms with a spacious living room',
    160,
    4,
    1
),
(
    'Executive Suite',
    'Luxury suite with business workspace',
    190,
    2,
    1
),
(
    'Royal Suite',
    'Luxury suite with jacuzzi and VIP services',
    280,
    4,
    1
),
(
    'Economy Studio',
    'Compact room suitable for long stays',
    40,
    1,
    0
);
GO

------------------------------------------------------------
-- 21. INSERT ROOMS
------------------------------------------------------------

INSERT INTO Rooms
(
    RoomNumber,
    FloorNumber,
    Price,
    Status,
    NumberOfBeds,
    RoomTypeID
)
VALUES
('101', 1, 30, 'Available', 1, 1),
('102', 1, 45, 'Reserved', 1, 2),
('103', 1, 40, 'Available', 1, 10),
('201', 2, 55, 'Available', 2, 3),
('202', 2, 70, 'Reserved', 1, 4),
('203', 2, 85, 'Available', 3, 5),
('301', 3, 110, 'Available', 1, 6),
('302', 3, 160, 'Reserved', 2, 7),
('401', 4, 190, 'Maintenance', 1, 8),
('501', 5, 280, 'Available', 2, 9);
GO

------------------------------------------------------------
-- 22. INSERT GUESTS
------------------------------------------------------------

INSERT INTO Guests
(
    GuestName,
    Gender,
    Nationality,
    PersonalCardType,
    PersonalCardNumber,
    PhoneNumber,
    Email,
    Address
)
VALUES
(
    'Mohammed Ali Ahmed',
    'Male',
    'Yemeni',
    'National ID',
    '0101002233',
    '771122334',
    'mohammed@example.com',
    'Sanaa, Yemen'
),
(
    'Ahmed Khaled Al-Shami',
    'Male',
    'Yemeni',
    'National ID',
    '0101004455',
    '772233445',
    'ahmed@example.com',
    'Sanaa, Yemen'
),
(
    'Sara Ibrahim Al-Qasimi',
    'Female',
    'Yemeni',
    'Passport',
    'P00998811',
    '773344556',
    'sara@example.com',
    'Taiz, Yemen'
),
(
    'Abdullah Omar Baabad',
    'Male',
    'Yemeni',
    'National ID',
    '0101006677',
    '774455667',
    'abdullah@example.com',
    'Aden, Yemen'
),
(
    'Mona Tariq Al-Ward',
    'Female',
    'Yemeni',
    'National ID',
    '0101008899',
    '775566778',
    'mona@example.com',
    'Sanaa, Yemen'
),
(
    'Khaled Waleed Al-Arieqi',
    'Male',
    'Yemeni',
    'Passport',
    'P00776622',
    '776677889',
    'khaled@example.com',
    'Ibb, Yemen'
),
(
    'Fatima Hassan Al-Hakimi',
    'Female',
    'Yemeni',
    'National ID',
    '0101010011',
    '777788990',
    'fatima@example.com',
    'Sanaa, Yemen'
),
(
    'Yassin Adel Al-Sabri',
    'Male',
    'Yemeni',
    'National ID',
    '0101012233',
    '778899001',
    'yassin@example.com',
    'Dhamar, Yemen'
),
(
    'Reem Nasser Al-Saqqaf',
    'Female',
    'Yemeni',
    'Passport',
    'P00554433',
    '779900112',
    'reem@example.com',
    'Aden, Yemen'
),
(
    'Majed Sami Al-Jabali',
    'Male',
    'Yemeni',
    'National ID',
    '0101014455',
    '770011223',
    'majed@example.com',
    'Sanaa, Yemen'
);
GO

------------------------------------------------------------
-- 23. INSERT RESERVATIONS
------------------------------------------------------------

INSERT INTO Reservations
(
    GuestID,
    RoomID,
    EmployeeID,
    CheckInDate,
    CheckOutDate,
    NumberOfGuests,
    ReservationStatus,
    Notes
)
VALUES
(1, 1, 2, '2026-08-01', '2026-08-04',
 1, 'CheckedOut', 'Completed stay'),

(2, 2, 2, '2026-08-18', '2026-08-22',
 1, 'CheckedIn', 'Current guest'),

(3, 4, 3, '2026-08-25', '2026-08-27',
 2, 'Confirmed', NULL),

(4, 5, 2, '2026-08-10', '2026-08-15',
 2, 'CheckedOut', 'Completed stay'),

(5, 6, 3, '2026-08-19', '2026-08-22',
 3, 'CheckedIn', NULL),

(6, 7, 2, '2026-08-20', '2026-08-22',
 2, 'CheckedIn', NULL),

(7, 8, 3, '2026-09-01', '2026-09-06',
 4, 'Confirmed', NULL),

(8, 9, 2, '2026-08-15', '2026-08-22',
 2, 'Cancelled', 'Guest cancelled reservation'),

(9, 10, 3, '2026-09-10', '2026-09-14',
 4, 'Confirmed', NULL),

(10, 3, 2, '2026-08-05', '2026-08-15',
 1, 'CheckedOut', NULL);
GO

------------------------------------------------------------
-- 24. INSERT INVOICES
------------------------------------------------------------

INSERT INTO Invoices
(
    ReservationID,
    SubTotal,
    TaxAmount,
    DiscountAmount,
    InvoiceStatus
)
VALUES
(1, 90, 0, 0, 'Paid'),
(2, 180, 0, 0, 'PartiallyPaid'),
(3, 110, 0, 0, 'Unpaid'),
(4, 350, 0, 0, 'Paid'),
(5, 255, 0, 0, 'PartiallyPaid'),
(6, 220, 0, 0, 'Paid'),
(7, 800, 0, 0, 'PartiallyPaid'),
(8, 0, 0, 0, 'Cancelled'),
(9, 1120, 0, 0, 'PartiallyPaid'),
(10, 400, 0, 0, 'Paid');
GO

------------------------------------------------------------
-- 25. INSERT PAYMENTS
------------------------------------------------------------

INSERT INTO Payments
(
    ReservationID,
    InvoiceID,
    Amount,
    PaymentDate,
    PaymentMethod,
    TransactionID
)
VALUES
(1, 1, 90, '2026-08-01 14:00:00',
 'Cash', 'TXN-10001'),

(2, 2, 180, '2026-08-18 16:30:00',
 'Credit Card', 'TXN-10002'),

(3, 3, 110, '2026-08-19 10:15:00',
 'Bank Transfer', 'TXN-10003'),

(4, 4, 350, '2026-08-10 12:45:00',
 'Cash', 'TXN-10004'),

(5, 5, 255, '2026-08-19 15:20:00',
 'Credit Card', 'TXN-10005'),

(6, 6, 220, '2026-08-20 18:00:00',
 'Cash', 'TXN-10006'),

(7, 7, 400, '2026-08-20 09:00:00',
 'Bank Transfer', 'TXN-10007'),

(9, 9, 500, '2026-09-01 13:10:00',
 'Bank Transfer', 'TXN-10009'),

(10, 10, 400, '2026-08-05 09:40:00',
 'Cash', 'TXN-10010');
GO

------------------------------------------------------------
-- 26. INSERT SERVICES
------------------------------------------------------------

INSERT INTO Services
(
    ServiceName,
    Description,
    Price
)
VALUES
('Breakfast',
 'Daily breakfast service',
 10),

('Airport Transfer',
 'Transportation to or from the airport',
 25),

('Laundry',
 'Laundry and ironing service',
 15),

('Room Cleaning',
 'Additional room cleaning',
 10),

('Room Service',
 'Food and drinks delivered to the room',
 20),

('Extra Bed',
 'Additional bed for the room',
 20);
GO

------------------------------------------------------------
-- 27. INSERT RESERVATION SERVICES
------------------------------------------------------------

INSERT INTO ReservationServices
(
    ReservationID,
    ServiceID,
    Quantity,
    UnitPrice,
    Notes
)
VALUES
(1, 1, 3, 10, 'Breakfast for three days'),
(2, 1, 4, 10, 'Breakfast'),
(2, 5, 2, 20, 'Room service'),
(4, 3, 2, 15, 'Laundry'),
(5, 1, 3, 10, 'Breakfast'),
(6, 2, 1, 25, 'Airport transfer'),
(7, 6, 1, 20, 'Extra bed');
GO

------------------------------------------------------------
-- 28. INSERT AMENITIES
------------------------------------------------------------

INSERT INTO Amenities
(
    AmenityName,
    Description
)
VALUES
('Wi-Fi', 'Free wireless internet'),
('Television', 'Smart television'),
('Mini Bar', 'Mini refrigerator and drinks'),
('Balcony', 'Private balcony'),
('Jacuzzi', 'Private jacuzzi'),
('Safe Box', 'Electronic safe box'),
('Hair Dryer', 'Hair dryer'),
('Coffee Maker', 'Coffee and tea maker');
GO

------------------------------------------------------------
-- 29. INSERT ROOM AMENITIES
------------------------------------------------------------

INSERT INTO RoomAmenities (RoomID, AmenityID)
VALUES
(1, 1),
(1, 2),
(1, 6),

(2, 1),
(2, 2),
(2, 4),
(2, 6),

(3, 1),
(3, 2),

(4, 1),
(4, 2),
(4, 6),

(5, 1),
(5, 2),
(5, 4),
(5, 7),

(6, 1),
(6, 2),
(6, 3),
(6, 8),

(7, 1),
(7, 2),
(7, 3),
(7, 4),

(8, 1),
(8, 2),
(8, 3),
(8, 4),
(8, 6),

(9, 1),
(9, 2),
(9, 3),
(9, 4),
(9, 5),
(9, 6),
(9, 8),

(10, 1),
(10, 2);
GO

------------------------------------------------------------
-- 30. INSERT ROOM STATUS HISTORY
------------------------------------------------------------

INSERT INTO RoomStatusHistory
(
    RoomID,
    OldStatus,
    NewStatus,
    ChangedByEmployeeID,
    Reason
)
VALUES
(1, 'Available', 'Reserved', 2, 'New reservation'),
(1, 'Reserved', 'Occupied', 2, 'Guest checked in'),
(1, 'Occupied', 'Available', 2, 'Guest checked out'),

(2, 'Available', 'Reserved', 2, 'Reservation created'),

(4, 'Available', 'Reserved', 3, 'Reservation created'),

(5, 'Available', 'Reserved', 2, 'Reservation created'),
(5, 'Reserved', 'Occupied', 2, 'Guest checked in'),
(5, 'Occupied', 'Available', 2, 'Guest checked out'),

(9, 'Available', 'Maintenance', 5, 'Room maintenance required');
GO

------------------------------------------------------------
-- 31. INDEXES
------------------------------------------------------------

CREATE INDEX IX_Rooms_Status
ON Rooms(Status);

CREATE INDEX IX_Reservations_GuestID
ON Reservations(GuestID);

CREATE INDEX IX_Reservations_RoomID
ON Reservations(RoomID);

CREATE INDEX IX_Reservations_CheckInDate
ON Reservations(CheckInDate);

CREATE INDEX IX_Payments_ReservationID
ON Payments(ReservationID);

CREATE INDEX IX_Payments_PaymentDate
ON Payments(PaymentDate);

CREATE INDEX IX_Guests_PhoneNumber
ON Guests(PhoneNumber);

CREATE INDEX IX_Employees_JobTitle
ON Employees(JobTitle);
GO

------------------------------------------------------------
-- 32. VIEW: ROOM INFORMATION
------------------------------------------------------------

CREATE VIEW vw_RoomInformation
AS
SELECT
    r.RoomID,
    r.RoomNumber,
    r.FloorNumber,
    rt.TypeName AS RoomType,
    rt.Capacity,
    r.NumberOfBeds,
    r.Price,
    rt.BasePrice,
    r.Status,
    rt.HasAirConditioner
FROM Rooms r
INNER JOIN RoomTypes rt
    ON r.RoomTypeID = rt.RoomTypeID;
GO

------------------------------------------------------------
-- 33. VIEW: RESERVATION INFORMATION
------------------------------------------------------------

CREATE VIEW vw_ReservationInformation
AS
SELECT
    r.ReservationID,
    g.GuestName,
    g.PhoneNumber,
    rm.RoomNumber,
    rt.TypeName AS RoomType,
    r.CheckInDate,
    r.CheckOutDate,
    r.Duration,
    r.NumberOfGuests,
    r.ReservationStatus,
    e.EmployeeName AS CreatedBy,
    r.CreatedAt
FROM Reservations r
INNER JOIN Guests g
    ON r.GuestID = g.GuestID
INNER JOIN Rooms rm
    ON r.RoomID = rm.RoomID
INNER JOIN RoomTypes rt
    ON rm.RoomTypeID = rt.RoomTypeID
LEFT JOIN Employees e
    ON r.EmployeeID = e.EmployeeID;
GO

------------------------------------------------------------
-- 34. VIEW: INVOICE INFORMATION
------------------------------------------------------------

CREATE VIEW vw_InvoiceInformation
AS
SELECT
    i.InvoiceID,
    i.ReservationID,
    g.GuestName,
    rm.RoomNumber,
    i.InvoiceDate,
    i.SubTotal,
    i.TaxAmount,
    i.DiscountAmount,
    i.TotalAmount,
    ISNULL(SUM(p.Amount), 0) AS PaidAmount,
    i.TotalAmount - ISNULL(SUM(p.Amount), 0) AS RemainingAmount,
    i.InvoiceStatus
FROM Invoices i
INNER JOIN Reservations r
    ON i.ReservationID = r.ReservationID
INNER JOIN Guests g
    ON r.GuestID = g.GuestID
INNER JOIN Rooms rm
    ON r.RoomID = rm.RoomID
LEFT JOIN Payments p
    ON i.InvoiceID = p.InvoiceID
GROUP BY
    i.InvoiceID,
    i.ReservationID,
    g.GuestName,
    rm.RoomNumber,
    i.InvoiceDate,
    i.SubTotal,
    i.TaxAmount,
    i.DiscountAmount,
    i.TotalAmount,
    i.InvoiceStatus;
GO

------------------------------------------------------------
-- 35. VIEW: AVAILABLE ROOMS
------------------------------------------------------------

CREATE VIEW vw_AvailableRooms
AS
SELECT
    r.RoomID,
    r.RoomNumber,
    r.FloorNumber,
    rt.TypeName AS RoomType,
    r.NumberOfBeds,
    rt.Capacity,
    r.Price
FROM Rooms r
INNER JOIN RoomTypes rt
    ON r.RoomTypeID = rt.RoomTypeID
WHERE r.Status = 'Available';
GO

------------------------------------------------------------
-- 36. STORED PROCEDURE: SEARCH GUESTS
------------------------------------------------------------

CREATE PROCEDURE sp_SearchGuests
    @SearchTerm NVARCHAR(150)
AS
BEGIN
    SELECT
        GuestID,
        GuestName,
        Gender,
        Nationality,
        PersonalCardType,
        PersonalCardNumber,
        PhoneNumber,
        Email
    FROM Guests
    WHERE GuestName LIKE '%' + @SearchTerm + '%'
       OR PhoneNumber LIKE '%' + @SearchTerm + '%'
       OR PersonalCardNumber LIKE '%' + @SearchTerm + '%';
END;
GO

------------------------------------------------------------
-- 37. STORED PROCEDURE: GET AVAILABLE ROOMS
------------------------------------------------------------

CREATE PROCEDURE sp_GetAvailableRooms
AS
BEGIN
    SELECT *
    FROM vw_AvailableRooms
    ORDER BY RoomNumber;
END;
GO

------------------------------------------------------------
-- 38. STORED PROCEDURE: HOTEL DASHBOARD
------------------------------------------------------------

CREATE PROCEDURE sp_HotelDashboard
AS
BEGIN

    SELECT
        (SELECT COUNT(*) FROM Rooms) AS TotalRooms,

        (SELECT COUNT(*)
         FROM Rooms
         WHERE Status = 'Available') AS AvailableRooms,

        (SELECT COUNT(*)
         FROM Rooms
         WHERE Status = 'Occupied') AS OccupiedRooms,

        (SELECT COUNT(*)
         FROM Rooms
         WHERE Status = 'Reserved') AS ReservedRooms,

        (SELECT COUNT(*)
         FROM Rooms
         WHERE Status = 'Maintenance') AS MaintenanceRooms,

        (SELECT COUNT(*) FROM Guests) AS TotalGuests,

        (SELECT COUNT(*)
         FROM Employees
         WHERE IsActive = 1) AS ActiveEmployees,

        (SELECT ISNULL(SUM(Amount), 0)
         FROM Payments) AS TotalPayments;

END;
GO

------------------------------------------------------------
-- 39. TEST QUERIES
------------------------------------------------------------

SELECT * FROM RoomTypes;
SELECT * FROM Rooms;
SELECT * FROM Guests;
SELECT * FROM Employees;
SELECT * FROM Reservations;
SELECT * FROM Invoices;
SELECT * FROM Payments;
SELECT * FROM Services;
SELECT * FROM Amenities;

SELECT * FROM vw_RoomInformation;
SELECT * FROM vw_ReservationInformation;
SELECT * FROM vw_InvoiceInformation;
SELECT * FROM vw_AvailableRooms;

EXEC sp_HotelDashboard;
GO
