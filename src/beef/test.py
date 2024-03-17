from py_ecc.secp256k1 import secp256k1
import binascii
import hashlib
import os

# Generate a private key
private_key = int.from_bytes(os.urandom(32), 'big') % secp256k1.N
private_key_bytes = private_key.to_bytes(32, 'big')

# Calculate the public key
public_key = secp256k1.multiply(secp256k1.G, private_key)

# Create a message hash
message = b"Hello, world!"
message_hash = hashlib.sha256(message).digest()
# print(message_hash)


private_key = 0xbeaf
public_key = secp256k1.multiply(secp256k1.G, private_key)
# calculate eth address from public key
eth_address = keccak(public_key[0].to_bytes(32, 'big')[12:]).hex()
print("ETH Address: ", eth_address)
exit()


# Calculate a hash's signature (creating r, s values)
# v, r, s = secp256k1.ecdsa_raw_sign(message_hash, private_key_bytes)

# Verifying the signature
# verification_pub = secp256k1.ecdsa_raw_recover(message_hash, (v, r, s))

# print("Private Key:", private_key)
# print("Public Key: (x={}, y={})".format(*public_key))
# print(f"Signature: (r={r}, s={s})")
# print("Verification: ", verification_pub == public_key)

message_hash = binascii.unhexlify(
    "66e0a70286ab6c8798e00c681e3468dc120b463769be49f5efa461191b347b98")
verification_pub = secp256k1.ecdsa_raw_recover(message_hash, (27, 1, 1))
print("Verification pub: ", verification_pub)


# h1*G + pubKey = (1, y) = a*G
# h2*G + pubKey = (1, -y) = -a*G
# h3*G + r * pubKey = (s, t)


# h1 + privKey = k
# h2 + privKey = -k


message_hash = binascii.unhexlify(
    "5c1eaf21382cba991cce03c69332c2c2bc978427ee55bc1606b5436d47f94c2a")
verification_pub = secp256k1.ecdsa_raw_recover(message_hash, (27, 1, 1))
print("Verification pub: ", verification_pub)

h1Raw = "5c1eaf21382cba991cce03c69332c2c2bc978427ee55bc1606b5436d47f94c2a"
h2Raw = "66e0a70286ab6c8798e00c681e3468dc120b463769be49f5efa461191b347b98"
h1 = int(h1Raw, 16)
h2 = int(h2Raw, 16)
print(h2+h1)
t = (h2+h1)//2
print("t: ", t)

private_key_bytes_t = t.to_bytes(32, 'big')
# print private_key_bytes_t in hex
print("Private Key: ", private_key_bytes_t.hex())

public_key_t = secp256k1.multiply(secp256k1.G, t)
print("Public Key: (x={}, y={})".format(*public_key_t))
