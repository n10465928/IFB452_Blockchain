from common import w3, contract
import time

USER_PRIVATE = '0x6cbed15c793ce57650b9877cf6fa156fbef513c4e6134f022a85b1ffdd59b2a1'
ACCOUNT_INDEX = 1  # Index of the account to approve users

def handle_added_event(event):
    user = event['args']['user']
    print(f"Detected user add event: {user}")

    tx = contract.functions.approveUser(user).build_transaction({
        'from': w3.eth.accounts[ACCOUNT_INDEX],
        'nonce': w3.eth.get_transaction_count(w3.eth.accounts[ACCOUNT_INDEX]),
        'gas': 1000000,
        'gasPrice': w3.to_wei('1', 'gwei')
    })
    signed_tx = w3.eth.account.sign_transaction(tx, private_key=USER_PRIVATE)

    print(f"Signed transaction: {signed_tx.raw_transaction.hex()}")

    w3.eth.send_raw_transaction(signed_tx.raw_transaction)
    print(f"User approved: {user}")

def watch():
    print("Listening for Added events...")
    added_event_filter = contract.events.Added.create_filter(from_block='latest')
    while True:
        for event in added_event_filter.get_new_entries():
            handle_added_event(event)
        time.sleep(1)

watch()
