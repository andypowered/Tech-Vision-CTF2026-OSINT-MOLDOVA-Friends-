# Shadow Cloud: Broken Trust

Writeup for the **Shadow Cloud** cloud incident response CTF.

| | |
|---|---|
| **Target** | https://ctf-tke5.onrender.com |
| **Category** | Cloud / AWS |
| **Difficulty** | Advanced |
| **Flag** | `TVX{ROLE_HANDOFF_LAMBDA_TRUST_PUBLIC_POLICY_SECRET_READ_ROLE_SESSION_KMS_DECRYPT}` |

> Everything in the challenge is simulated. No AWS account, credentials, or real customer data are involved.

## Overview

The challenge gives you six evidence bundles from a made-up AWS incident. Each bundle asks for one exact AWS identifier: a permission, a service principal, an S3 control, a CloudTrail event, a role name, and a KMS action. A correct answer returns one fragment of the flag. The fragments go together in card order.

There is nothing to exploit here. It is a reading and correlation exercise, but the evidence is realistic enough that you need to know how the services fit together.

## Answers at a glance

| # | Stage | Answer | Fragment |
|---|-------|--------|----------|
| 1 | IAM / Delegation | `iam:PassRole` | `ROLE_HANDOFF` |
| 2 | IAM / Trust | `lambda.amazonaws.com` | `LAMBDA_TRUST` |
| 3 | S3 / Public access | `BlockPublicPolicy` | `PUBLIC_POLICY` |
| 4 | Secrets Manager | `GetSecretValue` | `SECRET_READ` |
| 5 | STS / Attribution | `FinanceReadOnly` | `ROLE_SESSION` |
| 6 | KMS / Authorization | `kms:Decrypt` | `KMS_DECRYPT` |

## Recon

I opened the page source first, mostly out of habit. The UI is static and the logic lives in `/app.js`. Answers are checked with `POST /api/submit`, and a correct response contains the fragment. The page stores solved stages in localStorage and builds the final flag as `TVX{fragment1_fragment2_...}` in card order.

That gave me the flag format and confirmed there were no hidden stages. The answers still have to come from the evidence.

## Walkthrough

### 1. The Borrowed Identity (IAM)

**Evidence**

```text
Policy: BuildPublisher
Effect: Allow
Action:
  - lambda:CreateFunction
  - iam:PassRole
Resource:
  arn:aws:iam::492610738155:role/FinanceReadOnly

CreateFunction
function: nightly-recon
role: arn:aws:iam::492610738155:role/FinanceReadOnly
```

**Reasoning**

`lambda:CreateFunction` lets the build identity create the function, but that alone does not let it attach an existing role. Passing a role to a service is controlled by `iam:PassRole` on the role resource. That is the permission in the policy that makes the delegation work.

**Answer:** `iam:PassRole`
**Fragment:** `ROLE_HANDOFF`

### 2. The Trust Boundary (IAM trust policy)

**Evidence**

```json
{
  "Effect": "Allow",
  "Principal": {
    "Service": "lambda.amazonaws.com"
  },
  "Action": "sts:AssumeRole",
  "Condition": {
    "ArnLike": {
      "AWS:SourceArn": "arn:aws:lambda:us-west-2:492610738155:function:nightly-recon"
    }
  }
}
```

**Reasoning**

The trust policy only lets `lambda.amazonaws.com` assume the role, and only from the `nightly-recon` function. The service principal is the part that makes the trust possible, so that is the answer. The `SourceArn` condition just narrows it down to one function.

**Answer:** `lambda.amazonaws.com`
**Fragment:** `LAMBDA_TRUST`

### 3. The Policy That Slipped Through (S3)

**Evidence**

```text
BlockPublicAcls:       true
IgnorePublicAcls:      true
BlockPublicPolicy:     false
RestrictPublicBuckets: false

Principal: "*"
Action: s3:GetObject
Resource: arn:aws:s3:::finance-archive/*
```

**Reasoning**

The four public access controls do different things:

| Control | Value | What it does |
|---------|-------|--------------|
| `BlockPublicAcls` | `true` | Rejects new public ACLs |
| `IgnorePublicAcls` | `true` | Makes S3 ignore existing public ACLs |
| `BlockPublicPolicy` | `false` | Would reject bucket policies that grant public access |
| `RestrictPublicBuckets` | `false` | Would limit access to public buckets to AWS services and authorized users in the account |

`BlockPublicPolicy` is the one that stops a public bucket policy from being applied. It was off, so the `Principal: "*"` policy on `finance-archive` could be attached. The ACL controls do not cover bucket policies.

**Answer:** `BlockPublicPolicy`
**Fragment:** `PUBLIC_POLICY`

### 4. The Read Hidden in the Noise (Secrets Manager)

**Evidence**

```text
09:14:02  ListSecrets
09:14:07  DescribeSecret
           resource: /prod/finance/db
09:14:11  GetSecretValue
           resource: /prod/finance/db
           sourceIp: 198.51.100.24
09:14:12  Decrypt (KMS)
           keyId: key/7c1e...
           sourceIp: secretsmanager.amazonaws.com
```

**Reasoning**

Only `GetSecretValue` returns the secret value. `ListSecrets` lists secrets, `DescribeSecret` returns metadata, and the KMS `Decrypt` is the backend operation Secrets Manager uses to decrypt the stored payload. The question asks for the Secrets Manager API event that retrieves the value, so it is `GetSecretValue`.

**Answer:** `GetSecretValue`
**Fragment:** `SECRET_READ`

### 5. Role or Session? (STS attribution)

**Evidence**

```text
AssumeRole
  userIdentity.arn:
  arn:aws:iam::492610738155:user/build-agent
  requestParameters.roleArn:
  arn:aws:iam::492610738155:role/FinanceReadOnly
  requestParameters.roleSessionName: release-8821

GetSecretValue
  userIdentity.arn:
  arn:aws:sts::492610738155:assumed-role/FinanceReadOnly/release-8821
```

**Reasoning**

An assumed-role ARN looks like:

```text
arn:aws:sts::<account-id>:assumed-role/<role-name>/<session-name>
```

Here `FinanceReadOnly` is the role and `release-8821` is the session name. The question asks for the role, so `FinanceReadOnly`.

**Answer:** `FinanceReadOnly`
**Fragment:** `ROLE_SESSION`

### 6. The Last Authorization Check (KMS)

**Evidence**

```text
FinanceReadOnly policy:
  secretsmanager:GetSecretValue
  Resource: secret:/prod/finance/db

CloudTrail event: Decrypt
Key: arn:aws:kms:us-west-2:492610738155:key/7c1e...
Error: not authorized to perform kms:Decrypt on the key
Caller: assumed-role/FinanceReadOnly
InvokedBy: secretsmanager.amazonaws.com
```

**Reasoning**

The role can call `GetSecretValue`, but Secrets Manager decrypts the secret with the customer managed key using the caller's identity. That means the role also needs `kms:Decrypt` on the key, or the key policy has to allow it. CloudTrail shows the exact failure: `not authorized to perform kms:Decrypt`.

**Answer:** `kms:Decrypt`
**Fragment:** `KMS_DECRYPT`

## Flag

Putting the fragments in card order:

```text
TVX{ROLE_HANDOFF_LAMBDA_TRUST_PUBLIC_POLICY_SECRET_READ_ROLE_SESSION_KMS_DECRYPT}
```

## Attack path

```text
build-agent
  -> iam:PassRole (FinanceReadOnly -> nightly-recon)
  -> lambda.amazonaws.com assumes FinanceReadOnly
  -> secretsmanager:GetSecretValue on /prod/finance/db
  -> kms:Decrypt denied (permission missing)
```

The build identity used `iam:PassRole` to attach `FinanceReadOnly` to a Lambda function it created. The role's trust policy allowed Lambda to assume it, so `nightly-recon` ran with the finance role's permissions. From there the attacker called `GetSecretValue` on `/prod/finance/db`, and the attempt died at KMS because the role never had `kms:Decrypt` on the CMK.

The S3 finding is a separate exposure: `BlockPublicPolicy` was disabled, so a bucket policy granting `s3:GetObject` to `*` could be applied to `finance-archive`. The other public access controls do not stop that.

## Takeaways

- `iam:PassRole` is a delegation primitive. It needs to be scoped as tightly as any other permission.
- A trust policy with a `SourceArn` condition is only as good as the service principal and the resource ARN in it.
- `BlockPublicPolicy` is the control that matters for public bucket policies. `BlockPublicAcls` and `IgnorePublicAcls` do not cover them.
- `secretsmanager:GetSecretValue` is not enough on its own. The caller also needs `kms:Decrypt` on the key that protects the secret.
