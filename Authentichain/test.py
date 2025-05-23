from web3 import Web3

# Connect to Ganache
web3 = Web3(Web3.HTTPProvider("http://127.0.0.1:8545"))

# Replace with the exact deployed contract address shown in Ganache
raw_address = "0x50200EdD39d0e8127E1A01681C2809D7b7DFdF6d"
address = web3.to_checksum_address(raw_address)

# Get code at that address
code = web3.eth.get_code(address)

# Print result
if code == b'':
    print(f"No contract deployed at {address}")
else:
    print(f"Contract deployed at {address}")
    print("Bytecode preview:", code.hex()[:60], "...")
