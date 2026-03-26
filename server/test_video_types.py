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

with open('test_face.jpg', 'rb') as f:
    face_b64 = base64.b64encode(f.read()).decode()

# Try all SwapModelType values
for smt in range(0, 10):
    req = models.FuseFaceUltraRequest()
    req.from_json_string(json.dumps({
        "ModelUrl": "https://images.unsplash.com/photo-1531746020798-e6953c6e8e04?w=512&h=512&fit=crop&crop=face",
        "RspImgType": "base64",
        "SwapModelType": smt,
        "MergeInfos": [{"Image": face_b64}]
    }))
    try:
        resp = client.FuseFaceUltra(req)
        if resp.FusedImage:
            buf = base64.b64decode(resp.FusedImage)
            is_png = buf[:4] == b'\x89PNG'
            is_mp4 = buf[:4] == b'\x00\x00\x00\x18' or b'ftyp' in buf[:12]
            print(f"SwapModelType={smt}: OK, size={len(resp.FusedImage)}, png={is_png}, mp4={is_mp4}")
        else:
            print(f"SwapModelType={smt}: OK but no image")
    except Exception as e:
        print(f"SwapModelType={smt}: ERR - {str(e)[:100]}")

# Also try without SwapModelType
req = models.FuseFaceUltraRequest()
req.from_json_string(json.dumps({
    "ModelUrl": "https://media.w3.org/2010/05/sintel/trailer.mp4",
    "RspImgType": "base64",
    "MergeInfos": [{"Image": face_b64}]
}))
try:
    resp = client.FuseFaceUltra(req)
    print(f"No SwapModelType video: OK, size={len(resp.FusedImage) if resp.FusedImage else 0}")
except Exception as e:
    print(f"No SwapModelType video: ERR - {str(e)[:100]}")

# Try with ModelImage (base64) instead of URL for a video frame
print("\n=== Check if there's a video-specific API ===")
# Let's also check if FuseFace (v20181201) supports video
from tencentcloud.facefusion.v20181201.facefusion_client import FacefusionClient as ClientV18
from tencentcloud.facefusion.v20181201 import models as models_v18

client_v18 = ClientV18(cred, 'ap-guangzhou', prof)

# Check FuseFace request params
print("FuseFace params:", [a for a in dir(models_v18.FuseFaceRequest()) if not a.startswith('_')])
print("FaceFusion params:", [a for a in dir(models_v18.FaceFusionRequest()) if not a.startswith('_')])
