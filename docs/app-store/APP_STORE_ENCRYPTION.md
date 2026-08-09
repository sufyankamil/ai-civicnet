# App Store Connect — Encryption compliance guide

CivicNet uses **in-app AES-256-CBC** and **RSA-2048-OAEP** for private chat (see [`civicnet-encryption-declaration.md`](civicnet-encryption-declaration.md)), plus normal HTTPS to Supabase/Firebase.

Because chat crypto is **standard algorithms implemented outside Apple OS crypto APIs**, treat encryption as **non-exempt** for App Store Connect.

## Files in this folder

| File | Use |
|------|-----|
| [`civicnet-encryption-declaration.md`](civicnet-encryption-declaration.md) | **Public** GitHub summary of chat encryption |
| [`civicnet-encryption-declaration.html`](civicnet-encryption-declaration.html) | Print → Save as PDF for App Store Connect |
| `civicnet-encryption-declaration.pdf` | Local only (gitignored) — upload this in App Store Connect |
| This guide | Questionnaire answers + post-approval plist steps (maintainers) |

## Before you upload

In [App Store Connect](https://appstoreconnect.apple.com):

1. Fill **App Description** for CivicNet.
2. Confirm **Pricing and Availability** / territories (include France if you intend to sell there).
3. Apple cannot properly review encryption docs without description + availability.

## Questionnaire answers (truthful for CivicNet)

App Information → **App Encryption Documentation** → (+)

Use answers equivalent to:

1. **Does your app use encryption?** → **Yes**
2. **Is encryption limited to Apple operating system encryption (e.g. HTTPS via URLSession only)?** → **No**  
   (CivicNet also encrypts chat payloads in-app.)
3. **Does your app use proprietary / non-standard algorithms?** → **No**  
   (AES-256-CBC, RSA-OAEP-SHA256 only.)
4. **Industry-standard algorithms not provided solely by Apple OS?** → **Yes**
5. **Distributing on the App Store in France?** → **Yes** (unless you explicitly exclude France)

Apple’s required upload for this case: **French encryption declaration** (not CCATS), when France is available.

## What to upload

1. Open [`civicnet-encryption-declaration.html`](civicnet-encryption-declaration.html) in a browser.
2. **File → Print → Save as PDF** (save as `civicnet-encryption-declaration.pdf` locally; PDFs in this folder are gitignored).
3. In App Store Connect, when prompted, **Choose File** and upload that PDF.
4. Click **Save**.

Apple typically reviews in about **two business days**.

### Optional: official ANSSI Cerfa

If Apple rejects the technical PDF and asks specifically for the French government form:

1. Download the current form from [ANSSI — contrôle relatif à un moyen de cryptologie](https://cyber.gouv.fr/reglementation/reglementation-identite-confiance-numerique/controles-reglementaires-cryptographie/controle-moyen-de-cryptologie/).
2. Fill product fields using values from the declaration (app name CivicNet, algorithms AES-256-CBC / RSA-2048-OAEP, purpose chat confidentiality).
3. Upload the signed PDF to App Store Connect (and/or email ANSSI per their instructions if required outside Apple).

## After Apple approves

Apple shows an **export compliance code** next to the approved documentation.

1. Copy that code.
2. Run from the repo root (preferred):

```bash
bash scripts/set_encryption_compliance_code.sh YOUR_APPLE_CODE
```

Or set manually in [`ios/Runner/Info.plist`](../../ios/Runner/Info.plist):

```xml
<key>ITSAppUsesNonExemptEncryption</key>
<true/>
<key>ITSEncryptionExportComplianceCode</key>
<string>YOUR_APPLE_CODE</string>
```

3. Use Apple’s exact value (do not invent one).
4. Commit `Info.plist` and ship a new build. Future uploads should skip repeated encryption questionnaires.

`ITSAppUsesNonExemptEncryption` is already set to `true` in the repo. The compliance code key is added only after Apple returns a value.

## Info.plist policy

| Key | Value | When |
|-----|--------|------|
| `ITSAppUsesNonExemptEncryption` | `true` | Now (in-app AES/RSA) |
| `ITSEncryptionExportComplianceCode` | Apple-provided string | Only after documentation approval |

Do **not** set `ITSAppUsesNonExemptEncryption` back to `false` while chat encryption remains in the app.

## References

- [Determine and upload app encryption documentation](https://developer.apple.com/help/app-store-connect/manage-app-information/determine-and-upload-app-encryption-documentation)
- [Export compliance documentation for encryption](https://developer.apple.com/help/app-store-connect/reference/export-compliance-documentation-for-encryption)
- [Complying with Encryption Export Regulations](https://developer.apple.com/documentation/security/complying-with-encryption-export-regulations)
