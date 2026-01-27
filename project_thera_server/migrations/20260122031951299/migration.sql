BEGIN;

--
-- ACTION DROP TABLE
--
DROP TABLE "user_device" CASCADE;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "user_device" (
    "id" bigserial PRIMARY KEY,
    "userId" bigint NOT NULL,
    "deviceToken" text NOT NULL,
    "platform" text NOT NULL,
    "isActive" boolean NOT NULL,
    "createdAt" timestamp without time zone,
    "updatedAt" timestamp without time zone
);

-- Indexes
CREATE INDEX "user_device_user_id_idx" ON "user_device" USING btree ("userId");
CREATE UNIQUE INDEX "user_device_token_idx" ON "user_device" USING btree ("deviceToken");

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "user_device"
    ADD CONSTRAINT "user_device_fk_0"
    FOREIGN KEY("userId")
    REFERENCES "user"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;


--
-- MIGRATION VERSION FOR project_thera
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('project_thera', '20260122031951299', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260122031951299', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20251208110333922-v3-0-0', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20251208110333922-v3-0-0', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod_auth
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod_auth', '20250825102351908-v3-0-0', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20250825102351908-v3-0-0', "timestamp" = now();

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
