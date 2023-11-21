
SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

CREATE EXTENSION IF NOT EXISTS "pg_net" WITH SCHEMA "extensions";

CREATE SCHEMA IF NOT EXISTS "new_schema";

ALTER SCHEMA "new_schema" OWNER TO "postgres";

CREATE EXTENSION IF NOT EXISTS "pgsodium" WITH SCHEMA "pgsodium";

ALTER SCHEMA "public" OWNER TO "postgres";

CREATE EXTENSION IF NOT EXISTS "pg_graphql" WITH SCHEMA "graphql";

CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";

CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";

CREATE EXTENSION IF NOT EXISTS "pgjwt" WITH SCHEMA "extensions";

CREATE EXTENSION IF NOT EXISTS "postgis" WITH SCHEMA "extensions";

CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";

CREATE EXTENSION IF NOT EXISTS "vector" WITH SCHEMA "extensions";

CREATE EXTENSION IF NOT EXISTS "wrappers" WITH SCHEMA "extensions";

CREATE TYPE "public"."activity_result" AS (
	"name" "text",
	"case_id" "uuid",
	"assigned_to" "uuid",
	"description" "text",
	"created_by" "uuid",
	"due_date" timestamp with time zone
);

ALTER TYPE "public"."activity_result" OWNER TO "postgres";

CREATE TYPE "public"."continents" AS ENUM (
    'Africa',
    'Antarctica',
    'Asia',
    'Europe',
    'Oceania',
    'North America',
    'South America'
);

ALTER TYPE "public"."continents" OWNER TO "postgres";

CREATE TYPE "public"."lesson_type" AS ENUM (
    'lecture',
    'tutorial',
    'lab'
);

ALTER TYPE "public"."lesson_type" OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."create_activity"("name" "text", "case_id" "uuid", "assigned_to" "uuid", "description" "text", "created_by" "uuid", "due_date" timestamp with time zone) RETURNS "public"."activity_result"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
  result activity_result;
BEGIN
  -- Set the search path to the public schema
  SET search_path = public;

  -- Create the activity
  INSERT INTO activities (name, case_id, assigned_to, description, created_by, due_date)
  VALUES (name, case_id, assigned_to, description, created_by, due_date)
  RETURNING * INTO result;

  RETURN result;
END;
$$;

ALTER FUNCTION "public"."create_activity"("name" "text", "case_id" "uuid", "assigned_to" "uuid", "description" "text", "created_by" "uuid", "due_date" timestamp with time zone) OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."get_page_parents"("page_id" bigint) RETURNS TABLE("id" bigint, "parent_page_id" bigint, "path" "text", "meta" "jsonb")
    LANGUAGE "sql"
    AS $$
  with recursive chain as (
    select *
    from nods_page 
    where id = page_id

    union all

    select child.*
      from nods_page as child
      join chain on chain.parent_page_id = child.id 
  )
  select id, parent_page_id, path, meta
  from chain;
$$;

ALTER FUNCTION "public"."get_page_parents"("page_id" bigint) OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."handle_new_user"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
begin
  insert into public.profiles (id, full_name, avatar_url)
  values (new.id, new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'avatar_url');
  return new;
end;
$$;

ALTER FUNCTION "public"."handle_new_user"() OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."insert_users"() RETURNS "void"
    LANGUAGE "plpgsql"
    AS $_$
BEGIN
    FOR i IN 1..100 LOOP
        INSERT INTO auth.users (id, instance_id, email, email_confirmed_at, encrypted_password, aud, "role", raw_app_meta_data, raw_user_meta_data, created_at, updated_at, last_sign_in_at, confirmation_token, email_change, email_change_token_new, recovery_token)
        VALUES ('662adb80-2949-46fc-8cad-a3cb156ede6e', '00000000-0000-0000-0000-000000000000', 'saltcod@gmail.com', '2023-02-25T10:06:34.441Z', '$2a$10$uFKPCIwHTZMrYF2lmfR1TOsJrNxm5rhJ1PQ/NrBwu7YkC2eXBpMZy', 'authenticated', 'authenticated', '{"provider":"github","providers":["email"]}', '{}', '2023-02-25T10:06:34.441Z', '2023-02-25T10:06:34.441Z', '2023-02-25T10:06:34.441Z', '', '', '', '');
        
        INSERT INTO auth.identities (id, user_id, "provider", identity_data, created_at, updated_at, last_sign_in_at)
        VALUES ('662adb80-2949-46fc-8cad-a3cb156ede6e', '662adb80-2949-46fc-8cad-a3cb156ede6e', 'github', '{"sub":"662adb80-2949-46fc-8cad-a3cb156ede6e","email":"saltcod@gmail.com"}', '2023-02-25T10:06:34.441Z', '2023-02-25T10:06:34.441Z', '2023-02-25T10:06:34.441Z');
    END LOOP;
END;
$_$;

ALTER FUNCTION "public"."insert_users"() OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."insert_users_and_identities"() RETURNS "void"
    LANGUAGE "plpgsql"
    AS $_$
DECLARE
    i integer := 1;
    uuid uuid;
    email text;
BEGIN
    WHILE i <= 500 LOOP
        -- generate unique values for each iteration
        uuid := uuid_generate_v4();
        email := format('user%d@example.com', i);

        -- insert user
        INSERT INTO auth.users (id, instance_id, email, email_confirmed_at, encrypted_password, aud, "role", raw_app_meta_data, raw_user_meta_data, created_at, updated_at, last_sign_in_at, confirmation_token, email_change, email_change_token_new, recovery_token) 
        VALUES
            (uuid, '00000000-0000-0000-0000-000000000000', email, '2023-02-25T10:06:34.441Z', '$2a$10$uFKPCIwHTZMrYF2lmfR1TOsJrNxm5rhJ1PQ/NrBwu7YkC2eXBpMZy', 'authenticated', 'authenticated', '{"provider":"github","providers":["email"]}', '{}', '2023-02-25T10:06:34.441Z', '2023-02-25T10:06:34.441Z', '2023-02-25T10:06:34.441Z', '', '', '', '');

        -- insert identity
        INSERT INTO auth.identities (id, user_id, "provider", identity_data, created_at, updated_at, last_sign_in_at) 
        VALUES
            (uuid, uuid, 'github', format('{"sub": "%s","email": "%s"}', uuid, email), '2023-02-25T10:06:34.441Z', '2023-02-25T10:06:34.441Z', '2023-02-25T10:06:34.441Z');
        
        i := i + 1;
    END LOOP;
END;
$_$;

ALTER FUNCTION "public"."insert_users_and_identities"() OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."match_page_sections"("embedding" "extensions"."vector", "match_threshold" double precision, "match_count" integer, "min_content_length" integer) RETURNS TABLE("id" bigint, "page_id" bigint, "slug" "text", "heading" "text", "content" "text", "similarity" double precision)
    LANGUAGE "plpgsql"
    AS $$
#variable_conflict use_variable
begin
  return query
  select
    nods_page_section.id,
    nods_page_section.page_id,
    nods_page_section.slug,
    nods_page_section.heading,
    nods_page_section.content,
    (nods_page_section.embedding <#> embedding) * -1 as similarity
  from nods_page_section

  -- We only care about sections that have a useful amount of content
  where length(nods_page_section.content) >= min_content_length

  -- The dot product is negative because of a Postgres limitation, so we negate it
  and (nods_page_section.embedding <#> embedding) * -1 > match_threshold

  -- OpenAI embeddings are normalized to length 1, so
  -- cosine similarity and dot product will produce the same results.
  -- Using dot product which can be computed slightly faster.
  --
  -- For the different syntaxes, see https://github.com/pgvector/pgvector
  order by nods_page_section.embedding <#> embedding
  
  limit match_count;
end;
$$;

ALTER FUNCTION "public"."match_page_sections"("embedding" "extensions"."vector", "match_threshold" double precision, "match_count" integer, "min_content_length" integer) OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";

CREATE TABLE IF NOT EXISTS "new_schema"."test2" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"()
);

ALTER TABLE "new_schema"."test2" OWNER TO "postgres";

ALTER TABLE "new_schema"."test2" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "new_schema"."aeuaeu_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

CREATE TABLE IF NOT EXISTS "new_schema"."test" (
    "id" integer NOT NULL,
    "campaign_name" character varying(255),
    "budget" numeric(10,2)
);

ALTER TABLE "new_schema"."test" OWNER TO "postgres";

CREATE SEQUENCE IF NOT EXISTS "new_schema"."marketing_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE "new_schema"."marketing_id_seq" OWNER TO "postgres";

ALTER SEQUENCE "new_schema"."marketing_id_seq" OWNED BY "new_schema"."test"."id";

CREATE TABLE IF NOT EXISTS "public"."blobs" (
    "sha256" character varying(64) NOT NULL,
    "type" character varying(64) NOT NULL,
    "blob" "bytea" NOT NULL,
    "blob_attributes" "jsonb" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "app" character varying DEFAULT '''''testing''''::character varying'::character varying NOT NULL
);

ALTER TABLE "public"."blobs" OWNER TO "postgres";

CREATE TABLE IF NOT EXISTS "public"."countries" (
    "id" bigint NOT NULL,
    "name" "text",
    "iso2" "text" NOT NULL,
    "iso3" "text",
    "local_name" "text",
    "continent" "public"."continents",
    "column1" "text",
    "column2" "text",
    "column3" "text",
    "column4" "text",
    "column5" "text",
    "column6" "text",
    "column7" "text",
    "column8" "text"
);

ALTER TABLE "public"."countries" OWNER TO "postgres";

CREATE TABLE IF NOT EXISTS "public"."countries_table_is_really_long_here" (
    "id" bigint NOT NULL,
    "name" "text",
    "iso2" "text" NOT NULL,
    "iso3" "text",
    "local_name" "text",
    "continent" "public"."continents"
);

ALTER TABLE "public"."countries_table_is_really_long_here" OWNER TO "postgres";

ALTER TABLE "public"."countries_table_is_really_long_here" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."countries_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

ALTER TABLE "public"."countries" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."countries_id_seq1"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

CREATE TABLE IF NOT EXISTS "public"."eeeeee" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

ALTER TABLE "public"."eeeeee" OWNER TO "postgres";

ALTER TABLE "public"."eeeeee" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."eeeeee_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

CREATE TABLE IF NOT EXISTS "public"."event" (
    "id" integer NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "event_creation_date" timestamp with time zone NOT NULL,
    "event_last_update_date" timestamp with time zone NOT NULL,
    "event_title" "text",
    "event_start_date" timestamp with time zone,
    "event_end_date" timestamp with time zone,
    "event_location_city" "text",
    "event_location_full_address" "text",
    "event_location_url" "text",
    "event_registration_method" "text",
    "event_registration_detail" "text",
    "event_description" "text",
    "event_facebook_url" "text" NOT NULL,
    "event_location_country" "text",
    "event_location_coordinates" "extensions"."geography",
    "event_picture" "text",
    "event_fb_header_dates" "text",
    "is_online" boolean,
    "categorised_by_ai" boolean
);

ALTER TABLE "public"."event" OWNER TO "postgres";

CREATE SEQUENCE IF NOT EXISTS "public"."event_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE "public"."event_id_seq" OWNER TO "postgres";

ALTER SEQUENCE "public"."event_id_seq" OWNED BY "public"."event"."id";

CREATE TABLE IF NOT EXISTS "public"."newwwwww" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "tester" boolean
);

ALTER TABLE "public"."newwwwww" OWNER TO "postgres";

ALTER TABLE "public"."newwwwww" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."newwwwww_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

CREATE TABLE IF NOT EXISTS "public"."testtttt" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "json1" "jsonb",
    "json2" "jsonb"
);

ALTER TABLE "public"."testtttt" OWNER TO "postgres";

ALTER TABLE "public"."testtttt" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."testtttt_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

CREATE TABLE IF NOT EXISTS "public"."users" (
    "id" bigint NOT NULL,
    "bool" boolean
);

ALTER TABLE "public"."users" OWNER TO "postgres";

ALTER TABLE "public"."users" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."users_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

CREATE TABLE IF NOT EXISTS "public"."weird_kiwi_words" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "title" "text",
    "description" "text",
    "wtf_level" numeric,
    "user_id" bigint
);

ALTER TABLE "public"."weird_kiwi_words" OWNER TO "postgres";

ALTER TABLE "public"."weird_kiwi_words" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."weird_kiwi_words_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

CREATE OR REPLACE VIEW "public"."weird_kiwi_words_view" AS
 SELECT "weird_kiwi_words"."id",
    "weird_kiwi_words"."created_at",
    "weird_kiwi_words"."title",
    "weird_kiwi_words"."description",
    "weird_kiwi_words"."wtf_level"
   FROM "public"."weird_kiwi_words";

ALTER TABLE "public"."weird_kiwi_words_view" OWNER TO "postgres";

ALTER TABLE ONLY "new_schema"."test" ALTER COLUMN "id" SET DEFAULT "nextval"('"new_schema"."marketing_id_seq"'::"regclass");

ALTER TABLE ONLY "public"."event" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."event_id_seq"'::"regclass");

ALTER TABLE ONLY "new_schema"."test2"
    ADD CONSTRAINT "aeuaeu_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "new_schema"."test"
    ADD CONSTRAINT "marketing_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."countries_table_is_really_long_here"
    ADD CONSTRAINT "countries_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."countries"
    ADD CONSTRAINT "countries_pkey1" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."eeeeee"
    ADD CONSTRAINT "eeeeee_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."event"
    ADD CONSTRAINT "event_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."newwwwww"
    ADD CONSTRAINT "newwwwww_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."testtttt"
    ADD CONSTRAINT "testtttt_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."users"
    ADD CONSTRAINT "users_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."weird_kiwi_words"
    ADD CONSTRAINT "weird_kiwi_words_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."weird_kiwi_words"
    ADD CONSTRAINT "fk_weird_kiwi_words_users" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id");

ALTER TABLE "new_schema"."test2" ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Enable read access for all users" ON "public"."eeeeee" FOR SELECT USING (true);

CREATE POLICY "Enable read access for all users" ON "public"."users" FOR SELECT USING (true);

CREATE POLICY "Enable read access for all users, again" ON "public"."users" FOR SELECT USING (true);

ALTER TABLE "public"."countries" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."eeeeee" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."newwwwww" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."testtttt" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."users" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."weird_kiwi_words" ENABLE ROW LEVEL SECURITY;

REVOKE USAGE ON SCHEMA "public" FROM PUBLIC;
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";

GRANT ALL ON FUNCTION "public"."create_activity"("name" "text", "case_id" "uuid", "assigned_to" "uuid", "description" "text", "created_by" "uuid", "due_date" timestamp with time zone) TO "anon";
GRANT ALL ON FUNCTION "public"."create_activity"("name" "text", "case_id" "uuid", "assigned_to" "uuid", "description" "text", "created_by" "uuid", "due_date" timestamp with time zone) TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_activity"("name" "text", "case_id" "uuid", "assigned_to" "uuid", "description" "text", "created_by" "uuid", "due_date" timestamp with time zone) TO "service_role";

GRANT ALL ON FUNCTION "public"."get_page_parents"("page_id" bigint) TO "anon";
GRANT ALL ON FUNCTION "public"."get_page_parents"("page_id" bigint) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_page_parents"("page_id" bigint) TO "service_role";

GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "service_role";

GRANT ALL ON FUNCTION "public"."insert_users"() TO "anon";
GRANT ALL ON FUNCTION "public"."insert_users"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."insert_users"() TO "service_role";

GRANT ALL ON FUNCTION "public"."insert_users_and_identities"() TO "anon";
GRANT ALL ON FUNCTION "public"."insert_users_and_identities"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."insert_users_and_identities"() TO "service_role";

GRANT ALL ON TABLE "public"."blobs" TO "anon";
GRANT ALL ON TABLE "public"."blobs" TO "authenticated";
GRANT ALL ON TABLE "public"."blobs" TO "service_role";

GRANT ALL ON TABLE "public"."countries" TO "anon";
GRANT ALL ON TABLE "public"."countries" TO "authenticated";
GRANT ALL ON TABLE "public"."countries" TO "service_role";

GRANT ALL ON TABLE "public"."countries_table_is_really_long_here" TO "anon";
GRANT ALL ON TABLE "public"."countries_table_is_really_long_here" TO "authenticated";
GRANT ALL ON TABLE "public"."countries_table_is_really_long_here" TO "service_role";

GRANT ALL ON SEQUENCE "public"."countries_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."countries_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."countries_id_seq" TO "service_role";

GRANT ALL ON SEQUENCE "public"."countries_id_seq1" TO "anon";
GRANT ALL ON SEQUENCE "public"."countries_id_seq1" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."countries_id_seq1" TO "service_role";

GRANT ALL ON TABLE "public"."eeeeee" TO "anon";
GRANT ALL ON TABLE "public"."eeeeee" TO "authenticated";
GRANT ALL ON TABLE "public"."eeeeee" TO "service_role";

GRANT ALL ON SEQUENCE "public"."eeeeee_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."eeeeee_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."eeeeee_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."event" TO "anon";
GRANT ALL ON TABLE "public"."event" TO "authenticated";
GRANT ALL ON TABLE "public"."event" TO "service_role";

GRANT ALL ON SEQUENCE "public"."event_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."event_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."event_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."newwwwww" TO "anon";
GRANT ALL ON TABLE "public"."newwwwww" TO "authenticated";
GRANT ALL ON TABLE "public"."newwwwww" TO "service_role";

GRANT ALL ON SEQUENCE "public"."newwwwww_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."newwwwww_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."newwwwww_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."testtttt" TO "anon";
GRANT ALL ON TABLE "public"."testtttt" TO "authenticated";
GRANT ALL ON TABLE "public"."testtttt" TO "service_role";

GRANT ALL ON SEQUENCE "public"."testtttt_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."testtttt_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."testtttt_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."users" TO "anon";
GRANT ALL ON TABLE "public"."users" TO "authenticated";
GRANT ALL ON TABLE "public"."users" TO "service_role";

GRANT ALL ON SEQUENCE "public"."users_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."users_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."users_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."weird_kiwi_words" TO "anon";
GRANT ALL ON TABLE "public"."weird_kiwi_words" TO "authenticated";
GRANT ALL ON TABLE "public"."weird_kiwi_words" TO "service_role";

GRANT ALL ON SEQUENCE "public"."weird_kiwi_words_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."weird_kiwi_words_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."weird_kiwi_words_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."weird_kiwi_words_view" TO "anon";
GRANT ALL ON TABLE "public"."weird_kiwi_words_view" TO "authenticated";
GRANT ALL ON TABLE "public"."weird_kiwi_words_view" TO "service_role";

ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "service_role";

ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "service_role";

ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "service_role";

RESET ALL;
