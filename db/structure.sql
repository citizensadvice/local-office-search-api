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

--
-- Name: tiger; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA tiger;


--
-- Name: tiger_data; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA tiger_data;


--
-- Name: topology; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA topology;


--
-- Name: SCHEMA topology; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA topology IS 'PostGIS Topology schema';


--
-- Name: fuzzystrmatch; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS fuzzystrmatch WITH SCHEMA public;


--
-- Name: EXTENSION fuzzystrmatch; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION fuzzystrmatch IS 'determine similarities and distance between strings';


--
-- Name: postgis; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public;


--
-- Name: EXTENSION postgis; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION postgis IS 'PostGIS geometry and geography spatial types and functions';


--
-- Name: postgis_tiger_geocoder; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS postgis_tiger_geocoder WITH SCHEMA tiger;


--
-- Name: EXTENSION postgis_tiger_geocoder; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION postgis_tiger_geocoder IS 'PostGIS tiger geocoder and reverse geocoder';


--
-- Name: postgis_topology; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS postgis_topology WITH SCHEMA topology;


--
-- Name: EXTENSION postgis_topology; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION postgis_topology IS 'PostGIS topology spatial types and functions';


--
-- Name: day_of_week; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.day_of_week AS ENUM (
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday'
);


--
-- Name: office_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.office_type AS ENUM (
    'member',
    'office',
    'outreach'
);


--
-- Name: opening_time_for_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.opening_time_for_type AS ENUM (
    'office',
    'telephone'
);


--
-- Name: time_subtype_diff(time without time zone, time without time zone); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.time_subtype_diff(x time without time zone, y time without time zone) RETURNS double precision
    LANGUAGE sql IMMUTABLE STRICT
    AS $$SELECT EXTRACT(EPOCH FROM (x - y))$$;


--
-- Name: timerange; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.timerange AS RANGE (
    subtype = time without time zone,
    multirange_type_name = public.timemultirange,
    subtype_diff = public.time_subtype_diff
);


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: local_authorities; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.local_authorities (
    id character(9) NOT NULL,
    name text NOT NULL
);


--
-- Name: offices; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.offices (
    id character(18) NOT NULL,
    legacy_id integer,
    office_type public.office_type NOT NULL,
    parent_id character(18),
    name text NOT NULL,
    about_text text,
    accessibility_information text[] DEFAULT '{}'::text[] NOT NULL,
    street text,
    city text,
    postcode text,
    location public.geography(Point,4326),
    email text,
    website text,
    phone text,
    opening_hours_information text,
    telephone_advice_hours_information text,
    membership_number character varying,
    company_number character varying,
    charity_number character varying,
    volunteer_roles text[] DEFAULT '{}'::text[] NOT NULL,
    county text,
    volunteer_recruitment_email text,
    allows_drop_ins boolean DEFAULT false NOT NULL
);


--
-- Name: opening_times; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.opening_times (
    id bigint NOT NULL,
    office_id character(18) NOT NULL,
    opening_time_for public.opening_time_for_type NOT NULL,
    day_of_week public.day_of_week NOT NULL,
    range public.timerange NOT NULL
);


--
-- Name: opening_times_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.opening_times_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: opening_times_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.opening_times_id_seq OWNED BY public.opening_times.id;


--
-- Name: postcodes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.postcodes (
    id bigint NOT NULL,
    canonical character varying(8) NOT NULL,
    normalised character varying(7) GENERATED ALWAYS AS (lower(replace((canonical)::text, ' '::text, ''::text))) STORED,
    location public.geography(Point,4326) NOT NULL,
    local_authority_id character(9) NOT NULL
);


--
-- Name: postcodes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.postcodes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: postcodes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.postcodes_id_seq OWNED BY public.postcodes.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: served_areas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.served_areas (
    id bigint NOT NULL,
    office_id character(18) NOT NULL,
    local_authority_id character(9) NOT NULL
);


--
-- Name: served_areas_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.served_areas_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: served_areas_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.served_areas_id_seq OWNED BY public.served_areas.id;


--
-- Name: opening_times id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.opening_times ALTER COLUMN id SET DEFAULT nextval('public.opening_times_id_seq'::regclass);


--
-- Name: postcodes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.postcodes ALTER COLUMN id SET DEFAULT nextval('public.postcodes_id_seq'::regclass);


--
-- Name: served_areas id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.served_areas ALTER COLUMN id SET DEFAULT nextval('public.served_areas_id_seq'::regclass);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: local_authorities local_authorities_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.local_authorities
    ADD CONSTRAINT local_authorities_pkey PRIMARY KEY (id);


--
-- Name: offices offices_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.offices
    ADD CONSTRAINT offices_pkey PRIMARY KEY (id);


--
-- Name: opening_times opening_times_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.opening_times
    ADD CONSTRAINT opening_times_pkey PRIMARY KEY (id);


--
-- Name: postcodes postcodes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.postcodes
    ADD CONSTRAINT postcodes_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: served_areas served_areas_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.served_areas
    ADD CONSTRAINT served_areas_pkey PRIMARY KEY (id);


--
-- Name: index_offices_on_legacy_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_offices_on_legacy_id ON public.offices USING btree (legacy_id);


--
-- Name: index_offices_on_membership_number_and_office_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_offices_on_membership_number_and_office_type ON public.offices USING btree (membership_number, office_type);


--
-- Name: index_offices_on_parent_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_offices_on_parent_id ON public.offices USING btree (parent_id);


--
-- Name: index_opening_times_on_office_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_opening_times_on_office_id ON public.opening_times USING btree (office_id);


--
-- Name: index_postcodes_on_local_authority_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_postcodes_on_local_authority_id ON public.postcodes USING btree (local_authority_id);


--
-- Name: index_postcodes_on_normalised; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_postcodes_on_normalised ON public.postcodes USING btree (normalised);


--
-- Name: index_served_areas_on_local_authority_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_served_areas_on_local_authority_id ON public.served_areas USING btree (local_authority_id);


--
-- Name: index_served_areas_on_office_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_served_areas_on_office_id ON public.served_areas USING btree (office_id);


--
-- Name: served_areas fk_rails_21c56aa565; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.served_areas
    ADD CONSTRAINT fk_rails_21c56aa565 FOREIGN KEY (office_id) REFERENCES public.offices(id);


--
-- Name: opening_times fk_rails_67a7efc4d6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.opening_times
    ADD CONSTRAINT fk_rails_67a7efc4d6 FOREIGN KEY (office_id) REFERENCES public.offices(id);


--
-- Name: postcodes fk_rails_7ab3384eab; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.postcodes
    ADD CONSTRAINT fk_rails_7ab3384eab FOREIGN KEY (local_authority_id) REFERENCES public.local_authorities(id) DEFERRABLE;


--
-- Name: served_areas fk_rails_90a03e3955; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.served_areas
    ADD CONSTRAINT fk_rails_90a03e3955 FOREIGN KEY (local_authority_id) REFERENCES public.local_authorities(id) DEFERRABLE;


--
-- Name: offices fk_rails_b381f08761; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.offices
    ADD CONSTRAINT fk_rails_b381f08761 FOREIGN KEY (parent_id) REFERENCES public.offices(id) DEFERRABLE;


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public, topology, tiger;

INSERT INTO "schema_migrations" (version) VALUES
('20240904130334'),
('20240813152802'),
('20231120143230'),
('20231120111349'),
('20230803145002'),
('20230803141746'),
('20230731104744'),
('20230705132647'),
('20230705095742'),
('20230704120347'),
('20230621151704'),
('20230531135320');

