import wikipediaapi
import pymongo

mongo_uri = "mongodb://localhost:27017/"
database_name = "wikipedia"
collection_name = "wikipedia_data"

client = pymongo.MongoClient(mongo_uri)
db = client[database_name]
collection = db[collection_name]

wiki_wiki = wikipediaapi.Wikipedia(
    user_agent="Devops Roadmap sh challenge (kzwolenik95@gmail.com)", language="en"
)


def fetch_wikipedia_data(article_title):
    page = wiki_wiki.page(article_title)
    if not page.exists():
        print(f"The page '{article_title}' does not exist on Wikipedia.")
        return None

    data = {
        "title": page.title,
        "summary": page.summary,
        "url": page.fullurl,
        "categories": [category for category in page.categories.keys()],
    }
    return data


article_titles = ["Python (programming language)", "DevOps", "Technology roadmap"]
wikipedia_data = [fetch_wikipedia_data(title) for title in article_titles]

# Filter out None values in case some pages do not exist
wikipedia_data = [data for data in wikipedia_data if data is not None]

collection.insert_many(wikipedia_data)

print(f"Inserted {len(wikipedia_data)} Wikipedia articles into the collection.")
