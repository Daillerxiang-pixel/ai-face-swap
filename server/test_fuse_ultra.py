import json, os, base64
from tencentcloud.facefusion.v20220927.facefusion_client import FacefusionClient
from tencentcloud.facefusion.v20220927 import models
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

client = FacefusionClient(cred, 'ap-guangzhou', prof)

# Read test face
with open('test_face.jpg', 'rb') as f:
    face_b64 = base64.b64encode(f.read()).decode()

# Test 1: FuseFaceUltra with a template URL (could be image or video)
print("=== Test 1: FuseFaceUltra - image template ===")
req = models.FuseFaceUltraRequest()

# Use the template image from uploads/previews as ModelUrl
# First serve it via our own server or use a public URL
# Let's use the Unsplash face as model template
model_url = 'https://images.unsplash.com/photo-1531746020798-e6953c6e8e04?w=512&h=512&fit=crop&crop=face'

req.from_json_string(json.dumps({
    "ModelUrl": model_url,
    "RspImgType": "base64",
    "MergeInfos": [
        {
            "Image": face_b64,
            "InputImageFaceRect": None,
            "TemplateFaceID": None,
            "TemplateFaceRect": None,
            "Url": None
        }
    ]
}))

try:
    resp = client.FuseFaceUltra(req)
    print("OK! Response keys:", [k for k in dir(resp) if not k.startswith('_')])
    if hasattr(resp, 'FusedImage') and resp.FusedImage:
        print("FusedImage size:", len(resp.FusedImage))
    print("Full:", resp.to_json_string()[:500])
except Exception as e:
    print(f"ERR: {e}")

# Test 2: Try with SwapModelType
print("\n=== Test 2: FuseFaceUltra with SwapModelType ===")
req2 = models.FuseFaceUltraRequest()
req2.from_json_string(json.dumps({
    "ModelUrl": model_url,
    "RspImgType": "base64",
    "SwapModelType": 0,
    "MergeInfos": [
        {"Image": face_b64}
    ]
}))
try:
    resp2 = client.FuseFaceUltra(req2)
    print("OK!")
    if hasattr(resp2, 'FusedImage') and resp2.FusedImage:
        print("FusedImage size:", len(resp2.FusedImage))
except Exception as e:
    print(f"ERR: {e}")

# Test 3: Try with video URL
print("\n=== Test 3: FuseFaceUltra with VIDEO URL ===")
# A short test video URL
video_url = 'https://media.w3.org/2010/05/sintel/trailer.mp4'
req3 = models.FuseFaceUltraRequest()
req3.from_json_string(json.dumps({
    "ModelUrl": video_url,
    "RspImgType": "base64",
    "SwapModelType": 1,
    "MergeInfos": [
        {"Image": face_b64}
    ]
}))
try:
    resp3 = client.FuseFaceUltra(req3)
    print("OK!")
    if hasattr(resp3, 'FusedImage') and resp3.FusedImage:
        print("FusedImage size:", len(resp3.FusedImage))
        print("Is it video data?", len(resp3.FusedImage) > 100000)
except Exception as e:
    print(f"ERR: {e}")
