# Supabase Storage Policies for `post-images` Bucket

This guide provides all the Row-Level Security (RLS) policies and SQL scripts needed to set up and secure the **`post-images`** storage bucket in Supabase.

---

## 1. Bucket Setup

Before applying RLS policies, ensure the bucket exists and is configured properly.

### SQL to Create Bucket
```sql
-- 1. Insert bucket into storage.buckets if not already existing
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'post-images',
  'post-images',
  true, -- Set to true so images can be publicly viewed in blog posts
  5242880, -- 5 MB file size limit in bytes (optional, adjust as needed)
  ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif'] -- Allowed image MIME types
)
ON CONFLICT (id) DO UPDATE SET
  public = EXCLUDED.public,
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types;
```

---

## 2. Storage RLS Policies (on `storage.objects`)

In Supabase, storage permissions are controlled via Row Level Security (RLS) on the `storage.objects` table.

---

### Option A: Recommended Secure Setup (User Folder Isolation)
> **Recommended**: File path in bucket follows the format: `<user_id>/<file_name>` (e.g. `c034945d-4f1b-4d43-a612-411a7bb0dc30/cover.jpg`).

#### 1. Public Read (SELECT)
Allows anyone (logged-in users and anonymous visitors) to view post images.
```sql
CREATE POLICY "Public Access for Post Images"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'post-images');
```

#### 2. Authenticated Upload (INSERT)
Allows authenticated users to upload images only into their own folder (`<auth.uid()>/...`).
```sql
CREATE POLICY "Authenticated users can upload post images to own folder"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'post-images' 
  AND (storage.foldername(name))[1] = auth.uid()::text
);
```

#### 3. Update / Overwrite (UPDATE)
Allows users to update/replace only the images in their own folder.
```sql
CREATE POLICY "Users can update their own post images"
ON storage.objects
FOR UPDATE
TO authenticated
USING (
  bucket_id = 'post-images' 
  AND (storage.foldername(name))[1] = auth.uid()::text
)
WITH CHECK (
  bucket_id = 'post-images' 
  AND (storage.foldername(name))[1] = auth.uid()::text
);
```

#### 4. Delete (DELETE)
Allows users to delete only images in their own folder.
```sql
CREATE POLICY "Users can delete their own post images"
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'post-images' 
  AND (storage.foldername(name))[1] = auth.uid()::text
);
```

---

### Option B: Simplified Setup (Any Authenticated User Can Upload)
> Use this if your client uploads directly to root or unique filenames without a user ID prefix. Ownership is tracked via `owner_id` / `owner` metadata or open to authenticated users.

#### 1. Public Read (SELECT)
```sql
CREATE POLICY "Public Access for Post Images"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'post-images');
```

#### 2. Authenticated Upload (INSERT)
```sql
CREATE POLICY "Authenticated users can upload post images"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'post-images');
```

#### 3. Owner Update (UPDATE)
```sql
CREATE POLICY "Owners can update post images"
ON storage.objects
FOR UPDATE
TO authenticated
USING (
  bucket_id = 'post-images'
  AND (auth.uid() = owner_id OR (storage.foldername(name))[1] = auth.uid()::text)
)
WITH CHECK (
  bucket_id = 'post-images'
  AND (auth.uid() = owner_id OR (storage.foldername(name))[1] = auth.uid()::text)
);
```

#### 4. Owner Delete (DELETE)
```sql
CREATE POLICY "Owners can delete post images"
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'post-images'
  AND (auth.uid() = owner_id OR (storage.foldername(name))[1] = auth.uid()::text)
);
```

---

## 3. All-in-One SQL Migration Script

You can copy and run this complete script directly in the **Supabase Dashboard > SQL Editor**:

```sql
-- 1. Enable RLS on storage.objects (enabled by default in Supabase)
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- 2. Create the 'post-images' bucket
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'post-images',
  'post-images',
  true,
  5242880, -- 5MB limit
  ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif']
)
ON CONFLICT (id) DO UPDATE SET
  public = EXCLUDED.public,
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types;

-- 3. Drop existing policies for 'post-images' if re-running
DROP POLICY IF EXISTS "Public can view post images" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can upload post images" ON storage.objects;
DROP POLICY IF EXISTS "Users can update own post images" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete own post images" ON storage.objects;

-- 4. Create Policies

-- SELECT: Anyone can read/download post images
CREATE POLICY "Public can view post images"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'post-images');

-- INSERT: Authenticated users can upload to their own user folder
CREATE POLICY "Authenticated users can upload post images"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'post-images' 
  AND (storage.foldername(name))[1] = auth.uid()::text
);

-- UPDATE: Users can modify their own post images
CREATE POLICY "Users can update own post images"
ON storage.objects
FOR UPDATE
TO authenticated
USING (
  bucket_id = 'post-images' 
  AND (storage.foldername(name))[1] = auth.uid()::text
)
WITH CHECK (
  bucket_id = 'post-images' 
  AND (storage.foldername(name))[1] = auth.uid()::text
);

-- DELETE: Users can delete their own post images
CREATE POLICY "Users can delete own post images"
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'post-images' 
  AND (storage.foldername(name))[1] = auth.uid()::text
);
```

---

## 4. Setting Up via Supabase Dashboard (UI)

If you prefer using the Supabase Web UI:

1. Go to **Storage** > **New bucket**.
2. Name the bucket: `post-images`.
3. Toggle **Public bucket** to `ON` (so image URLs can be rendered in the blog feed).
4. Save the bucket.
5. Go to **Storage** > **Policies** > find `post-images`.
6. Click **New policy**:
   - **For SELECT**:
     - Template: *Give users access to select/read files*.
     - Target roles: `anon`, `authenticated` (or `public`).
     - USING expression: `bucket_id = 'post-images'`.
   - **For INSERT**:
     - Target roles: `authenticated`.
     - WITH CHECK expression: `bucket_id = 'post-images' AND (storage.foldername(name))[1] = auth.uid()::text`.
   - **For UPDATE**:
     - Target roles: `authenticated`.
     - USING & WITH CHECK expression: `bucket_id = 'post-images' AND (storage.foldername(name))[1] = auth.uid()::text`.
   - **For DELETE**:
     - Target roles: `authenticated`.
     - USING expression: `bucket_id = 'post-images' AND (storage.foldername(name))[1] = auth.uid()::text`.

---

## 5. Dart / Flutter Upload Example

When uploading from your Flutter app, structure the path with the user ID:

```dart
final userId = supabase.auth.currentUser!.id;
final fileExtension = file.path.split('.').last;
final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
final storagePath = '$userId/$fileName';

// Upload
await supabase.storage.from('post-images').upload(
  storagePath,
  file,
  fileOptions: FileOptions(
    contentType: 'image/$fileExtension',
    upsert: false,
  ),
);

// Get Public URL
final publicUrl = supabase.storage.from('post-images').getPublicUrl(storagePath);
```
