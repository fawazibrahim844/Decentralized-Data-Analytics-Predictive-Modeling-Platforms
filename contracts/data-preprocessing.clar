;; Data Preprocessing Contract
;; Manages data preprocessing operations

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u300))
(define-constant ERR_JOB_NOT_FOUND (err u301))
(define-constant ERR_INVALID_STATUS (err u302))

;; Preprocessing job structure
(define-map preprocessing-jobs
  { job-id: uint }
  {
    requester: principal,
    processor: (optional principal),
    data-source-hash: (string-ascii 64),
    preprocessing-steps: (string-ascii 500),
    status: (string-ascii 20),
    created-at: uint,
    completed-at: (optional uint),
    output-hash: (optional (string-ascii 64)),
    quality-score: uint
  }
)

(define-data-var next-job-id uint u1)

;; Create preprocessing job
(define-public (create-preprocessing-job
  (data-source-hash (string-ascii 64))
  (preprocessing-steps (string-ascii 500))
)
  (let ((job-id (var-get next-job-id)))
    (map-set preprocessing-jobs
      { job-id: job-id }
      {
        requester: tx-sender,
        processor: none,
        data-source-hash: data-source-hash,
        preprocessing-steps: preprocessing-steps,
        status: "pending",
        created-at: block-height,
        completed-at: none,
        output-hash: none,
        quality-score: u0
      }
    )
    (var-set next-job-id (+ job-id u1))
    (ok job-id)
  )
)

;; Assign processor to job
(define-public (assign-processor (job-id uint) (processor principal))
  (match (map-get? preprocessing-jobs { job-id: job-id })
    job-data
      (begin
        (asserts! (is-eq (get requester job-data) tx-sender) ERR_UNAUTHORIZED)
        (asserts! (is-eq (get status job-data) "pending") ERR_INVALID_STATUS)
        (map-set preprocessing-jobs
          { job-id: job-id }
          (merge job-data {
            processor: (some processor),
            status: "assigned"
          })
        )
        (ok true)
      )
    ERR_JOB_NOT_FOUND
  )
)

;; Complete preprocessing job
(define-public (complete-job (job-id uint) (output-hash (string-ascii 64)) (quality-score uint))
  (match (map-get? preprocessing-jobs { job-id: job-id })
    job-data
      (begin
        (asserts! (is-eq (some tx-sender) (get processor job-data)) ERR_UNAUTHORIZED)
        (asserts! (is-eq (get status job-data) "assigned") ERR_INVALID_STATUS)
        (map-set preprocessing-jobs
          { job-id: job-id }
          (merge job-data {
            status: "completed",
            completed-at: (some block-height),
            output-hash: (some output-hash),
            quality-score: quality-score
          })
        )
        (ok true)
      )
    ERR_JOB_NOT_FOUND
  )
)

;; Get job details
(define-read-only (get-job (job-id uint))
  (map-get? preprocessing-jobs { job-id: job-id })
)

;; Get job status
(define-read-only (get-job-status (job-id uint))
  (match (map-get? preprocessing-jobs { job-id: job-id })
    job-data (ok (get status job-data))
    ERR_JOB_NOT_FOUND
  )
)
