;; game-items-contract
;; handles in-game item purchases, ownership, trading and rentals

;; Error codes
(define-constant ERR_INSUFFICIENT_BALANCE (err u100))
(define-constant ERR_ITEM_NOT_FOUND (err u101)) 
(define-constant ERR_UNAUTHORIZED (err u102))
(define-constant ERR_ITEM_NOT_FOR_SALE (err u103))
(define-constant ERR_ITEM_NOT_FOR_TRADE (err u104))
(define-constant ERR_INVALID_TRADE (err u105))
(define-constant ERR_ITEM_RENTED (err u106))
(define-constant ERR_RENTAL_EXPIRED (err u107))

;; Data maps
(define-map items 
    uint ;; item-id
    {
        name: (string-ascii 50),
        price: uint,
        for-sale: bool,
        for-trade: bool,
        owner: principal,
        rented-to: (optional principal),
        rental-end-height: (optional uint)
    }
)

(define-map user-items 
    { user: principal, item-id: uint } 
    { quantity: uint }
)

(define-map trade-offers
    uint ;; offer-id  
    {
        offered-item: uint,
        requested-item: uint,
        from: principal,
        to: principal,
        expires-at: uint
    }
)

;; Initialize contract
(define-data-var next-item-id uint u1)
(define-data-var next-trade-id uint u1)

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

(define-read-only (get-trade-offer (offer-id uint))
    (map-get? trade-offers offer-id)
)

;; Public functions - Original functionality
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
                for-trade: false,
                owner: tx-sender,
                rented-to: none,
                rental-end-height: none
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
        (asserts! (is-none (get rented-to item)) ERR_ITEM_RENTED)
        
        ;; Transfer STX from buyer to seller
        (try! (stx-transfer? (get price item) buyer (get owner item)))
        
        ;; Update item ownership
        (map-set items item-id
            (merge item {
                for-sale: false,
                owner: buyer,
                rented-to: none,
                rental-end-height: none
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

;; New Trading Functions
(define-public (create-trade-offer (offered-item-id uint) (requested-item-id uint) (to principal) (expires-in uint))
    (let (
        (offer-id (var-get next-trade-id))
        (offered-item (unwrap! (map-get? items offered-item-id) ERR_ITEM_NOT_FOUND))
        (expire-height (+ block-height expires-in))
    )
    (begin
        (asserts! (is-eq tx-sender (get owner offered-item)) ERR_UNAUTHORIZED)
        (asserts! (is-none (get rented-to offered-item)) ERR_ITEM_RENTED)
        
        (map-set trade-offers
            offer-id
            {
                offered-item: offered-item-id,
                requested-item: requested-item-id,
                from: tx-sender,
                to: to,
                expires-at: expire-height
            }
        )
        (var-set next-trade-id (+ offer-id u1))
        (ok offer-id)
    ))
)

(define-public (accept-trade (offer-id uint))
    (let (
        (offer (unwrap! (map-get? trade-offers offer-id) ERR_ITEM_NOT_FOUND))
        (offered-item (unwrap! (map-get? items (get offered-item offer)) ERR_ITEM_NOT_FOUND))
        (requested-item (unwrap! (map-get? items (get requested-item offer)) ERR_ITEM_NOT_FOUND))
    )
    (begin
        (asserts! (<= block-height (get expires-at offer)) ERR_INVALID_TRADE)
        (asserts! (is-eq tx-sender (get to offer)) ERR_UNAUTHORIZED)
        (asserts! (is-eq tx-sender (get owner requested-item)) ERR_UNAUTHORIZED)
        
        ;; Swap ownership
        (map-set items (get offered-item offer)
            (merge offered-item {
                owner: tx-sender,
                for-sale: false,
                for-trade: false
            })
        )
        
        (map-set items (get requested-item offer)
            (merge requested-item {
                owner: (get from offer),
                for-sale: false,
                for-trade: false
            })
        )
        
        ;; Delete trade offer
        (map-delete trade-offers offer-id)
        (ok true)
    ))
)

;; New Rental Functions
(define-public (rent-item (item-id uint) (renter principal) (duration uint))
    (let (
        (item (unwrap! (map-get? items item-id) ERR_ITEM_NOT_FOUND))
    )
    (begin
        (asserts! (is-eq tx-sender (get owner item)) ERR_UNAUTHORIZED)
        (asserts! (is-none (get rented-to item)) ERR_ITEM_RENTED)
        
        (map-set items item-id
            (merge item {
                rented-to: (some renter),
                rental-end-height: (some (+ block-height duration)),
                for-sale: false,
                for-trade: false
            })
        )
        (ok true)
    ))
)

(define-public (end-rental (item-id uint))
    (let (
        (item (unwrap! (map-get? items item-id) ERR_ITEM_NOT_FOUND))
    )
    (begin
        (asserts! (is-some (get rented-to item)) ERR_RENTAL_EXPIRED)
        (asserts! (>= block-height (unwrap! (get rental-end-height item) ERR_RENTAL_EXPIRED)) ERR_RENTAL_EXPIRED)
        
        (map-set items item-id
            (merge item {
                rented-to: none,
                rental-end-height: none
            })
        )
        (ok true)
    ))
)
