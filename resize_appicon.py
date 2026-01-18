#!/usr/bin/env python3
"""
Script to resize appicon.jpg for Android drawable folders.
Creates resized icons in the appropriate drawable-*dpi folders.
"""

import os
from PIL import Image

# Define the drawable folders and their icon sizes
DRAWABLE_CONFIGS = {
    'drawable-mdpi': 24,
    'drawable-hdpi': 36,
    'drawable-xhdpi': 48,
    'drawable-xxhdpi': 72,
    'drawable-xxxhdpi': 96,
}

# Notification icon sizes (same as launcher icons)
NOTIFICATION_CONFIGS = {
    'drawable-mdpi': 24,
    'drawable-hdpi': 36,
    'drawable-xhdpi': 48,
    'drawable-xxhdpi': 72,
    'drawable-xxxhdpi': 96,
}

# Paths
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
# Check if script is in thera_pod or project_thera directory
if os.path.basename(SCRIPT_DIR) == 'thera_pod':
    # Script is in parent directory, look in project_thera subdirectory
    PROJECT_DIR = os.path.join(SCRIPT_DIR, 'project_thera')
else:
    # Script is in project_thera directory
    PROJECT_DIR = SCRIPT_DIR

SOURCE_IMAGE = os.path.join(PROJECT_DIR, 'images', 'appicon.jpg')
RES_DIR = os.path.join(PROJECT_DIR, 'android', 'app', 'src', 'main', 'res')

print(f"Script directory: {SCRIPT_DIR}")
print(f"Project directory: {PROJECT_DIR}")
print(f"Source image: {SOURCE_IMAGE}")
print(f"Res directory: {RES_DIR}")
print()


def resize_appicon():
    """Resize appicon.jpg to different sizes for Android drawable folders."""
    
    print("[STEP 1] Checking source image...")
    # Check if source image exists
    if not os.path.exists(SOURCE_IMAGE):
        print(f"❌ ERROR: Source image not found!")
        print(f"   Expected location: {SOURCE_IMAGE}")
        print(f"   Absolute path: {os.path.abspath(SOURCE_IMAGE)}")
        print(f"   Directory exists: {os.path.exists(os.path.dirname(SOURCE_IMAGE))}")
        if os.path.exists(os.path.dirname(SOURCE_IMAGE)):
            print(f"   Files in directory: {os.listdir(os.path.dirname(SOURCE_IMAGE))}")
        return False
    print(f"✓ Source image found: {SOURCE_IMAGE}")
    
    print("\n[STEP 2] Loading source image...")
    # Load the source image
    try:
        img = Image.open(SOURCE_IMAGE)
        print(f"✓ Image loaded successfully")
        print(f"   Original size: {img.size[0]}x{img.size[1]} pixels")
        print(f"   Format: {img.format}")
        print(f"   Mode: {img.mode}")
    except FileNotFoundError as e:
        print(f"❌ ERROR: File not found!")
        print(f"   Details: {e}")
        return False
    except Exception as e:
        print(f"❌ ERROR: Failed to load image!")
        print(f"   Error type: {type(e).__name__}")
        print(f"   Details: {e}")
        return False
    
    print("\n[STEP 2.5] Removing background...")
    # Remove background and create transparent version
    try:
        # Convert to RGB first if needed (for corner detection)
        original_mode = img.mode
        if img.mode not in ('RGB', 'RGBA'):
            img_rgb = img.convert('RGB')
        else:
            img_rgb = img.convert('RGB')
        
        # Method 1: Corner-based background detection (more accurate)
        try:
            # Get corner pixels to determine background color
            width, height = img_rgb.size
            corners = [
                img_rgb.getpixel((0, 0)),
                img_rgb.getpixel((width-1, 0)),
                img_rgb.getpixel((0, height-1)),
                img_rgb.getpixel((width-1, height-1))
            ]
            
            # Average corner colors to get background color
            avg_r = sum(c[0] for c in corners) // len(corners)
            avg_g = sum(c[1] for c in corners) // len(corners)
            avg_b = sum(c[2] for c in corners) // len(corners)
            bg_color = (avg_r, avg_g, avg_b)
            
            print(f"   Detected background color: RGB{bg_color}")
            
            # Create mask: pixels similar to background color become transparent
            tolerance = 40  # Color difference tolerance (adjust if needed)
            img_rgba = img_rgb.convert('RGBA')
            data = img_rgba.getdata()
            new_data = []
            
            bg_r, bg_g, bg_b = bg_color
            
            for item in data:
                r, g, b, a = item
                # Calculate color distance from background
                color_distance = ((r - bg_r) ** 2 + (g - bg_g) ** 2 + (b - bg_b) ** 2) ** 0.5
                
                # If pixel is similar to background, make it transparent
                if color_distance < tolerance:
                    new_data.append((r, g, b, 0))  # Transparent
                else:
                    new_data.append((r, g, b, a if a < 255 else 255))  # Keep original
            
            img_no_bg = Image.new('RGBA', img_rgba.size)
            img_no_bg.putdata(new_data)
            img = img_no_bg
            print(f"✓ Background removed using corner detection method")
            
        except Exception as e:
            print(f"⚠️  Corner detection method failed, trying threshold method")
            print(f"   Error: {e}")
            
            # Method 2: Threshold-based (fallback for white/light backgrounds)
            img_rgba = img_rgb.convert('RGBA')
            data = img_rgba.getdata()
            new_data = []
            bg_threshold = 240  # Pixels brighter than this are considered background
            
            for item in data:
                r, g, b, a = item
                # If pixel is very light (white/light background), make it transparent
                if r > bg_threshold and g > bg_threshold and b > bg_threshold:
                    new_data.append((r, g, b, 0))  # Transparent
                else:
                    new_data.append((r, g, b, a if a < 255 else 255))
            
            img_no_bg = Image.new('RGBA', img_rgba.size)
            img_no_bg.putdata(new_data)
            img = img_no_bg
            print(f"✓ Background removed using threshold method")
        
        print(f"   Image now has transparent background")
    except Exception as e:
        print(f"⚠️  WARNING: Failed to remove background!")
        print(f"   Error type: {type(e).__name__}")
        print(f"   Details: {e}")
        print(f"   Continuing with original image (converted to RGBA)...")
        # Convert to RGBA anyway for transparency support
        if img.mode != 'RGBA':
            img = img.convert('RGBA')
    
    print("\n[STEP 3] Checking/creating res directory...")
    # Create res directory if it doesn't exist
    if not os.path.exists(RES_DIR):
        try:
            os.makedirs(RES_DIR)
            print(f"✓ Created res directory: {RES_DIR}")
        except Exception as e:
            print(f"❌ ERROR: Failed to create res directory!")
            print(f"   Path: {RES_DIR}")
            print(f"   Error type: {type(e).__name__}")
            print(f"   Details: {e}")
            return False
    else:
        print(f"✓ Res directory exists: {RES_DIR}")
    
    print("\n[STEP 4] Processing drawable folders...")
    # Process each drawable folder
    success_count = 0
    failed_folders = []
    
    for folder_name, size in DRAWABLE_CONFIGS.items():
        print(f"\n  Processing {folder_name} ({size}x{size}px)...")
        folder_path = os.path.join(RES_DIR, folder_name)
        
        # Create folder if it doesn't exist
        if not os.path.exists(folder_path):
            try:
                os.makedirs(folder_path)
                print(f"    ✓ Created folder: {folder_name}")
            except Exception as e:
                print(f"    ❌ ERROR: Failed to create folder!")
                print(f"       Path: {folder_path}")
                print(f"       Error: {e}")
                failed_folders.append(folder_name)
                continue
        else:
            print(f"    ✓ Folder exists: {folder_name}")
        
        # Resize image
        try:
            print(f"    → Resizing image to {size}x{size}px...")
            resized_img = img.resize((size, size), Image.Resampling.LANCZOS)
            print(f"    ✓ Image resized successfully")
        except Exception as e:
            print(f"    ❌ ERROR: Failed to resize image!")
            print(f"       Error type: {type(e).__name__}")
            print(f"       Details: {e}")
            failed_folders.append(folder_name)
            continue
        
        # Save as ic_launcher.png (Android standard naming)
        output_path = os.path.join(folder_path, 'ic_launcher.png')
        try:
            print(f"    → Saving to: {output_path}")
            resized_img.save(output_path, 'PNG')
            # Verify file was created
            if os.path.exists(output_path):
                file_size = os.path.getsize(output_path)
                print(f"    ✓ Created {folder_name}/ic_launcher.png ({size}x{size}px, {file_size} bytes)")
                success_count += 1
            else:
                print(f"    ❌ ERROR: File was not created!")
                print(f"       Expected: {output_path}")
                failed_folders.append(folder_name)
        except PermissionError as e:
            print(f"    ❌ ERROR: Permission denied!")
            print(f"       Path: {output_path}")
            print(f"       Details: {e}")
            failed_folders.append(folder_name)
        except Exception as e:
            print(f"    ❌ ERROR: Failed to save image!")
            print(f"       Path: {output_path}")
            print(f"       Error type: {type(e).__name__}")
            print(f"       Details: {e}")
            failed_folders.append(folder_name)
    
    print(f"\n[STEP 5] Creating notification icons (white/transparent)...")
    # Create white notification icons from the image with background removed
    notification_count = 0
    notification_failed_folders = []
    
    # Create a white version of the icon for notifications
    # Android requires white/transparent icons for notifications
    try:
        # Get alpha channel from original image (where there's content)
        if img.mode == 'RGBA':
            alpha = img.split()[3]
        else:
            alpha = Image.new('L', img.size, 255)
        
        # Create white icon: white pixels where there's content (non-transparent)
        img_white = Image.new('RGBA', img.size, (0, 0, 0, 0))
        white_pixels = Image.new('RGBA', img.size, (255, 255, 255, 255))
        
        # Use alpha channel as mask to create white silhouette
        img_white = Image.composite(white_pixels, img_white, alpha)
        
        print(f"✓ Created white notification icon template")
    except Exception as e:
        print(f"⚠️  WARNING: Failed to create white icon from source!")
        print(f"   Error type: {type(e).__name__}")
        print(f"   Details: {e}")
        print(f"   Will use original image with transparency for notifications")
        img_white = img  # Fallback to original
    
    for folder_name, size in NOTIFICATION_CONFIGS.items():
        print(f"\n  Processing notification icon {folder_name} ({size}x{size}px)...")
        folder_path = os.path.join(RES_DIR, folder_name)
        
        if not os.path.exists(folder_path):
            try:
                os.makedirs(folder_path)
                print(f"    ✓ Created folder: {folder_name}")
            except Exception as e:
                print(f"    ❌ ERROR: Failed to create folder!")
                print(f"       Path: {folder_path}")
                print(f"       Error: {e}")
                notification_failed_folders.append(folder_name)
                continue
        
        # Resize white notification icon
        try:
            print(f"    → Resizing notification icon to {size}x{size}px...")
            resized_notification = img_white.resize((size, size), Image.Resampling.LANCZOS)
            print(f"    ✓ Notification icon resized successfully")
        except Exception as e:
            print(f"    ❌ ERROR: Failed to resize notification icon!")
            print(f"       Error type: {type(e).__name__}")
            print(f"       Details: {e}")
            notification_failed_folders.append(folder_name)
            continue
        
        # Save as ic_notification.png
        output_path = os.path.join(folder_path, 'ic_notification.png')
        try:
            print(f"    → Saving notification icon to: {output_path}")
            resized_notification.save(output_path, 'PNG')
            if os.path.exists(output_path):
                file_size = os.path.getsize(output_path)
                print(f"    ✓ Created {folder_name}/ic_notification.png ({size}x{size}px, {file_size} bytes)")
                notification_count += 1
            else:
                print(f"    ❌ ERROR: Notification icon file was not created!")
                print(f"       Expected: {output_path}")
                notification_failed_folders.append(folder_name)
        except PermissionError as e:
            print(f"    ❌ ERROR: Permission denied!")
            print(f"       Path: {output_path}")
            print(f"       Details: {e}")
            notification_failed_folders.append(folder_name)
        except Exception as e:
            print(f"    ❌ ERROR: Failed to save notification icon!")
            print(f"       Path: {output_path}")
            print(f"       Error type: {type(e).__name__}")
            print(f"       Details: {e}")
            notification_failed_folders.append(folder_name)
    
    print(f"\n[STEP 6] Summary...")
    print(f"✅ Successfully created {success_count} launcher icon files!")
    print(f"✅ Successfully created {notification_count} notification icon files!")
    if failed_folders:
        print(f"❌ Failed to create {len(failed_folders)} launcher icon files:")
        for folder in failed_folders:
            print(f"   - {folder}")
    if notification_failed_folders:
        print(f"❌ Failed to create {len(notification_failed_folders)} notification icon files:")
        for folder in notification_failed_folders:
            print(f"   - {folder}")
    print(f"📁 All icons saved to: {RES_DIR}")
    return success_count == len(DRAWABLE_CONFIGS) and notification_count == len(NOTIFICATION_CONFIGS)


if __name__ == '__main__':
    print("=" * 60)
    print("Android App Icon Resizer")
    print("=" * 60)
    print()
    
    resize_appicon()
    
    print()
    print("=" * 60)
    print("Done!")
    print("=" * 60)
