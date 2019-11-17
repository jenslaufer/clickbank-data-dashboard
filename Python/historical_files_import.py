import logging
from data.gather import DataGather
import hashlib
from time import ctime
from datetime import datetime, date
import json
import xmltodict
import os


def find_files(folder):
    clickbank_xml = []
    for dirpath, dirnames, filenames in os.walk(folder):
        for filename in filenames:
            if filename == 'marketplace_feed_v2.xml':
                full_path = f"{dirpath}/{filename}"
                stat = os.stat(full_path)
                clickbank_xml.append(
                    {'path': full_path, "time": stat.st_mtime})
    for dirname in dirnames:
        find_files(dirname)
    return clickbank_xml


logging.basicConfig(level=40)
root = "C:/Users/jensl/AppData/Local/Temp/"
file_paths = find_files(root)

for file_path in file_paths:
    try:
        import_date = datetime.combine(datetime.fromtimestamp(
            file_path['time']), datetime.min.time())
        logging.info(file_path['path'])

        with open(file_path['path'], "r") as f:
            xml = f.read()
        data_raw = json.loads(json.dumps(xmltodict.parse(xml)))

        DataGather("mongodb://localhost", import_date).do(data_raw)
    except Exception as e:
        logging.error(f"{e}")
