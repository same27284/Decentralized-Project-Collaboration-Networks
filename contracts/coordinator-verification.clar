;; Project Coordinator Verification Contract
;; Manages verification and reputation of project coordinators

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_ALREADY_VERIFIED (err u101))
(define-constant ERR_NOT_FOUND (err u102))
(define-constant ERR_INSUFFICIENT_REPUTATION (err u103))

;; Data structures
(define-map coordinators
  { coordinator: principal }
  {
    verified: bool,
    reputation-score: uint,
    projects-completed: uint,
    verification-date: uint
  }
)

(define-map verification-requests
  { coordinator: principal }
  {
    requested-at: uint,
    status: (string-ascii 20)
  }
)

;; Public functions
(define-public (request-verification)
  (let ((coordinator tx-sender))
    (map-set verification-requests
      { coordinator: coordinator }
      {
        requested-at: block-height,
        status: "pending"
      }
    )
    (ok true)
  )
)

(define-public (verify-coordinator (coordinator principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (map-set coordinators
      { coordinator: coordinator }
      {
        verified: true,
        reputation-score: u50,
        projects-completed: u0,
        verification-date: block-height
      }
    )
    (map-set verification-requests
      { coordinator: coordinator }
      {
        requested-at: block-height,
        status: "approved"
      }
    )
    (ok true)
  )
)

(define-public (update-reputation (coordinator principal) (new-score uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (match (map-get? coordinators { coordinator: coordinator })
      coordinator-data
      (begin
        (map-set coordinators
          { coordinator: coordinator }
          (merge coordinator-data { reputation-score: new-score })
        )
        (ok true)
      )
      ERR_NOT_FOUND
    )
  )
)

;; Read-only functions
(define-read-only (get-coordinator-info (coordinator principal))
  (map-get? coordinators { coordinator: coordinator })
)

(define-read-only (is-verified (coordinator principal))
  (match (map-get? coordinators { coordinator: coordinator })
    coordinator-data (get verified coordinator-data)
    false
  )
)

(define-read-only (get-reputation (coordinator principal))
  (match (map-get? coordinators { coordinator: coordinator })
    coordinator-data (get reputation-score coordinator-data)
    u0
  )
)
