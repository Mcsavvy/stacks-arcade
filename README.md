# StacksArcade Game Items Marketplace

A decentralized marketplace for game items built on the Stacks blockchain using Clarity smart contracts.

## Features

### Core Features
- List game items for sale
- Purchase items using STX
- Track item ownership
- Manage item sale status

### New Trading System
- Create trade offers between users
- Specify desired items for trade
- Time-limited trade offers
- Direct peer-to-peer item swaps

### New Rental System
- Rent items to other players
- Time-based rental periods
- Automatic rental expiration
- Restrictions on rented items

## Contract Functions

### Marketplace Functions
- `list-item`: List a new item for sale
- `purchase-item`: Purchase an item using STX
- `set-item-for-sale`: Toggle item's sale status
- `get-item`: View item details
- `get-user-item-quantity`: Check user's item quantity

### Trading Functions
- `create-trade-offer`: Create a new trade offer
- `accept-trade`: Accept an existing trade offer
- `get-trade-offer`: View trade offer details

### Rental Functions
- `rent-item`: Rent an item to another user
- `end-rental`: End an expired rental period

## Error Codes
- `ERR_INSUFFICIENT_BALANCE` (u100): Insufficient STX balance
- `ERR_ITEM_NOT_FOUND` (u101): Item does not exist
- `ERR_UNAUTHORIZED` (u102): User not authorized
- `ERR_ITEM_NOT_FOR_SALE` (u103): Item not listed for sale
- `ERR_ITEM_NOT_FOR_TRADE` (u104): Item not available for trading
- `ERR_INVALID_TRADE` (u105): Invalid or expired trade
- `ERR_ITEM_RENTED` (u106): Item is currently rented
- `ERR_RENTAL_EXPIRED` (u107): Rental period not expired

## Testing
The contract includes comprehensive test cases covering all functionality including:
- Basic marketplace operations
- Trading system
- Rental system
- Error conditions
- Edge cases
