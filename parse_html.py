import urllib.request
from bs4 import BeautifulSoup

urls = [
    ("Report Emergency", "https://contribution.usercontent.google.com/download?c=CgthaWRhX2NvZGVmeBJ7Eh1hcHBfY29tcGFuaW9uX2dlbmVyYXRlZF9maWxlcxpaCiVodG1sXzI2OTY4NjZiMWIzYzQ0ZWJiN2JkM2Y0ODBiYmE1YmYyEgsSBxCJkqTarxYYAZIBIwoKcHJvamVjdF9pZBIVQhM5NjYyNzMwNjc5MTM2MTc0Mzg2&filename=&opi=89354086"),
    ("Health Feed", "https://contribution.usercontent.google.com/download?c=CgthaWRhX2NvZGVmeBJ7Eh1hcHBfY29tcGFuaW9uX2dlbmVyYXRlZF9maWxlcxpaCiVodG1sX2YyOTY3ODFkYmU4NzQ4OTA4ODdkODMyMzBkZmVkOTc4EgsSBxCJkqTarxYYAZIBIwoKcHJvamVjdF9pZBIVQhM5NjYyNzMwNjc5MTM2MTc0Mzg2&filename=&opi=89354086"),
    ("Guardian Leaderboard", "https://contribution.usercontent.google.com/download?c=CgthaWRhX2NvZGVmeBJ7Eh1hcHBfY29tcGFuaW9uX2dlbmVyYXRlZF9maWxlcxpaCiVodG1sXzE5MWQ4MDcyZWZmNTQ1MzJiN2EzYWZmN2JkZjU3NTM1EgsSBxCJkqTarxYYAZIBIwoKcHJvamVjdF9pZBIVQhM5NjYyNzMwNjc5MTM2MTc0Mzg2&filename=&opi=89354086")
]

for name, url in urls:
    req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
    html = urllib.request.urlopen(req).read().decode('utf-8')
    soup = BeautifulSoup(html, 'html.parser')
    
    print(f"\n--- {name} ---")
    
    # Just extract all text blocks that might be headers or buttons
    for element in soup.find_all(['h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'button', 'a', 'span', 'p']):
        text = element.get_text(strip=True)
        if text and len(text) < 100:
            print(f"{element.name}: {text}")
