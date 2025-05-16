from common import w3, contract
import time

USER_PRIVATE = '0x6370fd033278c143179d81c5526140625662b8daa446c22ee2d73db3707e620c'
ACCOUNT_INDEX = 2  # Index of the account to approve users

def handle_approved_event(event):
    user = event['args']['user']
    result = contract.functions.getStatus(user).call()
    print(f"Status for {user}: {result}")

def watch():
    print("Listening for Approved events...")
    approved_event_filter = contract.events.Approved.create_filter(from_block='latest')
    while True:
        for event in approved_event_filter.get_new_entries():
            handle_approved_event(event)
        time.sleep(1)

watch()
