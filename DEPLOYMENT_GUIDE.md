# 🌐 Hướng Dẫn Deploy C Global Calendar lên GitHub Pages

## 🎯 Mục tiêu
Triển khai ứng dụng Flutter lên GitHub Pages để người dùng có thể trải nghiệm trước khi cài đặt app trên điện thoại.

## 📋 Yêu cầu
- ✅ GitHub account
- ✅ Firebase project đã setup
- ✅ Repository GitHub đã tạo

## 🔥 Bước 1: Cấu hình Firebase cho Web

### 1.1. Thêm Web App vào Firebase Project

1. **Truy cập Firebase Console:**
   - Vào https://console.firebase.google.com
   - Chọn project của bạn

2. **Thêm Web app:**
   - Click biểu tượng `</>` (Add web app)
   - App nickname: `C Global Calendar Web`
   - ✅ Tick "Also set up Firebase Hosting for this app"
   - Click "Register app"

3. **Lấy Firebase Configuration:**
   - Copy toàn bộ config object từ Firebase
   - Ví dụ:
   ```javascript
   const firebaseConfig = {
     apiKey: "AIzaSyAbc123...",
     authDomain: "your-project.firebaseapp.com",
     projectId: "your-project-id", 
     storageBucket: "your-project.appspot.com",
     messagingSenderId: "123456789",
     appId: "1:123456789:web:abc123..."
   };
   ```

### 1.2. Cập nhật Firebase Config trong Code

**Option A: Cập nhật trực tiếp (dễ nhất)**
1. Mở file `web/index.html`
2. Tìm section Firebase Configuration
3. Thay thế các placeholder:
   ```javascript
   const firebaseConfig = {
     apiKey: "YOUR_ACTUAL_API_KEY_HERE",
     authDomain: "your-project.firebaseapp.com", 
     projectId: "your-project-id",
     storageBucket: "your-project.appspot.com",
     messagingSenderId: "your-sender-id",
     appId: "your-app-id"
   };
   ```

**Option B: Sử dụng GitHub Secrets (bảo mật hơn)**
1. Vào GitHub repo → Settings → Secrets and variables → Actions
2. Thêm các secrets:
   - `FIREBASE_API_KEY`: API key của bạn
   - `FIREBASE_PROJECT_ID`: Project ID
   - `FIREBASE_SENDER_ID`: Messaging sender ID
   - `FIREBASE_APP_ID`: App ID

### 1.3. Cấu hình Firebase Rules

**Firestore Security Rules:**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Events collection
    match /events/{eventId} {
      allow read, write: if request.auth != null && 
                        request.auth.uid == resource.data.userId;
      allow create: if request.auth != null && 
                   request.auth.uid == request.resource.data.userId;
    }
    
    // Users collection  
    match /users/{userId} {
      allow read, write: if request.auth != null && 
                        request.auth.uid == userId;
    }
  }
}
```

**Firebase Authentication:**
- Enable Email/Password authentication
- Add authorized domains:
  - `localhost` (for testing)
  - `your-username.github.io` (for GitHub Pages)

## 🚀 Bước 2: Setup GitHub Repository

### 2.1. Tạo Repository
```bash
# Tại thư mục project
git init
git add .
git commit -m "Initial commit: C Global Calendar"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/C_Global_Calendar.git
git push -u origin main
```

### 2.2. Enable GitHub Pages
1. Vào GitHub repo → Settings → Pages
2. Source: **GitHub Actions**
3. Save

## ⚙️ Bước 3: Cấu hình Deployment

### 3.1. Cập nhật Base Href (nếu cần)
Nếu repository name khác `C_Global_Calendar`, sửa trong `.github/workflows/deploy-web.yml`:
```yaml
- name: Build web
  run: flutter build web --release --web-renderer html --base-href "/YOUR_REPO_NAME/"
```

### 3.2. Test Local Build
```bash
# Test build local trước khi deploy
flutter build web --release
flutter pub global activate dhttpd
dhttpd --path build/web --port 8080
```
Mở http://localhost:8080 để test

## 🎉 Bước 4: Deploy

### 4.1. Auto Deploy
- Push code lên GitHub main branch
- GitHub Actions sẽ tự động build và deploy
- Check trong tab "Actions" để xem progress

### 4.2. URL Truy Cập
Sau khi deploy thành công:
```
https://YOUR_USERNAME.github.io/C_Global_Calendar/
```

## 🔧 Troubleshooting

### Lỗi Firebase Connection
```javascript
// Kiểm tra Network tab trong browser console
// Đảm bảo Firebase config đúng
// Check Firebase project settings
```

### Lỗi 404 hoặc Blank Page
```bash
# Kiểm tra base-href
flutter build web --release --base-href "/YOUR_REPO_NAME/"

# Kiểm tra GitHub Pages settings
# Đảm bảo source = GitHub Actions
```

### Local Notifications không hoạt động trên Web
- Đây là bình thường vì web không hỗ trợ local notifications
- Có thể thay bằng web notifications hoặc in-app notifications

### Google Sign In trên Web
1. Thêm domain vào Google Cloud Console:
   - Console → APIs & Services → Credentials
   - Edit OAuth 2.0 client ID
   - Add `your-username.github.io` vào Authorized domains

## 🎯 Kết quả mong đợi

✅ **Web app hoạt động đầy đủ tính năng:**
- 🔐 Đăng nhập/Đăng ký Firebase Auth
- 📅 Quản lý sự kiện với Firestore
- 🤖 AI Chat (nếu có API key)
- 📊 Thống kê chi phí với biểu đồ
- 💾 Lịch sử trò chuyện AI
- 📱 PWA features (cài đặt như app)

✅ **SEO và Social Media:**
- Meta tags cho Facebook/Twitter sharing
- PWA manifest với shortcuts
- Loading screen đẹp mắt
- Responsive design

## 📱 Marketing & User Experience

### Để quảng bá:
1. **Chia sẻ URL demo:** `https://your-username.github.io/C_Global_Calendar/`
2. **Thêm vào README:** Badge "Try Demo" 
3. **Social media:** Screenshots + demo link
4. **App stores:** Link đến web demo trong description

### User journey:
1. **Discover:** User thấy link demo
2. **Try:** Trải nghiệm đầy đủ trên web
3. **Convert:** Download app nếu thích
4. **Migrate:** Data sync qua Firebase account

## 🔄 Update & Maintenance

### Auto-deployment:
- Mỗi khi push code mới → Auto deploy
- Check GitHub Actions logs
- Monitor Firebase usage

### Version control:
```bash
# Release new version
git tag v1.0.0
git push origin v1.0.0
# Deploy sẽ tự động trigger
```

---

**🎉 Chúc mừng! Bạn đã có một web demo hoàn chỉnh cho C Global Calendar!**

**Demo URL sẽ là:** `https://your-username.github.io/C_Global_Calendar/` 