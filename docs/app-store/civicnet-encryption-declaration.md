# CivicNet chat encryption

CivicNet encrypts **private chat messages** between matched helpers and requesters. This page is the public summary of what we use and why.

App: **CivicNet** · Bundle ID: `com.sufyankamil.communityNet` · [App Store](https://apps.apple.com/app/id6761416586)

---

## Purpose

Encryption protects chat content so message bodies are not stored or sent as plain text.

Used for:

- Confidentiality of chat message payloads
- Wrapping per-conversation keys for each participant

Not used for DRM, proprietary ciphers, or hiding app behavior.

---

## Algorithms

Everything below is **industry-standard** cryptography (no proprietary or unpublished algorithms).

| Use | Algorithm | Parameters | Standard |
|-----|-----------|------------|----------|
| Chat messages | AES-CBC | 256-bit key, 128-bit IV | NIST FIPS 197 / ISO/IEC 18033-3 |
| Conversation key wrap | RSA-OAEP | 2048-bit RSA, OAEP + SHA-256 | PKCS #1 v2.2 / IETF RFC 8017 |
| API / backend traffic | TLS (HTTPS) | Negotiated by the OS | IETF TLS |

During a limited migration window, older messages encrypted with a former app-wide AES-256-CBC key may still decrypt in-app. New messages use per-conversation keys only.

---

## Where it runs

| Layer | Implementation |
|-------|----------------|
| Message & key-wrap | Flutter/Dart (`encrypt`, `pointycastle`) |
| Private keys | Device secure storage / iOS Keychain (`flutter_secure_storage`) |
| Network | Platform HTTPS to Supabase and Firebase |

Chat payload crypto runs **in the app**, on top of normal HTTPS.

Implementation: [`lib/services/encryption_service.dart`](../../lib/services/encryption_service.dart)

---

## What is encrypted

- **Encrypted:** message bodies; conversation AES keys wrapped under each participant’s RSA public key
- **Not covered by app message crypto:** public discovery profile fields; push notification text (generic alerts only)

Flow in short:

1. Device creates an RSA-2048 identity key pair and uploads the public wrap key.
2. A conversation gets a random 256-bit AES key.
3. That key is RSA-OAEP-wrapped for each participant.
4. Messages are AES-256-CBC encrypted; stored/sent as Base64(IV ‖ ciphertext).

---

## App Store export compliance

For Apple App Store Connect uploads (questionnaire answers, PDF upload, compliance code), see [`APP_STORE_ENCRYPTION.md`](APP_STORE_ENCRYPTION.md). Print [`civicnet-encryption-declaration.html`](civicnet-encryption-declaration.html) to PDF locally — the PDF is gitignored and not published on GitHub.
