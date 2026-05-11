# Mekari_Project

---

# Table of Content

---

# Business Understanding

## Business Background
Mekari is a fast-growing SaaS company with more than 1,400 employees ("Mekarians") distributed across multiple branches in Indonesia. In its 7th year, management aims to reassess payroll allocation to ensure cost efficiency and sustainable growth.

The payroll system currently operates on a monthly basis. However, management requires a deeper understanding of **cost efficiency in terms of salary per productive working hour, evaluated across branches and over time**, to determine whether the current scheme is aligned with employee productivity and operational performance.

## Business Problem
The existing payroll scheme does not fully reflect **employee productivity and cost efficiency**, creating potential risks such as:
- Overpaying employees relative to their productivity contribution
- Inefficient payroll budget allocation across branches
- Lack of visibility into cost per productive working hour (CPH)
- Difficulty identifying underperforming employees or structurally inefficient branches

Without proper analysis, management risks **suboptimal decision-making in workforce planning and cost control**.

## Project Objectives
This project evaluates Mekari's payroll effectiveness by analyzing the relationship between **salary, working hours, attendance, tenure, and operational efficiency**.

Specifically:
- Measuring **Cost per Productive Hour (CPH)** across branches
- Identifying **payroll inefficiencies** at employee and branch level
- Developing a **two-stage composite scoring model** to evaluate employee performance
- Classifying employees into performance tiers **(High Performer, Standard, Layoff Candidate)**
- Provide **strategic recommendations** for workforce optimization and cost efficiency

## Key Business Questions

### A. Cost Efficiency
- How cost-efficient is the current payroll scheme when evaluated using CPH across branches?
- Which branches have the highest and lowest cost efficiency, and what drives these differences?
- Does salary level reflect employee tenure and productivity, or does a **compensation-productivity mismatch** exist?

### B. Productivity & Workforce Behavior
- How do working hours and attendance vary across employees and branches?
- Given high utilization rates (~92%) and working hours (>7 hrs/day), what factors explain the **moderate average performance score (0.69)**?
- Which employees demonstrate low productivity relative to their salary?

### C. Performance Classification & Layoff Analysis
- How can employees be objectively classified using a **data-driven scoring model**?
- Who are the priority layoff candidates, and should layoff be the primary recommendation given overall high productivity levels?
- Are layoff candidates concentrated in specific branches, indicating structural inefficiencies?

### D. Strategic Direction
- Is mass layoff the most effective strategy, or would **targeted salary restructuring** yield better long-term results?
- What actionable strategies can management implement to optimize payroll allocation?

--- 

# Data Sources
This project utilizes two datasets representing employee profiles and daily work activity logs.

## 1. Timesheets Data
Daily attendance records including check-in and check-out timestamps. Used to calculate working hours and attendance-based productivity metrics.
- Records: ~39,000+ entries (Aug 2019 – Dec 2020)
- Key fields: `employee_id`, `date`, `checkin`, `checkout`

## 2. Employee Data
Employee-level information across branches. Used to analyze salary structure, tenure, and workforce distribution.
- Records: 177 employees, 16 branches
- Key fields: `employee_id`, `branch_id`, `salary`, `join_date`, `resign_date` 

## Data Integration
Both datasets merged via `employee_id`., filtered to valid employment periods only (between each employee's `join_date` and `resign_date`).

--- 

# Data Cleaning & Preparation
Cleaning was performed in **Python (Pandas)** to ensure reliability before analysis.

Key steps:
- Converted `checkin`/`checkout` to numerical format for working hours calculation
- Removed negative/invalid time entries (`checkout` < `checkin`)
- Capped working hours >14 hrs to 8 hrs standard (assumed missing checkout)
- Removed entries <1 hour (non-meaningful productivity records)
- Imputed missing `resign_date` with dataset max date (represents active employees)
- Removed duplicate employee records
- Merged timesheet and employee datasets on `employee_id` 
- Filtered to records between `join_date` and `resign_date` 

> **Assumption note:** 22 working days/month used as standard for attendance rate calculation. Months with fewer or more working days may cause minor distortion (evidenced by a small number of attendance rates slightly exceeding 1.0).

---

# Methodology & Scoring Framework

## A. Employee Scoring (Two-Stage Approach)
The scoring model separates **dynamic monthly behavior** from **static profile attributes** to avoid conflating short-term performance with long-term loyalty.

### Stage 1: Monthly Performance Score
Captures pure productivity behavior on a month-by-month basis. Only variables that change each month are included.

| Component | Weight | Rationale |
|---|---|---|
| Norm. Working Hours | 50% | Primary productivity proxy |
| Norm. Attendance Rate | 50% | Discipline & consistency |

**Normalization:**  Min-Max per month, partitioned by `month_date` (scores are relative within the same month across all employees).

```
Monthly_Score = (Norm_Working_Hours × 0.5) + (Norm_Attendance_Rate × 0.5)
```

> **Why salary is excluded from monthly scoring:** Salary is static (does not change month to month), so including it would assign a permanent fixed handicap to high-salary employees in every month's score, regardless of their actual behavior that month. Salary is more appropriately used at the layoff prioritization stage.

### Stage 2: Final Composite Score
Aggregates monthly performance history and incorporates tenure as a loyalty weight.

| Component | Weight | Rationale |
|---|---|---|
| Avg Monthly Score | 80% | Core performance signal |
| Norm. Tenure | 20% | Loyalty & experience proxy |

**Normalization:** Min-Max global across all employees (overall period).

```
Final_Score = (Norm_Avg_Monthly_Score × 0.8) + (Norm_Tenure × 0.2)
```

> **Why tenure is at final stage only:** Tenure is a static attribute - including it in monthly scoring would make a senior employee's score artificially higher every month regardless of actual behavior. At the final stage, it serves as a tiebreaker that rewards long-term commitment without distorting monthly performance measurement.

### Layoff Classification

```
- PERCENT_RANK() ≥ 0.80 → High Performer
- PERCENT_RANK() ≥ 0.20 → Standard
- PERCENT_RANK() < 0.20 → Low Performer (Layoff Candidate)
```

Among Low Performers:
- Salary ≥ company avg salary → Priority Layoff
- Salary < company avg salary → Standard Layoff

## B. Branch Scoring

| Metric | Weight | Direction | Rationale |
|---|---|---|---|
| CPH | 45% | Lower = better | Core case background KPI |
| Utilization Rate | 35% | Higher = better | SDM capacity usage |
| Payroll Burden | 20% | Lower = better | Cost per headcount |

**Normalization:** Min-Max global across all branches (overall period, scores do not change with time filters).

```
Branch_Score = (Norm_CPH × 0.45) + (Norm_Util × 0.35) + (Norm_Burden × 0.20)

Branch Status:
  PERCENT_RANK() ≥ 0.80  →  High Efficient
  PERCENT_RANK() ≥ 0.20  →  Operational
  PERCENT_RANK() < 0.20  →  Underperforming
```

> **Important:** CPH is computed as `SUM(salary) / SUM(hours)` across the full period (not as `AVG(monthly CPH)`) to avoid distortion from months with very few active employees (which would artificially inflate CPH for those months).

---

# Exploratory Data Analysis & Insights
**Tools: Python (Pandas, Matplotlib, Seaborn)**

## A. Productivity Overview
*Answers KBQ: How do working hours and attendance vary? What explains the moderate avg score given high utilization?*

### 1. Working Hours Distribution
<img width="989" height="590" alt="image" src="https://github.com/user-attachments/assets/b97a946a-5e80-44f7-a502-d3b583b219b6" />

**Finding:**
- Bimodal distribution with two peaks at **8 hours** and **9 hours/day**
- Mean: **8.45 hrs/day**, Median: **8.87 hrs/day**
- 75th percentile at 9.19 hrs, the majority of employees consistently work above the 8-hour standard
- Only a very small fraction falls below 4 hrs (already filtered during cleaning)
- Distribution is tight (std = 1.50), indicating consistent working behavior across the workforce

> 💡 **Insight A1 — Workforce is Operationally Active:**
> Mekarians are not underworking. The bimodal peak at 8–9 hours/day, combined with a 75th percentile above standard hours, confirms that **working behavior is consistently strong across the employee base**. Productivity issues, if any, are structural, not behavioral.


### 2. Distribution of Average Employee Attendance Rate
<img width="989" height="590" alt="download (5)" src="https://github.com/user-attachments/assets/52fbc34d-3ed7-4fdf-bbdc-2583bf754071" />

**Findings:**
- Mean attendance rate: **82.9%**, Median: **85.5%**
- 75th percentile at 95.9%, majority of employees attend very consistently
- Distribution is left-skewed: the low-attendance cluster (<0.4) is a small minority
- Small number of employees show attendance rate slightly >1.0, which is an artifact of the 22-day/month assumption *(see Limitations)*

> 💡 **Insight A2 — High Attendance Confirms Utilization Is Genuine:**
> The ~92% average utilization rate is not a calculation anomaly, it is supported by genuinely high attendance across most employees. The workforce is present and working. This makes the moderate avg final score (0.69) even more noteworthy, and points to a **structural rather than behavioral explanation.**


### 3. Combined Insight A, The Productivity Paradox:
> *Mekarians work an average of 8.45 hrs/day with an 82.9% attendance rate and ~92% utilization. Yet the average final score is only 0.69. This is not a contradiction, it is a signal that the issue lies in the **compensation structure, not employee behavior**. Employees are operationally productive, but cost per productive hour is not proportional across all branches and individuals. The primary driver of moderate scores is the **compensation-tenure mismatch**: many employees are in mid-to-high salary bands despite having low tenure, which suppresses their final score through the normalized tenure component, even when their daily performance is solid. As the salary-working hours analysis in Section B will further confirm, this mismatch is not limited to low performers, it is distributed across salary bands, pointing to a systemic issue in compensation policy design rather than isolated individual underperformance.*


## B. Cost Efficiency Analysis
*Answers KBQ: How cost-efficient is the payroll scheme? Which branches are most/least efficient? Does salary reflect productivity?*

### 1. Cost per Hour (CPH) Analysis by Branch
<img width="1189" height="690" alt="download" src="https://github.com/user-attachments/assets/fea8c905-95b1-4470-8ab2-2e405e9b4e6f" />

**Findings:**
- CPH range: **Rp42,941 (Branch 12722)** to **Rp72,765 (Branch 11265)**
- Standard deviation: Rp7,779, significant disparity across branches
- Branch 12722 is the most cost-efficient: lowest salary cost per productive hour
- Branches 11265, 2633, 2636 are the most expensive: CPH >Rp70,000
- Median CPH at Rp63,334 - more than half of branches exceed Rp60,000/hour

> 💡 **Insight B1 — Wide CPH Disparity Signals Unequal Cost Allocation:**
> The gap between the most and least efficient branches is nearly **69%** (Rp42.9K vs Rp72.8K). The highest-CPH branches pay almost twice as much per productive hour as the best-performing branch, for comparable operational output. This indicates a significant imbalance in payroll distribution that warrants branch-level review — though as discussed in Section C, CPH alone is insufficient to conclude structural inefficiency without considering branch observation period length.


### 2. Strategic Talent Mapping: Salary vs. Avg Working Hours
<img width="1189" height="790" alt="download (1)" src="https://github.com/user-attachments/assets/1a6b84fd-43aa-4d95-9823-c3bfa31bb54e" />


**Findings:**
- **Top-right quadrant** (High Salary / High Hours): ~30–35 employees, **not the dominant cluster**, contrary to what a healthy compensation system would show
- **Top-left quadrant** (High Salary / Low Hours): ~40–45 employees, one of the **largest clusters**, indicating widespread overpayment relative to working hour contribution
- **Bottom-right quadrant** (Low Salary / High Hours): ~40–45 employees, equally large, representing a **substantial underpaid but productive** workforce segment
- **Bottom-left quadrant** (Low Salary / Low Hours): ~30-35 employees, underutilized and underpaid, lowest priority for retention
- No positive correlation observed between salary level and working hours, the compensation structure does not effectively reward productivity

> 💡 **Insight B2 — Salary and Productivity Are Not Aligned at a Systemic Level:**
> Contrary to what a healthy compensation system should show, higher salary does not correlate with higher working hours at Mekari. The **High Salary / Low Hours quardrant is one of the largest clusters**, meaning a substantial portion of the high-salary workforce consistently works below the median working hours. Simultaneously, the **Low Salary / High Hours quadrant is equally large**, representing employees who contribute above-median hours but are compensated below the median salary.
> 
> This is not an isolated mismatch, it is a **systemic misalignment between compensation and effort contribution** affecting a large portion of the workforce. The implication is significant: Mekari's current salary structure does not effectively incentivize or reward productive behavior. This finding strengthens the case for a **company-wide salary band review**, extending well beyond the 34 layoff candidates identified by the scoring model.


## C. Performance Scoring & Classification
*Answers KBQ: How are employees classified? What explains moderate avg scores? Are underperforming branches structurally different?*

### 1. Performance Distribution: Percentile-Based Thresholds
<img width="987" height="590" alt="download (2)" src="https://github.com/user-attachments/assets/0e2541d6-fae3-4658-99a5-07c2f9b27656" />

**Findings:**
- Distribution is **right-skewed**: majority of employees score between **0.6–0.8**
- Mean: **0.69**, Median: **0.73**, a reasonably healthy central tendency
- Bottom 20% threshold (Low Performer cutoff): **score 0.64** → 34 employees
- Top 20% threshold (High Performer cutoff): **score 0.80** → 34 employees
- Small isolated cluster at score <0.2: extreme outliers requiring urgent attention
- Standard deviation: 0.16, moderate spread, not highly polarized

> 💡 **Insight C1 — Moderate Scores Reflect Structure, Not Failure:**
> The average final score of 0.69 does not indicate widespread underperformance. The distribution is healthy and centered, with 60% of employees in the Standard tier. The moderate average is structurally explained by the **compensation-tenure mismatch** identified in Sections A and B: employees with low tenure and high salaries receive a normalized tenure penalty in the final score, even when their monthly performance is solid. The small extreme-low cluster (<0.2) represents genuinely problematic cases distinct from the broader population and should be treated as immediate priority.


## 2. Score Analysis by Branch (Ranked by Score)
<img width="1189" height="690" alt="download (3)" src="https://github.com/user-attachments/assets/666b6806-8822-417b-9d93-8f8aee670d96" />

**Findings:**
- Branch 12722 dominates with a score of **0.86**, far above the average of 0.45
- **4 branches classified as High Efficient** (score >0.57): 12722, 2626, 2631, 1
- **9 branches classified as Operational** (score 0.30–0.57)
- **3 branches classified as Underperforming** (score <0.30): 2630, 3, 11265
- Branch 11265 is the lowest outlier with a score of **0.12**, only 14% of the best branch
- Standard deviation: 0.18, wide disparity confirming unequal branch efficiency

> 💡 **Insight C2 — Caution: Observation Period Bias: Branch 11265 May Reflect Newness, Not Chronic Underperformance:**
> Branch 11265's extremely low score (0.12) and high CPH (Rp72,765) appear alarming at first glance. However, the trend data reveals a pattern consistent with a **newly established branch**: CPH starts very high in early months (full salary cost but low working hours during onboarding/ramp-up), then declines sharply; simultaneously, utilization starts low and rises steadily as the branch reaches operational capacity.
> 
>This ramp-up signature is also visible in other branches when they first appear in the data. Since branch efficiency scores are computed as an overall average **across all available months**, branches with a shorter observation period are systematically **penalized by their ramp-up phase**, skewing their score downward even if their steady-state performance is comparable to operational branches.
> 
> **Branch 11265's low score likely reflects its newness, not chronic inefficiency**. Recommended action: re-evaluate branch scores after excluding the first 3 months of each branch's data to produce a more comparable "steady-state efficiency" metric before drawing structural conclusions.


### 3. Combined Insight C — Compensation-Tenure Mismatch as Root Cause:
> *The convergence of high working hours, high attendance, and moderate final scores points to one primary structural explanation: many employees carry mid-to-high salary levels despite having relatively low tenure. Since tenure contributes 20% to the final score and is normalized globally, newer employees with low tenure receive an automatic score penalty, regardless of how productive they are on a daily basis.
> 
> This is reinforced by the salary-working hours scatter in Section B, where high-salary employees are not working more hours than lower-salary peers. Together, these two findings consistently point to the same root cause: **Mekari's compensation structure is not calibrated to tenure or productivity, it is advancing employees into higher salary bands faster than their experience and track record justify.***


## D. Layoff Analysis & Strategic Mapping
*Answers KBQ: Who are the layoff candidates? Should mass layoff be the recommendation? Are candidates branch-concentrated?*

### 1. Layoff Proportion
<img width="1007" height="695" alt="download (4)" src="https://github.com/user-attachments/assets/f3313097-0fba-4e5f-8fb6-72d9e6b7a7fe" />

**Findings:**

| Segment | % | Count | Monthly Salary |
|---|---|---|---|
| Retained — Active | 70.6% | ~120 | — |
| Retained — Already Resigned | 9.4% | ~16 | — |
| Standard Layoff — Active | 5.3% | ~9 | Rp66M |
| Priority Layoff — Active | 4.7% | ~8 | Rp100M |
| Priority Layoff — Already Resigned | 6.5% | ~11 | Rp181M* |
| Standard Layoff — Already Resigned | 3.5% | ~6 | included above* |

*\*Rp181M/month in savings already automatically realized from the 17 resigned candidates.*

> 💡 **Insight D1 — Actionable Saving Is Smaller Than the Headline Number:**
> Of the 34 total layoff candidates, **17 have already resigned** before this analysis, meaning Rp181M/month in potential savings has been **automatically realized** without any management action. The genuinely actionable saving remaining is **Rp166M/month from 17 active candidates** (8 Priority + 9 Standard).
>
> Presenting the total Rp347M figure without this context would significantly overstate the actual decision-making opportunity. Furthermore, **dashboard analysis shows that layoff candidates are not evenly distributed across branches**, certain branches contribute disproportionately more candidates, suggesting that branch-level structural factors (headcount relative to workload, salary band decisions at hiring) play a role beyond individual employee performance.


### 2. Strategic Talent Mapping: Salary vs. Overall Performance Score
<img width="1188" height="790" alt="download (6)" src="https://github.com/user-attachments/assets/143eeadb-147f-4500-8c05-cec74711573a" />

**Findings:**

| Quadrant | Profile | Layoff Decision |
|---|---|---|
| High Score / High Salary | Key Talent,  critical to retain | Retained |
| Low Score / High Salary | Efficiency Target, high cost, low return | **Priority Layoff** |
| Low Score / Low Salary | Underperformer, low cost but low contribution | **Standard Layoff** |
| High Score / Low Salary | High Potential, productive but underpaid | Retained (⚠️ flight risk) |

> 💡 **Insight D2 — The Hidden Risk: High Performers Who Are Underpaid:**
> While the Priority Layoff quadrant (Low Score / High Salary) receives the most immediate attention, the **High Score / Low Salary quadrant** represents an equally important strategic risk. These employees deliver strong performance but are compensated below the company average, making them the most likely to leave voluntarily.
>
> Losing high performers to voluntary attrition eliminates productive capacity that is far more valuable than the savings generated from removing low performers. This quadrant is the direct counterpart to the systemic misalignment identified in Insight B2: if high-working-hours employees are systematically underpaid, the organization is simultaneously overpaying underproductive staff and underpaying its most committed contributors. A retention program for this group is not optional, it is a necessary complement to any layoff strategy.

### 3. Combined Insight D — Targeted Action Outperforms Mass Layoff:
> With an overall utilization rate of ~92% and the majority of employees in the productive quadrant, mass layoff poses a significant risk of reducing operational capacity that is genuinely contributing to business output. The evidence across all four sections consistently points toward a more surgical approach:
>
> 1. **Immediately execute Priority Layoff** (8 active candidates), clearest ROI, strongest justification from the scoring model, highest salary-to-score mismatch
> 2. **Review salary bands for Standard Layoff candidates** before PHK decisions, some may be more appropriately handled through salary adjustment or redeployment, given the high overall utilization context
> 3. **Address the systemic compensation misalignment** identified in Insight B2, the salary-productivity gap affects a far larger portion of the workforce than the 34 classified candidates, and requires a company-wide policy response, not just individual case management
> 4. **Implement retention measures for High Score / Low Salary employees**, protecting top contributors is as strategically important as removing low performers, and directly addresses the voluntary attrition risk created by the current compensation structure

---

# Dashboard Development
**Tools: Power BI**
An interactive 3-page dashboard was developed to communicate findings to both technical and non-technical stakeholders.

<img width="973" height="544" alt="image" src="https://github.com/user-attachments/assets/72a19fe1-d6b9-490b-853b-54371095715e" />
<img width="979" height="546" alt="image" src="https://github.com/user-attachments/assets/5af3d49d-3c5a-4f58-ba91-9366da8339ee" />
<img width="984" height="549" alt="image" src="https://github.com/user-attachments/assets/b232aebf-ee39-46bc-a7a1-4f8c80e1ba0c" />


## Page 1 - Branch Efficiency Overview
Provides an executive-level view of branch-level cost efficiency, utilization, and payroll burden. Includes trend charts for CPH and utilization rate over the 17-month analysis period.

> Key features: Branch efficiency score ranking, CPH/Utilization/Payroll Burden comparison, monthly trend lines for bottom 5 branches.

## Page 2 - Employee Performance & Scoring
Deep dives into individual employee performance, scoring distribution, and the relationship between salary and final score.

> Key features: Final score distribution with threshold lines (p20 / p80), salary vs. final score scatter plot with 4-quadrant layoff mapping, working hours and attendance distributions, full employee scoring detail table.

## Page 3 - Layoff Impact & Saving Analysis
Decision-support page focused on the financial impact of layoff scenarios and the strategic profile of candidates.

> Key features: Layoff proportion donut (6 segments), payroll waterfall (before vs. after layoff, active candidates only), branch-level candidate distribution, avg score comparison between retained and layoff candidates.

> **Note:** Branch scores and employee final scores are fixed based on the full analysis period (Aug 2019–Dec 2020). Time and branch filters affect trend charts only and do not recalculate scores — by design, to ensure analytical consistency.


---

# Key Insights & Strategic Recommendations

## Core Finding
> Mekari's workforce is **operationally productive** (avg 8.45 hrs/day, ~92% utilization, 82.9% attendance). The payroll efficiency problem is not one of employee laziness. It is a **systemic misalignment between compensation levels, employee tenure, and actual working hour contribution**, compounded by unequal cost distribution across branches.

## Recommendations by Priority

### Urgent - Execute Immediately
**1. Proceed with Priority Layoff (8 active candidates)**
- Salary ≥ company average + final score in bottom 20%
- Estimated saving: **Rp100M/month**
- These candidates have the clearest and most defensible justification from the scoring model
- Recommended action: initiate HR process within the current review cycle

### Medium Priority - Within 1-3 Months
**2a. Conduct salary review for Standard Layoff candidates (~9 active)**
- Before executing termination, evaluate whether salary adjustment or redeployment to higher-volume branches is more operationally sound
- Given high overall utilization (~92%), reducing headcount should be approached with caution — capacity impact must be assessed per branch
- Estimated saving if fully executed: **Rp66M/month**

**2b. Conduct company-wide salary-to-productivity realignment**
- The salary vs. working hours scatter reveals **systemic misalignment**: high salary does not correlate with high working hours, affecting a substantial portion of the workforce beyond the 34 identified layoff candidates
- Recommended action: audit salary bands across all performance tiers, with particular focus on the High Salary / Low Hours segment who are not classified as layoff candidates but still represent inefficient cost allocation

**3. Re-evaluate Branch 11265 using steady-state scoring methodology**
- Current score (0.12) and CPH (Rp72,765) may be artifacts of a short observation period and ramp-up effect, not chronic structural inefficiency
- Recommended action: recalculate branch scores excluding the first 3 months of each branch's operation period; if Branch 11265's score improves significantly, deprioritize audit and shift to monitoring mode
- If ramp-up hypothesis is disproven by the recalculation, escalate to full headcount-to-workload ratio review

### Long-Term Strategic — Ongoing
**4. Review salary onboarding and banding policy**
- Many employees are placed in mid-to-high salary bands with low tenure
- This creates a structural mismatch that suppresses scoring, inflates CPH, and makes layoff identification harder to distinguish from compensation policy effects
- Recommended action: establish tenure-gated salary progression milestones tied to performance review cycles

**5. Implement retention program for High Score / Low Salary employees**
- This segment is the most productive and most at risk of voluntary attrition
- Their departure represents a net productivity loss that is not offset by any direct cost saving
- Recommended action: salary band review and structured recognition program for this quadrant, prioritized by branch

**6. Standardize branch-level utilization monitoring**
- Overall utilization of ~92% is strong, but distribution across branches is unequal
- Branches with simultaneously low utilization and high CPH should be flagged for quarterly review
- Recommended action: establish branch-level utilization KPI targets and quarterly variance reporting


---

## 8. Limitations & Notes

| # | Limitation | Impact |
|---|---|---|
| 1 | Working hours used as **proxy for productivity**, no output/quality metrics available (e.g. revenue per employee, project delivery rate) | Productivity assessment is effort-based, not outcome-based |
| 2 | **22 working days/month** assumed as fixed standard | Attendance rate slightly exceeds 1.0 for some employees in months with more working days |
| 3 | Scoring model **weights (80/20, 50/50)** are based on analytical judgment, no statistical validation (e.g. regression, PCA) was performed to derive optimal weights | Weights are reasonable but not empirically derived |
| 4 | **Branch IDs** are used as identifiers — city or location information is not available in this dataset | Geographic analysis or regional benchmarking is not possible |
| 5 | Analysis period **(Aug 2019–Dec 2020)** spans the early COVID-19 period | Behavioral patterns in 2020 may be partially influenced by pandemic-related factors, not purely operational |
| 6 | Layoff recommendations are **data-driven and model-based** — final decisions should be combined with qualitative HR assessment, labor law compliance, and individual context | Scores should inform, not replace, human judgment in HR decisions |
| 7 | Branch scoring uses overall period averages without accounting for branch age | Newly established branches are systematically penalized by ramp-up phase data, potentially misclassifying them as underperforming. A tenure-adjusted branch scoring methodology would produce more comparable results. |

---

# Technical Resources
For a detailed step-by-step technical breakdown, including Python scripts for all 6 stages, please refer to:

**Source Code:** [Google Colab Notebook](https://colab.research.google.com/drive/1VhUIdYZ4fwIOt8FNcihVkQzjXW9d8NYQ?usp=sharing)

---

*Project by Nafidza Shadrina Diva Aulia | Tools: Python, MySQL, Power BI | Data: Bitlabs Bootcamp Case Study*
