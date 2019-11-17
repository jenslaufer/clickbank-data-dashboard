import requests
from zipfile import ZipFile
import os
import xmltodict
import json
import logging
from data.gather import DataGather


logging.basicConfig(level=40)
target = "c:/temp"
filename = f"{target}/clickbank.zip"
xml_file = f"{target}/marketplace_feed_v2.xml"
url = "https://accounts.clickbank.com/feeds/marketplace_feed_v2.xml.zip"

if not os.path.exists(xml_file):
    logging.info("loading data from clickbank...")
    result = requests.get(url)

    logging.info("save zip file...")
    with open(filename, "wb") as f:
        f.write(result.content)

    logging.debug("extracting zip...")
    with ZipFile(filename, 'r') as zipObj:
        zipObj.extractall(target)

logging.info("loading xml...")
with open(xml_file, "r") as f:
    xml = f.read()

logging.info("loading dict...")

data_raw = json.loads(json.dumps(xmltodict.parse(xml)))

DataGather().do(data_raw)

logging.info("import finalised.")
