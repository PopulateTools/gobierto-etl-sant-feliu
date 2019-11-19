#!/bin/bash

cd $DEV_DIR/gobierto
OPERATIONS=$DEV_DIR/gobierto-etl-sant-feliu/operations/gobierto_indicators
SITE_DOMAIN=madrid.gobierto.test

bin/rails runner $OPERATIONS/import_gci/run.rb $SITE_DOMAIN
bin/rails runner $OPERATIONS/import_ip12/run.rb $SITE_DOMAIN
bin/rails runner $OPERATIONS/import_ip15/run.rb $SITE_DOMAIN
bin/rails runner $OPERATIONS/import_ip16/run.rb $SITE_DOMAIN
bin/rails runner $OPERATIONS/import_ip17/run.rb $SITE_DOMAIN
bin/rails runner $OPERATIONS/import_ip18/run.rb $SITE_DOMAIN
bin/rails runner $OPERATIONS/import_ita12/run.rb $SITE_DOMAIN
bin/rails runner $OPERATIONS/import_ita14/run.rb $SITE_DOMAIN
bin/rails runner $OPERATIONS/import_ita17/run.rb $SITE_DOMAIN
