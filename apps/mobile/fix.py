import os, re

for dp, dn, fn in os.walk('apps/mobile/lib'):
    for f in fn:
        if f.endswith('.dart'):
            path = os.path.join(dp, f)
            with open(path, 'r', encoding='utf-8') as file:
                content = file.read()
            
            # Replace ApiService.xxx('/api/... with ApiService.xxx('/...
            new_content = re.sub(r"ApiService\.(get|post|put|delete|getList)\('/api/", r"ApiService.\g<1>('/", content)
            
            if new_content != content:
                with open(path, 'w', encoding='utf-8') as file:
                    file.write(new_content)
                print(f"Fixed {path}")
