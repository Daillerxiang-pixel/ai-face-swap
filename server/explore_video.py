import json, inspect
from tencentcloud.facefusion.v20220927.facefusion_client import FacefusionClient
from tencentcloud.facefusion.v20220927 import models

# List all classes in models module
for name in dir(models):
    obj = getattr(models, name)
    if inspect.isclass(obj):
        print(f"Class: {name}")
        # Get docstring
        if obj.__doc__:
            print(f"  Doc: {obj.__doc__.strip()[:200]}")
        # Get attributes
        for attr in sorted(dir(obj)):
            if not attr.startswith('_') and attr not in ['deserialize', 'serialize']:
                print(f"  Attr: {attr}")
        print()

# Specifically check FuseFaceUltraRequest
print("\n=== FuseFaceUltraRequest details ===")
req_cls = models.FuseFaceUltraRequest
for attr in sorted(dir(req_cls)):
    if not attr.startswith('_') and attr not in ['deserialize', 'serialize']:
        print(f"  {attr}")

# Check MergeInfos type
print("\n=== MergeInfo ===")
try:
    mi = models.MergeInfo()
    for attr in sorted(dir(mi)):
        if not attr.startswith('_') and attr not in ['deserialize', 'serialize']:
            print(f"  {attr}")
except:
    print("  MergeInfo not found")
    # Try FusionUltraMergeInfo
    try:
        mi = models.FusionUltraMergeInfo()
        for attr in sorted(dir(mi)):
            if not attr.startswith('_') and attr not in ['deserialize', 'serialize']:
                print(f"  {attr}")
    except Exception as e:
        print(f"  FusionUltraMergeInfo err: {e}")
