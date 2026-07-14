-- Cystic Fibrosis Patient Registry: Analysis Queries
-- 8 questions answered with JOIN queries
USE cf_registry;

-- Q1: Which CFTR mutations are most common among registry patients, and what is their associated disease class?
-- (Helps prioritize which mutation classes a clinic sees most)

SELECT
    m.mutation_name,
    m.cftr_class,
    COUNT(pm.patient_id) AS allele_count
FROM mutations m
JOIN patient_mutations pm ON m.mutation_id = pm.mutation_id
GROUP BY m.mutation_id, m.mutation_name, m.cftr_class
ORDER BY allele_count DESC;

-- Q2: For patients carrying at least one F508del allele (the most common CF-causing mutation), which CFTR
-- modulator drugs have they been treated with, and what was the outcome?
-- (Real-world question: does genotype predict modulator response?)

SELECT DISTINCT
    p.patient_id,
    p.first_name,
    p.last_name,
    d.drug_name,
    t.start_date,
    o.outcome_status,
    o.fev1_change_pct
FROM patients p
JOIN patient_mutations pm ON p.patient_id = pm.patient_id
JOIN mutations m ON pm.mutation_id = m.mutation_id
JOIN treatments t ON p.patient_id = t.patient_id
JOIN drugs d ON t.drug_id = d.drug_id
JOIN outcomes o ON t.treatment_id = o.treatment_id
WHERE m.mutation_name = 'F508del'
  AND (d.drug_class LIKE '%Potentiator%' OR d.drug_class LIKE '%Combination%')
ORDER BY p.patient_id;

-- Q3: What is the average FEV1 change (lung function improvement) for each drug across all patients who took it?
-- (Compares real-world effectiveness of each CFTR modulator)

SELECT
    d.drug_name,
    d.drug_class,
    COUNT(o.outcome_id) AS num_patients_treated,
    ROUND(AVG(o.fev1_change_pct), 2) AS avg_fev1_change_pct,
    ROUND(AVG(o.sweat_chloride_change), 2) AS avg_sweat_chloride_change
FROM drugs d
JOIN treatments t ON d.drug_id = t.drug_id
JOIN outcomes o ON t.treatment_id = o.treatment_id
GROUP BY d.drug_id, d.drug_name, d.drug_class
ORDER BY avg_fev1_change_pct DESC;

-- Q4: Which patients have BOTH a Class I (production-deficient) mutation AND severe respiratory symptoms? 
-- These patients are unlikely to benefit from CFTR correctors and may be candidates for gene therapy trials.

SELECT DISTINCT
    p.patient_id,
    p.first_name,
    p.last_name,
    m.mutation_name,
    m.cftr_class,
    s.symptom_name,
    ps.severity
FROM patients p
JOIN patient_mutations pm ON p.patient_id = pm.patient_id
JOIN mutations m ON pm.mutation_id = m.mutation_id
JOIN patient_symptoms ps ON p.patient_id = ps.patient_id
JOIN symptoms s ON ps.symptom_id = s.symptom_id
WHERE m.cftr_class = 'Class I - Production'
  AND s.category = 'Respiratory'
  AND ps.severity = 'Severe'
ORDER BY p.patient_id;

-- Q5: For each clinical trial, list the drug being tested, its FDA approval year, and how many registry patients
-- enrolled and completed the trial. (Connects mutation/drug approaches to real patients)

SELECT
    ct.nct_id,
    ct.title,
    ct.phase,
    d.drug_name,
    d.fda_approved,
    COUNT(tp.participation_id) AS enrolled_patients,
    SUM(CASE WHEN tp.completion_status = 'Completed' THEN 1 ELSE 0 END) AS completed_patients
FROM clinical_trials ct
JOIN drugs d ON ct.drug_id = d.drug_id
LEFT JOIN trial_participation tp ON ct.trial_id = tp.trial_id
GROUP BY ct.trial_id, ct.nct_id, ct.title, ct.phase, d.drug_name, d.fda_approved
ORDER BY enrolled_patients DESC;

-- Q6: What is the average age at diagnosis for patients, broken down by the CFTR class of their first
-- (Allele 1) mutation? Earlier-onset classes (I-III) should generally show earlier diagnosis ages.

SELECT
    m.cftr_class,
    COUNT(DISTINCT p.patient_id) AS num_patients,
    ROUND(AVG(YEAR(p.diagnosis_date) - YEAR(p.birth_date)), 2) AS avg_age_at_diagnosis
FROM patients p
JOIN patient_mutations pm ON p.patient_id = pm.patient_id AND pm.allele = 'Allele 1'
JOIN mutations m ON pm.mutation_id = m.mutation_id
GROUP BY m.cftr_class
ORDER BY avg_age_at_diagnosis;

-- Q7: List any patients who were enrolled in a clinical trial for a drug, were ALSO later prescribed that same drug
-- in standard treatment, and the outcome of that treatment. (Tracks trial-to-treatment for individual patients)

SELECT
    p.patient_id,
    p.first_name,
    p.last_name,
    d.drug_name,
    ct.nct_id AS trial_participated,
    tp.enrollment_date,
    t.start_date AS treatment_start_date,
    o.outcome_status
FROM patients p
JOIN trial_participation tp ON p.patient_id = tp.patient_id
JOIN clinical_trials ct ON tp.trial_id = ct.trial_id
JOIN drugs d ON ct.drug_id = d.drug_id
JOIN treatments t ON p.patient_id = t.patient_id AND t.drug_id = ct.drug_id
JOIN outcomes o ON t.treatment_id = o.treatment_id
ORDER BY p.patient_id;

-- Q8: For each symptom category, show the most frequently associated CFTR mutation class - i.e., which genotype
-- classes drive which clinical presentations? (Useful for genotype-phenotype correlation studies)

SELECT
    s.category AS symptom_category,
    m.cftr_class,
    COUNT(*) AS occurrence_count
FROM patient_symptoms ps
JOIN symptoms s ON ps.symptom_id = s.symptom_id
JOIN patient_mutations pm ON ps.patient_id = pm.patient_id
JOIN mutations m ON pm.mutation_id = m.mutation_id
GROUP BY s.category, m.cftr_class
ORDER BY s.category, occurrence_count DESC;