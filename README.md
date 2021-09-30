# Gobierto ETL for Sant Feliu

ETL scripts for Gobierto Sant Feliu site: https://pressupost.santfeliu.cat/

## Setup

Copy `.env` file:

```
cp .env.example .env && ln -s .env .rbenv-vars
```

And fill in the values

This repository relies heavily in [gobierto_budgets_data](https://github.com/PopulateTools/gobierto_budgets_data)

## Available operations

- check-json-columns
- transform-planned
- transform-executed
- import-planned-budgets
- import-executed-budgets
