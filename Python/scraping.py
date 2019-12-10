import logging
import os
from data.gather import DataGather

logging.basicConfig(level=os.environ.get('LOG_LEVEL', 20))
mongo_url = os.environ.get('MONGO_URI', "mongodb://localhost:27018")
db_name = 'clickbank'
logging.info("scraping data....")

data_gather = DataGather(mongourl=mongo_url, dbname=db_name)
data_gather.do()

logging.info("scraping data.")
