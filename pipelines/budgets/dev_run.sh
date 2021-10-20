#!/bin/bash

GOBIERTO_ETL_UTILS=$DEV_DIR/gobierto-etl-utils
ETL_SANT_FELIU=$DEV_DIR/gobierto-etl-sant-feliu
STORAGE_DIR=/tmp/sant-feliu

# Extract > Download data sources
cd $GOBIERTO_ETL_UTILS; ruby operations/download/run.rb "https://www.santfeliu.cat/scripts/previsio_pressupost?execute&any=21&key=$SANT_FELIU_API_TOKEN" $STORAGE_DIR/budgets-planned-2021.json --compatible
cd $GOBIERTO_ETL_UTILS; ruby operations/download/run.rb "https://www.santfeliu.cat/scripts/pressupost_despesa?execute&any=21"  $STORAGE_DIR/budgets-executed-expense-2021.json --compatible
cd $GOBIERTO_ETL_UTILS; ruby operations/download/run.rb "https://www.santfeliu.cat/scripts/pressupost_ingres?execute&any=21"   $STORAGE_DIR/budgets-executed-income-2021.json --compatible

cd $GOBIERTO_ETL_UTILS; ruby operations/download/run.rb "https://www.santfeliu.cat/scripts/previsio_pressupost?execute&any=22&key=$SANT_FELIU_API_TOKEN" $STORAGE_DIR/budgets-planned-2022.json --compatible

# Extract > Check valid JSON
cd $GOBIERTO_ETL_UTILS; ruby operations/check-json/run.rb $STORAGE_DIR/budgets-planned-2021.json
cd $GOBIERTO_ETL_UTILS; ruby operations/check-json/run.rb $STORAGE_DIR/budgets-executed-expense-2021.json
cd $GOBIERTO_ETL_UTILS; ruby operations/check-json/run.rb $STORAGE_DIR/budgets-executed-income-2021.json
cd $GOBIERTO_ETL_UTILS; ruby operations/check-json/run.rb $STORAGE_DIR/budgets-planned-2022.json

# Extract > Check data source columns
cd $ETL_SANT_FELIU; ruby operations/gobierto_budgets/check-json-columns/run.rb $STORAGE_DIR/budgets-planned-2021.json
cd $ETL_SANT_FELIU; ruby operations/gobierto_budgets/check-json-columns/run.rb $STORAGE_DIR/budgets-executed-expense-2021.json
cd $ETL_SANT_FELIU; ruby operations/gobierto_budgets/check-json-columns/run.rb $STORAGE_DIR/budgets-executed-income-2021.json
cd $ETL_SANT_FELIU; ruby operations/gobierto_budgets/check-json-columns/run.rb $STORAGE_DIR/budgets-planned-2022.json

# Transform > Transform planned budgets data files
cd $ETL_SANT_FELIU; ruby operations/gobierto_budgets/transform-planned/run.rb $STORAGE_DIR/budgets-planned-2021.json $STORAGE_DIR/budgets-planned-2021-transformed.json 2021
cd $ETL_SANT_FELIU; ruby operations/gobierto_budgets/transform-planned/run.rb $STORAGE_DIR/budgets-planned-2022.json $STORAGE_DIR/budgets-planned-2022-transformed.json 2022

# Transform > Transform executed budgets data files
cd $ETL_SANT_FELIU; ruby operations/gobierto_budgets/transform-executed/run.rb $STORAGE_DIR/budgets-executed-expense-2021.json $STORAGE_DIR/budgets-executed-expense-2021-transformed.json 2021 G
cd $ETL_SANT_FELIU; ruby operations/gobierto_budgets/transform-executed/run.rb $STORAGE_DIR/budgets-executed-income-2021.json  $STORAGE_DIR/budgets-executed-income-2021-transformed.json 2021 I

# Load > Import planned budgets
cd $ETL_SANT_FELIU; ruby operations/gobierto_budgets/import-planned-budgets/run.rb $STORAGE_DIR/budgets-planned-2021-transformed.json 2021
cd $ETL_SANT_FELIU; ruby operations/gobierto_budgets/import-planned-budgets/run.rb $STORAGE_DIR/budgets-planned-2022-transformed.json 2022

# Load > Import executed budgets
cd $ETL_SANT_FELIU; ruby operations/gobierto_budgets/import-executed-budgets/run.rb $STORAGE_DIR/budgets-executed-expense-2021-transformed.json 2021
cd $ETL_SANT_FELIU; ruby operations/gobierto_budgets/import-executed-budgets/run.rb $STORAGE_DIR/budgets-executed-income-2021-transformed.json 2021

# Load > Calculate totals
echo "8211" > $STORAGE_DIR/organization.id.txt
cd $GOBIERTO_ETL_UTILS; ruby operations/gobierto_budgets/update_total_budget/run.rb "2022 2021" $STORAGE_DIR/organization.id.txt

# Load > Calculate bubbles
cd $GOBIERTO_ETL_UTILS; ruby operations/gobierto_budgets/bubbles/run.rb $STORAGE_DIR/organization.id.txt

# Load > Calculate annual data
cd $DEV_DIR/gobierto; bin/rails runner $GOBIERTO_ETL_UTILS/operations/gobierto_budgets/annual_data/run.rb "2022 2021" $STORAGE_DIR/organization.id.txt

# Load > Publish activity
cd $DEV_DIR/gobierto; bin/rails runner $GOBIERTO_ETL_UTILS/operations/gobierto/publish-activity/run.rb budgets_updated $STORAGE_DIR/organization.id.txt

# Clear cache
cd $DEV_DIR/gobierto; bin/rails runner $GOBIERTO_ETL_UTILS/operations/gobierto/clear-cache/run.rb
