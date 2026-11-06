// Exercise the actual local worker and its Durable Object; never target a deployed inbox.
const base = process.env.OTP_LOCAL_URL || "http://127.0.0.1:8797";
if (!["127.0.0.1", "localhost"].includes(new URL(base).hostname)) {
  throw new Error("OTP_LOCAL_URL must target a local worker.");
}
const address = "e2e+dependency-check@e2e-mail.clashk.ing";
const headers = {
  authorization: `Bearer ${process.env.OTP_LOCAL_TOKEN || "local-dependency-check"}`,
};
const url = base + "/v1/otp?email=" + encodeURIComponent(address);
function assert(v, msg) {
  if (!v) throw Error(msg);
}
assert((await fetch(base + "/health")).status === 200, "health");
assert((await fetch(url)).status === 401, "unauthorized");
await fetch(url, { method: "DELETE", headers });
const raw =
  "Message-ID: <dependency-check@example.test>\r\nFrom: sender@example.test\r\nTo: " +
  address +
  "\r\nSubject: Verification code\r\nMIME-Version: 1.0\r\nContent-Type: text/plain; charset=UTF-8\r\n\r\nYour verification code is 483921.\r\n";
const sent = await fetch(
  base +
    "/cdn-cgi/local/email?from=sender%40example.test&to=" +
    encodeURIComponent(address),
  { method: "POST", body: raw },
);
assert(sent.ok, "email ingestion: " + (await sent.text()));
const read = await fetch(url, { headers });
const data = await read.json();
assert(
  read.status === 200 && data.code === "483921",
  "stored parsed code: " + JSON.stringify(data),
);
const other = await fetch(
  base + "/v1/otp?email=" + encodeURIComponent("e2e+other@e2e-mail.clashk.ing"),
  { headers },
);
assert(other.status === 404, "recipient isolation");
assert(
  (await fetch(url, { method: "DELETE", headers })).status === 204,
  "delete",
);
assert((await fetch(url, { headers })).status === 404, "deleted");
console.log(
  "PASS: real local worker health, authorization, email parsing, Durable Object storage, recipient isolation and deletion.",
);
