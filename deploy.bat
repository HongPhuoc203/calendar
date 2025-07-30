@echo off
echo 🚀 Deploying C Global Calendar to GitHub Pages...
echo.

echo 📝 Adding all changes to git...
git add .

echo 💾 Committing changes...
git commit -m "Fix: Resolve analyzer warnings for GitHub Pages deployment - Remove unused imports - Fix deprecated withOpacity methods - Update file naming conventions - Remove missing asset references"

echo 🌐 Pushing to GitHub (will trigger auto-deployment)...
git push origin main

echo.
echo ✅ Push completed! 
echo 🕐 GitHub Actions will now build and deploy automatically.
echo 📱 Check deployment status at: https://github.com/HongPhuoc203/calendar/actions
echo 🌟 Live site will be available at: https://HongPhuoc203.github.io/calendar/
echo.
pause 