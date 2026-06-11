# 🔍 SQL Murder Mystery — Complete Solution

> Solving a murder investigation using pure SQL — from crime scene to hidden mastermind.

[![SQL](https://img.shields.io/badge/SQL-SQLite-blue?logo=sqlite&logoColor=white)](https://mystery.knightlab.com/)
[![Status](https://img.shields.io/badge/Case-Solved%20✔-brightgreen)]()
[![Level](https://img.shields.io/badge/Level-Advanced-red)]()
[![Concepts](https://img.shields.io/badge/Concepts-JOINs%20%7C%20CTEs%20%7C%20Subqueries-orange)]()

---

## 📌 About This Project

The [SQL Murder Mystery](https://mystery.knightlab.com/) is a free, gamified SQL challenge by **Knight Lab (Northwestern University)**. The goal is to investigate a murder using only SQL queries on a relational SQLite database — no hints, just data.

**The scenario:**
> A murder occurred on **January 15, 2018** in **SQL City**. The detective lost the crime scene report. Using only the database, identify the murderer — and the wealthy mastermind who hired them.

---

## 🗃️ Database Schema

```
┌─────────────────────────┐     ┌──────────────────────────┐
│   crime_scene_report    │     │         person           │
│─────────────────────────│     │──────────────────────────│
│ date        INTEGER     │     │ id           INTEGER  PK │
│ type        TEXT        │     │ name         TEXT        │
│ description TEXT        │     │ license_id   INTEGER  FK │
│ city        TEXT        │     │ address_number INTEGER   │
└─────────────────────────┘     │ address_street_name TEXT │
                                │ ssn          CHAR        │
┌─────────────────────────┐     └──────────────────────────┘
│    drivers_license      │
│─────────────────────────│     ┌──────────────────────────┐
│ id          INTEGER  PK │     │        interview         │
│ age         INTEGER     │     │──────────────────────────│
│ height      INTEGER     │     │ person_id    INTEGER  FK │
│ eye_color   TEXT        │     │ transcript   TEXT        │
│ hair_color  TEXT        │     └──────────────────────────┘
│ gender      TEXT        │
│ plate_number TEXT       │     ┌──────────────────────────┐
│ car_make    TEXT        │     │   get_fit_now_member     │
│ car_model   TEXT        │     │──────────────────────────│
└─────────────────────────┘     │ id           TEXT     PK │
                                │ person_id    INTEGER  FK │
┌─────────────────────────┐     │ name         TEXT        │
│  get_fit_now_check_in   │     │ membership_start_date INT│
│─────────────────────────│     │ membership_status TEXT   │
│ membership_id TEXT   FK │     └──────────────────────────┘
│ check_in_date  INTEGER  │
│ check_in_time  INTEGER  │     ┌──────────────────────────┐
│ check_out_time INTEGER  │     │  facebook_event_checkin  │
└─────────────────────────┘     │──────────────────────────│
                                │ person_id    INTEGER  FK │
┌─────────────────────────┐     │ event_id     INTEGER     │
│         income          │     │ event_name   TEXT        │
│─────────────────────────│     │ date         INTEGER     │
│ ssn         CHAR     FK │     └──────────────────────────┘
│ annual_income INTEGER   │
└─────────────────────────┘
```

---

## 🧠 My Approach

Solved the mystery in **10 steps** across 2 parts:

| Part | Goal | Steps |
|------|------|-------|
| Part 1 | Find the murderer | Steps 1–8 |
| Part 2 (Bonus) | Expose the mastermind | Steps 9–10 |

**Key challenge:** The final mastermind reveal was solved in a **single query using 3 chained CTEs** — no manual lookups.

---

## 🔎 Step-by-Step Solution

### Step 1 — Get the Crime Scene Report

```sql
SELECT *
FROM crime_scene_report
WHERE city = 'SQL City'
  AND date = 20180115
  AND type = 'murder';
```

**📋 Result:** 2 witnesses — one at the last house on Northwestern Dr, one named Annabel on Franklin Ave.

---

### Step 2 — Find Witness 1 (Last House on Northwestern Dr)

```sql
SELECT *
FROM person
WHERE address_street_name = 'Northwestern Dr'
ORDER BY address_number DESC
LIMIT 1;
```

**📋 Result:** `Morty Schapiro` — id: 14887, address: 4919 Northwestern Dr

---

### Step 3 — Find Witness 2 (Annabel on Franklin Ave)

```sql
SELECT *
FROM person
WHERE name LIKE '%Annabel%'
  AND address_street_name = 'Franklin Ave';
```

**📋 Result:** `Annabel Miller` — id: 16371, address: 103 Franklin Ave

---

### Step 4 — Read Both Witness Transcripts

```sql
SELECT p.name, i.transcript
FROM interview i
JOIN person p ON p.id = i.person_id
WHERE i.person_id IN (14887, 16371);
```

**📋 Key Clues Extracted:**
- 🏋️ Suspect has **Get Fit Now Gym gold membership** starting with `48Z`
- 📅 Was at the gym on **January 9, 2018**
- 🚗 Car plate contains `H42W`

---

### Step 5 — Check Gym Records

```sql
SELECT *
FROM get_fit_now_check_in
WHERE membership_id LIKE '48Z%'
  AND check_in_date = 20180109;
```

**📋 Result:** 2 suspects — membership IDs `48Z55` and `48Z7A`

---

### Step 6 — Get Their Names

```sql
SELECT *
FROM get_fit_now_member
WHERE id IN ('48Z7A', '48Z55');
```

**📋 Result:** Jeremy Bowers (48Z55) and Joe Germuska (48Z7A)

---

### Step 7 — Match Car Plate 'H42W'

```sql
SELECT *
FROM drivers_license
WHERE plate_number LIKE '%H42W%';
```

**📋 Result:** License IDs `423327` (male) and `664760` (male) match

---

### Step 8 — Cross-reference with Person Table

```sql
SELECT *
FROM person
WHERE license_id IN (423327, 664760);
```

**📋 Result:** Jeremy Bowers (id: 67318) matches BOTH the gym check-in AND the plate! ✅

> **✅ MURDERER: `Jeremy Bowers`**

---

### Step 9 — Read Jeremy's Interview Transcript

```sql
SELECT transcript
FROM interview
WHERE person_id = 67318;
```

**📋 Mastermind Clues:**
- Female, height 65–67", red hair, drives Tesla Model S
- Attended SQL Symphony Concert **exactly 3 times in December 2017**

---

### Step 10 — Find the Mastermind (Advanced CTE)

```sql
WITH
red_hair_tesla AS (
    SELECT id AS license_id
    FROM drivers_license
    WHERE gender     = 'female'
      AND hair_color = 'red'
      AND height     BETWEEN 65 AND 67
      AND car_make   = 'Tesla'
      AND car_model  = 'Model S'
),
matching_persons AS (
    SELECT p.id AS person_id, p.name, p.ssn
    FROM person p
    JOIN red_hair_tesla rht ON rht.license_id = p.license_id
),
concert_goers AS (
    SELECT person_id, COUNT(*) AS times_attended
    FROM facebook_event_checkin
    WHERE event_name LIKE '%SQL Symphony Concert%'
      AND date BETWEEN 20171201 AND 20171231
    GROUP BY person_id
    HAVING COUNT(*) = 3
)
SELECT mp.name, mp.person_id, cg.times_attended, i.annual_income
FROM matching_persons mp
JOIN concert_goers    cg ON cg.person_id = mp.person_id
JOIN income            i ON i.ssn = mp.ssn;
```

**📋 Result:** `Miranda Priestly` — Annual income: $310,000 | Attended concert: 3 times ✅

> **✅ MASTERMIND: `Miranda Priestly`**

---

## 🏆 Final Answers

| Role | Name |
|------|------|
| 🔪 Murderer | Jeremy Bowers |
| 🧠 Mastermind | Miranda Priestly |

---

## 💡 SQL Concepts Used

| Concept | Where Applied |
|---------|--------------|
| `WHERE` + `AND` | Filtering crime report, dates, city |
| `LIKE` | Partial membership ID (`48Z%`), plate (`%H42W%`) |
| `ORDER BY` + `LIMIT 1` | Finding the last house on a street |
| `JOIN` (multi-table) | Linking person ↔ interview ↔ gym ↔ license |
| `IN` | Matching multiple IDs at once |
| `GROUP BY` + `HAVING` | Counting concert attendance per person |
| `BETWEEN` | Height range and date range filtering |
| `CTEs (WITH clause)` | Chaining 3 filters into one clean mastermind query |

---

## 🚀 How to Run

**Option 1 — Browser (Easiest)**
1. Go to [mystery.knightlab.com](https://mystery.knightlab.com/)
2. Paste queries from [`solution.sql`](./solution.sql) one step at a time

**Option 2 — Local SQLite**
```bash
# Download the DB from the repo or use the uploaded .db file
sqlite3 sql-murder-mystery.db
# Then paste queries interactively
```

**Option 3 — Python**
```python
import sqlite3
conn = sqlite3.connect('sql-murder-mystery.db')
cur = conn.cursor()
cur.execute("SELECT * FROM crime_scene_report WHERE city='SQL City' AND date=20180115")
print(cur.fetchall())
```

---

## 📁 Files

```
├── README.md              ← This file (project overview + all queries)
├── solution.sql           ← All 10 queries with results as comments
└── sql-murder-mystery.db  ← SQLite database (optional to upload)
```


---

*Challenge by [Knight Lab, Northwestern University](https://knightlab.northwestern.edu/) · Solved with SQL 🔍*
