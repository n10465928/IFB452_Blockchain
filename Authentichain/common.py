from web3 import Web3
import json

# --- Configuration ---
WEB3_PROVIDER = "http://127.0.0.1:8545"

# Raw (lowercase or mixed-case) contract addresses
MATERIAL_CONTRACT_ADDRESS = "0x50200EdD39d0e8127E1A01681C2809D7b7DFdF6d"
MINT_CONTRACT_ADDRESS = "0x1b3B01d9Ed4aE8DaF4E86662aB679743e14175d4"
OWNERSHIP_CONTRACT_ADDRESS = "0xYourOwnershipContractAddress"

OPEN_SALE_CONTRACT_ADDRESS = "0xYourOpenSaleContractAddress"

# --- Connect to Ethereum node ---
web3 = Web3(Web3.HTTPProvider(WEB3_PROVIDER))

# --- Helper to load contract ---
def load_contract(abi_path, raw_address):
    with open(abi_path) as f:
        abi = json.load(f)
    checksum_address = web3.to_checksum_address(raw_address)
    return web3.eth.contract(address=checksum_address, abi=abi)

# --- Contract instances ---
# mint_contract = load_contract("abi/MintContract_abi.json", MINT_CONTRACT_ADDRESS)
# ownership_contract = load_contract("abi/OwnershipControl_abi.json", OWNERSHIP_CONTRACT_ADDRESS)
material_contract = load_contract("abi/MaterialTracking_abi.json", MATERIAL_CONTRACT_ADDRESS)
# open_sale_contract = load_contract("abi/OpenSale_abi.json", OPEN_SALE_CONTRACT_ADDRESS)
