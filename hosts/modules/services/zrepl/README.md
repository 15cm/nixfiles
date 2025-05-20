# zrepl config

## How to generate certificates
Ref: https://zrepl.github.io/configuration/transports.html#certificate-authority-using-easyrsa

```sh
mkdir -p /tmp/ca
cd /tmp/ca
easyrsa init-pki
EASYRSA_BATCH=1 EASYRSA_REQ_CN=mado.moe easyrsa build-ca nopass
cp pki/ca.crt /nixfiles/hosts/modules/services/zrepl/zrepl-ca.crt
domain=".m.mado.moe"
HOSTS=(kazuki asako sachi amane yumiko)
for host in "${HOSTS[@]}"; do
    full_host=${host}${domain}
    EASYRSA_BATCH=1 EASYRSA_CERT_EXPIRE=3600 easyrsa --auto-san build-serverClient-full $full_host nopass
    echo cert for host $host available at pki/issued/${full_host}.crt
    echo key for host $host available at pki/private/${full_host}.key
    cpy < pki/issued/${full_host}.crt
    sops /nixfiles/hosts/$host/zrepl/${full_host}.crt
    cpy < pki/private/${full_host}.key
    sops /nixfiles/hosts/$host/zrepl/${full_host}.key
done
```
