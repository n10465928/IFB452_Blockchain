import sys, os
import time
from web3.exceptions import ContractLogicError
from web3._utils.events import get_event_data

sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from common import web3, mint_contract, material_contract

# ========== MANUFACTURER IDENTITY ==========
MANUFACTURER_PRIVATE_KEY = "0xb81fb5e8347771296b29e396c2cca0d25e6ce5ed8a793a26f7f8f63b173952eb"
MANUFACTURER_ADDRESS = web3.eth.account.from_key(MANUFACTURER_PRIVATE_KEY).address


# ========== STEP 1: APPROVAL CHECK ==========
def is_manufacturer_approved():
    approved = mint_contract.functions.approvedManufacturers(MANUFACTURER_ADDRESS).call()
    print(f"✅ Manufacturer approved: {approved}")
    return approved


# ========== STEP 2: FIND MATERIALS MINTED BY MANUFACTURER ==========

def get_materials_owned_by_manufacturer():
    print("🔍 Scanning all known materials for balances held by manufacturer...")

    # Event signature for MaterialMinted
    
    event_signature = "MaterialMinted(uint256,string,string,uint256,string,string,address)"
    event_signature_hash = "0x" + web3.keccak(text=event_signature).hex()

    try:
        logs = web3.eth.get_logs({
            "fromBlock": 0,
            "toBlock": "latest",
            "address": material_contract.address,
            "topics": [event_signature_hash]
        })

        owned_materials = []

        for log in logs:
            decoded_event = get_event_data(
                web3.codec,
                material_contract.events.MaterialMinted._get_event_abi(),
                log
            )

            material_id = decoded_event["args"]["materialId"]
            cert_hash = decoded_event["args"]["certHash"]
            balance = material_contract.functions.balanceOf(MANUFACTURER_ADDRESS, material_id).call()

            if balance > 0:
                owned_materials.append({
                    "id": material_id,
                    "certHash": cert_hash,
                    "balance": balance
                })

        if owned_materials:
            print(f"📦 Manufacturer owns the following materials:")
            for m in owned_materials:
                print(f"  ID: {m['id']} | Balance: {m['balance']} | certHash: {m['certHash']}")
        else:
            print("⚠️ Manufacturer owns no material tokens.")

        return owned_materials

    except Exception as e:
        print(f"❌ Error while fetching materials: {e}")
        return []


# ========== STEP 3: CHECK MATERIAL BALANCE ==========
def check_material_balance(material_id):
    try:
        balance = material_contract.functions.balanceOf(MANUFACTURER_ADDRESS, material_id).call()
        print(f"📦 Balance of material {material_id}: {balance}")
        return balance
    except Exception as e:
        print(f"❌ Error checking balance: {e}")
        return 0


# ========== STEP 4: MINT PRODUCT ==========
def mint_product(material_id, metadata_uri):
    print("🛠️ Minting product...")

    try:
        nonce = web3.eth.get_transaction_count(MANUFACTURER_ADDRESS)
        tx = mint_contract.functions.mintProduct(MANUFACTURER_ADDRESS, [material_id], metadata_uri).build_transaction({
            'from': MANUFACTURER_ADDRESS,
            'nonce': nonce,
            'gas': 600000,
            'gasPrice': web3.to_wei("1", "gwei")
        })

        signed_tx = web3.eth.account.sign_transaction(tx, private_key=MANUFACTURER_PRIVATE_KEY)
        tx_hash = web3.eth.send_raw_transaction(signed_tx.raw_transaction)
        receipt = web3.eth.wait_for_transaction_receipt(tx_hash)

        # Extract tokenId from ProductMinted event
        logs = mint_contract.events.ProductMinted().process_receipt(receipt)
        for log in logs:
            token_id = log["args"]["tokenId"]
            print(f"✅ Product minted! Token ID: {token_id} | Tx Hash: {tx_hash.hex()}")
            return token_id

        print("⚠️ Product minted, but token ID not found in event logs.")
        return None

    except ContractLogicError as e:
        print(f"❌ Contract rejected the transaction: {e}")
    except Exception as e:
        print(f"❌ Error during minting: {e}")
    return None

def mint_product_interactive():
    print("🧾 Enter material ID you want to use to mint a product:")
    try:
        material_id = int(input("🔢 Material ID: ").strip())
    except ValueError:
        print("❌ Invalid input. Please enter a numeric material ID.")
        return

    # Check balance
    balance = material_contract.functions.balanceOf(MANUFACTURER_ADDRESS, material_id).call()
    if balance <= 0:
        print(f"❌ You don't have any units of material ID {material_id}.")
        return

    # Fetch certHash from MaterialMinted event or getMaterial()
    try:
        material = material_contract.functions.getMaterial(material_id).call()
        cert_hash = material[4]  # certHash is the 5th field
        print(f"📄 Using certHash: {cert_hash}")
    except Exception as e:
        print(f"❌ Failed to fetch metadata for material ID {material_id}: {e}")
        return

    # Proceed with minting
    token_id = mint_product(material_id, cert_hash)
    if token_id:
        print(f"🎉 Minted product NFT {token_id} using material ID {material_id}")
    else:
        print("⚠️ Minting failed.")


# ========== STEP 5: CHECK MATERIAL CONSUMED ==========

def listen_materials_consumed():
    print("🔎 Fetching all MaterialsConsumed events for this manufacturer...")

    # Define the event signature as it appears in Solidity
    event_signature = "MaterialsConsumed(uint256,address,uint256[])"
    event_signature_hash = "0x" + web3.keccak(text=event_signature).hex()

    try:
        logs = web3.eth.get_logs({
            "fromBlock": 0,
            "toBlock": "latest",
            "address": mint_contract.address,
            "topics": [event_signature_hash]
        })

        if not logs:
            print("ℹ️ No materials consumed yet.")
            return

        event_abi = mint_contract.events.MaterialsConsumed._get_event_abi()

        for log in logs:
            try:
                decoded = get_event_data(web3.codec, event_abi, log)
                args = decoded["args"]

                # Optional: filter only for this manufacturer
                if args["manufacturer"].lower() != MANUFACTURER_ADDRESS.lower():
                    continue

                token_id = args["tokenId"]
                material_ids = args["materialIds"]

                print(f"📦 Token ID {token_id} consumed {len(material_ids)} materials:")
                print(f"    Material IDs: {material_ids}")
            except Exception as e:
                print(f"⚠️ Skipping log (could not decode): {e}")

    except Exception as e:
        print(f"❌ Failed to fetch logs: {e}")


    


# ========== MAIN WORKFLOW ==========
if __name__ == "__main__":
    print(f"👤 Manufacturer Address: {MANUFACTURER_ADDRESS}")
    print("=" * 50)

    # Step 1: Check approval
    is_manufacturer_approved()


    # Step 2: Get all materials minted to this address
    materials = get_materials_owned_by_manufacturer()
    if not materials:
        exit(1)

    print("=" * 50)


    # Step 3: Mint product using selected material
    mint_product_interactive()

    print("=" * 50)

    # Step 4: Check materials consumed 
    listen_materials_consumed()
