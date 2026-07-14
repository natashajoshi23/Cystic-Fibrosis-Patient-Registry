# Cystic Fibrosis Patient Registry Database

A relational MySQL database modeling the full **CFTR genotype → phenotype → treatment → outcome** pipeline for cystic fibrosis patients — built to answer the kinds of questions pharmaceutical researchers and clinicians actually need answered.

---

## Why This Exists

Over 40,000 people in the US live with cystic fibrosis, a progressive genetic disease caused by mutations in the CFTR gene. There is no cure. Treatment depends heavily on *which* mutation a patient carries — different CFTR classes respond to different modulator drugs — but most registries don't connect a patient's genotype to their treatment history and outcomes in one place.

This database does that.

---

## What's Inside

**11 tables across two layers:**

| Layer | Tables |
|---|---|
| Reference data | `genes`, `mutations`, `symptoms`, `drugs`, `clinical_trials` |
| Patient data | `patients`, `patient_mutations`, `patient_symptoms`, `treatments`, `outcomes`, `trial_participation` |

**Reference data sourced from:**
- CFTR mutations → [ClinVar](https://www.ncbi.nlm.nih.gov/clinvar/)
- CFTR modulator drugs → [DrugBank](https://www.drugbank.com/) / [FDA](https://www.fda.gov/)
- Symptoms & phenotypes → [Human Phenotype Ontology (HPO)](https://hpo.jax.org/)
- Clinical trials → [ClinicalTrials.gov](https://clinicaltrials.gov/)

**36 synthetic patients**, each with:
- A CFTR genotype (2 alleles from real ClinVar mutations)
- Observed symptoms with onset age and severity
- A treatment history with real CFTR modulator drugs and dosages
- Clinical outcomes tracking FEV1 lung function change and sweat chloride change per treatment
- Optional clinical trial enrollment records

---

## Schema Overview

```
genes ──< mutations ──< patient_mutations >── patients
                                                  │
                                     ┌────────────┼──────────────┐
                                     │            │              │
                              patient_symptoms  treatments  trial_participation
                                                  │
                                               outcomes
                                     (1:1 per treatment course)
```

**Key design decisions:**
- Each patient carries exactly 2 CFTR alleles (models autosomal recessive inheritance)
- Every treatment has exactly one outcome record, tracking FEV1 % change and sweat chloride change
- `trial_participation` links patients to clinical trials; `treatments` links to standard care — enabling trial-to-treatment pathway queries

---

## Analysis Queries

8 JOIN queries that answer real clinical and research questions:

| # | Question | Clinical Use |
|---|---|---|
| 1 | Which mutations are most common in the registry, and what class are they? | Prioritize modulator availability |
| 2 | For F508del carriers, which drugs were prescribed and what were the outcomes? | Does genotype predict modulator response? |
| 3 | What is the average FEV1 and sweat chloride change per drug? | Compare real-world drug effectiveness |
| 4 | Which patients have a Class I mutation AND severe respiratory symptoms? | Flag gene therapy trial candidates |
| 5 | For each trial, how many patients enrolled and completed? | Connect R&D pipelines to patient data |
| 6 | What is the average diagnosis age by CFTR class? | Test whether severe classes diagnose earlier |
| 7 | Which patients went from trial enrollment to standard prescription of the same drug? | Track trial-to-treatment pathway |
| 8 | Which mutation class most commonly drives each symptom category? | Genotype-phenotype correlation study |

---

## Key Finding

Query 3 shows that **Elexacaftor/Tezacaftor/Ivacaftor (Trikafta)** and **Ivacaftor** produce the highest average FEV1 lung function gains across registry patients — consistent with published FDA approval data and ClinicalTrials.gov outcomes for these drugs. Symptom-management therapies like Dornase alfa show smaller average FEV1 effects, as expected.

---

## How to Run

1. Clone the repo
2. Run the schema + data file in MySQL Workbench or the CLI:
```sql
SOURCE cf_registry_schema.sql;
```
3. Run individual queries from `queries.sql`, or run all at once

**Requirements:** MySQL 8.0+

---

## Files

```
├── cf_registry_schema.sql   # Full schema, reference data, and 36 mock patients
├── queries.sql              # 8 annotated analysis queries
└── README.md
```

---

## Limitations & Future Work

- Patient data is synthetic — a real system would require IRB approval, HIPAA compliance, and consent management
- Schema is CF-specific; generalizing to other rare diseases would require abstracting the `mutations` and `symptoms` tables
- Future additions: longitudinal observations table (track FEV1/sweat chloride over time), family relationship modeling (useful for hereditary diseases), and side-effect tracking per treatment

---

*Built by [Natasha Joshi](https://github.com/natashajoshi23)*
