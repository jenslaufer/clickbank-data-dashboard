import logging
from datetime import date, datetime
from pymongo import MongoClient, DESCENDING, ASCENDING
from zipfile import ZipFile
from gridfs import GridFS
import io
import os
import requests
import xmltodict
import json
import logging
from hashlib import md5
from tempfile import gettempdir
import io


class DataGather:
    DATA_URL = "https://accounts.clickbank.com/feeds/marketplace_feed_v2.xml.zip"

    def __init__(self, mongourl, dbname, import_date=datetime.combine(date.today(), datetime.min.time())):
        self.import_date = import_date

        client = MongoClient(mongourl)
        db = client[dbname]
        self.fs = GridFS(db)

        self.products = db.products
        self.products.create_index(
            [("_id", ASCENDING), ("Category", ASCENDING), ("Date", ASCENDING)])
        self.products.create_index(
            [("_id", ASCENDING), ("ParentCategory", ASCENDING), ("Category", ASCENDING), ("Date", ASCENDING)])
        self.products.create_index(
            [("Date", ASCENDING)])
        self.files = db["fs.files"]

    def do(self):
        target = gettempdir()
        filename = f"{target}/clickbank.zip"
        filename_bak = f"{target}/clickbank_bak.zip"
        xml_file = f"{target}/marketplace_feed_v2.xml"

        logging.info("loading data from clickbank...")
        result = requests.get(self.DATA_URL)

        out = io.BytesIO(result.content)

        self.fs.put(out.getvalue(), filename="marketplace_feed_v2.xml.zip",
                    contentType="application/zip")

        files = list(self.files.find({"filename": "marketplace_feed_v2.xml.zip"}).sort(
            [("uploadDate", DESCENDING)]))
        with open(filename, "wb") as f:
            f.write(self.fs.find_one({"_id": files[0]["_id"]}).read())
        if len(files) == 2:
            with open(filename_bak, "wb") as f:
                f.write(self.fs.find_one({"_id": files[1]["_id"]}).read())

        do_import = True
        if os.path.exists(filename_bak):
            checksum_old = self._md5_file(filename_bak)
            checksum_new = self._md5_file(filename)
            if checksum_new == checksum_old:
                logging.debug(
                    "new file and sold file are the same. Do nothing.")
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

            logging.info("import finalised.")

            self._handle_categories(None, data_raw.get('Catalog'))

    def _handle_categories(self, parent, node):
        if type(node) == list:
            logging.debug("handling categories list...")
            for category in node:
                self._handle_category(parent, category)
        elif type(node) == dict:
            logging.debug("handling categories dict...")
            items = node.items()
            logging.debug("type of items {}".format(type(items)))
            for key, categories in items:
                if type(categories) == list:
                    for category in categories:
                        self._handle_category(parent, category)
                else:
                    self._handle_category(parent, node)

    def _handle_category(self, parent_category, category):
        try:
            category_name = category.get("Name")
            sites = category.get("Site")
            if sites is not None:
                if type(sites) == list:
                    logging.debug("handling sites list...")
                    for site in sites:
                        self._handle_site(parent_category,
                                          category_name, site)
                elif type(sites) == dict:
                    self._handle_site(parent_category,
                                      category_name, sites)

            sub_categories = category.get("Category")
            if sub_categories is not None:
                self._handle_categories(category_name, sub_categories)
        except Exception as e:
            logging.error(f"_handle_category  {e}")

    def _handle_site(self, parent_category, category, site):
        try:
            site["ParentCategory"] = parent_category
            site["Category"] = category
            site["Gravity"] = float(site["Gravity"])
            site["PopularityRank"] = float(site["PopularityRank"])
            site["HasRecurringProducts"] = site["HasRecurringProducts"] == "true"
            site["PercentPerSale"] = float(site["PercentPerSale"])
            site["PercentPerRebill"] = float(site["PercentPerRebill"])
            site["AverageEarningsPerSale"] = float(
                site["AverageEarningsPerSale"])
            site["InitialEarningsPerSale"] = float(
                site["InitialEarningsPerSale"])
            site["TotalRebillAmt"] = float(site["TotalRebillAmt"])
            site["Referred"] = float(site["Referred"])
            site["Commission"] = float(site["Commission"])
            site["Date"] = self.import_date

            if site["ActivateDate"] == None:
                site["ActivateDate"] = datetime.strptime(
                    "2000-01-01", '%Y-%m-%d')
            elif type(site["ActivateDate"]) == str:
                site["ActivateDate"] = datetime.strptime(
                    site["ActivateDate"], '%Y-%m-%d')

            logging.info(site)
            self.products.replace_one(
                {"Id": site['Id'],
                    "Category": site["Category"],
                    "Date": self.import_date},
                site,
                upsert=True)
            logging.debug("inserted {}".format(site["Id"]))
        except Exception as e:
            logging.error(f"_handle_site error: {site} {e}")

    def _md5_file(self, fname):
        hash_md5 = md5()
        with open(fname, "rb") as f:
            for chunk in iter(lambda: f.read(4096), b""):
                hash_md5.update(chunk)

        return hash_md5.hexdigest()
