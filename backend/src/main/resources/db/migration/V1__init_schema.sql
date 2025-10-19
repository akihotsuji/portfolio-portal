-- ========================================
-- Portal Schema: 認証・認可システムの初期化
-- ========================================
-- このスキーマは Portal アプリケーションの認証・認可情報を管理します
-- 他のマイクロアプリ（TODO, IMG_EXIF等）は別スキーマで管理されます
CREATE SCHEMA IF NOT EXISTS portal;


-- ========================================
-- Users テーブル: ユーザー情報の管理
-- ========================================
-- 【役割】
--   - ログイン認証の基本情報を保持
--   - パスワードはBCryptでハッシュ化して保存（平文は保存しない）
--   - マイクロアプリごとのアクセス権限を管理
--
-- 【セキュリティ】
--   - password_hash: BCryptで不可逆変換（レインボーテーブル攻撃対策）
--   - email: UNIQUE制約で重複登録を防止
--   - is_active: 論理削除やアカウント凍結に使用
CREATE TABLE portal.users (
    -- UUID主キー: 自動生成、推測不可能、分散環境でも衝突しない
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- メールアドレス: ログインIDとして使用
    email VARCHAR(255) UNIQUE NOT NULL,
    
    -- BCryptハッシュ値（60文字固定だが余裕を持たせる）
    password_hash VARCHAR(255) NOT NULL,
    
    -- 表示名: UI上で「〇〇さん」と表示するため
    display_name VARCHAR(100),
    
    -- アクセス可能なマイクロアプリのコード配列
    -- 例: ['TODO', 'IMG_EXIF'] → TODOアプリとEXIFアプリにアクセス可
    apps TEXT[] DEFAULT '{}',
    
    -- アカウント有効フラグ: false = 無効化（ログイン不可）
    is_active BOOLEAN DEFAULT TRUE,
    
    -- 作成日時・更新日時（監査ログ用）
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


-- ========================================
-- Refresh Tokens テーブル: JWT更新トークンの管理
-- ========================================
-- 【役割】
--   - Access Token（短命：15分）が切れた際の再発行に使用
--   - Refresh Token（長命：30日）を安全に管理
--
-- 【JWT の仕組み】
--   1. ログイン → Access Token(15分) + Refresh Token(30日) 発行
--   2. 15分後 → Access Token 期限切れ
--   3. Refresh Token を使って Access Token を再発行
--   4. 30日後 → Refresh Token も期限切れ → 再ログイン必要
--
-- 【セキュリティ】
--   - token_hash: トークン自体をハッシュ化して保存（漏洩時の被害軽減）
--   - revoked_at: トークン無効化（ログアウト・不正検知時）
--   - ON DELETE CASCADE: ユーザー削除時にトークンも自動削除
CREATE TABLE portal.refresh_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- どのユーザーのトークンか（外部キー制約）
    user_id UUID NOT NULL REFERENCES portal.users(id) ON DELETE CASCADE,
    
    -- トークンのハッシュ値（実際のトークンは保存しない）
    token_hash VARCHAR(255) UNIQUE NOT NULL,
    
    -- トークン有効期限（30日後）
    expires_at TIMESTAMP NOT NULL,
    
    -- トークン発行日時
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- トークン無効化日時（NULL = 有効, NOT NULL = 無効化済み）
    -- ログアウト時やセキュリティ侵害検知時に設定
    revoked_at TIMESTAMP NULL
);


-- ========================================
-- インデックス: クエリ性能の最適化
-- ========================================
-- 【効果】
--   - idx_users_email: ログイン時のメール検索を高速化（O(log n)）
--   - idx_refresh_tokens_user_id: ユーザーの全トークン取得を高速化
--   - idx_refresh_tokens_token_hash: トークン検証を高速化
CREATE INDEX idx_refresh_tokens_user_id ON portal.refresh_tokens(user_id);
CREATE INDEX idx_refresh_tokens_token_hash ON portal.refresh_tokens(token_hash);
CREATE INDEX idx_users_email ON portal.users(email);

-- ========================================
-- 初期テストユーザー挿入
-- ========================================
-- 【開発・テスト用】
--   本番環境では別途管理画面から登録する想定
--
-- 【パスワード】
--   - admin@example.com → "admin1234"
--   - user@example.com  → "user1234"
--   ※ BCryptでハッシュ化済み（平文は保存しない）
--
-- 【権限の違い】
--   - Admin User: 全マイクロアプリにアクセス可能（フルアクセス）
--   - Regular User: TODOとIMG_EXIFのみアクセス可能（制限付き）
INSERT INTO portal.users (email, password_hash, display_name, apps, is_active) VALUES
(
    'admin@example.com',
    '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy',  -- "admin1234" のハッシュ
    'Admin User',
    ARRAY['TODO', 'IMG_EXIF', 'CSV_SUMMARY', 'PDF_SEARCH', 'IMG_THUMB', 'MD_RENDER', 'SSE_LOG', 'URL_SHORT', 'FX', 'GITHUB_VIEW'],  -- 全アプリ
    true
),
(
    'user@example.com',
    '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',  -- "user1234" のハッシュ
    'Regular User',
    ARRAY['TODO', 'IMG_EXIF'],  -- 制限付き
    true
);