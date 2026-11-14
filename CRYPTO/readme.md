```tvx-ctf-crypto/
├── README.md
├── creeper-vaults/
│   ├── solve.py
│   └── flag.txt
└── ender-chest/
    ├── solve.sage
    └── flag.txt
```
# TVX CTF: Crypto Writeups

Two crypto challenges from TVX CTF. Both look reasonable at first: standard RSA, standard ECC, big numbers everywhere. Both fall apart because of how the parameters were generated. No memory bugs, no protocol tricks, just math.

| Challenge | Weakness | Attack | Tool |
|---|---|---|---|
| [Creeper Vaults](#challenge-1-creeper-vaults) | Shared prime between two RSA moduli | `gcd(nA, nB)` | Python |
| [Ender Chest](#challenge-2-ender-chest) | Smooth order of `#E(F_p)` | Pohlig-Hellman | SageMath |

---

## Challenge 1: Creeper Vaults

**Category:** Crypto  
**Difficulty:** Easy  
**Type:** RSA shared prime

### The setup

> A Creeper built two RSA vaults with parts stolen from the same crafting table.
> The message was encrypted for Vault A. Recover it.

```text
=== Creeper Vault A ===
n = 1942668892225729070919461906823520455305416829490420089422957436437580309796491507761
e = 65537

=== Creeper Vault B ===
n = 1942668892225729070919461906823519371241578281403951004079222153957205455266330293941
e = 65537

c = 1574928985319013777436289945491687612751672976588545303342361399014858100334313795739
```

### The weakness

Both moduli are 281 bits and extremely close to each other. That alone is suspicious, but the hint is the real giveaway. If the two keys were built from parts taken from the same table, they may share a prime.

RSA stops being safe if the primes are reused. If `nA = p * qA` and `nB = p * qB`, then:

```text
p   = gcd(nA, nB)
q   = nA // p
phi = (p - 1) * (q - 1)
d   = pow(e, -1, phi)
m   = pow(c, d, nA)
```

One `gcd` gives us `p`. From there, `q`, `phi`, `d`, and the plaintext follow in a few lines. This is the classic shared-prime attack, and it works because the two keys were not generated independently.

### Solver

```python
from math import gcd

nA = 1942668892225729070919461906823520455305416829490420089422957436437580309796491507761
nB = 1942668892225729070919461906823519371241578281403951004079222153957205455266330293941
c  = 1574928985319013777436289945491687612751672976588545303342361399014858100334313795739
e  = 65537

# The two moduli share a prime factor.
p = gcd(nA, nB)
q = nA // p

# Normal RSA key recovery.
phi = (p - 1) * (q - 1)
d = pow(e, -1, phi)

m = pow(c, d, nA)
flag = m.to_bytes((m.bit_length() + 7) // 8, "big").decode()

print("p =", p)
print("q =", q)
print("d =", d)
print("FLAG:", flag)
```

### Flag

```text
TVXCTF{the_creeper_reused_a_prime}
```

### What to remember

- Never reuse a prime across RSA keys. A single `gcd` breaks both of them.
- Two moduli that share any factor are linked. You do not have to factor the full modulus.
- Weak randomness can create these links even when the keys look independent.

---

## Challenge 2: Ender Chest

**Category:** Crypto  
**Difficulty:** Medium  
**Type:** ECC smooth order

### The setup

> You found a world seed nobody could guess and used it as the key to his chests.
> Elliptic curves are unbreakable, so the curve the server admin picked must be
> fine, right?... RIGHT???

The challenge gives us a curve over `F_p`, a generator `G`, a public point `Q = d * G`, and two AES-CBC blobs. The first is keyed with `sha256(str(d))`, the second with `sha256(str(Q[0]))`.

```python
p = 4724861355973759862466485852137759
a = 927566916496059264792326746507264
b = 4715968330470840770745781630703560
G = (3675942204092047283238136253093045, 3544727085494657603430718404172845)
Q = (3869418175838450319054504785525959, 1429060253338888234770668216689896)

ender_hex   = "46e14511e959705d1fe179ab3a4c2c40f5db5273f61faa0e319096122ccc59f812a0f0591c193aab914bda09c9f609413398a9c3e8c8e602fc356ff3ea5a7583"
shulker_hex = "db755bc9df9ca0eb13611170fceaf940a9395f71ac25050188701bf0b7c7fcb4954519578e377ed12f027388d3d63c8f"
```

### Checking the usual ECC weaknesses

ECC has a few classic failure modes. I ruled them out before going after the discrete log.

1. **Singular curve.** The discriminant `4a^3 + 27b^2 mod p` is `3124890983027699820811290486381296`, which is not zero. No singular curve trick here.

2. **Anomalous curve.** `p * G` is not the point at infinity, and neither is `(p + 1) * G`. So the order is not `p` or `p + 1`.

3. **Smooth order.** This is the one. Sage gives the curve order and its factorization:

```python
E = EllipticCurve(GF(p), [a, b])
N = E.order()
factor(N)
# 11 * 367 * 13399 * 58453 * 484079 * 40128631 * 76927309
```

The largest prime factor is 76,927,309. That is small enough for baby-step giant-step, which needs about `sqrt(76,927,309)`, or roughly 8,800 steps. Pohlig-Hellman solves the discrete log in each small subgroup and uses CRT to combine the answers.

The fact that `p` is 112 bits does not help the defender here. The attacker cares about the order of the group, not the size of the field.

### Solver

```python
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
```

### Recovered private key

```text
d = 2327569722739447708246377569803395
```

### Flags

| Blob | Flag |
|---|---|
| `ender_chest` | `TVX{D1dn5_F4lL_4_7h3_7r4p_7h15_t1me}` |
| `shulker_box` | `TVX{tNt_g035_B00m_C0ngr4t5}` |

### What to remember

- Check the order of the curve, not just the size of `p`.
- A smooth group order is fatal. Pohlig-Hellman turns one big discrete log into several small ones.
- Rule out singular, anomalous, and small embedding degree before assuming the curve is safe.
- "Elliptic curves are unbreakable" only applies when the parameters are chosen properly.

---

## Running the solvers

The RSA solver uses only the Python standard library. It lives in `creeper-vaults/solve.py`:

```bash
python3 creeper-vaults/solve.py
```

The ECC solver needs SageMath and pycryptodome. I used Sage 10.x, but any recent version should work. The script is in `ender-chest/solve.sage`:

```bash
pip install pycryptodome
sage ender-chest/solve.sage
```

If you do not want to install Sage locally, the online cell at <https://sagecell.sagemath.org> is enough for this challenge.

---

Neither challenge needed a clever exploit. In both cases, the key generation was the bug. That is usually where I look first in CTF crypto, and this set was no exception.
