;; Data Scientist Verification Contract
;; Validates data science professionals on the platform

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_ALREADY_VERIFIED (err u101))
(define-constant ERR_NOT_FOUND (err u102))
(define-constant ERR_INVALID_CREDENTIALS (err u103))

;; Data scientist profile structure
(define-map data-scientists
  { scientist-id: principal }
  {
    name: (string-ascii 100),
    credentials: (string-ascii 200),
    verification-status: bool,
    verification-date: uint,
    reputation-score: uint
  }
)

;; Verification requests
(define-map verification-requests
  { request-id: uint }
  {
    scientist-id: principal,
    credentials: (string-ascii 200),
    status: (string-ascii 20),
    submitted-at: uint
  }
)

(define-data-var next-request-id uint u1)

;; Submit verification request
(define-public (submit-verification-request (name (string-ascii 100)) (credentials (string-ascii 200)))
  (let ((request-id (var-get next-request-id)))
    (map-set verification-requests
      { request-id: request-id }
      {
        scientist-id: tx-sender,
        credentials: credentials,
        status: "pending",
        submitted-at: block-height
      }
    )
    (var-set next-request-id (+ request-id u1))
    (ok request-id)
  )
)

;; Verify data scientist (admin only)
(define-public (verify-scientist (scientist-id principal) (name (string-ascii 100)) (credentials (string-ascii 200)))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (is-none (map-get? data-scientists { scientist-id: scientist-id })) ERR_ALREADY_VERIFIED)
    (map-set data-scientists
      { scientist-id: scientist-id }
      {
        name: name,
        credentials: credentials,
        verification-status: true,
        verification-date: block-height,
        reputation-score: u100
      }
    )
    (ok true)
  )
)

;; Check if scientist is verified
(define-read-only (is-verified (scientist-id principal))
  (match (map-get? data-scientists { scientist-id: scientist-id })
    scientist-data (get verification-status scientist-data)
    false
  )
)

;; Get scientist profile
(define-read-only (get-scientist-profile (scientist-id principal))
  (map-get? data-scientists { scientist-id: scientist-id })
)

;; Update reputation score
(define-public (update-reputation (scientist-id principal) (new-score uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (match (map-get? data-scientists { scientist-id: scientist-id })
      scientist-data
        (begin
          (map-set data-scientists
            { scientist-id: scientist-id }
            (merge scientist-data { reputation-score: new-score })
          )
          (ok true)
        )
      ERR_NOT_FOUND
    )
  )
)
