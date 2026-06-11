
-- ================================================================
-- 🔍 SQL MURDER MYSTERY — COMPLETE SOLUTION
-- Play here: https://mystery.knightlab.com/
-- Database : SQLite (sql-murder-mystery.db)
-- Author   : [Your Name]
-- ================================================================


-- ================================================================
-- STEP 0 — Explore the Database
-- Always understand the schema before writing queries
-- ================================================================

SELECT name
FROM sqlite_master
WHERE type = 'table';

/*
TABLES:
  crime_scene_report | drivers_license | facebook_event_checkin
  interview          | get_fit_now_member | get_fit_now_check_in
  income             | person           | solution
*/


-- ================================================================
-- STEP 1 — Get the Crime Scene Report
-- Known facts: murder | Jan 15 2018 | SQL City
-- ================================================================

SELECT *
FROM crime_scene_report
WHERE city = 'SQL City'
  AND date = 20180115
  AND type = 'murder';

/*
RESULT:
  "Security footage shows that there were 2 witnesses.
   The first witness lives at the last house on 'Northwestern Dr'.
   The second witness, named Annabel, lives somewhere on 'Franklin Ave'."

CLUES:
  → Witness 1: Last (highest) house number on Northwestern Dr
  → Witness 2: First name Annabel, lives on Franklin Ave
*/


-- ================================================================
-- STEP 2 — Find Witness 1
-- Last house = MAX address number on Northwestern Dr
-- ================================================================

SELECT *
FROM person
WHERE address_street_name = 'Northwestern Dr'
ORDER BY address_number DESC
LIMIT 1;

/*
RESULT:
  id: 14887 | name: Morty Schapiro
  address: 4919 Northwestern Dr
  license_id: 118009 | ssn: 111564949
*/


-- ================================================================
-- STEP 3 — Find Witness 2
-- Name LIKE '%Annabel%' on Franklin Ave
-- ================================================================

SELECT *
FROM person
WHERE name LIKE '%Annabel%'
  AND address_street_name = 'Franklin Ave';

/*
RESULT:
  id: 16371 | name: Annabel Miller
  address: 103 Franklin Ave
  license_id: 490173 | ssn: 318771143
*/


-- ================================================================
-- STEP 4 — Read Both Witness Transcripts
-- ================================================================

SELECT p.name, i.transcript
FROM interview i
JOIN person p ON p.id = i.person_id
WHERE i.person_id IN (14887, 16371);

/*
RESULT — Morty Schapiro:
  "I heard a gunshot and then saw a man run out. He had a
   'Get Fit Now Gym' bag. The membership number on the bag
   started with '48Z'. Only gold members have those bags.
   The man got into a car with a plate that included 'H42W'."

RESULT — Annabel Miller:
  "I saw the murder happen, and I recognized the killer from
   my gym when I was working out last week on January the 9th."

CLUES:
  → Gold member at Get Fit Now Gym
  → Membership ID starts with '48Z'
  → Was at gym on January 9, 2018
  → Car plate contains 'H42W'
*/


-- ================================================================
-- STEP 5 — Check Gym Check-in Records
-- Filter: membership starts with 48Z AND check-in date Jan 9
-- ================================================================

SELECT *
FROM get_fit_now_check_in
WHERE membership_id LIKE '48Z%'
  AND check_in_date = 20180109;

/*
RESULT:
  membership_id: 48Z7A | check_in: 1600 | check_out: 1730
  membership_id: 48Z55 | check_in: 1530 | check_out: 1700

→ 2 suspects with matching gym check-ins
*/


-- ================================================================
-- STEP 6 — Get Gym Member Details for Both Suspects
-- ================================================================

SELECT *
FROM get_fit_now_member
WHERE id IN ('48Z7A', '48Z55');

/*
RESULT:
  id: 48Z55 | person_id: 67318 | name: Jeremy Bowers | status: gold
  id: 48Z7A | person_id: 28819 | name: Joe Germuska  | status: gold
*/


-- ================================================================
-- STEP 7 — Cross-check with Car Plate 'H42W'
-- Get driver license IDs matching plate pattern
-- ================================================================

SELECT *
FROM drivers_license
WHERE plate_number LIKE '%H42W%';

/*
RESULT:
  id: 183779 | female | plate: H42W0X | Toyota Prius
  id: 423327 | male   | plate: 0H42W2 | Chevrolet Spark LS
  id: 664760 | male   | plate: 4H42WR | Nissan Altima

→ 2 male matches: license_id 423327 and 664760
*/


-- ================================================================
-- STEP 8 — Match Person Table with License IDs
-- ================================================================

SELECT *
FROM person
WHERE license_id IN (423327, 664760);

/*
RESULT:
  id: 51739 | name: Tushar Chandra | license_id: 664760
  id: 67318 | name: Jeremy Bowers  | license_id: 423327

→ Jeremy Bowers (id: 67318) appears in BOTH gym check-in AND plate match!
*/


-- ================================================================
-- ✅ MURDERER CONFIRMED: Jeremy Bowers (person_id: 67318)
-- He matches: gold gym member starting 48Z + plate H42W + Jan 9 check-in
-- ================================================================

-- Verify answer
INSERT INTO solution VALUES (1, 'Jeremy Bowers');
SELECT value FROM solution;
-- "Congrats, you found the murderer! But wait, there's more..."


-- ================================================================
-- STEP 9 — Read Jeremy's Interview (Bonus: Find the Mastermind)
-- ================================================================

SELECT transcript
FROM interview
WHERE person_id = 67318;

/*
RESULT:
  "I was hired by a woman with a lot of money. I don't know her name
   but I know she's around 5'5" (65") or 5'7" (67"). She has red hair
   and she drives a Tesla Model S. I know that she attended the SQL
   Symphony Concert 3 times in December 2017."

MASTERMIND CLUES:
  → Female
  → Height: 65–67 inches
  → Red hair
  → Drives: Tesla Model S
  → Attended SQL Symphony Concert exactly 3x in December 2017
*/


-- ================================================================
-- STEP 10 — Find the Mastermind (ADVANCED — Single CTE Query)
-- ================================================================

WITH

-- CTE 1: Filter by physical description + vehicle
red_hair_tesla AS (
    SELECT id AS license_id
    FROM drivers_license
    WHERE gender     = 'female'
      AND hair_color = 'red'
      AND height     BETWEEN 65 AND 67
      AND car_make   = 'Tesla'
      AND car_model  = 'Model S'
),

-- CTE 2: Get matching persons from person table
matching_persons AS (
    SELECT p.id   AS person_id,
           p.name,
           p.ssn
    FROM person p
    JOIN red_hair_tesla rht ON rht.license_id = p.license_id
),

-- CTE 3: Attended SQL Symphony Concert exactly 3 times in Dec 2017
concert_goers AS (
    SELECT person_id,
           COUNT(*) AS times_attended
    FROM facebook_event_checkin
    WHERE event_name LIKE '%SQL Symphony Concert%'
      AND date BETWEEN 20171201 AND 20171231
    GROUP BY person_id
    HAVING COUNT(*) = 3
)

-- Final join: all three conditions must be true
SELECT
    mp.name,
    mp.person_id,
    cg.times_attended,
    i.annual_income
FROM matching_persons  mp
JOIN concert_goers     cg ON cg.person_id = mp.person_id
JOIN income             i ON i.ssn = mp.ssn;

/*
RESULT:
  name: Miranda Priestly
  person_id: 99716
  times_attended: 3
  annual_income: 310,000

✅ MASTERMIND FOUND: Miranda Priestly
*/


-- ================================================================
-- Verify Mastermind
-- ================================================================

INSERT INTO solution VALUES (1, 'Miranda Priestly');
SELECT value FROM solution;
-- "Congrats, you found the real villain behind this crime! ..."


-- ================================================================
-- FINAL ANSWERS
-- 🔪 Murderer   → Jeremy Bowers
-- 🧠 Mastermind → Miranda Priestly
--
-- SQL Concepts Used:
--   WHERE, LIKE, ORDER BY, LIMIT, JOIN, IN,
--   GROUP BY, HAVING, BETWEEN, CTEs (WITH clause)
-- ================================================================
