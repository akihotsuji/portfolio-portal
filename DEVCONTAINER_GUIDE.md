# Dev Container 開発ガイド

## 🎯 概要

このプロジェクトでは **Dev Container** を使用して、完全にコンテナ内で開発を行います。

```
✅ ローカルにJava/Node.jsのインストール不要
✅ 全ての開発ツールがコンテナ内に
✅ チームメンバー全員が同じ環境
✅ IDE機能（補完・デバッグ）もコンテナ内で動作
```

---

## 🚀 開発開始手順

### 1. 前提条件の確認

```bash
✅ Docker Desktop がインストール済み
✅ Cursor (VS Code) がインストール済み
✅ Dev Containers 拡張機能がインストール済み
   → 拡張機能ID: ms-vscode-remote.remote-containers
```

### 2. Backend 開発の場合

#### Step 1: フォルダを開く

```
Cursor で portal/backend/ フォルダを開く
```

#### Step 2: Dev Container で再度開く

```
1. Cursor左下の「><」アイコンをクリック
2. "Reopen in Container" を選択
3. 待つ（初回は5-10分かかります）
```

#### Step 3: 起動確認

```
自動的に以下が起動します：
✅ PostgreSQL (portfolio-db)
✅ Portal Backend (portal-backend) ← ここで開発中
✅ Portal Frontend (portal-frontend)
✅ Nginx (portfolio-nginx)
```

#### Step 4: 開発開始！

```java
// src/main/java/com/portfolio/portal/ 配下を編集
// ↓
// Spring Boot DevTools が自動検知
// ↓
// 自動リロード ✅
```

---

### 3. Frontend 開発の場合

#### Step 1: フォルダを開く

```
Cursor で portal/frontend/ フォルダを開く
```

#### Step 2: Dev Container で再度開く

```
1. Cursor左下の「><」アイコンをクリック
2. "Reopen in Container" を選択
3. 待つ（初回は3-5分かかります）
```

#### Step 3: 起動確認

```
自動的に以下が起動します：
✅ PostgreSQL (portfolio-db)
✅ Portal Backend (portal-backend)
✅ Portal Frontend (portal-frontend) ← ここで開発中
✅ Nginx (portfolio-nginx)
```

#### Step 4: 開発開始！

```tsx
// src/ 配下を編集
// ↓
// Vite が自動検知（HMR）
// ↓
// 自動リロード ✅
```

---

## 🌐 アクセス URL

Dev Container 起動後、以下の URL にアクセスできます：

| サービス          | URL                                   | 説明                       |
| ----------------- | ------------------------------------- | -------------------------- |
| **Frontend**      | http://localhost/                     | Nginx 経由でアクセス       |
| **Backend API**   | http://localhost/api/actuator/health  | Nginx 経由でヘルスチェック |
| **Frontend 直接** | http://localhost:5173/                | Vite 開発サーバー直接      |
| **Backend 直接**  | http://localhost:8080/actuator/health | Spring Boot 直接           |
| **PostgreSQL**    | localhost:5432                        | DB 直接接続                |

---

## 📝 よくあるコマンド

### Backend (コンテナ内のターミナルで実行)

```bash
# Mavenビルド
./mvnw clean package

# テスト実行
./mvnw test

# 依存関係確認
./mvnw dependency:tree

# アプリケーション再起動（通常は不要、DevToolsが自動リロード）
./mvnw spring-boot:run
```

### Frontend (コンテナ内のターミナルで実行)

```bash
# 依存関係インストール
npm install

# 開発サーバー起動（通常は自動起動済み）
npm run dev

# ビルド
npm run build

# Linter実行
npm run lint
```

### Docker Compose 操作 (ローカルのターミナルで実行)

```bash
# 全サービスの状態確認
docker ps

# ログ確認
docker-compose -f development/docker/docker-compose.all.yml logs -f

# 特定サービスのログ
docker-compose -f development/docker/docker-compose.all.yml logs -f portal-backend

# サービス再起動
docker-compose -f development/docker/docker-compose.all.yml restart portal-backend

# 全サービス停止
docker-compose -f development/docker/docker-compose.all.yml down

# ボリューム含めて完全削除
docker-compose -f development/docker/docker-compose.all.yml down -v
```

---

## 🔧 トラブルシューティング

### 問題 1: Dev Container が起動しない

**症状**:

```
Error: Cannot connect to the Docker daemon
```

**解決策**:

```
1. Docker Desktop が起動しているか確認
2. Docker Desktop を再起動
3. Cursor を再起動
```

---

### 問題 2: Backend/Frontend が起動しない

**症状**:

```
portal-backend exited with code 1
```

**解決策**:

```bash
# ログを確認
docker-compose -f development/docker/docker-compose.all.yml logs portal-backend

# よくある原因：
# 1. DBがまだ起動していない → 待つ（healthcheckで自動待機）
# 2. ポート競合 → 既存プロセスを停止
# 3. ボリュームキャッシュ問題 → down -v で削除して再起動
```

---

### 問題 3: ホットリロードが効かない

**Backend**:

```
原因: Spring Boot DevToolsが無効
解決: application-dev.yml を確認
```

**Frontend**:

```
原因: Vite HMRが無効
解決: ブラウザのコンソールでエラー確認
```

---

### 問題 4: 拡張機能が動作しない

**症状**:

```
Java Language Serverが起動しない
ESLintが動作しない
```

**解決策**:

```
1. Dev Container内で拡張機能がインストールされているか確認
2. Cursorを再起動
3. Dev Containerを再ビルド:
   Ctrl+Shift+P → "Dev Containers: Rebuild Container"
```

---

## 📊 開発フロー図

```
┌─────────────────────────────────────────┐
│ 1. Cursor で portal/backend を開く      │
└─────────────────────────────────────────┘
                ↓
┌─────────────────────────────────────────┐
│ 2. "Reopen in Container" をクリック     │
└─────────────────────────────────────────┘
                ↓
┌─────────────────────────────────────────┐
│ 3. Docker Compose で全サービス起動      │
│    - PostgreSQL                         │
│    - Backend (コンテナ内で開発)        │
│    - Frontend                           │
│    - Nginx                              │
└─────────────────────────────────────────┘
                ↓
┌─────────────────────────────────────────┐
│ 4. Cursorはコンテナ内に接続             │
│    - Java Language Server 起動          │
│    - Maven 利用可能                     │
│    - 自動補完・デバッグ可能             │
└─────────────────────────────────────────┘
                ↓
┌─────────────────────────────────────────┐
│ 5. コード編集                           │
│    ↓                                    │
│ ボリュームマウントで即座に反映          │
│    ↓                                    │
│ DevTools/Vite が自動検知                │
│    ↓                                    │
│ 自動リロード ✅                         │
└─────────────────────────────────────────┘
```

---

## 💡 Tips

### 1. 複数の Dev Container を同時に開く

```
Backend と Frontend を同時開発したい場合：

1. Cursorウィンドウ1: portal/backend を Dev Container で開く
2. Cursorウィンドウ2: portal/frontend を Dev Container で開く

→ 両方のコンテナが同じ docker-compose.all.yml を参照
→ 1つのネットワーク内で全サービスが動作
```

### 2. DB 接続（コンテナ内から）

```bash
# コンテナ内のターミナルで
docker exec -it portfolio-db psql -U dev -d portfolio

# またはDBクライアントツールで
Host: db  # コンテナ名で接続可能
Port: 5432
User: dev
Password: devpass
Database: portfolio
```

### 3. パフォーマンス改善

```
初回起動が遅い場合：

1. Docker Desktop の設定で WSL 2 を使用
2. メモリ・CPU割り当てを増やす
3. ボリュームキャッシュを活用（既に設定済み）
```

---

## 🎓 学習リソース

- [Dev Containers 公式ドキュメント](https://code.visualstudio.com/docs/devcontainers/containers)
- [Docker Compose 公式ドキュメント](https://docs.docker.com/compose/)
- [Spring Boot DevTools](https://docs.spring.io/spring-boot/docs/current/reference/html/using.html#using.devtools)
- [Vite HMR](https://vitejs.dev/guide/features.html#hot-module-replacement)

---

**最終更新**: 2025-10-19
