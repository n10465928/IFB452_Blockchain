import sys, os
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))
from common import web3, material_contract, MINT_CONTRACT_ADDRESS, mint_contract
from web3._utils.events import get_event_data

REGULATOR_PRIVATE_KEY = "0x33f8652ee0d8db2eba7d45943c71d99d476ae22a65dd189006b41797213a822f" 
REGULATOR_ADDRESS = web3.eth.account.from_key(REGULATOR_PRIVATE_KEY).address

MANUFACTURER_ADDRESS = "0x9D85142a946654842012C7d55fE33b9c381cDb79"


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
    print(f'Contract address being approved: {MINT_CONTRACT_ADDRESS}')
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

from web3._utils.events import get_event_data

def get_all_material_ids():
    print("🔍 Fetching all minted material IDs...")

    # Event signature must match Solidity exactly
    event_signature = "MaterialMinted(uint256,string,string,uint256,string,string,address)"
    
    # ✅ Add 0x prefix
    event_signature_hash = "0x" + web3.keccak(text=event_signature).hex()

    try:
        logs = web3.eth.get_logs({
            "fromBlock": 0,
            "toBlock": "latest",
            "address": material_contract.address,
            "topics": [event_signature_hash]
        })

        material_ids = []
        for log in logs:
            decoded_event = get_event_data(
                web3.codec,
                material_contract.events.MaterialMinted._get_event_abi(),
                log
            )
            material_ids.append(decoded_event["args"]["materialId"])

        print(f"🧾 Total materials minted: {len(material_ids)}")
        print("Material IDs:", material_ids)
        return material_ids

    except Exception as e:
        print(f"❌ Error while fetching material events: {e}")
        return []


def get_material_info():
    try:
        material_id = int(input("🔢 Enter the material ID to fetch: ").strip())
    except ValueError:
        print("❌ Invalid input. Please enter a numeric material ID.")
        return

    print(f"📦 Getting info for material ID: {material_id}")

    try:
        material = material_contract.functions.getMaterial(material_id).call()

        print("📋 Material Info:")
        print(f"  Origin   : {material[0]}")
        print(f"  Supplier : {material[1]}")
        print(f"  Weight   : {material[2]} units")
        print(f"  Purity   : {material[3]}")
        print(f"  Cert Hash: {material[4]}")

    except Exception as e:
        print(f"❌ Error fetching material info: {e}")

from common import mint_contract  # Import mint_contract if not already

def approve_manufacturer():
    print(f"🛂 Approving manufacturer: {MANUFACTURER_ADDRESS}")

    nonce = web3.eth.get_transaction_count(REGULATOR_ADDRESS)
    tx = mint_contract.functions.setManufacturerApproval(MANUFACTURER_ADDRESS, True).build_transaction({
        'from': REGULATOR_ADDRESS,
        'nonce': nonce,
        'gas': 150000,
        'gasPrice': web3.to_wei("1", "gwei")
    })

    signed_tx = web3.eth.account.sign_transaction(tx, private_key=REGULATOR_PRIVATE_KEY)
    tx_hash = web3.eth.send_raw_transaction(signed_tx.raw_transaction)
    receipt = web3.eth.wait_for_transaction_receipt(tx_hash)

    print(f"✅ Manufacturer approved | Tx Hash: {tx_hash.hex()}")


if __name__ == "__main__":
    #mint_material()
    #approve_burner()
    #get_all_material_ids()
    #get_material_info()
    approve_manufacturer()

