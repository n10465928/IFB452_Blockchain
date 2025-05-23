import sys, os
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))
from common import web3, material_contract, MINT_CONTRACT_ADDRESS


# Replace this with a Ganache private key of the contract owner
REGULATOR_PRIVATE_KEY = "0x33f8652ee0d8db2eba7d45943c71d99d476ae22a65dd189006b41797213a822f" 
REGULATOR_ADDRESS = web3.eth.account.from_key(REGULATOR_PRIVATE_KEY).address

def mint_material():
    print("🔨 Minting a new batch of materials...")

    origin = "Australia"
    supplier = "AU-Supplier-001"
    weight = 20  # e.g., 20kg
    purity = "99.99%"
    cert_hash = "ipfs://example-cert"

    nonce = web3.eth.get_transaction_count(REGULATOR_ADDRESS)
    tx = material_contract.functions.mintMaterial(origin, supplier, weight, purity, cert_hash).build_transaction({
        'from': REGULATOR_ADDRESS,
        'nonce': nonce,
        'gas': 300000,
        'gasPrice': web3.to_wei("1", "gwei")
    })

    signed_tx = web3.eth.account.sign_transaction(tx, private_key=REGULATOR_PRIVATE_KEY)
    

    tx_hash = web3.eth.send_raw_transaction(signed_tx.raw_transaction) 
    receipt = web3.eth.wait_for_transaction_receipt(tx_hash)

    print(f"✅ Material minted | Tx Hash: {tx_hash.hex()}")

def approve_burner():
    print("🔐 Approving MintContract to burn materials...")

    nonce = web3.eth.get_transaction_count(REGULATOR_ADDRESS)
    tx = material_contract.functions.setBurnerApproval(MINT_CONTRACT_ADDRESS, True).build_transaction({
        'from': REGULATOR_ADDRESS,
        'nonce': nonce,
        'gas': 150000,
        'gasPrice': web3.to_wei("1", "gwei")
    })

    signed_tx = web3.eth.account.sign_transaction(tx, private_key=REGULATOR_PRIVATE_KEY)
    tx_hash = web3.eth.send_raw_transaction(signed_tx.raw_transaction)
    receipt = web3.eth.wait_for_transaction_receipt(tx_hash)

    print(f"✅ MintContract approved as burner | Tx Hash: {tx_hash.hex()}")

if __name__ == "__main__":
    mint_material()
    approve_burner()
