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
