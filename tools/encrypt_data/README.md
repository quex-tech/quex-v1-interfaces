# Encrypt Data Tool

A command-line tool for the HTTP Oracle pool Trust domain encryption. This tool encrypts sensitive data (such as API keys, authentication tokens, etc.) using ECDH (Elliptic Curve Diffie-Hellman) key exchange and AES-GCM encryption, enabling secure transmission to trust domains in the Quex HTTP Oracle pool.

## Overview

This tool encrypts plaintext data using a trust domain's public key. It is designed for use with the HTTP Oracle pool where sensitive request data needs to be encrypted before being sent to trust domains. It implements:
- **ECDH key exchange**: Uses SECP256k1 curve to derive a shared secret
- **AES-GCM encryption**: Encrypts the data with authenticated encryption
- **Ephemeral key generation**: Generates a new ephemeral key pair for each encryption

## Usage

```bash
python encrypt_data.py --data <data> --td-public-key <public_key>
```

### Arguments

- `--data`: The plaintext data to encrypt (as a string)
- `--td-public-key`: The trust domain's public key in hex format (must start with `0x`)

### Example

```bash
python encrypt_data.py --data "Bearer api-key" --td-public-key 0x71d4094a7761904c851a51cc1b75a08175e4ecc1e0a1f4d5c87d81385409818450dd23944d7e771c1ea8b33a6c3b888516b7a7a82b895a49853455636fde13e8
```

### Output

The tool outputs the encrypted data as a hexadecimal string. The encrypted output format is:
- 64 bytes: Ephemeral public key point
- 16 bytes: Nonce
- 16 bytes: Authentication tag
- Variable length: Ciphertext

## Public Key Format

The trust domain public key for each network can be found in the [Quex documentation](https://docs.quex.tech/general-information/addresses) under the "TD Pubkey" parameter for your specific network.

The public key must be:
- In hexadecimal format
- Prefixed with `0x`
- Uncompressed format (65 bytes = 130 hex characters including `0x` prefix)
- A valid point on the SECP256k1 curve

## Dependencies

- `pycryptodome`: For AES encryption and HKDF
- `ecdsa`: For elliptic curve operations

## Encryption Algorithm

1. Generate a random 16-byte nonce
2. Generate a random ephemeral private key
3. Perform ECDH: `shared_point = public_key * ephemeral_private_key`
4. Derive symmetric key using HKDF with SHA-256:
   - Input: `0x04 || ephemeral_public_key || 0x04 || shared_point`
   - Output: 32-byte symmetric key
5. Encrypt plaintext using AES-GCM with the derived key and nonce
6. Return: `ephemeral_public_key || nonce || tag || ciphertext`

## Error Handling

The tool will exit with an error code if:
- Required arguments are missing
- Public key doesn't start with `0x`
- Public key contains invalid hex characters
- Public key cannot be parsed as a valid curve point

