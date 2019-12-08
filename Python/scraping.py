import requests
from zipfile import ZipFile
import os
import xmltodict
import json
import logging
from hashlib import md5
from data.gather import DataGather


def _md5_file(fname):
    hash_md5 = md5()
    with open(fname, "rb") as f:
        for chunk in iter(lambda: f.read(4096), b""):
            hash_md5.update(chunk)

    return hash_md5.hexdigest()


logging.basicConfig(level=50)
target = "/tmp"
filename = f"{target}/clickbank.zip"
filename_bak = f"{target}/clickbank_bak.zip"
xml_file = f"{target}/marketplace_feed_v2.xml"
url = "https://accounts.clickbank.com/feeds/marketplace_feed_v2.xml.zip"

logging.info("loading data from clickbank...")
result = requests.get(url)

if os.path.exists(filename):
    if os.path.exists(filename_bak):
        os.remove(filename_bak)
    os.rename(filename, filename_bak)

logging.info("save zip file...")
with open(filename, "wb") as f:
    f.write(result.content)

do_import = True
if os.path.exists(filename_bak):
    checksum_old = _md5_file(filename_bak)
    checksum_new = _md5_file(filename)
    if checksum_new == checksum_old:
        logging.debug("new file and sold file are the same. Do nothing.")
        do_import = False


if do_import:
    logging.debug("extracting zip...")
    with ZipFile(filename, 'r') as zipObj:
        zipObj.extractall(target)

    logging.info("loading xml...")
    with open(xml_file, "r", encoding="ISO-8859-1") as f:
        xml = f.read()

    logging.info("loading dict...")

    data_raw = json.loads(json.dumps(xmltodict.parse(xml)))

    DataGather(mongourl="mongodb://cb-data-db").do(data_raw)

    logging.info("import finalised.")
