# App Store Connect — Encryption compliance guide

CivicNet uses **in-app AES-256-CBC** and **RSA-2048-OAEP** for private chat (see [`civicnet-encryption-declaration.md`](civicnet-encryption-declaration.md)), plus normal HTTPS to Supabase/Firebase.

## Current App Store Connect outcome

Questionnaire result: **no documents to upload**.

With France **not** available for distribution, Apple does not require a French encryption declaration for this submission. To skip encryption questions on each upload, [`ios/Runner/Info.plist`](../../ios/Runner/Info.plist) has:

```xml
<key>ITSAppUsesNonExemptEncryption</key>
<false/>
```

That matches Apple’s “no documentation required / exempt from providing documentation” path — not a claim that the app has zero cryptography.

**Keep France excluded** in Pricing and Availability while this plist value is `false`.

## Questionnaire answers (CivicNet)

| Question | Answer |
|----------|--------|
| App purpose | Short community-help + private chat description |
| Proprietary / non-standard algorithms? | **No** (do not select) |
| Standard algorithms in addition to Apple OS? | **Yes** |
| Available in France? | **No** (current) |

If France is **Yes**, Apple requires the official **French encryption declaration approval form** from ANSSI (not our technical PDF alone). See below.

## Files in this folder

| File | Use |
|------|-----|
| [`civicnet-encryption-declaration.md`](civicnet-encryption-declaration.md) | Public GitHub summary of chat encryption |
| [`civicnet-encryption-declaration.html`](civicnet-encryption-declaration.html) | Technical brochure if ANSSI / Apple later need supporting docs |
| `civicnet-encryption-declaration.pdf` | Local only (gitignored) |

## Adding France later

1. Download the ANSSI form from [contrôle relatif à un moyen de cryptologie](https://cyber.gouv.fr/reglementation/reglementation-identite-confiance-numerique/controles-reglementaires-cryptographie/controle-moyen-de-cryptologie/).
2. Fill for CivicNet (AES-256-CBC, RSA-2048-OAEP, chat confidentiality); email `controle@ssi.gouv.fr` with subject `[formalités] CivicNet – com.sufyankamil.communityNet`.
3. When ANSSI returns the **attestation**, upload that PDF in App Store Connect → App Encryption Documentation.
4. After Apple approves, set:

```bash
bash scripts/set_encryption_compliance_code.sh YOUR_APPLE_CODE
```

And set `ITSAppUsesNonExemptEncryption` to `true` (the script does this) before enabling France.

## References

- [Determine and upload app encryption documentation](https://developer.apple.com/help/app-store-connect/manage-app-information/determine-and-upload-app-encryption-documentation)
- [Export compliance documentation for encryption](https://developer.apple.com/help/app-store-connect/reference/export-compliance-documentation-for-encryption)
- [Complying with Encryption Export Regulations](https://developer.apple.com/documentation/security/complying-with-encryption-export-regulations)
