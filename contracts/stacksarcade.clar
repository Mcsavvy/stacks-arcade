;; game-items-contract
;; handles in-game item purchases and ownership

;; Error codes
(define-constant ERR_INSUFFICIENT_BALANCE (err u100))
(define-constant ERR_ITEM_NOT_FOUND (err u101))
(define-constant ERR_UNAUTHORIZED (err u102))
(define-constant ERR_ITEM_NOT_FOR_SALE (err u103))

;; Data maps
(define-map items 
    uint ;; item-id
    {
        name: (string-ascii 50),
        price: uint,
        for-sale: bool,
        owner: principal
    }
)

(define-map user-items 
    { user: principal, item-id: uint } 
    { quantity: uint }
)

;; Initialize contract
(define-data-var next-item-id uint u1)

;; Read-only functions
(define-read-only (get-item (item-id uint))
    (map-get? items item-id)
)

(define-read-only (get-user-item-quantity (user principal) (item-id uint))
    (default-to 
        { quantity: u0 }
        (map-get? user-items { user: user, item-id: item-id })
    )
)

;; Public functions
(define-public (list-item (name (string-ascii 50)) (price uint))
    (let (
        (item-id (var-get next-item-id))
    )
    (begin
        (map-set items
            item-id
            {
                name: name,
                price: price,
                for-sale: true,
                owner: tx-sender
            }
        )
        (var-set next-item-id (+ item-id u1))
        (ok item-id)
    ))
)

(define-public (purchase-item (item-id uint))
    (let (
        (item (unwrap! (map-get? items item-id) ERR_ITEM_NOT_FOUND))
        (buyer tx-sender)
    )
    (begin
        (asserts! (get for-sale item) ERR_ITEM_NOT_FOR_SALE)
        
        ;; Transfer STX from buyer to seller
        (try! (stx-transfer? (get price item) buyer (get owner item)))
        
        ;; Update item ownership
        (map-set items item-id
            (merge item {
                for-sale: false,
                owner: buyer
            })
        )
        
        ;; Update user's item quantity
        (map-set user-items 
            { user: buyer, item-id: item-id }
            { quantity: (+ 
                (get quantity (get-user-item-quantity buyer item-id))
                u1
            )}
        )
        
        (ok true)
    ))
)

(define-public (set-item-for-sale (item-id uint) (sale-status bool))
    (let (
        (item (unwrap! (map-get? items item-id) ERR_ITEM_NOT_FOUND))
    )
    (begin
        (asserts! (is-eq tx-sender (get owner item)) ERR_UNAUTHORIZED)
        (map-set items item-id
            (merge item {
                for-sale: sale-status
            })
        )
        (ok true)
    ))
)