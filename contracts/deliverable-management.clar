;; Deliverable Management Contract
;; Manages project deliverables and submissions

(define-constant ERR_UNAUTHORIZED (err u500))
(define-constant ERR_DELIVERABLE_NOT_FOUND (err u501))
(define-constant ERR_INVALID_STATUS (err u502))
(define-constant ERR_ALREADY_SUBMITTED (err u503))

;; Data structures
(define-map deliverables
  { deliverable-id: uint }
  {
    project-id: uint,
    title: (string-ascii 100),
    description: (string-ascii 500),
    assignee: principal,
    due-date: uint,
    status: (string-ascii 20),
    submission-hash: (optional (buff 32)),
    submitted-at: (optional uint),
    reviewed-by: (optional principal),
    review-status: (string-ascii 20),
    created-by: principal,
    created-at: uint
  }
)

(define-map project-deliverables
  { project-id: uint }
  { deliverable-count: uint }
)

(define-data-var next-deliverable-id uint u1)

;; Public functions
(define-public (create-deliverable
  (project-id uint)
  (title (string-ascii 100))
  (description (string-ascii 500))
  (assignee principal)
  (due-date uint)
)
  (let ((deliverable-id (var-get next-deliverable-id)))
    (map-set deliverables
      { deliverable-id: deliverable-id }
      {
        project-id: project-id,
        title: title,
        description: description,
        assignee: assignee,
        due-date: due-date,
        status: "assigned",
        submission-hash: none,
        submitted-at: none,
        reviewed-by: none,
        review-status: "pending",
        created-by: tx-sender,
        created-at: block-height
      }
    )

    ;; Update deliverable count
    (match (map-get? project-deliverables { project-id: project-id })
      project-data
      (map-set project-deliverables
        { project-id: project-id }
        { deliverable-count: (+ (get deliverable-count project-data) u1) }
      )
      (map-set project-deliverables
        { project-id: project-id }
        { deliverable-count: u1 }
      )
    )

    (var-set next-deliverable-id (+ deliverable-id u1))
    (ok deliverable-id)
  )
)

(define-public (submit-deliverable (deliverable-id uint) (submission-hash (buff 32)))
  (match (map-get? deliverables { deliverable-id: deliverable-id })
    deliverable-data
    (begin
      (asserts! (is-eq (get assignee deliverable-data) tx-sender) ERR_UNAUTHORIZED)
      (asserts! (is-none (get submission-hash deliverable-data)) ERR_ALREADY_SUBMITTED)
      (map-set deliverables
        { deliverable-id: deliverable-id }
        (merge deliverable-data {
          status: "submitted",
          submission-hash: (some submission-hash),
          submitted-at: (some block-height),
          review-status: "under-review"
        })
      )
      (ok true)
    )
    ERR_DELIVERABLE_NOT_FOUND
  )
)

(define-public (review-deliverable
  (deliverable-id uint)
  (review-status (string-ascii 20))
)
  (match (map-get? deliverables { deliverable-id: deliverable-id })
    deliverable-data
    (begin
      (asserts! (is-eq (get created-by deliverable-data) tx-sender) ERR_UNAUTHORIZED)
      (map-set deliverables
        { deliverable-id: deliverable-id }
        (merge deliverable-data {
          reviewed-by: (some tx-sender),
          review-status: review-status,
          status: (if (is-eq review-status "approved") "completed" "revision-required")
        })
      )
      (ok true)
    )
    ERR_DELIVERABLE_NOT_FOUND
  )
)

;; Read-only functions
(define-read-only (get-deliverable (deliverable-id uint))
  (map-get? deliverables { deliverable-id: deliverable-id })
)

(define-read-only (get-project-deliverable-count (project-id uint))
  (match (map-get? project-deliverables { project-id: project-id })
    project-data (get deliverable-count project-data)
    u0
  )
)
