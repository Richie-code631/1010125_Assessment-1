# Assessment 1: SQL and Big Data Foundations

**Student name:** Richmond Panyin Assafuah
**Student ID:** 1010125

## Submission contents

| File | Content |
|---|---|
| `Part_A_SQL.sql` | SQL answers A1 to A10 (Microsoft SQL Server) |
| `Part_B_Big_Data_Architecture.pdf` | Written answers B1 to B5|
| `Part_B_Architecture_Diagram.png` | Architecture diagram for B4 |
| `Part_C_Storage_Modelling.ipynb` | Notebook with C1 to C5, code and visible outputs |
| `Part_C_Storage_Modelling.pdf` | PDF export of the completed notebook |
| `README.md` | This file |

## Software and versions

| Item | Version |
|---|---|
| Microsoft SQL Server | Microsoft SQL Server 2025 (RTM) – 17.0.1000.7 (X64)|
| SQL Server Management Studio | 22.11.3+171.12328.437 |						
| Python | 3.13.9 |
| Jupyter Notebook (via Anaconda) | 7.4.5 |
| pandas | 2.3.3 |
| pyarrow | 21.0.0|
| Diagram tool (Part B and Part C) | diagrams.net and Graphviz |

## Setup note

The supplied setup script (`01_AssessmentDB_Setup.sql`) failed at line 321 with `Incorrect syntax near the keyword 'RowCount'`. The final check query used `RowCount` as an unbracketed column alias, and `RowCount` is a reserved word in T-SQL. I wrote the alias as `[RowCount]`. This changes only an output alias in the check query. No table, column or source field was renamed. After the fix the script completed and the row counts were 20 customers, 14 products, 72 orders and 138 order lines.

## Part A assumptions (SQL)

- **Revenue:** line revenue is `Quantity * UnitPrice * (1 - DiscountRate)`, using the order-line `UnitPrice` from `Sales.OrderItems`, not the catalogue price in `Sales.Products`.
- **Completed orders:** revenue tasks A5 to A10 use only orders with `Status = 'Completed'`.
- **A4:** the brief does not ask for completed orders only, and the task needs only `Sales.OrderItems`, so no status filter and no join were used.
- **Rounding in filters (A4 and A7):** the revenue condition is applied to the rounded value (`ROUND(..., 2)`), the same expression that is displayed, so the filter and the output agree.
- **A6:** "average selling unit price" is not defined in the brief. I used the simple average of the order-line `UnitPrice`, before discount. Distinct orders are counted with `COUNT(DISTINCT OrderID)` so an order with several lines in one category is counted once.
- **A8:** the average price is calculated over active products only (`IsActive = 1`), and only active products are listed.
- **A9:** the thresholds use "at least" (`>= 1500` High Value, `>= 700` Medium Value), and every other customer with completed orders is labelled `Standard`. Customers with no completed orders do not appear.
- **A10:** `MonthStart` is the first day of each calendar month (`DATEFROMPARTS`). Only months that contain completed orders appear.
- **A11:** the SQL answer template lists "A11 Rank customers within regions", but the assessment document lists only A1 to A10. I asked the instructor, who confirmed that A11 is not required, so it is not included.

## Part B assumptions (architecture)
- **Architecture approach:** A scalable, cloud-based architecture was proposed to support MetroFlow's continuous data ingestion, growing storage requirements, and real-time processing needs.
- **Technology choices:** Apache Kafka was selected as an example of an event-ingestion platform, Apache Flink or Spark Structured Streaming for real-time processing, Apache Spark for batch processing, and cloud object storage for long-term data retention.
- **Retention:** Raw data is retained for five years, as required by the scenario. Storage capacity can be expanded as more vehicles are added.
- **Latency:** The streaming path is designed to support the requirement to deliver delay and congestion alerts within 30 seconds. Actual performance would need to be tested under the expected workload.
- **Access and governance:** Role-based access control, encryption, pseudonymisation, and audit logging are proposed to protect passenger identifiers and vehicle location data.


## Part C assumptions (storage and modelling)

- **Timing method:** each format was loaded three times with the same procedure. The median is reported and all runs were kept. No run was removed. The final table and discussion use the values from the last full run (Restart and Run All).
- **Benchmark limitation:** the files contain only 480 rows and may be cached by the operating system. The timing covers the whole DataFrame load (file access, parsing, type conversion, memory allocation), so the results illustrate differences between formats and are not a benchmark for large datasets.
- **Parquet file:** the supplied `04_retail_sales.parquet` was used as provided.
- **Partitioning (C4):** the proposed partition key is a month value derived from `order_date` (for example `order_month`), giving about 60 partitions over five years. No partitioned files were created, because a proposal and justification were enough.
- **Star schema (C5):**
  - `transaction_id` is unique for all 480 rows, so it is the primary key of `FactSales`, and no extra surrogate key was added.
  - `region` varies for the same customer (a single customer appears with up to 5 different regions), so I treated it as an attribute of the sale and placed it in `FactSales`, not in `DimCustomer`.
  - Each product has exactly one name and one category, so both sit in `DimProduct`.
  - `order_id`, `returned`, `payment_method` and `promotion_code` do not belong to the Customer, Product or Date dimensions, so they are kept in `FactSales` as descriptive attributes.
- **Star schema diagram:** the diagram was created with Graphviz outside the notebook and inserted as a PNG image. The code used to create it is included in the notebook for reference.
