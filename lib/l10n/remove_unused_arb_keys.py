import os
import json
import glob

def get_unused_keys(arb_file_path, search_dir):
    """Find unused keys in the ARB file by searching through Dart files."""
    with open(arb_file_path, 'r', encoding='utf-8') as file:
        arb_data = json.load(file)
    
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
                    try:
                        with open(file_path, 'r', encoding='utf-8') as source_file:
                            if key in source_file.read():
                                found = True
                                break
                    except (UnicodeDecodeError, PermissionError):
                        # Skip files that can't be read
                        continue
            if found:
                break
        
        if not found:
            unused_keys.append(key)
    
    return unused_keys

def remove_keys_from_arb(arb_file_path, keys_to_remove):
    """Remove specified keys from an ARB file."""
    with open(arb_file_path, 'r', encoding='utf-8') as file:
        arb_data = json.load(file)
    
    removed_keys = []
    
    # Remove the keys and their associated @ keys
    for key in keys_to_remove:
        if key in arb_data:
            del arb_data[key]
            removed_keys.append(key)
        
        # Also remove the associated @ key if it exists
        at_key = f"@{key}"
        if at_key in arb_data:
            del arb_data[at_key]
            removed_keys.append(at_key)
    
    # Write the updated data back to the file
    if removed_keys:
        with open(arb_file_path, 'w', encoding='utf-8') as file:
            json.dump(arb_data, file, indent=2, ensure_ascii=False)
    
    return removed_keys

def main():
    # Get the directory of the current script
    script_dir = os.path.dirname(os.path.abspath(__file__))
    
    # Define paths
    en_arb_path = os.path.join(script_dir, 'app_en.arb')
    search_dir = os.path.join(script_dir, '../')
    
    print("Checking for unused keys in English ARB file...")
    
    # Find unused keys in the English ARB file
    unused_keys = get_unused_keys(en_arb_path, search_dir)
    
    if not unused_keys:
        print("No unused keys found.")
        return
    
    print(f"Found {len(unused_keys)} unused keys:")
    for key in unused_keys:
        print(f"  - {key}")
    
    # Confirm removal
    response = input("\nDo you want to remove these unused keys from all ARB files? (y/N): ")
    if response.lower() != 'y':
        print("Operation cancelled.")
        return
    
    # Find all ARB files in the directory
    arb_files = glob.glob(os.path.join(script_dir, 'app_*.arb'))
    
    print(f"\nRemoving unused keys from {len(arb_files)} ARB files...")
    
    total_removed = 0
    
    # Remove unused keys from each ARB file
    for arb_file in arb_files:
        file_name = os.path.basename(arb_file)
        removed_keys = remove_keys_from_arb(arb_file, unused_keys)
        
        if removed_keys:
            print(f"  {file_name}: Removed {len(removed_keys)} keys")
            total_removed += len(removed_keys)
        else:
            print(f"  {file_name}: No keys to remove")
    
    print(f"\nCompleted! Removed {total_removed} total key entries across all files.")
    print("Note: This includes both the main keys and their associated @ description keys.")

if __name__ == "__main__":
    main()