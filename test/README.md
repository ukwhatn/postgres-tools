# PostgreSQL Tools テスト環境

このディレクトリには、postgres-tools のイメージの機能をテストするための環境が含まれています。

## 構成

- `compose.yml`: Docker Compose V2 形式で記述されたテスト環境の設定ファイル
- `run_tests.sh`: テスト実行スクリプト
- `alembic/versions/`: テスト用マイグレーションファイルを格納するディレクトリ

## テスト環境の構成

テスト環境は以下のコンテナで構成されています：

1. `test-postgres`: PostgreSQL データベースサーバー
2. `test-minio`: S3互換ストレージ（MinIO）
3. `test-mc`: MinIO クライアント（バケット作成用）
4. `test-migrator`: テスト対象の migrator イメージ
5. `test-dumper`: テスト対象の dumper イメージ

## テスト内容

以下の機能がテストされます：

1. **マイグレーターの機能**
   - マイグレーションファイルの適用
   - テーブルの作成確認

2. **ダンパーの機能**
   - バックアップの作成
   - バックアップのリストア
   - データの一貫性確認

## 手動でのテスト実行

テストを手動で実行するには：

```bash
# ローカルでビルドしたイメージを使用してテスト実行
./run_tests.sh --use-local

# テスト環境を実行後に残す
./run_tests.sh --use-local --keep

# テスト環境をクリーンアップ
docker compose -f ./compose.yml down -v
```

## CIでの実行

GitHub Actionsワークフローが設定されており、関連ファイルが変更されたときに自動的にテストが実行されます。