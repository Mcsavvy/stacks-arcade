import {
    Clarinet,
    Tx,
    Chain,
    Account,
    types,
    assertEquals,
  } from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
  
  Clarinet.test({
    name: "StacksArcade: Test suite for game items marketplace",
    async fn(chain: Chain, accounts: Map<string, Account>) {
      const deployer = accounts.get('deployer')!;
      const user1 = accounts.get('wallet_1')!;
      const user2 = accounts.get('wallet_2')!;
  
      // Test 1: List a new item
      const listItemBlock = chain.mineBlock([
        Tx.contractCall(
          'stacksarcade',
          'list-item',
          [
            types.ascii('Legendary Sword'),
            types.uint(100_000_000) // 100 STX
          ],
          deployer.address
        ),
      ]);
      
      // Assert item listing succeeded
      assertEquals(listItemBlock.receipts[0].result, '(ok u1)');
  
      // Test 2: Get item details
      const getItemResult = chain.callReadOnlyFn(
        'stacksarcade',
        'get-item',
        [types.uint(1)],
        deployer.address
      );
      
      // Check if the returned item has the correct properties
      assertEquals(
        getItemResult.result,
        `{name: "Legendary Sword", price: u100000000, for-sale: true, owner: ${deployer.address}}`
      );
  
      // Test 3: Purchase item
      const purchaseBlock = chain.mineBlock([
        Tx.contractCall(
          'stacksarcade',
          'purchase-item',
          [types.uint(1)],
          user1.address
        ),
      ]);
      
      assertEquals(purchaseBlock.receipts[0].result, '(ok true)');
  
      // Test 4: Verify ownership after purchase
      const getItemAfterPurchase = chain.callReadOnlyFn(
        'stacksarcade',
        'get-item',
        [types.uint(1)],
        user1.address
      );
      
      assertEquals(
        getItemAfterPurchase.result,
        `{name: "Legendary Sword", price: u100000000, for-sale: false, owner: ${user1.address}}`
      );
  
      // Test 5: Check user item quantity
      const getUserItemQuantity = chain.callReadOnlyFn(
        'stacksarcade',
        'get-user-item-quantity',
        [
          types.principal(user1.address),
          types.uint(1)
        ],
        user1.address
      );
      
      assertEquals(
        getUserItemQuantity.result,
        '{quantity: u1}'
      );
  
      // Test 6: Try to purchase non-existent item (should fail)
      const failedPurchaseBlock = chain.mineBlock([
        Tx.contractCall(
          'stacksarcade',
          'purchase-item',
          [types.uint(999)],
          user2.address
        ),
      ]);
      
      assertEquals(
        failedPurchaseBlock.receipts[0].result,
        '(err u101)' // ERR_ITEM_NOT_FOUND
      );
  
      // Test 7: Test setting item for sale status
      const toggleSaleBlock = chain.mineBlock([
        Tx.contractCall(
          'stacksarcade',
          'set-item-for-sale',
          [
            types.uint(1),
            types.bool(true)
          ],
          user1.address // Current owner
        ),
      ]);
      
      assertEquals(toggleSaleBlock.receipts[0].result, '(ok true)');
  
      // Test 8: Unauthorized set-item-for-sale attempt (should fail)
      const unauthorizedToggleBlock = chain.mineBlock([
        Tx.contractCall(
          'stacksarcade',
          'set-item-for-sale',
          [
            types.uint(1),
            types.bool(true)
          ],
          user2.address // Not the owner
        ),
      ]);
      
      assertEquals(
        unauthorizedToggleBlock.receipts[0].result,
        '(err u102)' // ERR_UNAUTHORIZED
      );
  
      // Test 9: Try to purchase item not for sale
      const purchaseNotForSaleBlock = chain.mineBlock([
        // First set item not for sale
        Tx.contractCall(
          'stacksarcade',
          'set-item-for-sale',
          [
            types.uint(1),
            types.bool(false)
          ],
          user1.address
        ),
        // Then try to purchase it
        Tx.contractCall(
          'stacksarcade',
          'purchase-item',
          [types.uint(1)],
          user2.address
        ),
      ]);
      
      assertEquals(
        purchaseNotForSaleBlock.receipts[1].result,
        '(err u103)' // ERR_ITEM_NOT_FOR_SALE
      );
  
      // Test 10: Check STX transfer after purchase
      const checkBalanceBlock = chain.mineBlock([
        Tx.contractCall(
          'stacksarcade',
          'list-item',
          [
            types.ascii('Magic Staff'),
            types.uint(50_000_000) // 50 STX
          ],
          deployer.address
        ),
        Tx.contractCall(
          'stacksarcade',
          'purchase-item',
          [types.uint(2)],
          user2.address
        ),
      ]);
  
      // Verify successful purchase
      assertEquals(checkBalanceBlock.receipts[1].result, '(ok true)');
      // Verify STX transfer events in the receipt
      assertEquals(checkBalanceBlock.receipts[1].events[0].type, 'stx_transfer_event');
    },
  });