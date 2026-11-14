# solve.sage -- run with: sage solve.sage
import hashlib
from Crypto.Cipher import AES
from Crypto.Util.Padding import unpad

p = 4724861355973759862466485852137759
a = 927566916496059264792326746507264
b = 4715968330470840770745781630703560
G = (3675942204092047283238136253093045, 3544727085494657603430718404172845)
Q = (3869418175838450319054504785525959, 1429060253338888234770668216689896)

ender_hex   = "46e14511e959705d1fe179ab3a4c2c40f5db5273f61faa0e319096122ccc59f812a0f0591c193aab914bda09c9f609413398a9c3e8c8e602fc356ff3ea5a7583"
shulker_hex = "db755bc9df9ca0eb13611170fceaf940a9395f71ac25050188701bf0b7c7fcb4954519578e377ed12f027388d3d63c8f"

# 1. The curve order is smooth.
E = EllipticCurve(GF(p), [a, b])
N = E.order()
print("Curve order:", N)
print("Factors:", factor(N))

# 2. Pohlig-Hellman. Sage picks the algorithm based on the group order.
d = discrete_log(E(Q), E(G), operation="+")
print("Recovered d =", d)

# 3. Decrypt ender_chest. The key is sha256(str(d)).
key = hashlib.sha256(str(d).encode()).digest()
ct  = bytes.fromhex(ender_hex)
pt  = unpad(AES.new(key, AES.MODE_CBC, ct[:16]).decrypt(ct[16:]), 16)
print("ENDER FLAG:", pt.decode())

# 4. Decrypt shulker_box. The key is sha256(str(Q[0])).
key2 = hashlib.sha256(str(Q[0]).encode()).digest()
ct2  = bytes.fromhex(shulker_hex)
pt2  = unpad(AES.new(key2, AES.MODE_CBC, ct2[:16]).decrypt(ct2[16:]), 16)
print("SHULKER FLAG:", pt2.decode())
