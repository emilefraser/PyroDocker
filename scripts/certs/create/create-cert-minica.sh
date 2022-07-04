# usage
```
# Generate a root key and cert in minica-key.pem, and minica.pem, then
# generate and sign an end-entity key and cert, storing them in ./foo.com/
$ minica --domains foo.com

# Wildcard
$ minica --domains '*.foo.com'
```
