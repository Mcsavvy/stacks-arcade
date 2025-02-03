[... previous test code ...]

// Test 16: Set and use rental price
const setRentalPriceBlock = chain.mineBlock([
  Tx.contractCall(
    'stacksarcade',
    'set-rental-price',
    [
      types.uint(1),
      types.uint(50_000_000)
    ],
    user1.address
  ),
]);

assertEquals(setRentalPriceBlock.receipts[0].result, '(ok true)');

const rentWithPaymentBlock = chain.mineBlock([
  Tx.contractCall(
    'stacksarcade',
    'rent-item',
    [
      types.uint(1),
      types.principal(user2.address),
      types.uint(100)
    ],
    user1.address
  ),
]);

assertEquals(rentWithPaymentBlock.receipts[0].result, '(ok true)');
