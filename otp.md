# One-time password

By default, FreeIPA is configured to allow every user to generate a self-managed 
software token for one-time password. To generate the token, the user has to enter 
the following command 
```
ipa otptoken-add
```

The user can then scan the QR code with his password manager app or copy the
URI text.