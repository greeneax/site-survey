# HTML → Normalized Schema Change Guide (AI-executable)

Purpose: Precisely update `site-survey_fixed_v5.html` to use the normalized Supabase schema.

## checklist (must complete all)
- Replace all legacy survey_data JSON writes with normalized column/table writes.
- Expand fetch/hydration to join child tables (contacts, team, AV, rooms, etc.).
- Update FIELD_TO_COLUMN and two-way mappers to use new columns/tables.
- Implement normalized upserts/deletes per table with stable ids and position.
- Adjust Start New Survey create/duplicate checks to target new schema.
- Update realtime subscriptions to per-table channels filtered by survey_id.
- Switch delete/restore to RPCs for soft-delete cascade.
- Keep legacy read-only fallback for old records (hydration only).

## schema constants (add near Supabase init)
- TABLES:
  - SURVEYS='surveys'
  - CONTACTS='survey_contacts'
  - INHOUSE_AV='inhouse_av'
  - TEAM='survey_team_members'
  - ROOMS='rooms'
  - ACCESS='room_access'
  - PHOTOS='photos'
  - AGENDA='agenda_files'
  - GUIDELINES='guidelines'
  - VENUES='venues'
  - VENUE_CONTACTS='venue_contacts'  # library-level contacts
  - CLIENTS='clients'
  - CLIENT_ALIASES='client_aliases'
  - CLIENT_CONTACTS='client_contacts'  # library-level client contacts
- ENUM contactCategory: 'client' | 'venue' | 'inhouse_av' | 'event_contact'
- ENUM phoneType: 'cell' | 'office' | 'other'

## table purposes (from supabase_schema.sql)
High-level intent of each normalized table / helper structure. Use this when mapping UI data and choosing where new fields belong.

- venues: Library of venue entities (name/address/notes). Soft-deletable. Selected by a survey for seeding rooms, guidelines, contacts.
- venue_rooms: Re-usable room templates scoped to a venue (structural & infrastructure attributes) used to seed survey.rooms when a venue is chosen.
- venue_guidelines: Single (unique per venue) parsed guideline JSON (important_info, due_dates) plus raw_text for a venue; copied into survey.guidelines on seeding.
- venue_contacts: Library-level contacts for a venue (category implicit = 'venue' when cloned); cloned into survey_contacts on seeding if none exist yet.
- clients: Library of client businesses (business name/address, tax status, tags, notes). Selected by survey for seeding contacts & base client fields.
- client_aliases: Alternate spellings/brands for clients to improve typeahead/fuzzy search (not cloned; only used for search resolution).
- client_contacts: Library-level contacts for a client business; cloned into survey_contacts (category='client') on seeding if none exist yet; also source for setting primary client contact.
- surveys: Core per-survey record (identifiers, event metadata, scheduling, client & venue linkage + denormalized snapshot fields, financial/budget/tax info, top-level contact fields). Child tables reference surveys.id via survey_id.
- survey_team_members: Per-survey additional team roster (beyond freeform survey_team string) with ordered positions.
- inhouse_av: Singleton (unique per survey) toggle + company name for in-house AV provider; related AV contacts live in survey_contacts with category='inhouse_av'.
- survey_contacts: All survey-scoped contacts across categories (client, venue, inhouse_av, event_contact) including exclusion flag and ordering.
- rooms: Rooms specific to a survey (editable copy—may originate from venue_rooms). Ordered list with technical attributes.
- room_access: Time-window entries describing when each room (or named area) is accessible during load-in / show / strike phases.
- photos: Metadata rows for uploaded photos (storage_path, url, section, optional room association) used by gallery & summary; physical file stored in Supabase Storage.
- agenda_files: Uploaded agenda / schedule documents (name, mime, size, optional analysis JSON) for a survey.
- guidelines: Singleton parsed guideline JSON + raw_text for a survey (copied from venue_guidelines then user-edited / AI-processed).
- audit_log: Immutable audit trail capturing row-level inserts/updates/deletes (old/new JSON, actor, timestamp, txid) for undo & history views.
- active_clients / active_surveys / active_venues (views): Convenience filtered views exposing only non-soft-deleted rows.

Supporting structures & helpers:
- Enums contact_phone_type, contact_category: constrains phone type & contact classification.
- Triggers set_updated_at_and_version: Bumps version & timestamps; audit_after_ins_upd_del: Writes audit_log rows.
- Soft delete RPC helpers: soft_delete / restore_soft_deleted generic; domain-specific cascades (soft_delete_survey, restore_survey, soft_delete_venue, restore_venue) propagate deleted_at to children.
- Seeding RPCs: seed_survey_from_venue, seed_survey_from_client copy library data into survey scope; set_survey_primary_client_contact updates canonical client_* fields and ensures presence in survey_contacts.
- undo_change: Reconstructs prior state from audit_log (supports manual rollback tooling).

Data placement guidelines:
- Survey-scoped mutable data lives in survey_* or child tables (rooms, room_access, photos, etc.).
- Library (reusable) data lives in venue_* or client_* tables; never edited by survey flows except via explicit library management UI (future).
- Avoid adding new JSON columns; prefer first-class columns or new tables for repeated/structured arrays.
- Use guidelines.important_info/due_dates arrays (JSONB) only for semi-structured extracted items; consider future normalization if querying/filtering becomes complex.

Index/uniqueness rationale (summary):
- Uniqueness on venue_guidelines (one per venue) & guidelines (one per survey) enforces singleton semantics.
- Trigram (pg_trgm) indexes on venue_name, clients.business_name, client_aliases.alias support fast fuzzy typeahead.
- Composite unique constraints (e.g., photos(survey_id,storage_path), venue_contacts(venue_id,email)) prevent duplicates during batch upserts.

Soft delete pattern: All entity tables (except audit_log & views) have deleted_at/deleted_by; UI should filter out deleted rows (already enforced in many indexes). Restores simply null those fields.

Versioning: version column auto-incremented on UPDATE for potential optimistic concurrency or diff auditing (currently informative; not enforced client-side yet).

Undo scope: undo_change works per audit_log row (INSERT -> soft delete, UPDATE -> revert old_data, DELETE -> reinsert). Not currently exposed in UI; potential future 'History' panel.

## model keys (UI data contract)
- Every array item must have id (uuid) and position (int).
- Top-level survey has both id (uuid, DB PK) and survey_id (string, canonical key).
- Maintain r2_quote_number if provided.
- Contacts: { id, category, name, title, email, phone, phone_type, excluded, note, position }
- InHouseAV: { enabled(bool), company_name(text) } + contacts in CONTACTS with category='inhouse_av'
- Team: { id, name, role, position }
- Rooms: { id, name, type, capacity, layout, dimensions, ceiling_height, electrical, rigging, sound_patch, door_size, wifi_available, wifi_notes, hardline_available, hardline_notes, misc_notes, position }
- Room Access: { id, room_id?, room_name?, room_type?, access_date, access_start_time, access_end_time, access_notes, position }
- Photos: { id, room_id?, section?, storage_path, url, filename, mime_type, size_bytes }
- Agenda: { id, name, url, mime_type, size_bytes, uploaded_at, analysis }
- Guidelines: { important_info:[], due_dates:[], raw_text, processed_by?, processed_at? }

## FIELD_TO_COLUMN (replace/extend)
- Remove any mapping into survey_data JSON.
- Map UI simple fields to SURVEYS columns:
  - event info → event_name, status, show_* dates/times, load_in_*, setup_*, rehearsal_*, strike_*, indoor_outdoor, anticipated_attendees, charge_days, budget
  - client info → client_id (uuid), client_business, client_address, tax_status, client_name, client_email, client_cell, client_title
  - event contact → event_contact_name, event_contact_email, event_contact_phone, event_contact_title
  - venue → venue_id (uuid optional), venue_name, venue_address
  - meta → survey_date, survey_team (Completed by), r2_quote_number, survey_id
- Array/complex fields map to tables (do not include in SURVEYS):
  - client-contacts → CONTACTS where category='client' (survey-scoped)
  - venue-contacts → CONTACTS where category='venue'
  - inhouse-av → INHOUSE_AV row (enabled, company_name) + CONTACTS category='inhouse_av'
  - survey-team-members → TEAM
  - rooms → ROOMS
  - room-access → ACCESS
  - photos → PHOTOS
  - agenda-files → AGENDA
  - guidelines → GUIDELINES
  - venue library contacts (for auto-fill) -> VENUE_CONTACTS; on venue selection, clone into CONTACTS as category='venue'

## mappers (update both directions)
- mapPatchToColumns(patch):
  - Only return SURVEYS columns for simple fields (sanitize types: int, numeric, date, time).
  - Exclude arrays (contacts, team, rooms, access, photos, agenda, guidelines).
- mapRowToUIData(row, children):
  - From SURVEYS row: hydrate simple fields.
  - Merge children fetched from each table into UI state under keys listed above.
  - Fallback (read-only) to legacy JSON only when child table has no rows and legacy has data.
  - Sort arrays by position ascending; ensure default position=idx when null.

## fetch/hydration (replace existing single-table fetch)
- fetchSurvey({ survey_id? string, r2_quote_number? string }):
  - Resolve primary SURVEYS row:
    - if survey_id provided: select single where survey_id=eq
    - else if r2 provided: select single where r2_quote_number=ilike or eq (normalize to string trim)
    - On success capture survey.id (uuid) and survey.survey_id (string).
  - In parallel (by survey.uuid):
    - INHOUSE_AV: select single where survey_id=eq
    - CONTACTS: select all where survey_id=eq and deleted_at is null; split into client/venue/inhouse_av/event_contact by category; order by position nulls last, created_at
    - TEAM: select all where survey_id=eq and deleted_at is null order by position, created_at
    - ROOMS: select all where survey_id=eq and deleted_at is null order by position, created_at
    - ACCESS: select all where survey_id=eq and deleted_at is null order by access_date nulls last, access_start_time nulls last, position
    - PHOTOS: select all where survey_id=eq and deleted_at is null order by created_at
    - AGENDA: select all where survey_id=eq and deleted_at is null order by uploaded_at desc
    - GUIDELINES: select single where survey_id=eq
  - Return UI model via mapRowToUIData.

Client library search (typeahead):
- Query CLIENTS and CLIENT_ALIASES for business name matches; union or two queries combined in UI.
- Example: select id, business_name, business_address from CLIENTS where business_name ilike '%term%' limit 10.

Note: venue library is queried separately for typeahead: select id, venue_name, venue_address from VENUES where venue_name ilike '%term%' and deleted_at is null limit 10.

## create/update (split base vs children)
- saveSurveyBase(patch):
  - const cols = mapPatchToColumns(patch)
  - supabase.from(SURVEYS).update(cols).eq('id', survey.uuid).select('id').single()
- upsertInHouseAV(obj):
  - shape: { survey_id, enabled, company_name }
  - supabase.from(INHOUSE_AV).upsert(obj, { onConflict:'survey_id' }).select('id')
- upsertContacts(list, category):
  - normalize items: ensure id (uuid or generate client-side), position=index
  - set category for all
  - upsert batch to CONTACTS onConflict:'id'
  - deletions: compute toDelete = prevIds - currIds; for safety set excluded=true for removed OR hard delete by ids (pick one policy; recommended: set excluded=true)
- upsertTeam(list):
  - normalize ids and position; upsert on id
  - deletions: remove missing ids (hard delete) OR leave (no-op). Recommended: hard delete for team members.
- upsertRooms(list):
  - normalize ids/position; upsert on id; delete removed ids
- upsertRoomAccess(list):
  - normalize ids/position; upsert on id; delete removed ids
- upsertPhotos(list):
  - After successful storage upload, insert/upsert each photo row (conflict on id or on (survey_id,storage_path)); do not delete automatically
- upsertAgenda(list):
  - upsert on id; delete removed ids if UI supports removal
- upsertGuidelines(obj):
  - upsert on survey_id unique
- saveComposite(patch):
  - await saveSurveyBase(patch.simple)
  - if patch.inhouse_av then await upsertInHouseAV({ survey_id, ... })
  - if client-contacts then await upsertContacts(list,'client')
  - if venue-contacts then await upsertContacts(list,'venue')
  - if inhouse_av.contacts then await upsertContacts(list,'inhouse_av')
  - if event contact (single fields in SURVEYS) optionally mirror to CONTACTS category='event_contact' (1 row)
  - if team then await upsertTeam(list)
  - if rooms then await upsertRooms(list)
  - if access then await upsertRoomAccess(list)
  - if photos then await upsertPhotos(list)
  - if agenda then await upsertAgenda(list)
  - if guidelines then await upsertGuidelines(obj)

Client seeding (new):
- On client selection from typeahead:
  - Update survey base with client_id and copy client_business/address/tax_status into SURVEYS.
  - Call RPC seed_survey_from_client(survey_uuid, client_uuid) to clone CLIENT_CONTACTS -> CONTACTS (category='client') if none exist yet.
  - Optionally call RPC set_survey_primary_client_contact(survey_uuid, client_contact_uuid) after user selects a primary client person.
  - Refetch client contacts or update incrementally.

## start new survey (replace flow)
- On “Go”:
  - validate: survey_id string required; if R2 entered, require not duplicate.
  - duplicate checks (debounced):
    - r2 duplicate: select from SURVEYS where r2_quote_number=ilike(r2) and deleted_at is null; must be none
    - survey_id duplicate: select by survey_id eq; must be none
  - create SURVEYS row: insert { survey_id, r2_quote_number?, survey_date=today, survey_team=starter_displayName, status='Draft' }
  - create INHOUSE_AV default: upsert { survey_id:<uuid>, enabled:false, company_name:null }
  - set UI state with returned survey.id + survey_id

## venue selection seeding (new)
- On venue selection from typeahead:
  - set survey.venue_id, survey.venue_name, survey.venue_address (update base row).
  - call RPC seed_survey_from_venue(survey_uuid, venue_uuid) to clone:
    - venue_rooms -> rooms (if rooms empty)
    - venue_guidelines -> guidelines (upsert)
    - venue_contacts -> survey_contacts (category='venue') if none exist yet
  - refetch rooms/guidelines/contacts or update incrementally.

## client selection seeding (new)
- On business selection:
  - set survey.client_id; update survey.client_business, client_address, tax_status.
  - rpc('seed_survey_from_client', { _survey_id: survey.uuid, _client_id: client.id })
  - refresh client contacts list.
- On selecting a specific client person as the primary contact:
  - rpc('set_survey_primary_client_contact', { _survey_id: survey.uuid, _client_contact_id: person.id })
  - refresh survey base fields (client_name/email/phone/title).

## realtime (update subscriptions)
- Subscribe to per-table changes filtered by survey_id (uuid):
  - SURVEYS (update): refresh base fields
  - INHOUSE_AV (ins/upd): refresh inhouse_av
  - CONTACTS (ins/upd/del): refresh contacts lists
  - TEAM (ins/upd/del): refresh team list
  - ROOMS (ins/upd/del): refresh rooms
  - ACCESS (ins/upd/del): refresh room access
  - PHOTOS (ins/upd/del): refresh photos
  - AGENDA (ins/upd/del): refresh agenda
  - GUIDELINES (ins/upd): refresh guidelines
- On event: do minimal incremental update by id/operation; otherwise refetch that table.

## delete/restore (replace handlers)
- Delete Survey: call RPC soft_delete_survey(survey_uuid)
  - supabase.rpc('soft_delete_survey',{ _id: survey.uuid })
- Restore Survey: supabase.rpc('restore_survey',{ _id: survey.uuid })
- Delete Venue (if supported): soft_delete_venue(uuid), restore_venue(uuid)

## UI id management (arrays)
- When creating new array items client-side, assign a temporary uuid (crypto.randomUUID()) to id; persist via upsert; replace UI temp id with returned id if API returns different (it won’t when you provide id).
- Maintain position = index in the rendered list; update before save.

## remove legacy writes
- Remove all writes to any survey_data JSON field.
- Keep read-only fallback in mapRowToUIData if no normalized rows exist.

## queries (Supabase v2 usage patterns)
- single row read: .select('*').eq('survey_id', val).limit(1).maybeSingle()
- insert with return: .insert(obj).select('id,survey_id').single()
- upsert batch: .upsert(list, { onConflict:'id' }).select('id')
- delete batch: .delete().in('id', ids)
- rpc: .rpc('function_name', { param:value })

## summary renderer (verification only)
- Ensure sections source from normalized structures:
  - Client Contacts: CONTACTS where category='client' (active first, excluded after)
  - Venue Contacts
  - In-House AV: INHOUSE_AV + CONTACTS category='inhouse_av'
  - Survey Team: SURVEYS.survey_team + TEAM array
  - Event Contact: SURVEYS.event_contact_* fields (optional mirror contact row)
- Mailto/tel links preserved; sorting: active (excluded=false) first, then excluded=true.

## error handling/edge cases
- maybeSingle() on reads to avoid errors when zero rows.
- Treat null enabled/company_name as {enabled:false, company_name:null}.
- For arrays, default to [] if no rows.
- For dates/times, sanitize empty string to null before update.
- Numeric fields: parse to number or null; prevent NaN writes.

## minimal function list to verify exists/updated
- field mapping: FIELD_TO_COLUMN, mapPatchToColumns, mapRowToUIData
- data ops: fetchSurvey, saveSurveyBase, saveComposite, upsertInHouseAV, upsertContacts, upsertTeam, upsertRooms, upsertRoomAccess, upsertPhotos, upsertAgenda, upsertGuidelines
- new survey: createNewSurvey (insert SURVEYS + default INHOUSE_AV), duplicate checks
- realtime: subscribeSurveyChannels, handleTableEvent
- delete/restore: deleteSurveySoft, restoreSurvey

## test matrix (smoke)
- Create survey without R2; add client/venue/in-house contacts; add team; add room + access; upload photo + agenda; add guidelines; save & reload; verify all persist.
- EX/restore contacts; verify excluded flag persisted and list order in summary.
- Duplicate R2 blocked; duplicate survey_id blocked.
- Soft delete survey; verify hidden in lists; restore; verify children restored.
- Realtime: open two windows, update contacts/team/rooms; verify other window updates.

## clarifications (added)
- Canonical client business field: use survey.client_business (copied from CLIENTS.business_name). Treat survey.client_company as legacy read-only; do not overwrite. Summary displays client_business.
- Typeahead hooks:
  - Venue input: onSelect => update base (venue_id, venue_name, venue_address) -> rpc seed_survey_from_venue -> refetch rooms, guidelines, venue contacts.
  - Client business input: onSelect => update base (client_id, client_business, client_address, tax_status) -> rpc seed_survey_from_client -> refetch client contacts.
  - Primary client person selector: onSelect => rpc set_survey_primary_client_contact -> refresh base client contact fields.
- Deletion policy:
  - CONTACTS (survey_contacts): prefer exclusion (excluded=true) instead of delete; editing list sets excluded flag; optional hard delete only on explicit purge.
  - TEAM / ROOMS / ROOM_ACCESS / AGENDA: hard delete removed items (delete by id) before inserting new positions.
  - PHOTOS: never auto-delete on diff; delete only when user explicitly removes asset (also remove storage object separately).
  - GUIDELINES / INHOUSE_AV (singletons): always upsert; no delete path except survey soft delete.
  - VENUE_CONTACTS / CLIENT_CONTACTS (library): maintain manually; never mutated by survey-level edits (survey clones are separate rows in survey_contacts).

  ## UI adjustments (implementation tracking)
  Status Legend: [x] = done, [~] = partial, [ ] = not started

  ### Global & Infrastructure
  - [x] Replace legacy initial load with normalized fetch + subscribeSurveyChannels
  - [x] Manual Save button uses saveComposite (composite patch assembly)
  - [x] Debounced autosave switched to composite buffer (updateSurveyData -> queueCompositeAutosave)
  - [x] Visual indicator for autosave errors (saving/ok/error status in footer)

  ### New Survey Flows
  - [x] Start Without R2 path uses createNewSurvey (immediate row insert)
  - [x] R2 "Go" path refactored to createNewSurvey + duplicate check + default INHOUSE_AV seed (buttons disabled during create)
  - [x] Disable Start buttons while duplicate check in-flight (prevent double insert)

  ### Client Selection & Contacts
  - [x] Client business typeahead UI container added
  - [x] Client business typeahead JS (setupClientBusinessTypeahead) implemented
  - [x] Primary client contact <select> UI added
  - [x] Primary client contact selector JS (setupPrimaryClientContactSelector) calling RPC
  - [x] Display/loading spinner for client typeahead results
  - [x] Clear typeahead suggestions on Escape key
  - [x] Keyboard navigation (arrow up/down + Enter) in suggestions list
  - [x] Visual badge for primary client contact in contacts list & summary
  - [x] Option to exclude (toggle) client contacts updates excluded flag via upsertContacts

  ### Venue Selection & Seeding
  - [x] Venue selection triggers seed_survey_from_venue RPC
  - [x] Venue typeahead keyboard navigation & loading indicator
  - [x] UI feedback on venue seeding completion (toast / inline message)

  ### In-House AV
  - [x] In-house AV upsert path (upsertInHouseAV + contacts category)
  - [x] Toggle enable/disable visually greys out dependent fields
  - [x] Add button to add AV contact reusing contact editor component

  ### Contacts Management (Generic)
  - [x] Contact exclusion (excluded flag) logic (UI toggles update excluded and persist via upsertContacts)
  - [x] Unified contact edit modal (replaces inline forms)
  - [x] Soft delete vs exclude distinction tooltips (in modal footer)

  ### Rooms & Access
  - [x] Room save/upsert normalized
  - [x] Reorder (drag/drop) updates position immediately with autosave
  - [x] Inline new room form auto-focus first field
  - [x] Room access save/upsert normalized
  - [x] Calendar/date picker consistent styling vs native default

  ### Agenda Files
  - [x] Agenda upsert normalized
  - [x] Progress bar during file upload (photos & agenda)
  - [x] Remove agenda file triggers delete + refresh

  ### Photos
  - [x] Photo upsert normalized
  - [x] Remove photo UI (delete + storage removal) (normalized)
  - [x] Thumbnail grid lazy loading / preview modal

  ### Guidelines
  - [x] Guidelines upsert normalized
  - [x] Split view editor (raw text vs parsed important_info/due_dates) with diff highlight

  ### Summary / Export
  - [x] Summary rendering uses normalized arrays (category separation added)
  - [x] Separate sections: Client Contacts / Venue Contacts / In-House AV Contacts / Event Contacts
  - [x] Show excluded contacts in collapsible subsection
  - [x] Export (copy/email) uses normalized data, not legacy keys (verified)

  ### Delete / Restore
  - [x] Add Delete Survey button calling deleteSurveySoft
  - [x] Add Restore Survey button (visible via banner when soft-deleted)
  - [x] Visual badge when survey is soft-deleted (banner + Archive state)

  ### Realtime UX
  - [ ] Inline highlight of fields updated by remote session
  - [ ] Remote typing indicators (currently disabled placeholder)
  - [ ] Conflict resolution messaging if local edit overwritten

  ### Accessibility & UX Polish
  - [ ] ARIA roles/labels for interactive components (typeahead, tabs, modals) 
  - [ ] Keyboard trap prevention in modals
  - [ ] Focus outline consistent (currently browser default)
  - [ ] High contrast mode support (CSS vars)

  ### Performance & Reliability
  - [x] Incremental table-specific refresh in handleTableEvent (targeted queries per table)
  - [x] Throttle large array saves (rooms/access) during rapid reordering
  - [x] Optimistic UI updates with rollback on saveComposite error

  ### Misc
  - [ ] Central toast/notification system (success/error/info) replace scattered console logs
  - [ ] Settings panel toggle (future) for experimental features (realtime granular, optimistic)

  ### Prioritization (suggested next 5)
  1. R2 "Go" path refactor
  2. Delete/Restore survey UI
  3. Summary category separation & excluded grouping
  4. Contact exclusion toggle wired to excluded flag
  5. Typeahead keyboard + Escape interactions

