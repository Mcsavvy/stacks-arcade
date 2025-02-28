# StacksArcade Game Items Marketplace

### Enhanced Rental System V2
- Set rental prices for items
- Automatic rental payments in STX
- Time-based rental periods
- Rental history tracking
- Rental extension capability
- Early rental termination
- Improved security checks

### Rental Functions
- `set-rental-price`: Set the rental price for an item
- `rent-item`: Rent an item by paying the rental fee
- `extend-rental`: Extend an active rental period
- `end-rental`: End an active rental period

## Error Codes
- `ERR_INVALID_RENTAL` (u108): Invalid rental price or duration
- `ERR_RENTAL_NOT_ACTIVE` (u109): No active rental found
- `ERR_INVALID_EXTENSION` (u110): Invalid rental extension
