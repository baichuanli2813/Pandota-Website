with open("inventory.html", "r", encoding="utf-8", errors="ignore") as f:
    content = f.read()

# Replace any double-encoded Â£ or \xc2\xa3 with clean £
clean_content = content.replace("Â£", "£").replace("Ã‚Â£", "£")

with open("inventory.html", "w", encoding="utf-8") as f:
    f.write(clean_content)

print("Python successfully cleaned all £ signs in inventory.html!")
