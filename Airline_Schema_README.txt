AIRLINE RESERVATION SYSTEM - SQL PROJECT

This project implements a complete Airline Reservation System using MySQL.
All code for the project is contained in a single SQL file named:

Project_Airline_Schema.sql

CONTENT OF THE SQL FILE:
- Database creation (AirlineDB)
- Creation of all tables: Airports, Flights, Customers, Seats, Bookings, Payments
- Index creation
- Insertion of sample data
- Seat generation procedure for all flights
- Stored procedure for booking (sp_make_booking)
- Stored procedure for cancellation (sp_cancel_booking)
- Triggers for booking insert and booking update
- Reporting views for daily bookings and flight load factor
- Sample queries for flight search, revenue, and passenger list
- Full testing script for booking and cancellation

PROJECT FEATURES:
- Normalized relational database
- Automatic seat generation (1A, 1B ... based on total seats)
- ACID-compliant booking and cancellation logic
- Use of transactions and row locking (SELECT ... FOR UPDATE)
- Automatic seat marking through triggers
- Revenue and load factor reporting views
- Realistic airline workflow simulation

HOW TO RUN:
1. Open MySQL Workbench or any MySQL client.
2. Run the file: Project_Airline_Schema.sql
3. The entire database and all logic will be created automatically.
4. Use the stored procedures to test bookings and cancellations.
5. Use the included queries and views for reporting and analysis.

FILE STRUCTURE:
Project_Airline_Schema.sql    (main and only SQL script)
README.txt                    (this file)

This project demonstrates SQL database design, stored procedures,
transactions, triggers, referential integrity, and reporting.
