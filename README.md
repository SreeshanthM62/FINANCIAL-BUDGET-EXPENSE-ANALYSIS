# Financial Budget & Expense Variance Analysis

## Business Problem

Organizations need to monitor whether actual spending remains aligned with planned
budgets, identify significant unfavorable variances, and determine where management
should prioritize corrective action.

## Objective

This project analyzes budget and actual expense data to:

- Evaluate overall budget performance
- Identify departments and categories with significant overspending
- Analyze regional and monthly spending patterns
- Identify recurring budget overruns
- Investigate high-value unfavorable transactions
- Build an Excel-based financial what-if model
- Provide actionable management recommendations

## Tools & Technologies

- Python
- Pandas
- NumPy
- Matplotlib
- Seaborn
- MySQL
- SQL
- Microsoft Excel

## Data Preparation

The dataset contains 10,000 financial transactions across departments,
expense categories, regions, and payment methods.

The data was:

- Loaded and validated using Python and MySQL
- Checked for duplicate records
- Checked for missing values
- Standardized blank analytical dimensions as `Unknown`
- Prepared for business analysis

The original raw data was preserved separately from the cleaned analytical dataset.

## SQL Analysis

SQL was used to analyze:

- Overall budget vs actual spending
- Department-level budget variance
- Department budget utilization
- Category-level variance
- Category contribution to unfavorable variance
- Regional budget performance
- Monthly budget vs actual spending
- Department-category combinations
- Department variance rankings
- Recurring monthly overspending
- Top unfavorable transactions
- Month-over-month department spending
- Category contribution to total spending

SQL techniques included:

- Aggregations
- CASE statements
- CTEs
- RANK()
- LAG()
- Window functions
- Conditional aggregation
- Date functions

## Excel Financial Model

The Excel model includes:

- Raw data
- Calculated financial metrics
- Department analysis
- Category analysis
- Variance analysis
- Monthly budget vs actual analysis
- Management priority classification
- What-if scenario analysis

The scenario model allows management to select a department and evaluate the
potential impact of spending reductions and budget changes.

## Key Findings

### Overall Performance

Actual spending was approximately **$890.27M** against a total budget of
**$795.47M**, resulting in an unfavorable variance of approximately
**$94.80M (11.92%)**.

Budget utilization reached **111.92%**.

### Transaction Performance

**5,590 of 10,000 transactions (55.9%)** were unfavorable, indicating that
overspending was widespread across the dataset.

### Department Performance

Marketing recorded the highest departmental variance at approximately
**$19.88M**, followed by HR and Sales.

### Category Performance

Salaries recorded the highest category variance at approximately
**$20.61M**.

### Recurring Overspending

Marketing exceeded its monthly budget in **34 of 36 months (94.44%)**,
indicating persistent budget pressure.

### Regional Performance

The East region recorded the highest regional variance at approximately
**$21.39M**.

## Business Recommendations

1. Introduce monthly budget-vs-actual reviews with defined variance thresholds.
2. Investigate the drivers of Marketing's recurring overspending.
3. Review salary-related spending, including staffing, overtime, and contractor costs.
4. Establish corrective-action plans for departments with repeated monthly overruns.
5. Use transaction-level exception monitoring to identify significant budget breaches
   earlier.

## Project Structure

```
data/
notebooks/
sql/
excel/
README.md