#!/usr/bin/env python
import argparse
import sys

from Crypto.Cipher import AES
from Crypto.Hash import SHA256
from Crypto.Protocol.KDF import HKDF
from ecdsa import SECP256k1, SigningKey
from ecdsa.ellipticcurve import Point
from Crypto.Random import get_random_bytes

def encrypt(plaintext, pk):
    nonce = get_random_bytes(16)
    r = int.from_bytes(get_random_bytes(32),'little')
    ephemeral_priv = SigningKey.from_secret_exponent(r, curve=SECP256k1)
    shared_point = pk * r
    ephemeral = ephemeral_priv.verifying_key.pubkey.point
    symm_key = HKDF(b'\x04' + ephemeral.to_bytes() + b'\x04' + shared_point.to_bytes(), 32, salt=None, hashmod=SHA256)
    cipher = AES.new(symm_key, AES.MODE_GCM, nonce=nonce)
    ciphertext, tag = cipher.encrypt_and_digest(plaintext)
    return ephemeral.to_bytes() + nonce + tag + ciphertext

if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="HTTP Oracle pool Trust domain encryption tool. Encrypts data using ECDH key exchange and AES-GCM encryption for secure transmission to trust domains."
    )
    parser.add_argument(
        "--data",
        required=True,
        help="The plaintext data to encrypt (as a string)"
    )
    parser.add_argument(
        "--td-public-key",
        required=True,
        help="The trust domain's public key in hex format (must start with 0x)"
    )
    
    args = parser.parse_args()
    
    data = args.data
    public_key_hex = args.td_public_key
    
    # Validate public key starts with 0x
    if not public_key_hex.startswith("0x"):
        print("Error: Public key must start with 0x", file=sys.stderr)
        sys.exit(1)
    
    # Remove 0x prefix and convert to bytes
    try:
        public_key_bytes = bytes.fromhex(public_key_hex[2:])
    except ValueError as e:
        print(f"Error: Invalid hex string in public key: {e}", file=sys.stderr)
        sys.exit(1)
    
    # Convert bytes to Point
    try:
        pk = Point.from_bytes(SECP256k1.curve, public_key_bytes)
    except Exception as e:
        print(f"Error: Failed to parse public key: {e}", file=sys.stderr)
        sys.exit(1)
    
    # Encrypt the data
    plaintext = data.encode('utf-8')
    encrypted = encrypt(plaintext, pk)
    
    # Output as hex string
    print(encrypted.hex()) 