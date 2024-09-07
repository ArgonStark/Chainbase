# Chainbase

### Run this command in your terminal to Setup an AVS Operator for Chainbase : 

```
wget https://raw.githubusercontent.com/ArgonStark/Chainbase/main/chainbase-setup.sh && chmod +x chainbase-setup.sh && ./chainbase-setup.sh
```

## Config & register operator


- `operator address`: Your Eigenlayer ETH address
- `earnings address`: press `Enter`
- `ETH rpc url`: https://ethereum-holesky-rpc.publicnode.com
- `network`: holesky
- `signer type`: local_keystore
- `ecdsa key path:`: /root/.eigenlayer/operator_keys/opr.ecdsa.key.json `or` /root/.eigenlayer/operator_keys/myEigenDAKey.ecdsa.key.json

## Check Operator Health

#### Check chainbase-node logs
```
docker logs chainbase-node -f
```
#### Check Operator Health
```
curl -i localhost:8080/eigen/node/health
```

#### Check docker containers

- You must have 4 new docker containers

```console
docker ps
```

### Fill this the form

https://forms.gle/w9h8Su87kEnDwRMA7

### Send your Operator address in discord

https://discord.gg/chainbase

