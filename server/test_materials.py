import json, os, sys
from tencentcloud.facefusion.v20220927 import facefusion_client as fc_v22
from tencentcloud.facefusion.v20181201 import facefusion_client as fc_v18
from tencentcloud.common.profile.client_profile import ClientProfile
from tencentcloud.common.profile.http_profile import HttpProfile
from tencentcloud.common.credential import Credential

sid = os.environ.get('TENCENT_SECRET_ID')
skey = os.environ.get('TENCENT_SECRET_KEY')

cred = Credential(sid, skey)
httpProf = HttpProfile()
httpProf.endpoint = 'facefusion.tencentcloudapi.com'
prof = ClientProfile()
prof.httpProfile = httpProf

# Try v20181201 dedicated client
client = fc_v18.FacefusionClient(cred, 'ap-guangzhou', prof)

from tencentcloud.facefusion.v20181201 import models as m18

# DescribeMaterialList request
req = m18.DescribeMaterialListRequest()
req.from_json_string(json.dumps({
    "ActivityId": 2035634829506617344,
    "Offset": 0,
    "Limit": 20
}))

try:
    resp = client.DescribeMaterialList(req)
    print("v20181201 DescribeMaterialList OK!")
    print("Count:", resp.Count)
    if resp.MaterialInfos:
        for m in resp.MaterialInfos:
            print("---")
            print("MaterialId:", m.MaterialId)
            print("Url:", m.Url if hasattr(m, 'Url') else 'N/A')
            print("Name:", m.MaterialName if hasattr(m, 'MaterialName') else 'N/A')
    else:
        print("MaterialInfos is None/empty")
    print("Full response:", resp.to_json_string())
except Exception as e:
    print(f"ERR: {e}")

# Also try FaceFusion to confirm it works
print("\n--- FaceFusion test ---")
import base64
# Use a small real image
with open('test_face.jpg', 'rb') as f:
    img_b64 = base64.b64encode(f.read()).decode()

req2 = m18.FaceFusionRequest()
req2.from_json_string(json.dumps({
    "ProjectId": "at_2035634829506617344",
    "ModelId": "mt_2035647018124681216",
    "Image": img_b64,
    "RspImgType": "base64"
}))
try:
    resp2 = client.FaceFusion(req2)
    print("FaceFusion OK, Image size:", len(resp2.Image))
except Exception as e:
    print(f"FaceFusion ERR: {e}")
