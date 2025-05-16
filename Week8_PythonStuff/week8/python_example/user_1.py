from common import w3, contract

USER_PRIVATE = '0x4f3edf983ac636a65a842ce7c78d9aa706d3b113bce9c46f30d7d21715b23b1d'
ACCOUNT_INDEX = 0  # Index of the account to approve users

def add_user():

    print("Adding user...")
    print(f"Account: {w3.eth.accounts[ACCOUNT_INDEX]}")
    print(f"Private Key: {USER_PRIVATE}")

    tx = contract.functions.addUser().build_transaction({
        'from': w3.eth.accounts[ACCOUNT_INDEX],
        'nonce': w3.eth.get_transaction_count(w3.eth.accounts[ACCOUNT_INDEX]),
        'gas': 1000000,
        'gasPrice': w3.to_wei('1', 'gwei')
    })
    signed_tx = w3.eth.account.sign_transaction(tx, private_key=USER_PRIVATE)

    print(f"Signed transaction: {signed_tx.raw_transaction.hex()}")

    tx_hash = w3.eth.send_raw_transaction(signed_tx.raw_transaction)

    print(f"User added: {w3.eth.accounts[ACCOUNT_INDEX]}")

    w3.eth.wait_for_transaction_receipt(tx_hash)

add_user()
