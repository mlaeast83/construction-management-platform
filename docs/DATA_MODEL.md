# Core Data Model

## Principles
- Every tenant-owned business record includes organization_id.
- UUID primary keys and timestamptz audit timestamps.
- Monetary values use numeric, never floating point.
- Units and currencies are explicit; missing values are not inferred.
- Audit-sensitive records are not silently overwritten after approval.
- RLS is enabled on every exposed public table.
- Authorization is enforced by PostgreSQL as well as the application.

## Initial entities
- organizations: tenant/company account.
- profiles: user profile linked to auth.users.
- organization_members: membership and role per organization.
- projects: construction projects.
- counterparties: clients, contractors, subcontractors, consultants and suppliers.
- contracts: project agreements and commercial terms.
- boq_items: priced contract items, units and quantities.

## Next entities (planned, not yet created)
- contract_amendments / variations
- measurement_records
- payment_certificates and payment_certificate_items
- deductions
- approvals
- documents / attachments
- audit_logs
- payments

## Authorization foundation
The initial migration includes a private helper to check active membership. Tenant-owned records use it in RLS policies. Browser clients cannot create organizations or self-assign memberships in the initial schema. A trusted onboarding/invitation workflow must be designed and security-reviewed before enabling those operations.

## Important distinction
A measurement record is evidence of work measured/recorded. It is not automatically an approved quantity, a payment certificate, or a payment. Those are separate workflow entities and states.
