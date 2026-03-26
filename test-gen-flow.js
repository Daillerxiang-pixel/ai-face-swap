const http = require("http");

// Tiny valid JPEG for upload test
const jpeg = Buffer.from("/9j/4AAQSkZJRgABAQEASABIAAD/2wBDAAgGBgcGBQgHBwcJCQgKDBQNDAsLDBkSEw8UHRofHh0aHBwgJC4nICIsIxwcKDcpLDAxNDQ0Hyc5PTgyPC4zNDL/wAALCAABAAEBAREA/8QAFAABAAAAAAAAAAAAAAAAAAAACf/EABQQAQAAAAAAAAAAAAAAAAAAAAD/2gAIAQEAAD8AKp//2Q==", "base64");

// Step 1: Upload
const boundary = "BOUNDARY1234";
const formData = `--${boundary}\r\nContent-Disposition: form-data; name="photo"; filename="test.jpg"\r\nContent-Type: image/jpeg\r\n\r\n`;
const endData = `\r\n--${boundary}--\r\n`;
const body = Buffer.concat([Buffer.from(formData), jpeg, Buffer.from(endData)]);

console.log("=== Step 1: Upload ===");
const uploadReq = http.request({
  hostname: "127.0.0.1", port: 8080, path: "/api/upload/image", method: "POST",
  headers: { "Content-Type": `multipart/form-data; boundary=${boundary}`, "X-User-Id": "user-mock-001", "Content-Length": body.length }
}, (res) => {
  let data = "";
  res.on("data", (c) => data += c);
  res.on("end", () => {
    console.log("Upload:", data);
    try {
      const parsed = JSON.parse(data);
      const fileId = parsed.data ? parsed.data.fileId : null;
      console.log("FileId:", fileId);
      if (!fileId) { console.log("NO FILEID"); return; }
      doGenerate(fileId);
    } catch(e) { console.log("Parse error:", e.message); }
  });
});
uploadReq.end(body);

function doGenerate(fileId) {
  console.log("\n=== Step 2: Generate (templateId=1, sourceFileId=" + fileId + ") ===");
  const genBody = JSON.stringify({ templateId: 1, sourceFileId: fileId });
  const genReq = http.request({
    hostname: "127.0.0.1", port: 8080, path: "/api/generate", method: "POST",
    headers: { "Content-Type": "application/json", "X-User-Id": "user-mock-001", "Content-Length": Buffer.byteLength(genBody) }
  }, (res) => {
    let data = "";
    res.on("data", (c) => data += c);
    res.on("end", () => { console.log("Generate:", data); });
  });
  genReq.setTimeout(60000, () => { console.log("TIMEOUT after 60s"); genReq.destroy(); });
  genReq.end(genBody);
}
