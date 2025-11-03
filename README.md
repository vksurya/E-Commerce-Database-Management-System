# 🛒 E-Commerce Database Management System (SQL)

**Author:** V. K. Surya

## Overview
This project is a **Database Management System for an E-Commerce platform**, implemented in **MySQL 8+**.
It models an online marketplace where **customers**, **sellers**, and **admins** interact to manage **products, orders, payments, reviews, inventory,** and **discount coupons**.

## Contents
- `schema.sql` — Database creation and schema (tables, indexes)
- `sample_data.sql` — Sample data inserts
- `triggers_procedures.sql` — Triggers and stored procedures
- `views_queries.sql` — Views and useful example queries

## Installation
1. Start MySQL server.
2. Run these scripts in order:
```sql
SOURCE schema.sql;
SOURCE sample_data.sql;
SOURCE triggers_procedures.sql;
SOURCE views_queries.sql;
```

## Notes
- This repository intentionally has **no license**.
- Replace placeholder password hashes with secure hashes in production.
- Consider splitting large data files and using migrations for real projects.

## Author
V. K. Surya
