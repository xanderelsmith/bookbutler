# Serverpod Questions Answered

## 1. Why does data get lost when debugging in Serverpod?

Data loss during debugging in Serverpod typically happens for these reasons:

### Common Causes:

1. **Hot Reload / Hot Restart**: When you hot reload/restart your Flutter app, it doesn't affect the database. However, if you're restarting the Serverpod server itself, check if migrations are being applied correctly.

2. **Database Container Resets**: If your Docker container is being removed and recreated, data will be lost unless you're using persistent volumes. Your `docker-compose.yaml` already has persistent volumes configured (`project_thera_data`), which is good.

3. **Migration Issues**: If migrations fail or are applied incorrectly, you might see schema issues. Always run:
   ```bash
   dart run bin/main.dart --apply-migrations
   ```

4. **Debug Mode Database Resets**: Some IDEs might restart the database container. Check your Docker container status:
   ```bash
   docker ps -a
   docker-compose ps
   ```

### Solutions:

1. **Ensure Database Container is Running**:
   ```bash
   docker-compose up -d postgres
   ```

2. **Check Volume Persistence**:
   ```bash
   docker volume ls | grep project_thera
   ```

3. **Don't Use `docker-compose down -v`**: The `-v` flag removes volumes and deletes all data.

4. **Backup Before Major Changes**:
   ```bash
   docker exec project_thera_server-postgres-1 pg_dump -U postgres project_thera > backup.sql
   ```

5. **Check Serverpod Server Logs**: Look for any database connection errors or migration issues in your server logs.

## 2. Do you need to attach a User model to save username and bio?

**Yes!** While Serverpod's auth system has a `Profile` table with `userName` and `fullName`, it's better to create your own `User` model for custom fields like `bio` and to have full control.

The `serverpod_auth_core_profile` table has:
- `userName` (text)
- `fullName` (text)
- `email` (text)
- But **no `bio` field**

### Solution: Create a Custom User Model

See the implementation files:
- `project_thera_server/lib/src/user/user.dart` - User model linked to AuthUser
- `project_thera_server/lib/src/user/user_endpoint.dart` - Endpoints to get/update user

This model:
- Links to `AuthUser` via `authUserId`
- Stores `username` and `bio`
- Can be extended with more custom fields later

## 3. How to implement push notifications from Serverpod?

Serverpod doesn't have built-in push notifications. You need to integrate with Firebase Cloud Messaging (FCM) for Android and Apple Push Notification Service (APNs) for iOS.

### Implementation Steps:

#### Step 1: Set up FCM/APNs on Flutter Side

1. Add dependencies to `project_thera/pubspec.yaml`:
   ```yaml
   dependencies:
     firebase_core: ^3.0.0
     firebase_messaging: ^15.0.0
   ```

2. Get FCM token on the client and send it to your Serverpod server.

#### Step 2: Store Device Tokens on Server

Create a `UserDevice` model to store FCM/APNs tokens:
- `userId` (links to your User model)
- `deviceToken` (FCM token or APNs token)
- `platform` (android/ios)
- `createdAt`

#### Step 3: Send Notifications from Server

Use the `http` package on the server to send HTTP requests to:
- **FCM**: `https://fcm.googleapis.com/fcm/send` (requires Firebase Server Key)
- **APNs**: Apple's APNs API (requires APNs certificates)

### Example Flow:

1. User logs in → Flutter app gets FCM token → Sends token to Serverpod
2. Serverpod stores token in database
3. When you want to send a notification → Serverpod makes HTTP request to FCM/APNs
4. FCM/APNs delivers notification to device

### Notes:

- You'll need Firebase project setup for FCM
- You'll need Apple Developer account and APNs certificates for iOS
- Consider using a package like `firebase_admin` or `apns` on the server side to simplify sending notifications

See `PUSH_NOTIFICATIONS_IMPLEMENTATION.md` for detailed implementation guide.

## 4. How do I deploy my Serverpod project?

Deployment can be done via **Globe.dev** (easiest), **AWS/GCP** (using Terraform), or **Self-Hosted Docker**.

See `DEPLOYMENT.md` for a comprehensive guide on all these methods.
