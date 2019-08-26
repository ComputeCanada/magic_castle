# One-time password

By default, FreeIPA is configured to allow every user to generate a self-managed 
software token for one-time password. To generate the token, the user has to enter 
the following commands
```
kinit
ipa otptoken-add
kdestroy
```

The user can then scan the QR code with his password manager app or copy the URI.

# References
* https://www.freeipa.org/page/V4/OTP