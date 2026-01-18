package com.example.project_thera

import android.content.ContentUris
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.DocumentsContract
import android.provider.MediaStore
import android.provider.OpenableColumns
import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.*
import java.util.*
import kotlin.collections.ArrayList

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.project_thera/storage_access"
    private val REQUEST_CODE_OPEN_DIRECTORY = 1001
    private var pendingResult: MethodChannel.Result? = null
    private var pendingScanResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "openDirectoryPicker" -> {
                    pendingResult = result
                    openDirectoryPicker()
                }
                "scanDirectory" -> {
                    val uriString = call.argument<String>("uri") ?: ""
                    if (uriString.isEmpty()) {
                        result.error("INVALID_ARGUMENT", "URI is empty", null)
                    } else {
                        pendingScanResult = result
                        scanDirectory(Uri.parse(uriString))
                    }
                }
                "copyContentUriToFile" -> {
                    val uriString = call.argument<String>("contentUri") ?: ""
                    val bookId = call.argument<String>("bookId") ?: ""
                    val fileName = call.argument<String>("originalFileName")
                    val cachedPath = call.argument<String>("cachedPath")
                    
                    if (uriString.isEmpty() || bookId.isEmpty()) {
                        result.error("INVALID_ARGUMENT", "contentUri or bookId is empty", null)
                    } else {
                        copyContentUriToFile(Uri.parse(uriString), bookId, fileName, cachedPath, result)
                    }
                }
                "takePersistableUriPermission" -> {
                    val uriString = call.argument<String>("uri") ?: ""
                    if (uriString.isEmpty()) {
                        result.error("INVALID_ARGUMENT", "URI is empty", null)
                    } else {
                        takePersistablePermission(Uri.parse(uriString))
                        result.success(true)
                    }
                }
                "clearCache" -> {
                    val success = clearCache()
                    result.success(success)
                }
                "searchBooksWithMediaStore" -> {
                    pendingScanResult = result
                    searchBooksWithMediaStore()
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun openDirectoryPicker() {
        try {
            val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
                flags = Intent.FLAG_GRANT_READ_URI_PERMISSION or
                        Intent.FLAG_GRANT_WRITE_URI_PERMISSION or
                        Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION
            }
            startActivityForResult(intent, REQUEST_CODE_OPEN_DIRECTORY)
        } catch (e: Exception) {
            Log.e("MainActivity", "Error opening directory picker: ${e.message}")
            pendingResult?.error("PICKER_ERROR", e.message, null)
            pendingResult = null
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode == REQUEST_CODE_OPEN_DIRECTORY) {
            if (resultCode == RESULT_OK && data != null) {
                val treeUri = data.data
                if (treeUri != null) {
                    try {
                        // Take persistable permission
                        contentResolver.takePersistableUriPermission(
                            treeUri,
                            Intent.FLAG_GRANT_READ_URI_PERMISSION
                        )
                        
                        pendingResult?.success(treeUri.toString())
                    } catch (e: SecurityException) {
                        Log.e("MainActivity", "Error taking persistable permission: ${e.message}")
                        pendingResult?.error("PERMISSION_ERROR", e.message, null)
                    }
                } else {
                    pendingResult?.error("NO_URI", "No URI returned from picker", null)
                }
            } else {
                pendingResult?.error("CANCELLED", "User cancelled directory selection", null)
            }
            pendingResult = null
        }
        super.onActivityResult(requestCode, resultCode, data)
    }

    private fun takePersistablePermission(uri: Uri) {
        try {
            contentResolver.takePersistableUriPermission(
                uri,
                Intent.FLAG_GRANT_READ_URI_PERMISSION
            )
        } catch (e: SecurityException) {
            Log.e("MainActivity", "Error taking persistable permission: ${e.message}")
        }
    }

    private fun copyContentUriToFile(
        contentUri: Uri,
        bookId: String,
        fileName: String?,
        cachedPath: String?,
        result: MethodChannel.Result
    ) {
        try {
            // Get internal storage directory
            val internalDir = File(filesDir, "books")
            if (!internalDir.exists()) {
                internalDir.mkdirs()
            }

            // Determine output filename
            val extension = fileName?.substringAfterLast('.', "") ?: "pdf"
            val outputFileName = if (extension.isNotEmpty()) "$bookId.$extension" else "$bookId"
            val outputFile = File(internalDir, outputFileName)

            // Get file name from URI if not provided
            var displayName = fileName ?: "book"
            try {
                contentResolver.query(contentUri, null, null, null, null)?.use { cursor ->
                    if (cursor.moveToFirst()) {
                        val nameIndex = cursor.getColumnIndex(DocumentsContract.Document.COLUMN_DISPLAY_NAME)
                        if (nameIndex >= 0) {
                            displayName = cursor.getString(nameIndex) ?: displayName
                        }
                    }
                }
            } catch (e: Exception) {
                Log.w("MainActivity", "Could not get display name from URI: ${e.message}")
            }

            // Optimize: Use cached file if available (faster than reading from content URI)
            val cachedFile = cachedPath?.let { File(it) }
            if (cachedFile != null && cachedFile.exists()) {
                Log.d("MainActivity", "Using cached file for faster copy: ${cachedFile.absolutePath}")
                // Copy from cached file instead of content URI (much faster)
                FileInputStream(cachedFile).use { input ->
                    FileOutputStream(outputFile).use { output ->
                        input.copyTo(output)
                    }
                }
            } else {
                // Fallback to copying from content URI if no cached file
                Log.d("MainActivity", "No cached file available, copying from content URI")
                contentResolver.openInputStream(contentUri)?.use { input ->
                    FileOutputStream(outputFile).use { output ->
                        input.copyTo(output)
                    }
                } ?: run {
                    result.error("COPY_FAILED", "Could not open input stream from URI", null)
                    return
                }
            }

            result.success(mapOf(
                "path" to outputFile.absolutePath,
                "fileName" to displayName
            ))
        } catch (e: FileNotFoundException) {
            Log.e("MainActivity", "File not found: ${e.message}")
            result.error("FILE_NOT_FOUND", e.message, null)
        } catch (e: IOException) {
            Log.e("MainActivity", "IO error copying file: ${e.message}")
            result.error("IO_ERROR", e.message, null)
        } catch (e: Exception) {
            Log.e("MainActivity", "Error copying file: ${e.message}")
            result.error("COPY_FAILED", e.message, null)
        }
    }

    private fun scanDirectory(treeUri: Uri) {
        try {
            val files = ArrayList<Map<String, Any>>()
            val bookExtensions = listOf("pdf", "epub", "mobi", "fb2", "txt", "doc", "docx", "rtf", "html", "djvu")
            
            // Build document URI from tree URI
            val documentId = DocumentsContract.getTreeDocumentId(treeUri)
            val documentUri = DocumentsContract.buildDocumentUriUsingTree(treeUri, documentId)
            
            // Scan directory recursively
            scanDirectoryRecursive(treeUri, documentUri, files, bookExtensions)
            
            // Sort by name
            files.sortBy { it["name"] as String }
            
            pendingScanResult?.success(files)
        } catch (e: Exception) {
            Log.e("MainActivity", "Error scanning directory: ${e.message}")
            pendingScanResult?.error("SCAN_ERROR", e.message, null)
        } finally {
            pendingScanResult = null
        }
    }

    private fun scanDirectoryRecursive(
        treeUri: Uri,
        parentUri: Uri,
        files: ArrayList<Map<String, Any>>,
        bookExtensions: List<String>
    ) {
        try {
            val childrenUri = DocumentsContract.buildChildDocumentsUriUsingTree(
                treeUri,
                DocumentsContract.getDocumentId(parentUri)
            )

            contentResolver.query(
                childrenUri,
                arrayOf(
                    DocumentsContract.Document.COLUMN_DOCUMENT_ID,
                    DocumentsContract.Document.COLUMN_DISPLAY_NAME,
                    DocumentsContract.Document.COLUMN_MIME_TYPE,
                    DocumentsContract.Document.COLUMN_SIZE,
                    DocumentsContract.Document.COLUMN_FLAGS
                ),
                null,
                null,
                null
            )?.use { cursor ->
                while (cursor.moveToNext()) {
                    val documentId = cursor.getString(0) ?: continue
                    val displayName = cursor.getString(1) ?: continue
                    val mimeType = cursor.getString(2)
                    val size = cursor.getLong(3)
                    val flags = cursor.getInt(4)

                    val documentUri = DocumentsContract.buildDocumentUriUsingTree(treeUri, documentId)

                    val isDirectory = DocumentsContract.Document.MIME_TYPE_DIR == mimeType ||
                            (flags and DocumentsContract.Document.FLAG_DIR_SUPPORTS_CREATE) != 0

                    if (isDirectory) {
                        // Recursively scan subdirectories
                        scanDirectoryRecursive(treeUri, documentUri, files, bookExtensions)
                    } else {
                        // Check if it's a book file
                        val extension = displayName.substringAfterLast('.', "").lowercase()
                        if (extension.isNotEmpty() && bookExtensions.contains(extension)) {
                            // Automatically cache the file (like file_picker does)
                            val cachedFile = cacheFileFromUri(documentUri, displayName, applicationContext)
                            
                            val fileMap = mutableMapOf<String, Any>(
                                "path" to documentUri.toString(),
                                "name" to displayName,
                                "size" to size,
                                "extension" to extension
                            )
                            
                            // Add cached path if caching succeeded
                            if (cachedFile != null && cachedFile.exists()) {
                                fileMap["cachedPath"] = cachedFile.absolutePath
                                fileMap["cachedSize"] = cachedFile.length()
                            }
                            
                            files.add(fileMap)
                        }
                    }
                }
            }
        } catch (e: Exception) {
            Log.e("MainActivity", "Error scanning directory recursively: ${e.message}")
            // Continue scanning other directories even if one fails
        }
    }

    /**
     * Cache a file from content URI to temporary cache directory (similar to file_picker's openFileStream)
     * This allows faster access to files without repeatedly accessing the content URI
     */
    private fun cacheFileFromUri(
        contentUri: Uri,
        fileName: String,
        context: Context
    ): File? {
        try {
            // Use cache directory like file_picker does: cacheDir + "/file_picker/" + timestamp + "/" + fileName
            val cacheDir = File(context.cacheDir, "file_picker")
            val timestampDir = File(cacheDir, System.currentTimeMillis().toString())
            
            if (!timestampDir.exists()) {
                timestampDir.mkdirs()
            }
            
            val cachedFile = File(timestampDir, fileName.takeIf { it.isNotEmpty() } ?: "unnamed")
            
            // Check if file already exists (avoid re-caching)
            if (cachedFile.exists()) {
                return cachedFile
            }
            
            // Open and cache the file using ContentResolver (same approach as file_picker)
            var inputStream: InputStream? = null
            var outputStream: FileOutputStream? = null
            
            try {
                inputStream = context.contentResolver.openInputStream(contentUri)
                if (inputStream == null) {
                    Log.e("MainActivity", "Could not open input stream from URI: $contentUri")
                    return null
                }
                
                outputStream = FileOutputStream(cachedFile)
                
                // Copy using buffered streams (same buffer size as file_picker: 8192)
                val buffer = ByteArray(8192)
                var len: Int
                while (inputStream.read(buffer).also { len = it } >= 0) {
                    outputStream.write(buffer, 0, len)
                }
                
                // Flush and sync to ensure data is written to disk
                outputStream.flush()
                outputStream.fd?.sync()
                
                return cachedFile
            } catch (e: FileNotFoundException) {
                Log.e("MainActivity", "File not found while caching: ${e.message}", e)
                // Clean up partial file if exists
                if (cachedFile.exists()) {
                    cachedFile.delete()
                }
                return null
            } catch (e: IOException) {
                Log.e("MainActivity", "IO error while caching file: ${e.message}", e)
                // Clean up partial file if exists
                if (cachedFile.exists()) {
                    cachedFile.delete()
                }
                return null
            } finally {
                try {
                    inputStream?.close()
                    outputStream?.close()
                } catch (e: IOException) {
                    Log.e("MainActivity", "Error closing streams: ${e.message}", e)
                }
            }
        } catch (e: Exception) {
            Log.e("MainActivity", "Error caching file: ${e.message}", e)
            return null
        }
    }

    /**
     * Clear the cache directory (similar to file_picker's clearCache)
     * Removes all cached files from the temporary cache directory
     */
    private fun clearCache(): Boolean {
        return try {
            val cacheDir = File(applicationContext.cacheDir, "file_picker")
            recursiveDeleteFile(cacheDir)
            true
        } catch (e: Exception) {
            Log.e("MainActivity", "Error clearing cache: ${e.message}", e)
            false
        }
    }

    /**
     * Recursively delete a file or directory
     */
    private fun recursiveDeleteFile(file: File?) {
        if (file == null || !file.exists()) {
            return
        }
        
        if (file.isDirectory) {
            file.listFiles()?.forEach { child ->
                recursiveDeleteFile(child)
            }
        }
        
        file.delete()
    }

    /**
     * Search for book files using MediaStore API (no directory access required)
     * This searches common locations like Downloads, Documents, etc.
     */
    private fun searchBooksWithMediaStore() {
        try {
            val files = ArrayList<Map<String, Any>>()
            val bookExtensions = listOf("pdf", "epub", "mobi", "fb2", "txt", "doc", "docx", "rtf", "html", "djvu")
            val bookMimeTypes = listOf(
                "application/pdf",
                "application/epub+zip",
                "application/x-mobipocket-ebook",
                "application/x-fictionbook+xml",
                "text/plain",
                "application/msword",
                "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
                "application/rtf",
                "text/html",
                "image/vnd.djvu"
            )

            // Search in Downloads and Documents using MediaStore
            val collection = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                MediaStore.Files.getContentUri(MediaStore.VOLUME_EXTERNAL)
            } else {
                MediaStore.Files.getContentUri("external")
            }

            val projection = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                arrayOf(
                    MediaStore.Files.FileColumns._ID,
                    MediaStore.Files.FileColumns.DISPLAY_NAME,
                    MediaStore.Files.FileColumns.SIZE,
                    MediaStore.Files.FileColumns.MIME_TYPE,
                    MediaStore.Files.FileColumns.RELATIVE_PATH
                )
            } else {
                arrayOf(
                    MediaStore.Files.FileColumns._ID,
                    MediaStore.Files.FileColumns.DISPLAY_NAME,
                    MediaStore.Files.FileColumns.SIZE,
                    MediaStore.Files.FileColumns.MIME_TYPE,
                    MediaStore.Files.FileColumns.DATA
                )
            }

            // Build selection query for book file extensions
            val selectionBuilder = StringBuilder()
            selectionBuilder.append("(")
            
            // Add MIME type filters
            bookMimeTypes.forEachIndexed { index, mimeType ->
                if (index > 0) selectionBuilder.append(" OR ")
                selectionBuilder.append("${MediaStore.Files.FileColumns.MIME_TYPE} = ?")
            }
            
            // Add file extension filters (for files that might not have correct MIME type)
            selectionBuilder.append(") OR (")
            bookExtensions.forEachIndexed { index, ext ->
                if (index > 0) selectionBuilder.append(" OR ")
                selectionBuilder.append("LOWER(${MediaStore.Files.FileColumns.DISPLAY_NAME}) LIKE ?")
            }
            selectionBuilder.append(")")

            val selectionArgs = mutableListOf<String>()
            selectionArgs.addAll(bookMimeTypes)
            bookExtensions.forEach { ext ->
                selectionArgs.add("%.$ext")
            }

            // Filter to Downloads and Documents folders (only on Android 10+)
            val finalSelection = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                val pathFilter = "(${MediaStore.Files.FileColumns.RELATIVE_PATH} LIKE ? OR ${MediaStore.Files.FileColumns.RELATIVE_PATH} LIKE ?)"
                selectionArgs.add("%/Download/%")
                selectionArgs.add("%/Documents/%")
                "$selectionBuilder AND $pathFilter"
            } else {
                // On older Android versions, filter by DATA path
                val pathFilter = "(${MediaStore.Files.FileColumns.DATA} LIKE ? OR ${MediaStore.Files.FileColumns.DATA} LIKE ?)"
                selectionArgs.add("%/Download/%")
                selectionArgs.add("%/Documents/%")
                "$selectionBuilder AND $pathFilter"
            }

            contentResolver.query(
                collection,
                projection,
                finalSelection,
                selectionArgs.toTypedArray(),
                "${MediaStore.Files.FileColumns.DISPLAY_NAME} ASC"
            )?.use { cursor ->
                val idColumn = cursor.getColumnIndexOrThrow(MediaStore.Files.FileColumns._ID)
                val nameColumn = cursor.getColumnIndexOrThrow(MediaStore.Files.FileColumns.DISPLAY_NAME)
                val sizeColumn = cursor.getColumnIndexOrThrow(MediaStore.Files.FileColumns.SIZE)
                val mimeTypeColumn = cursor.getColumnIndexOrThrow(MediaStore.Files.FileColumns.MIME_TYPE)

                while (cursor.moveToNext()) {
                    val id = cursor.getLong(idColumn)
                    val displayName = cursor.getString(nameColumn) ?: continue
                    val size = cursor.getLong(sizeColumn)
                    val mimeType = cursor.getString(mimeTypeColumn)

                    // Get content URI
                    val contentUri = ContentUris.withAppendedId(collection, id)

                    // Get file extension
                    val extension = displayName.substringAfterLast('.', "").lowercase()

                    // Verify it's a book file
                    if (extension.isNotEmpty() && bookExtensions.contains(extension)) {
                        // Cache the file automatically
                        val cachedFile = cacheFileFromUri(contentUri, displayName, applicationContext)

                        val fileMap = mutableMapOf<String, Any>(
                            "path" to contentUri.toString(),
                            "name" to displayName,
                            "size" to size,
                            "extension" to extension
                        )

                        // Add cached path if caching succeeded
                        if (cachedFile != null && cachedFile.exists()) {
                            fileMap["cachedPath"] = cachedFile.absolutePath
                            fileMap["cachedSize"] = cachedFile.length()
                        }

                        files.add(fileMap)
                    }
                }
            }

            // Sort by name
            files.sortBy { it["name"] as String }

            pendingScanResult?.success(files)
        } catch (e: Exception) {
            Log.e("MainActivity", "Error searching books with MediaStore: ${e.message}", e)
            pendingScanResult?.error("SEARCH_ERROR", e.message, null)
        } finally {
            pendingScanResult = null
        }
    }
}
