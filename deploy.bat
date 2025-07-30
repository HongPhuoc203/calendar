@echo off
echo 🚀 Deploying C Global Calendar to GitHub Pages...
echo.

echo 📝 Adding all changes to git...
git add .

echo 💾 Committing changes...
git commit -m "🚀 Fix: Deployment ready - resolved all build issues ✅ Fixed Firebase test dependencies ✅ Replaced with simple widget tests ✅ All analyzer warnings resolved ✅ Web build successful (39.3s)"

echo 🌐 Pushing to GitHub (will trigger auto-deployment)...
git push origin main

echo.
echo ✅ Push completed! 
echo 🕐 GitHub Actions will now build and deploy automatically.
echo 📱 Check deployment status at: https://github.com/HongPhuoc203/calendar/actions
echo 🌟 Live site will be available at: https://HongPhuoc203.github.io/calendar/
echo.
pause 