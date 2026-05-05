BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "leaderboard_entry" (
    "id" bigserial PRIMARY KEY,
    "points" bigint NOT NULL,
    "name" text NOT NULL,
    "books" bigint NOT NULL,
    "pages" bigint NOT NULL,
    "email" text,
    "userId" bigint NOT NULL
);

-- Indexes
CREATE INDEX "leaderboard_user_id_idx" ON "leaderboard_entry" USING btree ("userId");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "user" (
    "id" bigserial PRIMARY KEY,
    "authUserId" uuid NOT NULL,
    "username" text,
    "bio" text,
    "createdAt" timestamp without time zone,
    "updatedAt" timestamp without time zone
);

-- Indexes
CREATE INDEX "user_auth_id_idx" ON "user" USING btree ("authUserId");

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "leaderboard_entry"
    ADD CONSTRAINT "leaderboard_entry_fk_0"
    FOREIGN KEY("userId")
    REFERENCES "user"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "user"
    ADD CONSTRAINT "user_fk_0"
    FOREIGN KEY("authUserId")
    REFERENCES "serverpod_auth_core_user"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;


--
-- MIGRATION VERSION FOR project_thera
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('project_thera', '20260112150526198', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260112150526198', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20251208110333922-v3-0-0', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20251208110333922-v3-0-0', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod_auth_idp
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod_auth_idp', '20260109031533194', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260109031533194', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod_auth_core
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod_auth_core', '20251208110412389-v3-0-0', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20251208110412389-v3-0-0', "timestamp" = now();


COMMIT;
