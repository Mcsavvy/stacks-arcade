// Enhanced rental system tests

// Test for rental availability check
const checkAvailabilityBlock = chain.mineBlock([
  Tx.contractCall(
    'stacksarcade',
    'is-item-available-for-rent',
    [types.uint(1)],
    user1.address
  ),
]);

assertEquals(checkAvailabilityBlock.receipts[0].result, 'true');

// Test invalid rental price
const setInvalidPriceBlock = chain.mineBlock([
  Tx.contractCall(
    'stacksarcade',
    'set-rental-price',
    [
      types.uint(1),
      types.uint(100)  // Below MIN_RENTAL_PRICE
    ],
    user1.address
  ),
]);

assertEquals(setInvalidPriceBlock.receipts[0].result, `(err u${ERR_INVALID_PRICE})`);

[... rest of the original test cases ...]
