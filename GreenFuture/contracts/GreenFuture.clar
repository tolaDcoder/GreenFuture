;; GreenFuture - Environmental Conservation Crowdfunding Platform on Stacks
;; A smart contract for managing environmental and sustainability projects with community funding

(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-UNAUTHORIZED (err u1))
(define-constant ERR-INVALID-AMOUNT (err u2))
(define-constant ERR-PROJECT-NOT-FOUND (err u3))
(define-constant ERR-PROJECT-ACTIVE (err u4))
(define-constant ERR-PROJECT-INACTIVE (err u5))
(define-constant ERR-ALREADY-FUNDED (err u6))
(define-constant ERR-GOAL-NOT-MET (err u7))
(define-constant ERR-INSUFFICIENT-BALANCE (err u8))

;; Project status constants
(define-constant STATUS-ACTIVE u1)
(define-constant STATUS-COMPLETED u2)
(define-constant STATUS-CANCELLED u3)

;; Data structures
(define-map projects
  { project-id: uint }
  {
    title: (string-ascii 100),
    description: (string-ascii 500),
    creator: principal,
    target-amount: uint,
    current-amount: uint,
    deadline: uint,
    status: uint,
    created-at: uint
  }
)

(define-map contributions
  { project-id: uint, contributor: principal }
  { amount: uint }
)

(define-map user-contributions
  { user: principal }
  { total-contributed: uint }
)

(define-data-var next-project-id uint u1)
(define-data-var total-platform-raised uint u0)

;; Create a new environmental project
(define-public (create-project (title (string-ascii 100)) (description (string-ascii 500)) (target-amount uint) (deadline uint))
  (let ((project-id (var-get next-project-id)))
    (asserts! (> target-amount u0) ERR-INVALID-AMOUNT)
    (asserts! (> deadline u0) ERR-INVALID-AMOUNT)
    
    (map-set projects
      { project-id: project-id }
      {
        title: title,
        description: description,
        creator: tx-sender,
        target-amount: target-amount,
        current-amount: u0,
        deadline: deadline,
        status: STATUS-ACTIVE,
        created-at: u0
      }
    )
    
    (var-set next-project-id (+ project-id u1))
    (ok project-id)
  )
)

;; Contribute STX to a project
(define-public (contribute-to-project (project-id uint) (amount uint))
  (let (
    (project (unwrap! (map-get? projects { project-id: project-id }) ERR-PROJECT-NOT-FOUND))
    (existing-contrib (map-get? contributions { project-id: project-id, contributor: tx-sender }))
    (current-contribution (if (is-some existing-contrib) (get amount (unwrap-panic existing-contrib)) u0))
  )
    (asserts! (> amount u0) ERR-INVALID-AMOUNT)
    (asserts! (is-eq (get status project) STATUS-ACTIVE) ERR-PROJECT-INACTIVE)
    
    ;; Transfer STX from contributor to contract
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    
    ;; Update project amount
    (map-set projects
      { project-id: project-id }
      (merge project { current-amount: (+ (get current-amount project) amount) })
    )
    
    ;; Record contribution
    (map-set contributions
      { project-id: project-id, contributor: tx-sender }
      { amount: (+ current-contribution amount) }
    )
    
    ;; Update user total contributions
    (let (
      (existing-user-contrib (map-get? user-contributions { user: tx-sender }))
      (user-total (if (is-some existing-user-contrib) (get total-contributed (unwrap-panic existing-user-contrib)) u0))
    )
      (map-set user-contributions
        { user: tx-sender }
        { total-contributed: (+ user-total amount) }
      )
    )
    
    ;; Update platform total
    (var-set total-platform-raised (+ (var-get total-platform-raised) amount))
    
    (ok true)
  )
)

;; Get project details
(define-read-only (get-project (project-id uint))
  (map-get? projects { project-id: project-id })
)

;; Get user's contribution to a specific project
(define-read-only (get-user-contribution (project-id uint) (user principal))
  (map-get? contributions { project-id: project-id, contributor: user })
)

;; Get total contributions by a user
(define-read-only (get-user-total-contributions (user principal))
  (map-get? user-contributions { user: user })
)

;; Get platform statistics
(define-read-only (get-platform-stats)
  {
    total-projects: (var-get next-project-id),
    total-raised: (var-get total-platform-raised)
  }
)

;; Check if project goal is met
(define-read-only (is-goal-met (project-id uint))
  (let ((project (unwrap! (map-get? projects { project-id: project-id }) ERR-PROJECT-NOT-FOUND)))
    (ok (>= (get current-amount project) (get target-amount project)))
  )
)

;; Cancel a project (only creator or contract owner)
(define-public (cancel-project (project-id uint))
  (let ((project (unwrap! (map-get? projects { project-id: project-id }) ERR-PROJECT-NOT-FOUND)))
    (asserts! (or (is-eq tx-sender (get creator project)) (is-eq tx-sender CONTRACT-OWNER)) ERR-UNAUTHORIZED)
    (asserts! (is-eq (get status project) STATUS-ACTIVE) ERR-PROJECT-ACTIVE)
    
    (map-set projects
      { project-id: project-id }
      (merge project { status: STATUS-CANCELLED })
    )
    
    (ok true)
  )
)

;; Complete a project (only creator)
(define-public (complete-project (project-id uint))
  (let ((project (unwrap! (map-get? projects { project-id: project-id }) ERR-PROJECT-NOT-FOUND)))
    (asserts! (is-eq tx-sender (get creator project)) ERR-UNAUTHORIZED)
    (asserts! (is-eq (get status project) STATUS-ACTIVE) ERR-PROJECT-ACTIVE)
    
    (map-set projects
      { project-id: project-id }
      (merge project { status: STATUS-COMPLETED })
    )
    
    (ok true)
  )
)

;; Withdraw funds to project creator (only if goal met and project completed)
(define-public (withdraw-funds (project-id uint))
  (let ((project (unwrap! (map-get? projects { project-id: project-id }) ERR-PROJECT-NOT-FOUND)))
    (asserts! (is-eq tx-sender (get creator project)) ERR-UNAUTHORIZED)
    (asserts! (is-eq (get status project) STATUS-COMPLETED) ERR-PROJECT-INACTIVE)
    (asserts! (>= (get current-amount project) (get target-amount project)) ERR-GOAL-NOT-MET)
    
    (try! (as-contract (stx-transfer? (get current-amount project) (as-contract tx-sender) tx-sender)))
    
    (map-set projects
      { project-id: project-id }
      (merge project { current-amount: u0 })
    )
    
    (ok true)
  )
)