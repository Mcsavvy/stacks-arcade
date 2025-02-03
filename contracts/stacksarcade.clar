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
(define-constant ERR_INVALID_RENTAL (err u108))

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
        rental-end-height: (optional uint),
        rental-price: (optional uint)
    }
)

[... rest of original contract code ...]

;; Enhanced Rental Functions
(define-public (set-rental-price (item-id uint) (price uint))
    (let (
        (item (unwrap! (map-get? items item-id) ERR_ITEM_NOT_FOUND))
    )
    (begin
        (asserts! (is-eq tx-sender (get owner item)) ERR_UNAUTHORIZED)
        (asserts! (is-none (get rented-to item)) ERR_ITEM_RENTED)
        
        (map-set items item-id
            (merge item {
                rental-price: (some price)
            })
        )
        (ok true)
    ))
)

(define-public (rent-item (item-id uint) (renter principal) (duration uint))
    (let (
        (item (unwrap! (map-get? items item-id) ERR_ITEM_NOT_FOUND))
        (rental-cost (unwrap! (get rental-price item) ERR_INVALID_RENTAL))
    )
    (begin
        (asserts! (is-eq tx-sender (get owner item)) ERR_UNAUTHORIZED)
        (asserts! (is-none (get rented-to item)) ERR_ITEM_RENTED)
        (asserts! (> duration u0) ERR_INVALID_RENTAL)
        
        ;; Transfer rental payment
        (try! (stx-transfer? rental-cost renter (get owner item)))

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
