#!/bin/bash

GOBIERTO_ETL_UTILS=$DEV_DIR/gobierto-etl-utils
ETL_SANT_FELIU=$DEV_DIR/gobierto-etl-sant-feliu
STORAGE_DIR=/tmp/sant-feliu
SANT_FELIU_INE_CODE=8211

# Extract > Download data sources
cd $GOBIERTO_ETL_UTILS; ruby operations/download/run.rb "https://www.santfeliu.cat/scripts/previsio_pressupost?execute&any=23&key=$SANT_FELIU_API_TOKEN" $STORAGE_DIR/budgets-planned-2023.json --compatible
cd $GOBIERTO_ETL_UTILS; ruby operations/download/run.rb "https://www.santfeliu.cat/scripts/pressupost_despesa?execute&any=23"  $STORAGE_DIR/budgets-executed-expense-2023.json --compatible
cd $GOBIERTO_ETL_UTILS; ruby operations/download/run.rb "https://www.santfeliu.cat/scripts/pressupost_ingres?execute&any=23"   $STORAGE_DIR/budgets-executed-income-2023.json --compatible

cd $GOBIERTO_ETL_UTILS; ruby operations/download/run.rb "https://www.santfeliu.cat/scripts/previsio_pressupost?execute&any=23&key=$SANT_FELIU_API_TOKEN" $STORAGE_DIR/budgets-planned-2023.json --compatible

# Extract > Check valid JSON
cd $GOBIERTO_ETL_UTILS; ruby operations/check-json/run.rb $STORAGE_DIR/budgets-planned-2023.json
cd $GOBIERTO_ETL_UTILS; ruby operations/check-json/run.rb $STORAGE_DIR/budgets-executed-expense-2023.json
cd $GOBIERTO_ETL_UTILS; ruby operations/check-json/run.rb $STORAGE_DIR/budgets-executed-income-2023.json
cd $GOBIERTO_ETL_UTILS; ruby operations/check-json/run.rb $STORAGE_DIR/budgets-planned-2023.json

# Extract > Check data source columns
cd $ETL_SANT_FELIU; ruby operations/gobierto_budgets/check-json-columns/run.rb $STORAGE_DIR/budgets-planned-2023.json
cd $ETL_SANT_FELIU; ruby operations/gobierto_budgets/check-json-columns/run.rb $STORAGE_DIR/budgets-executed-expense-2023.json
cd $ETL_SANT_FELIU; ruby operations/gobierto_budgets/check-json-columns/run.rb $STORAGE_DIR/budgets-executed-income-2023.json
cd $ETL_SANT_FELIU; ruby operations/gobierto_budgets/check-json-columns/run.rb $STORAGE_DIR/budgets-planned-2023.json

# Transform > Transform planned budgets data files
cd $ETL_SANT_FELIU; ruby operations/gobierto_budgets/transform-planned/run.rb $STORAGE_DIR/budgets-planned-2023.json $STORAGE_DIR/budgets-planned-2023-transformed.json 2023
cd $ETL_SANT_FELIU; ruby operations/gobierto_budgets/transform-planned/run.rb $STORAGE_DIR/budgets-planned-2023.json $STORAGE_DIR/budgets-planned-2023-transformed.json 2023

# Transform > Transform executed budgets data files
cd $ETL_SANT_FELIU; ruby operations/gobierto_budgets/transform-executed/run.rb $STORAGE_DIR/budgets-executed-expense-2023.json $STORAGE_DIR/budgets-executed-expense-2023-transformed.json 2023 G
cd $ETL_SANT_FELIU; ruby operations/gobierto_budgets/transform-executed/run.rb $STORAGE_DIR/budgets-executed-income-2023.json  $STORAGE_DIR/budgets-executed-income-2023-transformed.json 2023 I

# Load > Import planned budgets
cd $ETL_SANT_FELIU; ruby operations/gobierto_budgets/import-planned-budgets/run.rb $STORAGE_DIR/budgets-planned-2023-transformed.json 2023
cd $ETL_SANT_FELIU; ruby operations/gobierto_budgets/import-planned-budgets/run.rb $STORAGE_DIR/budgets-planned-2023-transformed.json 2023

# Load > Import executed budgets
cd $ETL_SANT_FELIU; ruby operations/gobierto_budgets/import-executed-budgets/run.rb $STORAGE_DIR/budgets-executed-expense-2023-transformed.json 2023
cd $ETL_SANT_FELIU; ruby operations/gobierto_budgets/import-executed-budgets/run.rb $STORAGE_DIR/budgets-executed-income-2023-transformed.json 2023

# Load > Calculate totals
echo "$SANT_FELIU_INE_CODE" > $STORAGE_DIR/organization.id.txt
cd $GOBIERTO_ETL_UTILS; ruby operations/gobierto_budgets/update_total_budget/run.rb "2023 2023" $STORAGE_DIR/organization.id.txt

# Load > Calculate bubbles
cd $GOBIERTO_ETL_UTILS; ruby operations/gobierto_budgets/bubbles/run.rb $STORAGE_DIR/organization.id.txt

# Load > Calculate annual data
cd $DEV_DIR/gobierto; bin/rails runner $GOBIERTO_ETL_UTILS/operations/gobierto_budgets/annual_data/run.rb "2023 2023" $STORAGE_DIR/organization.id.txt

# Load > Publish activity
cd $DEV_DIR/gobierto; bin/rails runner $GOBIERTO_ETL_UTILS/operations/gobierto/publish-activity/run.rb budgets_updated $STORAGE_DIR/organization.id.txt

# Clear cache
cd $DEV_DIR/gobierto; bin/rails runner $GOBIERTO_ETL_UTILS/operations/gobierto/clear-cache/run.rb --site-organization-id "$SANT_FELIU_INE_CODE" --namespace "GobiertoBudgets"
