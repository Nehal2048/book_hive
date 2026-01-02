from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel
from datetime import datetime, timedelta
from config import supabase

router = APIRouter(prefix="/borrow", tags=["Borrow"])

class BorrowRequest(BaseModel):
    target_id: int      # Listing you want to borrow
    borrower_id: str    # Your user ID (borrower)

# 1. SEND BORROW REQUEST
@router.post("/request")
def send_request(req: BorrowRequest):
    # Get target listing (book to borrow)
    target = supabase.table("listings").select("*").eq("id", req.target_id).execute()
    if not target.data:
        raise HTTPException(404, "Target listing not found")
    
    target_data = target.data[0]
    
    # Validations
    if target_data["listing_type"] != "borrow":
        raise HTTPException(400, "Listing must be for borrow")
    
    if target_data["request_flag"]:
        raise HTTPException(400, "Listing already has pending request")
    
    if target_data["status"] != "available":
        raise HTTPException(400, "Listing not available")
    
    # Check borrower exists
    borrower = supabase.table("users").select("*").eq("id", req.borrower_id).execute()
    if not borrower.data:
        raise HTTPException(404, "Borrower not found")
    
    # Update target listing - store BORROWER ID in request_id
    supabase.table("listings").update({
        "request_flag": True,
        "request_type": "received",
        "request_id": req.borrower_id  # Store borrower UUID as string
    }).eq("id", req.target_id).execute()
    
    return {"message": "Borrow request sent successfully"}

# 2. GET RECEIVED BORROW REQUESTS (for lenders)
@router.get("/received/{user_id}")
def get_received_requests(user_id: str):
    # User's listings that received borrow requests
    result = supabase.table("listings") \
        .select("*") \
        .eq("seller_id", user_id) \
        .eq("listing_type", "borrow") \
        .eq("request_flag", True) \
        .eq("request_type", "received") \
        .execute()
    
    requests = []
    for listing in result.data:
        # Get borrower details from request_id (which stores borrower UUID)
        borrower = supabase.table("users").select("id,name,email").eq("id", listing["request_id"]).execute()
        if borrower.data:
            requests.append({
                "listing": listing,
                "borrower": borrower.data[0]
            })
    
    return requests

# 3. GET SENT BORROW REQUESTS (for borrowers)
@router.get("/sent/{user_id}")
def get_sent_requests(user_id: str):
    # Find borrow listings where request_id = user_id (user is borrower)
    result = supabase.table("listings") \
        .select("*") \
        .eq("listing_type", "borrow") \
        .eq("request_flag", True) \
        .eq("request_type", "received") \
        .eq("request_id", user_id) \
        .execute()
    
    return result.data

# 4. ACCEPT BORROW REQUEST
@router.post("/accept/{listing_id}")
def accept_request(listing_id: int, lender_id: str = Query(...)):
    # Get the listing
    listing = supabase.table("listings").select("*").eq("id", listing_id).execute()
    if not listing.data:
        raise HTTPException(404, "Listing not found")
    
    listing_data = listing.data[0]
    
    # Must be a received borrow request
    if not listing_data["request_flag"] or listing_data["request_type"] != "received":
        raise HTTPException(400, "No pending borrow request")
    
    # Only listing owner can accept
    if listing_data["seller_id"] != lender_id:
        raise HTTPException(403, "Only listing owner can accept borrow request")
    
    # Get borrower ID from request_id
    borrower_id = listing_data["request_id"]
    if not borrower_id:
        raise HTTPException(400, "No borrower information")
    
    # Create borrow record (dates auto-filled by database)
    borrow_record = {
        "lender": listing_data["seller_id"],
        "borrower": borrower_id,
        "listing_id": listing_id,
        "returned_flag": False
    }
    
    borrow_result = supabase.table("borrow").insert(borrow_record).execute()
    
    # Update listing status
    supabase.table("listings").update({
        "status": "borrowed",
        "request_flag": False,
        "request_type": None,
        "request_id": None
    }).eq("id", listing_id).execute()
    
    return {
        "message": "Borrow request accepted",
        "borrow_id": borrow_result.data[0]["id"]
    }

# 5. REJECT BORROW REQUEST
@router.post("/reject/{listing_id}")
def reject_request(listing_id: int, lender_id: str = Query(...)):
    # Get the listing
    listing = supabase.table("listings").select("*").eq("id", listing_id).execute()
    if not listing.data:
        raise HTTPException(404, "Listing not found")
    
    listing_data = listing.data[0]
    
    if not listing_data["request_flag"] or listing_data["request_type"] != "received":
        raise HTTPException(400, "No pending borrow request")
    
    # Only listing owner can reject
    if listing_data["seller_id"] != lender_id:
        raise HTTPException(403, "Only listing owner can reject borrow request")
    
    # Reset listing
    supabase.table("listings").update({
        "request_flag": False,
        "request_type": None,
        "request_id": None
    }).eq("id", listing_id).execute()
    
    return {"message": "Borrow request rejected"}

# 6. CANCEL BORROW REQUEST
@router.post("/cancel/{listing_id}")
def cancel_request(listing_id: int, borrower_id: str = Query(...)):
    # Get the listing
    listing = supabase.table("listings").select("*").eq("id", listing_id).execute()
    if not listing.data:
        raise HTTPException(404, "Listing not found")
    
    listing_data = listing.data[0]
    
    # Must be a borrow listing with pending request
    if listing_data["listing_type"] != "borrow" or not listing_data["request_flag"]:
        raise HTTPException(400, "No borrow request found")
    
    # Only the borrower who sent request can cancel
    if listing_data["request_id"] != borrower_id:
        raise HTTPException(403, "Only the borrower can cancel this request")
    
    # Reset listing
    supabase.table("listings").update({
        "request_flag": False,
        "request_type": None,
        "request_id": None
    }).eq("id", listing_id).execute()
    
    return {"message": "Borrow request cancelled"}

# 7. RETURN BORROWED BOOK
@router.post("/return/{borrow_id}")
def return_book(borrow_id: int, user_id: str = Query(...)):
    # Get borrow record
    borrow = supabase.table("borrow").select("*").eq("id", borrow_id).execute()
    if not borrow.data:
        raise HTTPException(404, "Borrow record not found")
    
    borrow_data = borrow.data[0]
    
    # Check if already returned
    if borrow_data["returned_flag"]:
        raise HTTPException(400, "Book already returned")
    
    # Only lender or borrower can return
    if borrow_data["lender"] != user_id and borrow_data["borrower"] != user_id:
        raise HTTPException(403, "Only lender or borrower can return book")
    
    # Update borrow record
    today = datetime.now().date()
    supabase.table("borrow").update({
        "return_date": str(today),
        "returned_flag": True
    }).eq("id", borrow_id).execute()
    
    # Make listing available again
    supabase.table("listings").update({
        "status": "available",
        "request_flag": False,
        "request_type": None,
        "request_id": None
    }).eq("id", borrow_data["listing_id"]).execute()
    
    return {"message": "Book returned successfully"}

# 8. GET ACTIVE BORROWS
@router.get("/active/{user_id}")
def get_active_borrows(user_id: str):
    # Books user is borrowing
    borrowing = supabase.table("borrow") \
        .select("*") \
        .eq("borrower", user_id) \
        .eq("returned_flag", False) \
        .execute()
    
    # Books user lent out
    lending = supabase.table("borrow") \
        .select("*") \
        .eq("lender", user_id) \
        .eq("returned_flag", False) \
        .execute()
    
    return {
        "borrowing": borrowing.data,
        "lending": lending.data
    }

# 9. GET BORROW HISTORY
@router.get("/history/{user_id}")
def get_borrow_history(user_id: str):
    # All borrows involving user
    result = supabase.table("borrow") \
        .select("*") \
        .or_(f"lender.eq.{user_id},borrower.eq.{user_id}") \
        .execute()
    
    return result.data


from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel
from config import supabase

router = APIRouter(prefix="/exchange", tags=["Exchange"])

def check_is_admin(user_id: str) -> bool:
    """Check if user is admin"""
    result = supabase.table("users").select("user_type").eq("id", user_id).execute()
    if result.data and result.data[0]["user_type"] == "admin":
        return True
    return False

class ExchangeRequest(BaseModel):
    target_id: int  # Listing you want
    your_id: int    # Your listing

# 1. SEND EXCHANGE REQUEST
@router.post("/request")
def send_request(req: ExchangeRequest):
    # Get target listing
    target = supabase.table("listings").select("*").eq("id", req.target_id).execute()
    if not target.data:
        raise HTTPException(404, "Target listing not found")
    target_data = target.data[0]
    
    # Get your listing
    your = supabase.table("listings").select("*").eq("id", req.your_id).execute()
    if not your.data:
        raise HTTPException(404, "Your listing not found")
    your_data = your.data[0]
    
    # Validations
    if target_data["seller_id"] == your_data["seller_id"]:
        raise HTTPException(400, "Cannot request your own listing")
    
    if target_data["listing_type"] != "exchange" or your_data["listing_type"] != "exchange":
        raise HTTPException(400, "Both must be exchange listings")
    
    if target_data["request_flag"] or your_data["request_flag"]:
        raise HTTPException(400, "One of the listings already has active request")
    
    if target_data["status"] != "available" or your_data["status"] != "available":
        raise HTTPException(400, "Both listings must be available")
    
    # UPDATE BOTH LISTINGS:
    # 1. Target listing (RECEIVED request)
    supabase.table("listings").update({
        "request_flag": True,
        "request_type": "received",
        "request_id": req.your_id
    }).eq("id", req.target_id).execute()
    
    # 2. Your listing (SENT request)
    supabase.table("listings").update({
        "request_flag": True,
        "request_type": "sent",
        "request_id": req.target_id
    }).eq("id", req.your_id).execute()
    
    return {"message": "Exchange request sent successfully"}

# 2. GET RECEIVED REQUESTS
@router.get("/received/{user_id}")
def get_received_requests(user_id: str):
    # User's listings that received requests
    result = supabase.table("listings") \
        .select("*") \
        .eq("seller_id", user_id) \
        .eq("request_flag", True) \
        .eq("request_type", "received") \
        .execute()
    
    requests = []
    for listing in result.data:
        # Get the sender's listing
        sender = supabase.table("listings").select("*").eq("id", listing["request_id"]).execute()
        if sender.data:
            requests.append({
                "my_listing": listing,
                "sender_listing": sender.data[0]
            })
    
    return requests

# 3. GET SENT REQUESTS
@router.get("/sent/{user_id}")
def get_sent_requests(user_id: str):
    # User's listings that sent requests
    result = supabase.table("listings") \
        .select("*") \
        .eq("seller_id", user_id) \
        .eq("request_flag", True) \
        .eq("request_type", "sent") \
        .execute()
    
    requests = []
    for listing in result.data:
        # Get the target listing
        target = supabase.table("listings").select("*").eq("id", listing["request_id"]).execute()
        if target.data:
            requests.append({
                "my_listing": listing,
                "target_listing": target.data[0]
            })
    
    return requests

# 4. ACCEPT EXCHANGE REQUEST
@router.post("/accept/{listing_id}")
def accept_request(listing_id: int, user_id: str = Query(...)):
    # Get the listing (which received request)
    listing = supabase.table("listings").select("*").eq("id", listing_id).execute()
    if not listing.data:
        raise HTTPException(404, "Listing not found")
    
    listing_data = listing.data[0]

    # authorization check
    if listing_data["seller_id"] != user_id:
        raise HTTPException(403, "You are not allowed to accept this request")
    
    # Must be a received request
    if not listing_data["request_flag"] or listing_data["request_type"] != "received":
        raise HTTPException(400, "No pending exchange request to accept")
    
    sender_id = listing_data["request_id"]
    
    # Get sender's listing
    sender = supabase.table("listings").select("*").eq("id", sender_id).execute()
    if not sender.data:
        raise HTTPException(404, "Sender listing not found")
    
    # Mark both as completed
    supabase.table("listings").update({
        "status": "exchanged",
        "request_flag": False,
        "request_type": None,
        "request_id": None
    }).eq("id", listing_id).execute()
    
    supabase.table("listings").update({
        "status": "exchanged",
        "request_flag": False,
        "request_type": None,
        "request_id": None
    }).eq("id", sender_id).execute()
    
    # Create exchange record
    supabase.table("exchanges").insert({
        "user1": listing_data["seller_id"],        # Receiver
        "user2": sender.data[0]["seller_id"],      # Sender
        "listing1": listing_id,                    # Receiver's listing
        "listing2": sender_id                      # Sender's listing
    }).execute()
    
    return {"message": "Exchange completed successfully"}

# 5. REJECT EXCHANGE REQUEST
@router.post("/reject/{listing_id}")
def reject_request(listing_id: int, user_id: str = Query(...)):
    # Get the listing (which received request)
    listing = supabase.table("listings").select("*").eq("id", listing_id).execute()
    if not listing.data:
        raise HTTPException(404, "Listing not found")
    
    listing_data = listing.data[0]
    
    if listing_data["seller_id"] != user_id:
        raise HTTPException(403, "You are not allowed to reject this request")
    
    if not listing_data["request_flag"] or listing_data["request_type"] != "received":
        raise HTTPException(400, "No pending exchange request to reject")
    
    sender_id = listing_data["request_id"]
    
    # Reset BOTH listings
    supabase.table("listings").update({
        "request_flag": False,
        "request_type": None,
        "request_id": None
    }).eq("id", listing_id).execute()
    
    supabase.table("listings").update({
        "request_flag": False,
        "request_type": None,
        "request_id": None
    }).eq("id", sender_id).execute()
    
    return {"message": "Exchange request rejected"}

# 6. CANCEL EXCHANGE REQUEST
@router.post("/cancel/{your_listing_id}")
def cancel_request(your_listing_id: int, user_id: str = Query(...)):
    # Get your listing (which sent request)
    your = supabase.table("listings").select("*").eq("id", your_listing_id).execute()
    if not your.data:
        raise HTTPException(404, "Your listing not found")
    
    your_data = your.data[0]
    
    if your_data["seller_id"] != user_id:
        raise HTTPException(403, "You are not allowed to cancel this request")
    
    if not your_data["request_flag"] or your_data["request_type"] != "sent":
        raise HTTPException(400, "No sent request to cancel")
    
    target_id = your_data["request_id"]
    
    # Reset BOTH listings
    supabase.table("listings").update({
        "request_flag": False,
        "request_type": None,
        "request_id": None
    }).eq("id", your_listing_id).execute()
    
    supabase.table("listings").update({
        "request_flag": False,
        "request_type": None,
        "request_id": None
    }).eq("id", target_id).execute()
    
    return {"message": "Exchange request cancelled"}

# 7. GET ALL EXCHANGES (admin only)
@router.get("/")
def get_all_exchanges(user_id: str = Query(...)):
    if not check_is_admin(user_id):
        raise HTTPException(403, "Only admin can access all exchanges")
    
    result = supabase.table("exchanges").select("*").execute()
    return result.data

# 8. GET USER'S EXCHANGE HISTORY
@router.get("/user/{user_id}")
def get_user_exchanges(user_id: str):
    # Exchanges where user was either user1 or user2
    result = supabase.table("exchanges") \
        .select("*") \
        .or_(f"user1.eq.{user_id},user2.eq.{user_id}") \
        .execute()
    
    return result.data

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from config import supabase
from datetime import datetime
from typing import List
router = APIRouter(prefix="/orders", tags=["Orders"])

class OrderCreate(BaseModel):
    listing_id: int
    buyer_id: str


class OrderRead(BaseModel):
    listing_id: int
    buyer_id: str
    status: str

# GET ORDER BY ID
@router.get("/{order_id}", response_model=OrderRead)
def get_order(order_id: int):
    res = supabase.table("orders").select("*").eq("id", order_id).execute()
    if not res.data:
        raise HTTPException(404, "Order not found")
    order = res.data[0]
    
    # Attach listing_id from ordered_items
    oi_res = supabase.table("ordered_items").select("listing_id").eq("order_id", order_id).execute()
    listing_id = oi_res.data[0]["listing_id"] if oi_res.data else None

    return OrderRead(
        listing_id=listing_id,
        buyer_id=order["buyer_id"],
        status=order["status"]
    )

# GET ORDERS BY BUYER (user)
@router.get("/user/{user_id}", response_model=List[OrderRead])
def get_orders_by_user(user_id: str):
    orders_res = supabase.table("orders").select("*").eq("buyer_id", user_id).execute()
    orders_data = orders_res.data if orders_res.data else []

    orders_list = []
    for o in orders_data:
        oi_res = supabase.table("ordered_items").select("listing_id").eq("order_id", o["id"]).execute()
        listing_id = oi_res.data[0]["listing_id"] if oi_res.data else None

        orders_list.append(OrderRead(
            listing_id=listing_id,
            buyer_id=o["buyer_id"],
            status=o["status"]
        ))

    return orders_list

@router.post("/")
def create_order(order: OrderCreate):
    # check listing
    listing = (
        supabase
        .table("listings")
        .select("*")
        .eq("id", order.listing_id)
        .eq("status", "available")
        .eq("listing_type", "sale")
        .execute()
    )

    if not listing.data:
        raise HTTPException(400, "Listing not available")

    # check if already ordered
    existing = (
        supabase
        .table("ordered_items")
        .select("listing_id")
        .eq("listing_id", order.listing_id)
        .execute()
    )

    if existing.data:
        raise HTTPException(400, "This listing is already ordered")

    # create order
    order_res = supabase.table("orders").insert({
        "buyer_id": order.buyer_id,
        "status": "pending",
        "order_date": datetime.utcnow().isoformat(),
        "transaction_id": None
    }).execute()

    order_id = order_res.data[0]["id"]

    # link order ↔ listing
    supabase.table("ordered_items").insert({
        "order_id": order_id,
        "listing_id": order.listing_id
    }).execute()

    return {"message": "Order created", "order_id": order_id}

@router.post("/{order_id}/pay")
def make_payment(order_id: int):
    # get order
    order_res = (
        supabase
        .table("orders")
        .select("*")
        .eq("id", order_id)
        .eq("status", "pending")
        .execute()
    )

    if not order_res.data:
        raise HTTPException(404, "Order not found or already processed")

    order = order_res.data[0]
    buyer_email = order["buyer_id"]

    # get listing_id from ordered_items
    oi_res = (
        supabase
        .table("ordered_items")
        .select("listing_id")
        .eq("order_id", order_id)
        .execute()
    )
    if not oi_res.data:
       raise HTTPException(500, "Ordered item not found")
    listing_id = oi_res.data[0]["listing_id"]

    # get listing (price + seller)
    listing_res = (
        supabase
        .table("listings")
        .select("price, seller_id")
        .eq("id", listing_id)
        .execute()
    )

    listing = listing_res.data[0]
    price = listing["price"]
    seller_email = listing["seller_id"]

    # get buyer balance
    buyer_res = (
        supabase
        .table("users")
        .select("balance")
        .eq("email", buyer_email)
        .execute()
    )

    buyer_balance = buyer_res.data[0]["balance"]

    if buyer_balance < price:
        supabase.table("orders").update({
            "status": "cancelled"
        }).eq("id", order_id).execute()

        return {"message": "You do not have sufficient amount to buy this product"}

    # deduct buyer balance
    supabase.table("users").update({
        "balance": buyer_balance - price
    }).eq("email", buyer_email).execute()

    # add seller balance
    seller_res = (
        supabase
        .table("users")
        .select("balance")
        .eq("email", seller_email)
        .execute()
    )

    seller_balance = seller_res.data[0]["balance"]

    supabase.table("users").update({
        "balance": seller_balance + price
    }).eq("email", seller_email).execute()

    # create transaction
    txn_res = supabase.table("transactions").insert({
        "id": order_id,
        "amount": price,
        "status": "success"
    }).execute()

    transaction_id = txn_res.data[0]["id"]

    # confirm order
    supabase.table("orders").update({
        "status": "confirmed",
        "transaction_id": transaction_id
    }).eq("id", order_id).execute()

    # mark listing sold
    supabase.table("listings").update({
        "status": "sold"
    }).eq("id", listing_id).execute()

    return {"message": "Payment successful. Order confirmed."}


from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Optional, List
from config import supabase

router = APIRouter(prefix="/transactions", tags=["Transactions"])

# Models for transaction creation and response
class TransactionCreate(BaseModel):
    order_id: int

class TransactionUpdate(BaseModel):
    status: str

class Transaction(BaseModel):
    id: Optional[int] = None
    order_id: int
    buyer_id: str
    seller_id: str
    listing_id: int
    status: str
    created_at: Optional[str] = None

# 1. CREATE TRANSACTION
@router.post("/", response_model=Transaction)
def create_transaction(tx: TransactionCreate):
    # Retrieve order and verify it exists
    order_res = supabase.table("orders").select("*").eq("id", tx.order_id).execute()
    if not order_res.data:
        raise HTTPException(404, "Order not found")
    order = order_res.data[0]
    buyer_id = order["buyer_id"]

    # Retrieve listing via ordered_items (1 listing per order)
    oi_res = supabase.table("ordered_items").select("listing_id").eq("order_id", tx.order_id).execute()
    if not oi_res.data:
        raise HTTPException(404, "Ordered item not found")
    listing_id = oi_res.data[0]["listing_id"]

    # Retrieve seller_id from the listing
    listing_res = supabase.table("listings").select("*").eq("id", listing_id).execute()
    if not listing_res.data:
        raise HTTPException(404, "Listing not found")
    seller_id = listing_res.data[0]["seller_id"]

    # Create the transaction record
    tx_data = {
        "order_id": tx.order_id,
        "buyer_id": buyer_id,
        "seller_id": seller_id,
        "listing_id": listing_id,
        "status": "pending"
    }
    tx_res = supabase.table("transactions").insert(tx_data).execute()
    return tx_res.data[0]

# 2. GET ALL TRANSACTIONS
@router.get("/", response_model=List[Transaction])
def get_all_transactions():
    return supabase.table("transactions").select("*").execute().data

# 3. GET SINGLE TRANSACTION
@router.get("/{tx_id}", response_model=Transaction)
def get_transaction(tx_id: int):
    res = supabase.table("transactions").select("*").eq("id", tx_id).execute()
    if not res.data:
        raise HTTPException(404, "Transaction not found")
    return res.data[0]

# 4. UPDATE TRANSACTION STATUS
@router.put("/{tx_id}", response_model=Transaction)
def update_transaction(tx_id: int, updates: TransactionUpdate):
    res = (
        supabase
        .table("transactions")
        .update(updates.dict())
        .eq("id", tx_id)
        .execute()
    )
    if not res.data:
        raise HTTPException(404, "Transaction not found")
    return res.data[0]

# 5. (Optional) DELETE TRANSACTION
@router.delete("/{tx_id}")
def delete_transaction(tx_id: int):
    res = supabase.table("transactions").delete().eq("id", tx_id).execute()
    if not res.data:
        raise HTTPException(404, "Transaction not found")
    return {"message": "Transaction deleted"}