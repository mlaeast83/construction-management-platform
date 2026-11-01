# Phase 1 Product Scope

## Product
An Arabic-first multi-tenant construction management SaaS platform. The first release focuses on commercial and contractual control rather than a full ERP.

## Core workflow
Organization → Project → Contract → BOQ → Measurement record → Technical/quantity review → Approved cumulative quantity → Payment certificate → Deductions → Approval → Issuance → Payment tracking.

## MVP modules
1. Organizations, profiles, memberships and role foundation.
2. Projects and counterparties.
3. Contracts and amendments.
4. BOQ items and units.
5. Measurement records with evidence and status.
6. Interim and final payment certificates.
7. Typed deductions with contractual basis.
8. Review and approval workflow.
9. Audit history and document attachments.
10. Arabic/English exports and management summaries.

## Explicitly deferred
- Full accounting ledger and tax filing.
- Payroll and HR.
- Procurement and warehouse operations.
- Advanced scheduling and earned-value management.
- Native Android/iOS apps.
- Autonomous AI decisions or automatic approvals.

## Calculation rules
- BOQ value = contract quantity × unit rate.
- Current approved quantity = current approved cumulative quantity − previous approved cumulative quantity.
- Negative current quantity is invalid unless entered through a documented correction workflow.
- Exceeding contract quantity requires an approved variation/change order.
- Recorded, measured, checked, approved, certified and paid quantities/values remain distinct.
- Deductions are separately classified and linked to contractual basis, period and calculation method.
- AI may extract, classify, explain and flag; deterministic tested code calculates final monetary values.

## Quality gates
- Multi-tenant isolation and role permission tests.
- Calculation unit/integration tests.
- Audit trail tests for state transitions.
- Arabic RTL and English UI checks.
- Export reconciliation.
- Backup/restore drill and security review before real customer data.

## Discovery still required
First launch customer segment and country; local contract and measurement conventions; approval roles; currency, rounding and tax rules; customer interviews and usability testing.
