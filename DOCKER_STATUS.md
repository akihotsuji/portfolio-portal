# Docker 開発環境 - 状況まとめ

## 📊 現在の構成（Dev Container 使用）

```
portfolio/
├── development/docker/
│   ├── docker-compose.all.yml      ✅ 全サービス統合（Dev Containerで使用）
│   ├── docker-compose.db-only.yml  ✅ DB単体テスト用
│   └── nginx/
│       └── nginx.conf              ✅ Nginxリバースプロキシ設定
│
└── portal/
    ├── backend/
    │   ├── Dockerfile.dev           ✅ Backend開発用イメージ
    │   └── .devcontainer/
    │       └── devcontainer.json    ✅ Backend Dev Container設定
    │
    └── frontend/
        ├── Dockerfile.dev           ✅ Frontend開発用イメージ
        └── .devcontainer/
            └── devcontainer.json    ✅ Frontend Dev Container設定
```

---

## 🎯 開発フロー（Dev Container 使用）

### Backend 開発

```
1. Cursor で portal/backend/ を開く
   ↓
2. "Reopen in Container" を実行
   ↓
3. development/docker/docker-compose.all.yml で全サービス起動
   - PostgreSQL (portfolio-db)
   - Backend (portal-backend) ← コンテナ内で開発
   - Frontend (portal-frontend)
   - Nginx (portfolio-nginx)
   ↓
4. Javaの自動補完・デバッグがコンテナ内で利用可能
   ↓
5. コード編集 → Spring Boot DevTools → 自動リロード ✅
```

### Frontend 開発

```
1. Cursor で portal/frontend/ を開く
   ↓
2. "Reopen in Container" を実行
   ↓
3. development/docker/docker-compose.all.yml で全サービス起動
   - PostgreSQL (portfolio-db)
   - Backend (portal-backend)
   - Frontend (portal-frontend) ← コンテナ内で開発
   - Nginx (portfolio-nginx)
   ↓
4. TypeScript/ESLintがコンテナ内で利用可能
   ↓
5. コード編集 → Vite HMR → 自動リロード ✅
```

---

## 📝 修正内容

### ✅ 修正済み

| ファイル                                          | 変更内容                                                                                                                                               |
| ------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `portal/backend/.devcontainer/devcontainer.json`  | dockerComposeFile を `../../development/docker/docker-compose.all.yml` に修正<br>service を `portal-backend` に修正<br>`runServices` で全サービス起動  |
| `portal/frontend/.devcontainer/devcontainer.json` | dockerComposeFile を `../../development/docker/docker-compose.all.yml` に修正<br>service を `portal-frontend` に修正<br>`runServices` で全サービス起動 |

---

## 🔑 重要ポイント

### 1. Dev Container 設定の仕組み

```json
{
  "dockerComposeFile": "../../development/docker/docker-compose.all.yml",
  "service": "portal-backend",
  "runServices": ["db", "portal-backend", "portal-frontend", "nginx"]
}
```

**説明**:

- `dockerComposeFile`: 全サービスの定義ファイルを指定
- `service`: 自分が開発するサービスを指定
- `runServices`: 起動するサービスを明示的に指定（全サービス）

**効果**:

- Dev Container 起動時に全サービスが立ち上がる
- Backend 開発中も Frontend/DB/Nginx が動いている
- 統合環境で開発できる

---

### 2. ボリュームマウント

```yaml
volumes:
  - ../../portal/backend:/app # ローカル → コンテナ
  - maven-cache:/root/.m2 # Maven依存関係キャッシュ
```

**効果**:

- ローカルで編集 → コンテナ内に即座に反映
- DevTools/Vite が変更検知 → 自動リロード
- Maven/npm キャッシュで高速化

---

### 3. ネットワーク構成

```
portfolio-net (Docker Network)
  ├── db (postgres:16-alpine)
  ├── portal-backend (Java 21)
  ├── portal-frontend (Node 20)
  └── nginx (nginx:alpine)
```

**コンテナ間通信**:

- Backend → DB: `jdbc:postgresql://db:5432/portfolio`
- Frontend → Backend: `http://portal-backend:8080/api`
- Nginx → Backend: `http://portal-backend:8080`
- Nginx → Frontend: `http://portal-frontend:5173`

---

## 🚀 使い方

### 開発開始

```bash
# Backend開発
1. Cursor で portal/backend/ を開く
2. 左下の「><」→ "Reopen in Container"
3. 待つ（初回は5-10分）
4. http://localhost:8080/actuator/health で確認

# Frontend開発
1. Cursor で portal/frontend/ を開く
2. 左下の「><」→ "Reopen in Container"
3. 待つ（初回は3-5分）
4. http://localhost:5173/ で確認
```

### アクセス URL

| サービス                 | URL                                   | 説明              |
| ------------------------ | ------------------------------------- | ----------------- |
| Frontend (Nginx 経由)    | http://localhost/                     | 本番と同じ構成    |
| Backend API (Nginx 経由) | http://localhost/api/actuator/health  | 本番と同じ構成    |
| Frontend (直接)          | http://localhost:5173/                | Vite 開発サーバー |
| Backend (直接)           | http://localhost:8080/actuator/health | Spring Boot 直接  |
| PostgreSQL               | localhost:5432                        | DB 接続           |

---

## 🔧 トラブルシューティング

### 問題: Dev Container が起動しない

```bash
# Docker Desktopが起動しているか確認
docker ps

# Docker Desktopを再起動
# → Cursorを再起動
```

### 問題: サービスが起動しない

```bash
# ログ確認
docker-compose -f development/docker/docker-compose.all.yml logs -f

# 再起動
docker-compose -f development/docker/docker-compose.all.yml restart portal-backend
```

### 問題: ホットリロードが効かない

```bash
# Backend: application-dev.yml を確認
spring:
  devtools:
    restart:
      enabled: true

# Frontend: package.json を確認
"dev": "vite --host 0.0.0.0"
```

---

## 📚 関連ドキュメント

- [DEVCONTAINER_GUIDE.md](./DEVCONTAINER_GUIDE.md) - Dev Container 詳細ガイド
- [../development/docs/phase1-tasks.md](../development/docs/phase1-tasks.md) - Phase1 タスク一覧
- [../development/docs/requirements.md](../development/docs/requirements.md) - 要件定義

---

## ✅ チェックリスト

**Dev Container 環境が正しく動作しているか確認**:

- [ ] Docker Desktop が起動している
- [ ] Cursor (VS Code)がインストール済み
- [ ] Dev Containers 拡張機能がインストール済み
- [ ] `portal/backend/` を Dev Container で開ける
- [ ] `portal/frontend/` を Dev Container で開ける
- [ ] http://localhost/ で Frontend が表示される
- [ ] http://localhost/api/actuator/health で Backend が応答する
- [ ] コード編集 → 自動リロード が動作する

---

**最終更新**: 2025-10-19
