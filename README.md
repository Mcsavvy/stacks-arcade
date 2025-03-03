# StacksArcade Game Items Marketplace

### Enhanced Rental System V2.1
- Set rental prices for items with minimum price validation
- Automatic rental payments with platform fee distribution
- Time-based rental periods with maximum duration limits
- Rental history tracking
- Rental extension capability
- Early rental termination
- Improved security checks
- Rental availability checking

### Rental Functions
- `set-rental-price`: Set the rental price for an item
- `rent-item`: Rent an item by paying the rental fee
- `extend-rental`: Extend an active rental period
- `end-rental`: End an active rental period
- `is-item-available-for-rent`: Check if an item is available for rent

## Error Codes
- `ERR_INVALID_RENTAL` (u108): Invalid rental price or duration
- `ERR_RENTAL_NOT_ACTIVE` (u109): No active rental found
- `ERR_INVALID_EXTENSION` (u110): Invalid rental extension
- `ERR_INVALID_PRICE` (u111): Rental price below minimum
- `ERR_INVALID_DURATION` (u112): Invalid rental duration
