import requests
from zipfile import ZipFile
import os
import xmltodict
import json
import logging
from pymongo import MongoClient
from datetime import date, datetime


def _traverse(node):
    _handle_categories(None, data_raw.get('Catalog'))


def _handle_categories(parent, node):
    if type(node) == list:
        #logging.debug("handling categories list...")
        for category in node:
            _handle_category(parent, category)
    elif type(node) == dict:
        #logging.debug("handling categories dict...")
        items = node.items()
        #logging.debug("type of items {}".format(type(items)))
        for key, categories in items:
            if type(categories) == list:
                for category in categories:
                    _handle_category(parent, category)
            else:
                _handle_category(parent, node)


def _handle_category(parent_category, category):
    try:
        category_name = category.get("Name")
        sites = category.get("Site")
        if sites is not None:
            if type(sites) == list:
                #logging.debug("handling sites list...")
                for site in sites:
                    _handle_site(parent_category, category_name, site)
            elif type(sites) == dict:
                _handle_site(parent_category, category_name, sites)

        sub_categories = category.get("Category")
        if sub_categories is not None:
            _handle_categories(category_name, sub_categories)
    except Exception as e:
        logging.error(f"_handle_category  {e}")


def _handle_site(parent_category, category, site):
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
        site["Date"] = today

        if site["ActivateDate"] == None:
            site["ActivateDate"] = datetime.strptime(
                "2000-01-01", '%Y-%m-%d')
        elif type(site["ActivateDate"]) == str:
            site["ActivateDate"] = datetime.strptime(
                site["ActivateDate"], '%Y-%m-%d')

        # logging.info(site)
        products.replace_one(
            {"Id": site['Id'],
                "Category": site["Category"],
                "Date": today},
            site,
            upsert=True)
        #logging.debug("inserted {}".format(site["Id"]))
    except Exception as e:
        logging.error(f"_handle_site error: {site} {e}")


client = MongoClient("mongodb://localhost:27017")
db = client.clickbank
products = db.products

target = "c:/temp"
filename = f"{target}/clickbank.zip"
xml_file = f"{target}/marketplace_feed_v2.xml"
url = "https://accounts.clickbank.com/feeds/marketplace_feed_v2.xml.zip"
logging.basicConfig(level=10)

if not os.path.exists(xml_file):
    logging.info("loading data from clickbank...")
    result = requests.get(url)

    logging.info("save zip file...")
    with open(filename, "wb") as f:
        f.write(result.content)

    # logging.debug("extracting zip...")
    with ZipFile(filename, 'r') as zipObj:
        zipObj.extractall(target)

logging.info("loading xml...")
with open(xml_file, "r") as f:
    xml = f.read()

logging.info("loading dict...")

json_file = "c:/temp/products.json"
with open(json_file, "w") as fp:
    json.dump(xmltodict.parse(xml), fp)
with open(json_file, "r") as fp:
    data_raw = json.load(fp)


today = datetime.combine(date.today(), datetime.min.time())
_traverse(data_raw)


# for value in category:
#     category_name = value['Name']
#     print(f"category {category_name}")

#     for site in value['Site']:
#         print("    {}".format(site['Id']))
# add_site(site)

# for value in value['Category']:
#     category_name = value['Name']
#     print(category_name)

#     for site in value['Site']:
#         add_site(site)

logging.info("import finalised.")
