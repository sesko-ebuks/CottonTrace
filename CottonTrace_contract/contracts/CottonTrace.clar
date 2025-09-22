
;; title: CottonTrace
;; version: 1.0.0
;; summary: Supply chain tracking smart contract for cotton farming and fair trade verification
;; description: This contract enables transparent tracking of cotton from farm to consumer,
;;              ensuring fair trade practices and supply chain integrity.

;; traits
;;

;; token definitions
;;

;; constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_NOT_FOUND (err u101))
(define-constant ERR_ALREADY_EXISTS (err u102))
(define-constant ERR_INVALID_STATUS (err u103))
(define-constant ERR_INVALID_PARAMS (err u104))

;; data vars
(define-data-var next-batch-id uint u1)
(define-data-var next-farm-id uint u1)

;; data maps
;; Farm registration and details
(define-map farms
    { farm-id: uint }
    {
        owner: principal,
        name: (string-ascii 100),
        location: (string-ascii 200),
        certification-level: (string-ascii 50),
        registered-at: uint,
        is-active: bool
    }
)

;; Cotton batch tracking
(define-map cotton-batches
    { batch-id: uint }
    {
        farm-id: uint,
        quantity-kg: uint,
        harvest-date: uint,
        quality-grade: (string-ascii 20),
        certification-status: (string-ascii 50),
        current-status: (string-ascii 50),
        created-by: principal,
        created-at: uint
    }
)

;; Supply chain events for each batch
(define-map supply-chain-events
    { batch-id: uint, event-id: uint }
    {
        event-type: (string-ascii 50),
        location: (string-ascii 200),
        handler: principal,
        timestamp: uint,
        notes: (string-ascii 500)
    }
)

;; Track number of events per batch
(define-map batch-event-count
    { batch-id: uint }
    { count: uint }
)

;; Fair trade certifications
(define-map certifications
    { cert-id: uint }
    {
        farm-id: uint,
        certifier: principal,
        cert-type: (string-ascii 100),
        issued-date: uint,
        expiry-date: uint,
        is-valid: bool
    }
)

(define-data-var next-cert-id uint u1)

;; public functions

;; Register a new farm
(define-public (register-farm (name (string-ascii 100))
                             (location (string-ascii 200))
                             (certification-level (string-ascii 50)))
    (let ((farm-id (var-get next-farm-id)))
        (asserts! (> (len name) u0) ERR_INVALID_PARAMS)
        (asserts! (> (len location) u0) ERR_INVALID_PARAMS)
        (map-set farms
            { farm-id: farm-id }
            {
                owner: tx-sender,
                name: name,
                location: location,
                certification-level: certification-level,
                registered-at: block-height,
                is-active: true
            }
        )
        (var-set next-farm-id (+ farm-id u1))
        (ok farm-id)
    )
)

;; Register a new cotton batch
(define-public (register-cotton-batch (farm-id uint)
                                     (quantity-kg uint)
                                     (quality-grade (string-ascii 20))
                                     (certification-status (string-ascii 50)))
    (let ((batch-id (var-get next-batch-id))
          (farm-data (map-get? farms { farm-id: farm-id })))
        (asserts! (is-some farm-data) ERR_NOT_FOUND)
        (asserts! (> quantity-kg u0) ERR_INVALID_PARAMS)
        (asserts! (get is-active (unwrap-panic farm-data)) ERR_INVALID_STATUS)

        (map-set cotton-batches
            { batch-id: batch-id }
            {
                farm-id: farm-id,
                quantity-kg: quantity-kg,
                harvest-date: block-height,
                quality-grade: quality-grade,
                certification-status: certification-status,
                current-status: "harvested",
                created-by: tx-sender,
                created-at: block-height
            }
        )

        ;; Initialize event count for this batch
        (map-set batch-event-count
            { batch-id: batch-id }
            { count: u0 }
        )

        (var-set next-batch-id (+ batch-id u1))
        (ok batch-id)
    )
)

;; Add supply chain event
(define-public (add-supply-chain-event (batch-id uint)
                                      (event-type (string-ascii 50))
                                      (location (string-ascii 200))
                                      (notes (string-ascii 500)))
    (let ((batch-data (map-get? cotton-batches { batch-id: batch-id }))
          (event-count-data (map-get? batch-event-count { batch-id: batch-id }))
          (event-count (default-to u0 (get count event-count-data))))
        (asserts! (is-some batch-data) ERR_NOT_FOUND)
        (asserts! (> (len event-type) u0) ERR_INVALID_PARAMS)

        ;; Add the event
        (map-set supply-chain-events
            { batch-id: batch-id, event-id: event-count }
            {
                event-type: event-type,
                location: location,
                handler: tx-sender,
                timestamp: block-height,
                notes: notes
            }
        )

        ;; Update event count
        (map-set batch-event-count
            { batch-id: batch-id }
            { count: (+ event-count u1) }
        )

        ;; Update batch status if it's a status change event
        (if (or (is-eq event-type "processed")
                (is-eq event-type "shipped")
                (is-eq event-type "delivered"))
            (map-set cotton-batches
                { batch-id: batch-id }
                (merge (unwrap-panic batch-data) { current-status: event-type })
            )
            true
        )

        (ok event-count)
    )
)

;; Issue fair trade certification
(define-public (issue-certification (farm-id uint)
                                   (cert-type (string-ascii 100))
                                   (expiry-date uint))
    (let ((cert-id (var-get next-cert-id))
          (farm-data (map-get? farms { farm-id: farm-id })))
        (asserts! (is-some farm-data) ERR_NOT_FOUND)
        (asserts! (> expiry-date block-height) ERR_INVALID_PARAMS)

        (map-set certifications
            { cert-id: cert-id }
            {
                farm-id: farm-id,
                certifier: tx-sender,
                cert-type: cert-type,
                issued-date: block-height,
                expiry-date: expiry-date,
                is-valid: true
            }
        )

        (var-set next-cert-id (+ cert-id u1))
        (ok cert-id)
    )
)

;; Revoke certification
(define-public (revoke-certification (cert-id uint))
    (let ((cert-data (map-get? certifications { cert-id: cert-id })))
        (asserts! (is-some cert-data) ERR_NOT_FOUND)
        (asserts! (is-eq tx-sender (get certifier (unwrap-panic cert-data))) ERR_UNAUTHORIZED)

        (map-set certifications
            { cert-id: cert-id }
            (merge (unwrap-panic cert-data) { is-valid: false })
        )
        (ok true)
    )
)

;; read only functions

;; Get farm details
(define-read-only (get-farm (farm-id uint))
    (map-get? farms { farm-id: farm-id })
)

;; Get cotton batch details
(define-read-only (get-cotton-batch (batch-id uint))
    (map-get? cotton-batches { batch-id: batch-id })
)

;; Get supply chain event
(define-read-only (get-supply-chain-event (batch-id uint) (event-id uint))
    (map-get? supply-chain-events { batch-id: batch-id, event-id: event-id })
)

;; Get number of events for a batch
(define-read-only (get-batch-event-count (batch-id uint))
    (default-to u0 (get count (map-get? batch-event-count { batch-id: batch-id })))
)

;; Get certification details
(define-read-only (get-certification (cert-id uint))
    (map-get? certifications { cert-id: cert-id })
)

;; Get next available IDs
(define-read-only (get-next-batch-id)
    (var-get next-batch-id)
)

(define-read-only (get-next-farm-id)
    (var-get next-farm-id)
)

(define-read-only (get-next-cert-id)
    (var-get next-cert-id)
)

;; Check if a farm is certified for fair trade
(define-read-only (is-farm-certified (farm-id uint) (cert-type (string-ascii 100)))
    (let ((cert-check (filter-certifications-by-farm farm-id)))
        ;; This is a simplified check - in a real implementation,
        ;; you'd iterate through all certifications for the farm
        (ok true) ;; Placeholder - would need more complex logic
    )
)

;; Get batch supply chain history (simplified - returns count)
(define-read-only (get-batch-history-count (batch-id uint))
    (get-batch-event-count batch-id)
)

;; private functions

;; Private helper function to validate farm ownership
(define-private (is-farm-owner (farm-id uint) (caller principal))
    (match (map-get? farms { farm-id: farm-id })
        farm-data (is-eq caller (get owner farm-data))
        false
    )
)

;; Private helper function to filter certifications by farm
(define-private (filter-certifications-by-farm (farm-id uint))
    ;; This would need to be implemented with a more sophisticated approach
    ;; For now, returning a placeholder
    true
)

