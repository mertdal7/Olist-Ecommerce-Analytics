# Olist E-Commerce Customer & Revenue Analytics

SQL and Tableau analysis of customer behavior, revenue drivers, and retention patterns using the Brazilian Olist e-commerce dataset.

---

# Dashboard Preview

![Dashboard](images/dashboard_preview.png)

Interactive Tableau dashboard:

https://public.tableau.com/views/Olist_Customer_Revenue_Analysis/Dashboard1

---

# Project Overview

This project analyzes an e-commerce platform to understand:

- how revenue is generated  
- how customers behave  
- whether the business has retention challenges  

The analysis combines **SQL for data analysis** and **Tableau for visualization**.

---

# Business Questions

The analysis focuses on answering the following questions:

1. Is the business growing over time?  
2. Which customers generate the most revenue?  
3. Which product categories drive revenue?  
4. Is there a customer retention problem?  
5. How concentrated is revenue among customers?

---

# Key Insights

### Revenue Growth

Revenue increased steadily during **2017**, indicating strong platform growth.

### Revenue Concentration

Top **20% of customers generate ~54% of total revenue**, showing moderate revenue concentration.

### Purchase Behavior

Approximately 97% of customers make only one purchase, highlighting a significant customer retention issue.

### Customer Retention

Customer retention drops sharply after the first purchase.

---

# Business Recommendations

Potential actions for improving the business:

- Identify growth drivers and scale successful channels  
- Retain high-value customers with loyalty programs  
- Encourage repeat purchases via targeted promotions 
- Improve post-purchase engagement and onboarding

---

# Tech Stack

**SQL (MySQL)**  
- Data transformation  
- Window functions  

**Tableau**  
- Dashboard development  
- Data visualization  

Analytical techniques used:

- Cohort retention analysis  
- Pareto analysis  
- Revenue trend analysis  
- Purchase frequency analysis  

---

# SQL Workflow

The complete SQL analysis can be found here:

```
sql/ecommerce_analysis.sql
```

Main steps:

- Data import and validation  
- Core business metric calculations  
- Customer behavior analysis  
- Revenue concentration analysis  
- Cohort retention analysis  

---

# Dataset

Olist Brazilian E-Commerce Dataset

https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce

---

# Project Structure

```
Olist-Ecommerce-Analytics
│
├── README.md
│
├── images
│   └── dashboard_preview.png
│
└── sql
    └── olist.ecommerce_analysis.sql
```

---

# Author

Mert Dal
