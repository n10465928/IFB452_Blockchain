from web3 import Web3
import json

w3 = Web3(Web3.HTTPProvider("http://127.0.0.1:8545"))
contract_address = "0xe78a0f7e598cc8b0bb87894b0f60dd2a88d6a8ab"
contract_address = w3.to_checksum_address(contract_address)

with open("contract_abi.json") as f:
    abi = json.load(f)

contract = w3.eth.contract(address=contract_address, abi=abi)
