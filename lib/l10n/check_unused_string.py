import os
import json

# Get the directory of the current script
script_dir = os.path.dirname(os.path.abspath(__file__))

# Load ARB file with a path relative to the script's directory
arb_file_path = os.path.join(script_dir, 'app_en.arb')
with open(arb_file_path, 'r', encoding='utf-8') as file:
    arb_data = json.load(file)

# Directory to search in, adjusted to start search from the project root
search_dir = os.path.join(script_dir, '../')

unused_keys = []

# Search for each key in the project directory
for key in arb_data.keys():
    # Skip keys that start with @ or @@
    if key.startswith('@'):
        continue

    found = False
    for root, dirs, files in os.walk(search_dir):
        for file in files:
            if file.endswith('.dart') and not file.startswith('app_localizations'):
                file_path = os.path.join(root, file)
                with open(file_path, 'r', encoding='utf-8') as source_file:
                    if key in source_file.read():
                        found = True
                        break
        if found:
            break
    if not found:
        unused_keys.append(key)

# Print the list of unused keys
if unused_keys:
    print("Unused keys found:")
    for key in unused_keys:
        print(key)
else:
    print("No unused keys found.")