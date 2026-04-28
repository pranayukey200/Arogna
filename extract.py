import re

log_path = r'C:\Users\prana\.gemini\antigravity\brain\eab5d479-38d3-433d-acab-960a1f867703\.system_generated\logs\overview.txt'
with open(log_path, 'r', encoding='utf-8') as f:
    text = f.read()

for match in re.finditer(r'The following code has been modified.*?<line_number>: <original_line>(.*?)(?=The above content|\\"\})', text, re.DOTALL):
    snippet = match.group(1)
    if 'ResponderActiveDispatch' in snippet or 'John Doe' in snippet or 'Cardiac Arrest' in snippet:
        print('--- FOUND SNIPPET ---')
        print(snippet[:500])
