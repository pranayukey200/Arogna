import re
import json

log_path = r'C:\Users\prana\.gemini\antigravity\brain\eab5d479-38d3-433d-acab-960a1f867703\.system_generated\logs\overview.txt'
with open(log_path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

for line in lines:
    if 'view_file' in line and 'ResponderActiveDispatch' in line and 'output' in line:
        try:
            data = json.loads(line)
            # data could be nested
            print('Found json')
        except:
            pass

    if 'Active Dispatch: Cardiac Arrest' in line:
        print('Found exact string in line length:', len(line))
        with open('d:\\Hackathon_projects\\arogna\\extracted_log.txt', 'w', encoding='utf-8') as out:
            out.write(line)

