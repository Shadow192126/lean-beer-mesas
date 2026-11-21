-- Ejecutar en SQL Editor en un proyecto de Supabase.
create table if not exists public.lb_sessions (
  id uuid primary key,
  host_hash bytea not null,
  state jsonb not null,
  version bigint not null default 0
);
alter table public.lb_sessions enable row level security;
revoke all on public.lb_sessions from public, anon, authenticated;

create or replace function public.lb_create(room uuid, host_key text, initial jsonb)
returns boolean language plpgsql security definer set search_path = '' as $$
begin
  if coalesce(length(host_key), 0) < 64 or octet_length(initial::text) > 10000 then
    raise exception 'Configuración inicial inválida';
  end if;
  insert into public.lb_sessions(id, host_hash, state)
    values (room, sha256(convert_to(host_key, 'UTF8')), initial);
  return true;
end;
$$;

create or replace function public.lb_read(room uuid)
returns jsonb language sql stable security definer set search_path = '' as $$
  select jsonb_build_object('state', state, 'version', version)
  from public.lb_sessions where id = room;
$$;

create or replace function public.lb_write(room uuid, expected bigint, next_state jsonb, host_key text)
returns boolean language plpgsql security definer set search_path = '' as $$
declare
  previous public.lb_sessions%rowtype;
  old_table jsonb;
  new_table jsonb;
  item record;
  old_card jsonb;
  new_card jsonb;
  expired boolean;
begin
  if next_state is null or octet_length(next_state::text) > 1000000 then
    raise exception 'La sesión excede el tamaño permitido';
  end if;
  select * into previous from public.lb_sessions where id = room for update;
  if not found or previous.version <> expected then return false; end if;

  if sha256(convert_to(coalesce(host_key, ''), 'UTF8')) <> previous.host_hash then
    if (select array_agg(k order by k) from jsonb_object_keys(previous.state->'tables') k)
        is distinct from
       (select array_agg(k order by k) from jsonb_object_keys(next_state->'tables') k) then
      raise exception 'Solo el facilitador puede administrar las mesas';
    end if;
    for item in select * from jsonb_each(previous.state->'tables') loop
      old_table := item.value;
      new_table := next_state->'tables'->item.key;
      expired := (old_table->>'end')::bigint > 0
        and (old_table->>'end')::bigint <= extract(epoch from clock_timestamp()) * 1000
        and new_table->>'end' = '0' and new_table->>'remaining' = '0'
        and new_table->'roman'->'votes' = '{}'::jsonb;
      if (old_table - array['cards','people','roman','end','remaining'])
         is distinct from (new_table - array['cards','people','roman','end','remaining'])
         or (not coalesce(expired,false) and
           row(old_table->'end',old_table->'remaining',old_table->'roman'->'id')
           is distinct from row(new_table->'end',new_table->'remaining',new_table->'roman'->'id')
           and not (coalesce((old_table->>'movement')::boolean,false)
             and new_table->>'end' = '0' and new_table->>'remaining' = '300'
             and new_table->'roman' = 'null'::jsonb
             and (select array_agg(c->>'id' order by c->>'id') from jsonb_array_elements(old_table->'cards') c where c->>'stage'='doing')
                 is distinct from
                 (select array_agg(c->>'id' order by c->>'id') from jsonb_array_elements(new_table->'cards') c where c->>'stage'='doing')))
      then raise exception 'Control reservado al facilitador'; end if;

      for old_card in select value from jsonb_array_elements(old_table->'cards') loop
        select c into new_card from jsonb_array_elements(new_table->'cards') c where c->>'id' = old_card->>'id';
        if new_card is null
           or (old_card - array['stage','notes','votes']) is distinct from (new_card - array['stage','notes','votes'])
           or (not (old_table->>'movement')::boolean and old_card->'stage' is distinct from new_card->'stage')
           or ((old_table->>'locked')::boolean and old_card->'votes' is distinct from new_card->'votes')
        then raise exception 'Cambio de tarjeta no permitido'; end if;
      end loop;
      if exists (select 1 from jsonb_array_elements(new_table->'cards') c
          where not exists (select 1 from jsonb_array_elements(old_table->'cards') o where o->>'id'=c->>'id')
          and (c->>'stage' is distinct from 'todo' or c->'votes' is distinct from '{}'::jsonb))
      then raise exception 'Los nuevos temas deben ingresar sin votos en Por discutir'; end if;
    end loop;
  end if;

  update public.lb_sessions set state = next_state, version = version + 1 where id = room;
  return true;
end;
$$;

revoke execute on function public.lb_create(uuid,text,jsonb), public.lb_read(uuid), public.lb_write(uuid,bigint,jsonb,text) from public;
grant execute on function public.lb_create(uuid,text,jsonb), public.lb_read(uuid), public.lb_write(uuid,bigint,jsonb,text) to anon, authenticated;

