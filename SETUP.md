# SETUP

terasu のセットアップ手順。

## 必要なもの

- Ruby 3.3.0
- Bundler
- Philips Hue Bridge + ライト（実機なしは `HUE_MOCK=true` で代替可）
- LINE Login チャネル（[LINE Developers Console](https://developers.line.biz/console/) で作成）

---

## 1. リポジトリのセットアップ

```bash
cd project-rails-remote-mcp
bundle install
rails db:create db:migrate
```

---

## 2. 環境変数の設定

`env.sample` をコピーして `.env` を作成する。

```bash
cp env.sample .env
```

`.env` を編集する。

```
BASE_URL=http://localhost:3000

# Hue（実機なしの場合は HUE_MOCK=true のまま）
HUE_BRIDGE_IP=192.168.1.100
HUE_API_KEY=YOUR_HUE_API_KEY
HUE_LIGHT_ID=1
HUE_MOCK=true

# LINE Login
LINE_CHANNEL_ID=YOUR_LINE_CHANNEL_ID
LINE_CHANNEL_SECRET=YOUR_LINE_CHANNEL_SECRET
```

---

## 3. LINE Login の設定

LINE Developers Console でチャネルを作成し、Callback URL を登録する。

1. [LINE Developers Console](https://developers.line.biz/console/) を開く
2. プロバイダー → チャネル作成 → **LINE Login** を選択
3. 「LINE Login設定」タブ → コールバック URL に追加：

```
http://localhost:3000/oauth/line/callback
```

4. チャネル基本設定から **Channel ID** と **Channel Secret** を取得して `.env` に記入

---

## 4. Hue API キーの取得（実機使用時）

1. Hue Bridge と同じネットワークに接続した状態で `http://<BRIDGE_IP>/debug/clip.html` を開く
2. URL: `/api`、Body: `{"devicetype":"terasu"}` を入力して POST
3. Bridge 本体のボタンを押してから再度 POST → レスポンスの `username` が API キー
4. `.env` の `HUE_API_KEY` に記入し、`HUE_MOCK=false` に変更

---

## 5. サーバーの起動

```bash
rails server -p 3000
```

起動確認：

```bash
curl http://localhost:3000/up
# → 200 OK
```

---

## 6. Claude Code との接続

プロジェクトルートの `.mcp.json` にすでに設定済み。

```json
{
  "mcpServers": {
    "terasu": {
      "type": "http",
      "url": "http://localhost:3000/mcp"
    }
  }
}
```

Claude Code を起動して `/mcp` を実行 → terasu を選択 → ブラウザで LINE Login → 認証完了。

---

## 7. 動作確認

Claude に話しかける。

```
「部屋を照らして」              → illuminate ツール
「照明を青にして」              → set_light_color ツール
「電気消して」                  → turn_off_lights ツール
「照明を #FF6600 にして」       → set_light_color_hex ツール
「カラーサイクル開始して」      → start_color_cycle ツール
「呼吸モードにして」            → start_breathing ツール
「サイクル止めて」              → stop_color_cycle ツール
```

---

## curl での手動確認

```bash
# 1. 認可コードを取得（ブラウザでLINE認証が走る）
curl -si "http://localhost:3000/oauth/authorize?client_id=test&redirect_uri=http://localhost:9999/cb&state=abc" | grep location

# 2. トークンを発行（LINE認証後に取得したcode を使う）
TOKEN=$(curl -s -X POST http://localhost:3000/oauth/token \
  -H "Content-Type: application/json" \
  -d '{"code":"<code>","client_id":"test"}' | jq -r .access_token)

# 3. ツールを呼ぶ
curl -s -X POST http://localhost:3000/mcp \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"illuminate","arguments":{"brightness":80,"color":"warm"}}}'
```
