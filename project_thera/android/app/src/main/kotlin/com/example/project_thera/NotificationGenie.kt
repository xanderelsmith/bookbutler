package com.example.project_thera

import android.util.Log
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage

class NotificationGenie : FirebaseMessagingService() {

    override fun onNewToken(token: String) {
        super.onNewToken(token)
        Log.d(TAG, "Refreshed token: $token")
        // Note: The token is also handled by the Flutter plugin.
    }

    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        // Log the message for debugging
        Log.d(TAG, "From: ${remoteMessage.from}")

        // Check if message contains a data payload.
        if (remoteMessage.data.isNotEmpty()) {
            Log.d(TAG, "Message data payload: ${remoteMessage.data}")
        }

        // Check if message contains a notification payload.
        remoteMessage.notification?.let {
            Log.d(TAG, "Message Notification Body: ${it.body}")
        }
        
        // Allow the default behavior (or Flutter plugin) to process if needed, 
        // but note that defining this service in Manifest might perform exclusive handling 
        // depending on priority. 
        super.onMessageReceived(remoteMessage)
    }

    companion object {
        private const val TAG = "NotificationGenie"
    }
}
