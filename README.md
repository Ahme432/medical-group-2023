# Medical Group 2023 - Attendance Registration

## Overview
This is a Flutter Web application designed to register attendance for the Medical Group 2023 demonstrators.

## Project Structure
- `lib/main.dart`: Contains the logic and UI for the attendance form.

## How to Create the Link (Deployment)

To turn this project into a shareable link using GitHub Pages, follow these steps:

### 1. Build for Web
Run the following command to generate the web files:
```bash
flutter build web --release
```

### 2. Deploy to GitHub Pages
You have two main options:

#### Option A: Manual Upload (Easiest)
1. Go to your GitHub repository.
2. Go to Settings > Pages.
3. Choose the source as "main" or "master" branch.
4. Upload the contents of `build/web` to your repository.

#### Option B: Using `peanut` (Recommmended for Flutter)
1. Install peanut: `dart pub global activate peanut`
2. Run: `peanut`
3. Push the `gh-pages` branch: `git push origin --set-upstream gh-pages`
4. Go to GitHub Settings > Pages and select `gh-pages` branch.

### 3. Share the Link
Your link will be: `https://<your-username>.github.io/<repository-name>/`

## Form Fields
- Name (Full Name)
- Department
- Governorate (Dropdown)
