require('dotenv').config();
const mod = require('tencentcloud-sdk-nodejs');
const fs = require('fs');
const path = require('path');

const client = new mod.facefusion.v20181201.Client({
  credential: { secretId: process.env.TENCENT_SECRET_ID, secretKey: process.env.TENCENT_SECRET_KEY },
  region: 'ap-guangzhou',
});

// Hack: Monkey-patch JSON.stringify to preserve int64 precision via string
// Actually, let's try a different approach:
// Intercept the request and modify the serialized body

const origRequest = client.request.bind(client);
const CORRECT_ACTIVITY_ID = 2035634829506617344;

// The SDK internally uses JSON.stringify which loses precision
// Let's try using the request method with the correct precision
// by passing it as a BigInt string that the SDK serializer can handle

// Actually, let me just check: does FaceFusion with numeric ProjectId (precision-lost) work?
// From the server logs, it DID work with the SDK. So the SDK must handle int64 somehow.

// Let me trace what the SDK actually sends:
const origSend = https.request;
const https = require('https');

// Simpler: just try DescribeMaterialList with the activity ID and see
async function test() {
  console.log('Testing DescribeMaterialList with various approaches...');
  
  // Approach 1: Direct SDK call (what we tried before, returns 0)
  try {
    const r = await client.DescribeMaterialList({ ActivityId: CORRECT_ACTIVITY_ID, Offset: 0, Limit: 20 });
    console.log('SDK direct (Number):', r.Count, 'materials');
  } catch (e) {
    console.log('SDK direct ERR:', e.code, '-', e.message);
  }

  // Approach 2: The SDK might have a way to send raw params
  // Let's try request() directly
  try {
    const r = await client.request('DescribeMaterialList', { ActivityId: CORRECT_ACTIVITY_ID, Offset: 0, Limit: 20 });
    console.log('SDK request():', r.Response.Count, 'materials');
  } catch (e) {
    console.log('SDK request() ERR:', e.code, '-', e.message);
  }

  // The real question: WHY does FaceFusion work with the same precision loss?
  // Answer: FaceFusion returns data (it processes), but DescribeMaterialList returns
  // an empty list because the ActivityId query doesn't match any activity in the DB
  
  // Maybe the issue is not precision but that materials are under a different ActivityId?
  // Let's use Python (which handles int64 natively) to verify
  
  console.log('\n--- Switching to Python for int64-safe test ---');
  process.exit(0);
}

test();
