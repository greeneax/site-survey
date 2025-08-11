-- Supabase/Postgres schema for Site Survey system
-- Includes: normalized tables, indexes, audit logging, versioning, soft delete and restore helpers, and undo.

-- Extensions
create extension if not exists pgcrypto; -- gen_random_uuid()
create extension if not exists pg_trgm;  -- optional, for fuzzy search
create extension if not exists citext;   -- case-insensitive text (emails)
create extension if not exists unaccent; -- accent-insensitive search

-- Enums
do $$ begin
    if not exists (select 1 from pg_type where typname='contact_phone_type') then
        create type contact_phone_type as enum ('cell','office','other');
    end if;
    if not exists (select 1 from pg_type where typname='contact_category') then
        create type contact_category as enum ('client','venue','inhouse_av','event_contact');
    end if;
end $$;

-- Venues
create table if not exists public.venues (
    id uuid primary key default gen_random_uuid(),
    venue_name text not null,
    venue_address text,
    notes text,
    created_at timestamptz not null default now(),
    created_by uuid default auth.uid(),
    updated_at timestamptz not null default now(),
    updated_by uuid default auth.uid(),
    version int not null default 1,
    deleted_at timestamptz,
    deleted_by uuid
);
create unique index if not exists ux_venues_name_active
on public.venues (lower(venue_name))
where deleted_at is null;

-- Typeahead optimization for venue_name
create index if not exists ix_venues_name_trgm
on public.venues using gin (venue_name gin_trgm_ops)
where deleted_at is null;

-- Venue rooms (library)
create table if not exists public.venue_rooms (
    id uuid primary key default gen_random_uuid(),
    venue_id uuid not null references public.venues(id) on update cascade,
    name text not null,
    type text,
    capacity int,
    layout text,
    dimensions text,
    ceiling_height text,
    electrical text,
    rigging text,
    sound_patch text,
    door_size text,
    wifi_available boolean,
    wifi_notes text,
    hardline_available boolean,
    hardline_notes text,
    misc_notes text,
    position int,
    created_at timestamptz not null default now(),
    created_by uuid default auth.uid(),
    updated_at timestamptz not null default now(),
    updated_by uuid default auth.uid(),
    version int not null default 1,
    deleted_at timestamptz,
    deleted_by uuid
);
create index if not exists ix_venue_rooms_venue on public.venue_rooms(venue_id) where deleted_at is null;

-- Venue guidelines (library)
create table if not exists public.venue_guidelines (
    id uuid primary key default gen_random_uuid(),
    venue_id uuid not null unique references public.venues(id) on update cascade,
    important_info jsonb default '[]'::jsonb,
    due_dates jsonb default '[]'::jsonb,
    raw_text text,
    processed_by uuid,
    processed_at timestamptz,
    created_at timestamptz not null default now(),
    created_by uuid default auth.uid(),
    updated_at timestamptz not null default now(),
    updated_by uuid default auth.uid(),
    version int not null default 1,
    deleted_at timestamptz,
    deleted_by uuid
);

-- Venue contacts (library)
create table if not exists public.venue_contacts (
  id uuid primary key default gen_random_uuid(),
  venue_id uuid not null references public.venues(id) on update cascade,
  name text,
  title text,
  email text,
  phone text,
  phone_type contact_phone_type default 'cell',
  note text,
  position int,
  created_at timestamptz not null default now(),
  created_by uuid default auth.uid(),
  updated_at timestamptz not null default now(),
  updated_by uuid default auth.uid(),
  version int not null default 1,
  deleted_at timestamptz,
  deleted_by uuid
);
create index if not exists ix_venue_contacts_venue on public.venue_contacts(venue_id) where deleted_at is null;
create unique index if not exists ux_venue_contacts_email on public.venue_contacts(venue_id, lower(email)) where email is not null and deleted_at is null;

-- Surveys
create table if not exists public.surveys (
    id uuid primary key default gen_random_uuid(),
    survey_id text not null,
    r2_quote_number text,
    event_name text,
    status text,
    client_business text,
    show_start_date date,
    show_start_time time,
    show_end_time time,
    load_in_date date,
    load_in_time time,
    setup_date date,
    setup_time time,
    rehearsal_date date,
    rehearsal_time time,
    strike_date date,
    strike_time time,
    indoor_outdoor text,
    anticipated_attendees int,
    charge_days int,
    budget numeric(12,2),
    survey_date date,
    survey_team text,
    client_name text,
    client_email text,
    client_cell text,
    client_address text,
    client_company text,
    client_title text,
    tax_status text,
    event_contact_name text,
    event_contact_email text,
    event_contact_phone text,
    event_contact_title text,
  client_id uuid references public.clients(id) on update cascade,
    venue_id uuid references public.venues(id) on update cascade,
    venue_name text,
    venue_address text,
    tags text[] default '{}',
    created_at timestamptz not null default now(),
    created_by uuid default auth.uid(),
    updated_at timestamptz not null default now(),
    updated_by uuid default auth.uid(),
    version int not null default 1,
    deleted_at timestamptz,
    deleted_by uuid,
    unique (survey_id)
);
create unique index if not exists ux_surveys_r2_active on public.surveys((lower(coalesce(r2_quote_number,'')))) where r2_quote_number is not null and deleted_at is null;
create index if not exists ix_surveys_status on public.surveys(status) where deleted_at is null;
create index if not exists ix_surveys_show_start on public.surveys(show_start_date) where deleted_at is null;

-- Clients (library)
create table if not exists public.clients (
    id uuid primary key default gen_random_uuid(),
    business_name text not null,
    business_address text,
    tax_status text,
    notes text,
    tags text[] default '{}',
    created_at timestamptz not null default now(),
    created_by uuid default auth.uid(),
    updated_at timestamptz not null default now(),
    updated_by uuid default auth.uid(),
    version int not null default 1,
    deleted_at timestamptz,
    deleted_by uuid
);
create unique index if not exists ux_clients_name_active on public.clients (lower(business_name)) where deleted_at is null;
create index if not exists ix_clients_name_trgm on public.clients using gin (business_name gin_trgm_ops) where deleted_at is null;

-- Client aliases (for search)
create table if not exists public.client_aliases (
    id uuid primary key default gen_random_uuid(),
    client_id uuid not null references public.clients(id) on update cascade,
    alias text not null,
    created_at timestamptz not null default now(),
    created_by uuid default auth.uid(),
    updated_at timestamptz not null default now(),
    updated_by uuid default auth.uid(),
    version int not null default 1,
    deleted_at timestamptz,
    deleted_by uuid
);
create index if not exists ix_client_aliases_client on public.client_aliases(client_id) where deleted_at is null;
create index if not exists ix_client_aliases_alias_trgm on public.client_aliases using gin (alias gin_trgm_ops) where deleted_at is null;

-- Client contacts (library)
create table if not exists public.client_contacts (
    id uuid primary key default gen_random_uuid(),
    client_id uuid not null references public.clients(id) on update cascade,
    name text,
    title text,
    email citext,
    phone text,
    phone_type contact_phone_type default 'cell',
    note text,
    position int,
    created_at timestamptz not null default now(),
    created_by uuid default auth.uid(),
    updated_at timestamptz not null default now(),
    updated_by uuid default auth.uid(),
    version int not null default 1,
    deleted_at timestamptz,
    deleted_by uuid
);
create index if not exists ix_client_contacts_client on public.client_contacts(client_id) where deleted_at is null;
create unique index if not exists ux_client_contacts_email on public.client_contacts(client_id, email) where email is not null and deleted_at is null;

-- Ensure surveys table has client_id column (idempotent, placed AFTER clients table so FK target exists)
do $$ begin
  begin
    alter table public.surveys add column if not exists client_id uuid references public.clients(id) on update cascade;
  exception when duplicate_column then
    -- already present
  end;
exception when undefined_table then
  -- Should not happen now; logged for diagnostics if script sections reordered inadvertently
  raise notice 'Skipped adding client_id to surveys because clients table not yet present';
end $$;

-- Survey team members
create table if not exists public.survey_team_members (
    id uuid primary key default gen_random_uuid(),
    survey_id uuid not null references public.surveys(id) on update cascade,
    name text not null,
    role text,
    position int,
    created_at timestamptz not null default now(),
    created_by uuid default auth.uid(),
    updated_at timestamptz not null default now(),
    updated_by uuid default auth.uid(),
    version int not null default 1,
    deleted_at timestamptz,
    deleted_by uuid
);
create index if not exists ix_team_members_survey on public.survey_team_members(survey_id) where deleted_at is null;

-- In-house AV
create table if not exists public.inhouse_av (
    id uuid primary key default gen_random_uuid(),
    survey_id uuid not null unique references public.surveys(id) on update cascade,
    enabled boolean not null default false,
    company_name text,
    created_at timestamptz not null default now(),
    created_by uuid default auth.uid(),
    updated_at timestamptz not null default now(),
    updated_by uuid default auth.uid(),
    version int not null default 1,
    deleted_at timestamptz,
    deleted_by uuid
);

-- Survey contacts
create table if not exists public.survey_contacts (
    id uuid primary key default gen_random_uuid(),
    survey_id uuid not null references public.surveys(id) on update cascade,
    category contact_category not null,
    name text,
    title text,
    email text,
    phone text,
    phone_type contact_phone_type default 'cell',
    excluded boolean not null default false,
    note text,
    created_at timestamptz not null default now(),
    created_by uuid default auth.uid(),
    updated_at timestamptz not null default now(),
    updated_by uuid default auth.uid(),
    version int not null default 1,
    deleted_at timestamptz,
    deleted_by uuid
);
create index if not exists ix_contacts_survey on public.survey_contacts(survey_id) where deleted_at is null;
create index if not exists ix_contacts_category on public.survey_contacts(category) where deleted_at is null;

-- Survey rooms
create table if not exists public.rooms (
    id uuid primary key default gen_random_uuid(),
    survey_id uuid not null references public.surveys(id) on update cascade,
    name text,
    type text,
    capacity int,
    layout text,
    dimensions text,
    ceiling_height text,
    electrical text,
    rigging text,
    sound_patch text,
    door_size text,
    wifi_available boolean,
    wifi_notes text,
    hardline_available boolean,
    hardline_notes text,
    misc_notes text,
    position int,
    created_at timestamptz not null default now(),
    created_by uuid default auth.uid(),
    updated_at timestamptz not null default now(),
    updated_by uuid default auth.uid(),
    version int not null default 1,
    deleted_at timestamptz,
    deleted_by uuid
);
create index if not exists ix_rooms_survey on public.rooms(survey_id) where deleted_at is null;

-- Room access
create table if not exists public.room_access (
    id uuid primary key default gen_random_uuid(),
    survey_id uuid not null references public.surveys(id) on update cascade,
    room_id uuid references public.rooms(id) on update cascade,
    room_name text,
    room_type text,
    access_date date,
    access_start_time time,
    access_end_time time,
    access_notes text,
    position int,
    created_at timestamptz not null default now(),
    created_by uuid default auth.uid(),
    updated_at timestamptz not null default now(),
    updated_by uuid default auth.uid(),
    version int not null default 1,
    deleted_at timestamptz,
    deleted_by uuid
);
create index if not exists ix_room_access_survey on public.room_access(survey_id) where deleted_at is null;
create index if not exists ix_room_access_date on public.room_access(access_date) where deleted_at is null;

-- Photos
create table if not exists public.photos (
    id uuid primary key default gen_random_uuid(),
    survey_id uuid not null references public.surveys(id) on update cascade,
    room_id uuid references public.rooms(id) on update cascade,
    section text,
    storage_path text not null,
    url text,
    filename text,
    mime_type text,
    size_bytes int,
    created_at timestamptz not null default now(),
    created_by uuid default auth.uid(),
    updated_at timestamptz not null default now(),
    updated_by uuid default auth.uid(),
    version int not null default 1,
    deleted_at timestamptz,
    deleted_by uuid
);
create unique index if not exists ux_photos_storage on public.photos(survey_id, storage_path) where deleted_at is null;
create index if not exists ix_photos_section on public.photos(section) where deleted_at is null;

-- Agenda files
create table if not exists public.agenda_files (
    id uuid primary key default gen_random_uuid(),
    survey_id uuid not null references public.surveys(id) on update cascade,
    name text,
    url text,
    mime_type text,
    size_bytes int,
    uploaded_at timestamptz not null default now(),
    analysis jsonb,
    created_at timestamptz not null default now(),
    created_by uuid default auth.uid(),
    updated_at timestamptz not null default now(),
    updated_by uuid default auth.uid(),
    version int not null default 1,
    deleted_at timestamptz,
    deleted_by uuid
);
create index if not exists ix_agenda_files_survey on public.agenda_files(survey_id) where deleted_at is null;

-- Survey guidelines
create table if not exists public.guidelines (
    id uuid primary key default gen_random_uuid(),
    survey_id uuid not null unique references public.surveys(id) on update cascade,
    important_info jsonb default '[]'::jsonb,
    due_dates jsonb default '[]'::jsonb,
    raw_text text,
    processed_by uuid,
    processed_at timestamptz,
    created_at timestamptz not null default now(),
    created_by uuid default auth.uid(),
    updated_at timestamptz not null default now(),
    updated_by uuid default auth.uid(),
    version int not null default 1,
    deleted_at timestamptz,
    deleted_by uuid
);

-- Audit log
create table if not exists public.audit_log (
    id bigserial primary key,
    table_name text not null,
    record_id uuid not null,
    action text not null,
    old_data jsonb,
    new_data jsonb,
    changed_at timestamptz not null default now(),
    changed_by uuid default auth.uid(),
    txid bigint not null default txid_current()
);
create index if not exists ix_audit_table_record on public.audit_log(table_name, record_id);
create index if not exists ix_audit_changed_at on public.audit_log(changed_at);

-- Triggers: updated_at/version
create or replace function public.tg_set_updated_at_and_version()
returns trigger language plpgsql as $$
begin
  new.updated_at := now();
  if tg_op = 'UPDATE' then
    new.version := coalesce(old.version, 0) + 1;
  end if;
  new.updated_by := auth.uid();
  return new;
end$$;

-- Triggers: audit
create or replace function public.tg_audit_log()
returns trigger language plpgsql as $$
begin
  if tg_op = 'INSERT' then
    insert into public.audit_log(table_name, record_id, action, old_data, new_data, changed_by)
    values (tg_table_name, new.id, 'INSERT', null, to_jsonb(new), auth.uid());
    return new;
  elsif tg_op = 'UPDATE' then
    insert into public.audit_log(table_name, record_id, action, old_data, new_data, changed_by)
    values (tg_table_name, new.id, 'UPDATE', to_jsonb(old), to_jsonb(new), auth.uid());
    return new;
  elsif tg_op = 'DELETE' then
    insert into public.audit_log(table_name, record_id, action, old_data, new_data, changed_by)
    values (tg_table_name, old.id, 'DELETE', to_jsonb(old), null, auth.uid());
    return old;
  end if;
  return null;
end$$;

-- Attach triggers to entity tables
do $$ declare t text; begin
  foreach t in array array[
  'venues','venue_rooms','venue_guidelines','venue_contacts',
  'clients','client_aliases','client_contacts',
    'surveys','survey_team_members','inhouse_av','survey_contacts',
    'rooms','room_access','photos','agenda_files','guidelines'
  ]
  loop
    execute format('drop trigger if exists set_updated_at_and_version on public.%I;', t);
    execute format('create trigger set_updated_at_and_version before update on public.%I for each row execute function public.tg_set_updated_at_and_version();', t);

    execute format('drop trigger if exists audit_after_ins_upd_del on public.%I;', t);
    execute format('create trigger audit_after_ins_upd_del after insert or update or delete on public.%I for each row execute function public.tg_audit_log();', t);
  end loop;
end $$;

-- Soft delete helpers (generic)
create or replace function public.soft_delete(table_name text, _id uuid)
returns void language plpgsql as $$
declare sql text; begin
  sql := format('update public.%I set deleted_at = now(), deleted_by = auth.uid() where id = $1 and deleted_at is null', table_name);
  execute sql using _id;
end $$;

create or replace function public.restore_soft_deleted(table_name text, _id uuid)
returns void language plpgsql as $$
declare sql text; begin
  sql := format('update public.%I set deleted_at = null, deleted_by = null where id = $1', table_name);
  execute sql using _id;
end $$;

-- Survey soft delete/restore cascades
create or replace function public.soft_delete_survey(_id uuid)
returns void language plpgsql as $$
begin
  perform public.soft_delete('surveys', _id);
  update public.survey_team_members set deleted_at = now(), deleted_by = auth.uid() where survey_id = _id and deleted_at is null;
  update public.inhouse_av set deleted_at = now(), deleted_by = auth.uid() where survey_id = _id and deleted_at is null;
  update public.survey_contacts set deleted_at = now(), deleted_by = auth.uid() where survey_id = _id and deleted_at is null;
  update public.rooms set deleted_at = now(), deleted_by = auth.uid() where survey_id = _id and deleted_at is null;
  update public.room_access set deleted_at = now(), deleted_by = auth.uid() where survey_id = _id and deleted_at is null;
  update public.photos set deleted_at = now(), deleted_by = auth.uid() where survey_id = _id and deleted_at is null;
  update public.agenda_files set deleted_at = now(), deleted_by = auth.uid() where survey_id = _id and deleted_at is null;
  update public.guidelines set deleted_at = now(), deleted_by = auth.uid() where survey_id = _id and deleted_at is null;
end $$;

create or replace function public.restore_survey(_id uuid)
returns void language plpgsql as $$
begin
  perform public.restore_soft_deleted('surveys', _id);
  update public.survey_team_members set deleted_at = null, deleted_by = null where survey_id = _id;
  update public.inhouse_av set deleted_at = null, deleted_by = null where survey_id = _id;
  update public.survey_contacts set deleted_at = null, deleted_by = null where survey_id = _id;
  update public.rooms set deleted_at = null, deleted_by = null where survey_id = _id;
  update public.room_access set deleted_at = null, deleted_by = null where survey_id = _id;
  update public.photos set deleted_at = null, deleted_by = null where survey_id = _id;
  update public.agenda_files set deleted_at = null, deleted_by = null where survey_id = _id;
  update public.guidelines set deleted_at = null, deleted_by = null where survey_id = _id;
end $$;

-- Venue soft delete/restore cascades
create or replace function public.soft_delete_venue(_id uuid)
returns void language plpgsql as $$
begin
  perform public.soft_delete('venues', _id);
  update public.venue_rooms set deleted_at = now(), deleted_by = auth.uid() where venue_id = _id and deleted_at is null;
  update public.venue_guidelines set deleted_at = now(), deleted_by = auth.uid() where venue_id = _id and deleted_at is null;
end $$;

create or replace function public.restore_venue(_id uuid)
returns void language plpgsql as $$
begin
  perform public.restore_soft_deleted('venues', _id);
  update public.venue_rooms set deleted_at = null, deleted_by = null where venue_id = _id;
  update public.venue_guidelines set deleted_at = null, deleted_by = null where venue_id = _id;
end $$;

-- Seed a survey with data from a selected venue (idempotent for rooms/contacts)
create or replace function public.seed_survey_from_venue(_survey_id uuid, _venue_id uuid)
returns void language plpgsql as $$
begin
  -- Rooms: only seed if survey has no rooms yet
  if not exists (select 1 from public.rooms where survey_id = _survey_id and deleted_at is null) then
    insert into public.rooms (
      survey_id, name, type, capacity, layout, dimensions, ceiling_height,
      electrical, rigging, sound_patch, door_size,
      wifi_available, wifi_notes, hardline_available, hardline_notes,
      misc_notes, position
    )
    select
      _survey_id, vr.name, vr.type, vr.capacity, vr.layout, vr.dimensions, vr.ceiling_height,
      vr.electrical, vr.rigging, vr.sound_patch, vr.door_size,
      vr.wifi_available, vr.wifi_notes, vr.hardline_available, vr.hardline_notes,
      vr.misc_notes,
      coalesce(vr.position, row_number() over (order by vr.created_at))
    from public.venue_rooms vr
    where vr.venue_id = _venue_id and vr.deleted_at is null;
  end if;

  -- Guidelines: upsert from venue_guidelines
  insert into public.guidelines (
    survey_id, important_info, due_dates, raw_text, processed_by, processed_at
  )
  select _survey_id, vg.important_info, vg.due_dates, vg.raw_text, vg.processed_by, vg.processed_at
  from public.venue_guidelines vg
  where vg.venue_id = _venue_id and vg.deleted_at is null
  on conflict (survey_id) do update set
    important_info = excluded.important_info,
    due_dates = excluded.due_dates,
    raw_text = excluded.raw_text,
    processed_by = excluded.processed_by,
    processed_at = excluded.processed_at;

  -- Venue Contacts -> Survey Contacts (category='venue'): only seed if none exist yet
  if not exists (
    select 1 from public.survey_contacts sc
    where sc.survey_id = _survey_id and sc.category = 'venue'::contact_category and sc.deleted_at is null
  ) then
    insert into public.survey_contacts (
      survey_id, category, name, title, email, phone, phone_type, excluded, note, position
    )
    select
      _survey_id, 'venue'::contact_category, vc.name, vc.title, vc.email, vc.phone, vc.phone_type,
      false, vc.note,
      coalesce(vc.position, row_number() over (order by vc.created_at))
    from public.venue_contacts vc
    where vc.venue_id = _venue_id and vc.deleted_at is null;
  end if;
end $$;

-- Seed a survey with data from a selected client
create or replace function public.seed_survey_from_client(_survey_id uuid, _client_id uuid)
returns void language plpgsql as $$
declare c record; begin
  select * into c from public.clients where id = _client_id and deleted_at is null;
  if not found then return; end if;
  update public.surveys s set
    client_id = _client_id,
    client_business = c.business_name,
    client_address = c.business_address,
    tax_status = c.tax_status
  where s.id = _survey_id;

  -- Seed client contacts into survey_contacts (category='client') if none exist
  if not exists (
    select 1 from public.survey_contacts sc
    where sc.survey_id = _survey_id and sc.category = 'client'::contact_category and sc.deleted_at is null
  ) then
    insert into public.survey_contacts (
      survey_id, category, name, title, email, phone, phone_type, excluded, note, position
    )
    select
      _survey_id, 'client'::contact_category, cc.name, cc.title, cc.email::text, cc.phone, cc.phone_type,
      false, cc.note,
      coalesce(cc.position, row_number() over (order by cc.created_at))
    from public.client_contacts cc
    where cc.client_id = _client_id and cc.deleted_at is null;
  end if;
end $$;

-- Set survey primary client contact from the library (updates survey.* client fields)
create or replace function public.set_survey_primary_client_contact(_survey_id uuid, _client_contact_id uuid)
returns void language plpgsql as $$
declare cc record; begin
  select * into cc from public.client_contacts where id = _client_contact_id and deleted_at is null;
  if not found then return; end if;
  update public.surveys s set
    client_name = cc.name,
    client_email = cc.email::text,
    client_cell = cc.phone,
    client_title = cc.title
  where s.id = _survey_id;

  -- Ensure the selected contact exists in survey_contacts (category='client')
  if not exists (
    select 1 from public.survey_contacts sc
    where sc.survey_id = _survey_id and sc.category='client'::contact_category and sc.email = cc.email::text and sc.deleted_at is null
  ) then
    insert into public.survey_contacts (
      survey_id, category, name, title, email, phone, phone_type, excluded, note, position
    ) values (
      _survey_id, 'client'::contact_category, cc.name, cc.title, cc.email::text, cc.phone, cc.phone_type, false, cc.note, 1
    );
  end if;
end $$;

-- Active clients view (optional)
create or replace view public.active_clients as
  select * from public.clients where deleted_at is null;

-- Undo using audit_log: reapply previous snapshot
create or replace function public.undo_change(audit_id bigint)
returns text language plpgsql as $$
declare r record; tbl text; pk uuid; col_list text; sql text; begin
  select * into r from public.audit_log where id = audit_id;
  if not found then return 'Audit row not found'; end if;
  tbl := r.table_name; pk := r.record_id;

  if r.action = 'INSERT' then
    -- Undo insert => soft-delete if possible else hard delete
    begin
      sql := format('update public.%I set deleted_at = now(), deleted_by = auth.uid() where id = $1 and deleted_at is null', tbl);
      execute sql using pk;
    exception when undefined_column then
      sql := format('delete from public.%I where id = $1', tbl);
      execute sql using pk;
    end;
    return 'Undid INSERT -> deleted/soft-deleted';
  elsif r.action = 'UPDATE' then
    -- Build column list dynamically (excluding id)
    select string_agg(quote_ident(column_name), ',') into col_list
    from information_schema.columns c
    where c.table_schema='public' and c.table_name=tbl and c.column_name <> 'id';
    if col_list is null then return 'No columns found to restore'; end if;
    sql := format('update public.%I set (%s) = (select %s from json_populate_record(NULL::public.%I, $1)) where id = $2',
                  tbl, col_list, col_list, tbl);
    execute sql using r.old_data, pk;
    return 'Undid UPDATE -> restored previous data';
  elsif r.action in ('DELETE') then
    -- Re-insert deleted row from old_data
    sql := format('insert into public.%I select * from json_populate_record(NULL::public.%I, $1) on conflict (id) do update set id=excluded.id', tbl, tbl);
    execute sql using r.old_data;
    return 'Undid DELETE -> reinserted';
  else
    -- For SOFT_DELETE/RESTORE we rely on normal updates; call restore if needed
    return 'Unsupported or not needed for this action';
  end if;
end $$;

-- Active views (optional)
create or replace view public.active_surveys as
  select * from public.surveys where deleted_at is null;

create or replace view public.active_venues as
  select * from public.venues where deleted_at is null;
