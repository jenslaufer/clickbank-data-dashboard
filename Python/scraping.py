#!/usr/bin/env python

import time
import logging
import os
from data.gather import DataGather
from apscheduler.schedulers.background import BackgroundScheduler

scheduler = BackgroundScheduler()

logging.basicConfig(level=int(os.environ.get('LOG_LEVEL', 30)))
mongo_url = os.environ.get('MONGO_URI', "mongodb://localhost")
db_name = 'clickbank'

data_gather = DataGather(mongourl=mongo_url, dbname=db_name)


scheduler.add_job(data_gather.do, 'interval', minutes=60)
scheduler.start()

while True:
    time.sleep(500)
