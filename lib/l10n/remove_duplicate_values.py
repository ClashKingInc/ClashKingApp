import os
import json
from collections import defaultdict

def find_duplicate_values(arb_file_path):
    """Find keys that have duplicate values in the ARB file."""
    with open(arb_file_path, 'r', encoding='utf-8') as file:
        arb_data = json.load(file)
    
    # Group keys by their values
    value_to_keys = defaultdict(list)
    
    for key, value in arb_data.items():
        # Skip keys that start with @ (metadata keys)
        if key.startswith('@'):
            continue
        
        # Only process string values
        if isinstance(value, str):
            value_to_keys[value].append(key)
    
    # Find values that have multiple keys
    duplicates = {}
    for value, keys in value_to_keys.items():
        if len(keys) > 1:
            duplicates[value] = keys
    
    return duplicates

def remove_duplicate_keys(arb_file_path, keys_to_remove):
    """Remove specified keys from the ARB file."""
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
    
    # Define path to English ARB file
    en_arb_path = os.path.join(script_dir, 'app_en.arb')
    
    if not os.path.exists(en_arb_path):
        print(f"❌ Error: {en_arb_path} not found.")
        return
    
    print("🔍 Checking for duplicate values in app_en.arb...")
    
    # Find duplicate values
    duplicates = find_duplicate_values(en_arb_path)
    
    if not duplicates:
        print("✅ No duplicate values found.")
        return
    
    print(f"⚠️ Found {len(duplicates)} values with duplicate keys:")
    
    keys_to_remove = []
    
    for value, keys in duplicates.items():
        print(f"\n📝 Value: \"{value}\"")
        print(f"   Keys: {', '.join(keys)}")
        
        # Ask user which keys to keep
        print("   Which key do you want to KEEP? (others will be removed)")
        for i, key in enumerate(keys, 1):
            print(f"   {i}. {key}")
        
        while True:
            try:
                choice = input(f"   Enter number (1-{len(keys)}): ").strip()
                choice_idx = int(choice) - 1
                
                if 0 <= choice_idx < len(keys):
                    key_to_keep = keys[choice_idx]
                    keys_to_remove.extend([k for k in keys if k != key_to_keep])
                    print(f"   ✅ Keeping: {key_to_keep}")
                    print(f"   🗑️ Will remove: {', '.join([k for k in keys if k != key_to_keep])}")
                    break
                else:
                    print(f"   ❌ Invalid choice. Please enter a number between 1 and {len(keys)}.")
            except ValueError:
                print(f"   ❌ Invalid input. Please enter a number between 1 and {len(keys)}.")
    
    if not keys_to_remove:
        print("\n✨ No keys selected for removal.")
        return
    
    print(f"\n📋 Summary:")
    print(f"   Keys to remove: {len(keys_to_remove)}")
    for key in keys_to_remove:
        print(f"   🗑️ {key}")
    
    # Confirm removal
    response = input(f"\nDo you want to remove these {len(keys_to_remove)} keys from app_en.arb? (y/N): ")
    if response.lower() != 'y':
        print("❌ Operation cancelled.")
        return
    
    print("\n🔄 Removing duplicate keys from app_en.arb...")
    
    # Remove the selected keys
    removed_keys = remove_duplicate_keys(en_arb_path, keys_to_remove)
    
    if removed_keys:
        print(f"✅ Successfully removed {len(removed_keys)} key entries from app_en.arb.")
        print("📋 Note: This includes both the main keys and their associated @ description keys.")
    else:
        print("✨ No keys were removed.")

if __name__ == "__main__":
    main()