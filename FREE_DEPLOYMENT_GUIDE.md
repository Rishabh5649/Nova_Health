# Free Deployment Guide for Nova Health HMS

This guide uses **100% free services** to host your application.

## 1. Database (Supabase)
We will use Supabase for a free, high-performance PostgreSQL database.

1.  Go to [Supabase.com](https://supabase.com/) and Sign Up.
2.  Click **"New Project"**.
3.  Enter a Name (e.g., `NovaHealthDB`) and a strong Database Password (SAVE THIS!).
4.  Select a Region close to you (e.g., Mumbai, Singapore).
5.  Click **Create New Project**.
6.  Once the project is ready (takes ~2 mins):
    *   Go to **Project Settings** (Gear icon) -> **Database**.
    *   Under **Connection String** -> **URI**, copy the connection string.
    *   It will look like: `postgresql://postgres:[YOUR-PASSWORD]@db.project.supabase.co:5432/postgres`
    *   **Replace `[YOUR-PASSWORD]`** with the password you created in step 3.
    *   **Keep this URL safe.** This is your `DATABASE_URL`.

---

## 2. Code Preparation (GitHub)
You need your code on GitHub to deploy it.

1.  Go to [GitHub.com](https://github.com/) and create a new Repository (e.g., `nova-health`).
2.  Open your local terminal in the project folder (`c:\Users\risha\dev\hms`) and run:
    ```bash
    git remote add origin https://github.com/YOUR_GITHUB_USERNAME/nova-health.git
    git branch -M main
    git push -u origin main
    ```

---

## 3. Backend API (Render)
Render offers a free tier for hosting Node.js apps. *Note: The free tier spins down after inactivity, so the first request might take 30-50s.*

1.  Go to [Render.com](https://render.com/) and Sign Up with GitHub.
2.  Click **New +** -> **Web Service**.
3.  Select your `nova-health` repository.
4.  **Configure the service**:
    *   **Name**: `nova-health-api`
    *   **Root Directory**: `apps/api`
    *   **Environment**: `Node`
    *   **Build Command**: `npm install && npx prisma generate && npm run build`
    *   **Start Command**: `npm run start:prod`
    *   **Instance Type**: `Free`
5.  **Environment Variables** (Click "Advanced"):
    *   Key: `DATABASE_URL`
    *   Value: (Paste your Supabase connection string from Step 1)
    *   Key: `JWT_SECRET`
    *   Value: (Enter a random secret word, e.g., `supersecretkey123`)
    *   Key: `NODE_VERSION`
    *   Value: `18` (Optional, ensuring compatibility)
6.  Click **Create Web Service**.
7.  Wait for the deployment to finish. You will get a URL like `https://nova-health-api.onrender.com`. **Copy this URL.**

---

## 4. Website / Admin Portal (Vercel)
Vercel is the best place to host the Next.js frontend.

1.  Go to [Vercel.com](https://vercel.com/) and Sign Up with GitHub.
2.  Click **Add New...** -> **Project**.
3.  Import your `nova-health` repository.
4.  **Configure Project**:
    *   **Root Directory**: Click "Edit" and select `apps/admin-web`.
    *   **Environment Variables**:
        *   Key: `NEXT_PUBLIC_API_URL`
        *   Value: (Paste your Render Backend URL from Step 3, e.g., `https://nova-health-api.onrender.com`)
5.  Click **Deploy**.
6.  Once done, you will get a URL like `https://nova-health.vercel.app`. This is your live website!

---

## 5. Mobile App (Manual Build)
Since Google Play ($25) and Apple App Store ($99) are not free, we will generate the app file manually.

### Initial Setup (One time)
1.  Open `hms_frontend_flutter/lib/core/env.dart`.
2.  Change the `baseUrl` to your **Render Backend URL**.
    ```dart
    static const baseUrl = 'https://nova-health-api.onrender.com';
    ```
3.  Commit this change:
    ```bash
    git add .
    git commit -m "Update API URL for production"
    git push
    ```

### Generate APK (Android)
1.  Open your terminal in `c:\Users\risha\dev\hms`.
2.  Run:
    ```powershell
    cd hms_frontend_flutter
    flutter build apk --release
    ```
3.  The file will be created at:
    `hms_frontend_flutter/build/app/outputs/flutter-apk/app-release.apk`
4.  **Share this file**: You can upload this `.apk` file to Google Drive, WhatsApp, or GitHub Releases and send the link to your users. They can download and install it directly.

---

### Summary of URLs
*   **Database**: Managed by Supabase
*   **Backend API**: `https://nova-health-api.onrender.com`
*   **Website**: `https://nova-health.vercel.app`
*   **App**: Download link you create for the APK.
