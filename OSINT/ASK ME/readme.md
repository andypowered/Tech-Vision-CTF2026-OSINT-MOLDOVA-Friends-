# Minecraft Screenshots: Hidden in Plain Sight

Writeup for the **Minecraft Screenshots** CTF.

| | |
|---|---|
| **Category** | Forensics / Misc |
| **Difficulty** | Easy / Beginner |
| **Hint** | "ASK ME" |
| **Password** | `F@OuNdIT` |
| **Flag** | `TVX{45C11_C0D3_15_US53FU11}` |

> Everything in the challenge is simulated. No real Minecraft accounts or actual in-game items were harmed in the making of this challenge.

## Overview

The challenge provides eight screenshots from a Minecraft game. The player has to find a password that unlocks a protected file containing the flag. The only hint from the challenge creator is:

> **"ASK ME"**

There is no memory corruption and no binary reversing here. It is a simple observation and ASCII decoding exercise. You just need to know how to read the game's UI and map numbers to characters.

## Answers at a glance

| # | Screenshot | Diamond stacks | Sum | ASCII | Character |
|---|------------|----------------|-----|-------|-----------|
| 1 | Screenshot 1 | 64 + 6 | 70 | 70 | `F` |
| 2 | Screenshot 2 | 64 + 0 | 64 | 64 | `@` |
| 3 | Screenshot 3 | 64 + 15 | 79 | 79 | `O` |
| 4 | Screenshot 4 | 64 + 53 | 117 | 117 | `u` |
| 5 | Screenshot 5 | 64 + 14 | 78 | 78 | `N` |
| 6 | Screenshot 6 | 64 + 36 | 100 | 100 | `d` |
| 7 | Screenshot 7 | 64 + 9 | 73 | 73 | `I` |
| 8 | Screenshot 8 | 64 + 20 | 84 | 84 | `T` |

**Password:** `F@OuNdIT`

## Recon

I opened the batch of screenshots and started comparing them. The map scenery, time of day, and player locations were completely different across the eight images. However, one thing changed on every single screenshot: **the number of diamonds in the inventory hotbar**.

The hint "ASK ME" sounded strange at first, but when I read it out loud, I realized it was a phonetic pun for **ASCII**. That meant the diamond counts were likely encoding ASCII characters.

## Walkthrough

### 1. Screenshot 1

**Evidence**

```text
Diamond Stack 1: 64
Diamond Stack 2: 6
```

OSINT/ASK ME/1.png

64 + 6 = 70. Decimal 70 in ASCII is the uppercase letter `F`.

**Answer:** `F`

### 2. Screenshot 2

**Evidence**

```text
Diamond Stack 1: 64
Diamond Stack 2: 0
```

64 + 0 = 64. Decimal 64 in ASCII is `@`.

**Answer:** `@`

### 3. Screenshot 3

**Evidence**

```text
Diamond Stack 1: 64
Diamond Stack 2: 15
```

64 + 15 = 79. Decimal 79 in ASCII is the uppercase letter `O`.

**Answer:** `O`

### 4. Screenshot 4

**Evidence**

```text
Diamond Stack 1: 64
Diamond Stack 2: 53
```

64 + 53 = 117. Decimal 117 in ASCII is the lowercase letter `u`.

**Answer:** `u`

### 5. Screenshot 5

**Evidence**

```text
Diamond Stack 1: 64
Diamond Stack 2: 14
```

64 + 14 = 78. Decimal 78 in ASCII is the uppercase letter `N`.

**Answer:** `N`

### 6. Screenshot 6

**Evidence**

```text
Diamond Stack 1: 64
Diamond Stack 2: 36
```

64 + 36 = 100. Decimal 100 in ASCII is the lowercase letter `d`.

**Answer:** `d`

### 7. Screenshot 7

**Evidence**

```text
Diamond Stack 1: 64
Diamond Stack 2: 9
```

64 + 9 = 73. Decimal 73 in ASCII is the uppercase letter `I`.

**Answer:** `I`

### 8. Screenshot 8

**Evidence**

```text
Diamond Stack 1: 64
Diamond Stack 2: 20
```

64 + 20 = 84. Decimal 84 in ASCII is the uppercase letter `T`.

**Answer:** `T`

## Password

Putting the characters together in order:

```text
F @ O u N d I T
```

**Password:** `F@OuNdIT`

It reads as "Found IT", which is a nice confirmation that the decoding is correct.

## Flag

The password unlocks the protected file, which contains:

```text
TVX{45C11_C0D3_15_US53FU11}
```

The flag is leetspeak for `ASCII_CODE_IS_USEFUL`.

## Data flow

```text
Screenshot (diamond stacks)
  -> add the two stack counts
  -> decimal value
  -> ASCII character
  -> password
  -> protected file
  -> flag
```

## Takeaways

- The hint was the whole challenge. "ASK ME" is just "ASCII" said out loud.
- Minecraft stack sizes are a natural place to hide numbers. Nobody looks at the hotbar twice.
- The diamond counts all stay under 128, so every sum is a printable ASCII character.
- The flag is also leetspeak: `45C11_C0D3_15_US53FU11` decodes to `ASCII_CODE_IS_USEFUL`.

