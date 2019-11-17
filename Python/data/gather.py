import logging
from datetime import date, datetime
from pymongo import MongoClient


class DataGather:

    def __init__(self, mongourl="mongodb://localhost", import_date=datetime.combine(date.today(), datetime.min.time())):
        self.import_date = import_date

        client = MongoClient(mongourl)
        db = client.clickbank
        self.products = db.products

    def do(self, data):
        self._handle_categories(None, data.get('Catalog'))

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
