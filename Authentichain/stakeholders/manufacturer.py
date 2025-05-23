import sys, os
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from common import web3, material_contract, mint_contract
from web3._utils.events import get_event_data

MANUFACTURER_PRIVATE_KEY = "0xb81fb5e8347771296b29e396c2cca0d25e6ce5ed8a793a26f7f8f63b173952eb"  
MANUFACTURER_ADDRESS = web3.eth.account.from_key(MANUFACTURER_PRIVATE_KEY).address

def mint_product():
    print("🎯 Minting a product NFT from materials...")

    # Define required material IDs (e.g., get from regulator output or known in advance)
    material_ids = [1]  # Replace with actual material ID(s)
    metadata_uri = "ipfs://product-metadata-example"

    nonce = web3.eth.get_transaction_count(MANUFACTURER_ADDRESS)

    # Build transaction to call mintProduct(materialIds[], metadataURI)
    tx = mint_contract.functions.mintProduct(material_ids, metadata_uri).build_transaction({
        'from': MANUFACTURER_ADDRESS,
        'nonce': nonce,
        'gas': 500000,
        'gasPrice': web3.to_wei("1", "gwei")
    })

    signed_tx = web3.eth.account.sign_transaction(tx, private_key=MANUFACTURER_PRIVATE_KEY)
    tx_hash = web3.eth.send_raw_transaction(signed_tx.raw_transaction)
    receipt = web3.eth.wait_for_transaction_receipt(tx_hash)

    print(f"✅ Product NFT minted | Tx Hash: {tx_hash.hex()}")

def check_balance(material_id):
    print(f"🔎 Checking balance for material ID {material_id}...")
    balance = material_contract.functions.balanceOf(MANUFACTURER_ADDRESS, material_id).call()
    print(f"📦 Balance: {balance}")
    return balance

if __name__ == "__main__":
    # Run functions for testing
    material_id = int(input("Enter material ID to use: ").strip())
    check_balance(material_id)

    confirm = input("Proceed to mint product using this material? (y/n): ").strip().lower()
    if confirm == "y":
        mint_product()
