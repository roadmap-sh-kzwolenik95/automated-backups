import pymongo
from pprint import pprint

mongo_uri = "mongodb://localhost:27017/"
database_name = "wikipedia"
collection_name = "wikipedia_data"

client = pymongo.MongoClient(mongo_uri)
db = client[database_name]
collection = db[collection_name]

# List all databases
databases = client.list_database_names()
print("Databases:", databases)

# List all collections in the specified database
collections = db.list_collection_names()
print("Collections in", database_name, ":", collections)

# List all documents in the specified collection
documents = collection.find()
print("Documents in", collection_name, ":")
for doc in documents:
    pprint(doc)
