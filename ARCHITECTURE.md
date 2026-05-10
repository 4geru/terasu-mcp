# ARCHITECTURE

terasu のシステム設計と実装の解説。

---

## システム概要

terasu は **Rails 製の Remote MCP Server** です。Claude などの AI クライアントが OAuth 2.0 で認証し、MCP プロトコルを通じて Philips Hue の照明を操作できます。

```mermaid
graph TD
    User([ユーザー])
    Claude[Claude Desktop / Claude Code]
    Terasu["terasu\n(Rails Server)"]
    LINE["LINE Login\n(OAuth IdP)"]
    Hue["Philips Hue Bridge"]
    Light[💡 照明]

    User -->|「照らして」| Claude
    Claude -->|Remote MCP\nJSON-RPC| Terasu
    Terasu -->|OAuth 認証| LINE
    LINE -->|ユーザー確認| User
    Terasu -->|Hue REST API| Hue
    Hue --> Light
```

---

## 認証フロー

OAuth 2.0 Authorization Code Flow + PKCE で実装しています。認証基盤として LINE Login を使用し、Devise / Doorkeeper などの gem は使わず最小実装しています。

```mermaid
sequenceDiagram
    participant C as Claude Code
    participant T as terasu (Rails)
    participant L as LINE Login
    participant U as ユーザー (ブラウザ)

    C->>T: POST /register
    T-->>C: { client_id }

    C->>T: GET /.well-known/oauth-authorization-server
    T-->>C: { authorization_endpoint, token_endpoint, ... }

    C->>T: GET /oauth/authorize?client_id=...&code_challenge=...
    T->>T: OauthCode.create!(pending)
    T-->>U: 302 → LINE Login

    U->>L: LINE でログイン
    L-->>T: GET /oauth/line/callback?code=LINE_CODE&state=...
    T->>L: POST token exchange
    L-->>T: { access_token }
    T->>L: GET /v2/profile
    L-->>T: { userId }
    T->>T: oauth_code.confirm!(line_user_id)
    T-->>U: 302 → redirect_uri?code=OUR_CODE

    C->>T: POST /oauth/token { code, code_verifier }
    T->>T: PKCE 検証
    T-->>C: { access_token, token_type: "Bearer" }
```

### 設計のポイント

- **セッション不使用**: Rails API モードはセッションを持たないため、認可コードを `OauthCode` テーブルで管理
- **PKCE (S256)**: コードインターセプト攻撃を防ぐため PKCE を実装
- **LINE Login を IdP として利用**: 独自のユーザー管理を持たず、LINE の認証に委譲

---

## MCP ツール呼び出しフロー

```mermaid
sequenceDiagram
    participant U as ユーザー
    participant C as Claude
    participant T as terasu (Rails)
    participant HC as HueCycler
    participant H as Hue Bridge
    participant L as 💡 照明

    U->>C: 「部屋を照らして」
    C->>T: POST /mcp\nAuthorization: Bearer token\n{ method: "tools/call", name: "illuminate" }
    T->>T: OauthToken.valid? 検証
    T->>H: PUT /api/.../lights/1/state\n{ on: true, bri: 203, hue: 8000 }
    H->>L: 点灯
    T-->>C: { content: "照らしました" }
    C-->>U: ツール実行結果を表示

    U->>C: 「カラーサイクル開始して」
    C->>T: POST /mcp\n{ method: "tools/call", name: "start_color_cycle" }
    T->>HC: HueCycler.start(interval: 5)
    HC->>H: PUT .../state { hue: ?, bri: ? } (定期実行)
    H->>L: 色が変化し続ける
    T-->>C: { content: "サイクル始めたよ！" }
```

---

## ファイル構成

```mermaid
graph LR
    subgraph controllers
        OC[oauth_controller.rb\nOAuth + LINE callback]
        MC[mcp_controller.rb\nJSON-RPC handler]
    end
    subgraph models
        OCM[OauthCode\n認可コード]
        OT[OauthToken\nアクセストークン]
    end
    subgraph services
        LS[LineService\nLINE API]
        HS[HueService\nHue REST API]
        subgraph mcp_tools
            IT[IlluminateTool]
            TT[TurnOffTool]
            SC[SetColorTool]
            SCC[SetColorCodeTool]
            SCY[StartCycleTool]
            SB[StartBreathingTool]
            ST[StopCycleTool]
        end
        HC[HueCycler\nサイクル・呼吸モード]
    end

    OC --> OCM
    OC --> OT
    OC --> LS
    MC --> OT
    MC --> IT
    MC --> TT
    MC --> SC
    MC --> SCC
    MC --> SCY
    MC --> SB
    MC --> ST
    IT --> HS
    TT --> HS
    SC --> HS
    SCC --> HS
    SCY --> HC
    SB --> HC
    ST --> HC
    HC --> HS
```

---

## DB スキーマ

```mermaid
erDiagram
    OauthCode {
        string code "認可コード（LINE認証後に確定）"
        string client_id "MCPクライアントID"
        string redirect_uri "MCPクライアントのコールバックURL"
        string mcp_state "MCPクライアントが渡したstate"
        string line_state "LINEコールバック識別用トークン"
        string line_user_id "LINE ユーザーID"
        string code_challenge "PKCE チャレンジ"
        string code_challenge_method "S256 固定"
        datetime expires_at "5分間有効"
    }

    OauthToken {
        string token "ベアラートークン"
        string client_id "MCPクライアントID"
        datetime expires_at "1時間有効"
    }

    OauthCode ||--o| OauthToken : "トークン交換後に発行"
```

---

## API エンドポイント一覧

| Method | Path | 説明 |
|--------|------|------|
| `GET`  | `/.well-known/oauth-protected-resource` | OAuth プロテクトリソースメタデータ |
| `GET`  | `/.well-known/oauth-authorization-server` | OAuth 認可サーバーメタデータ |
| `POST` | `/register` | Dynamic Client Registration (RFC 7591) |
| `GET`  | `/oauth/authorize` | 認可エンドポイント → LINE Login へリダイレクト |
| `GET`  | `/oauth/line/callback` | LINE Login コールバック |
| `POST` | `/oauth/token` | トークンエンドポイント |
| `GET`  | `/mcp` | MCP サーバー情報 |
| `POST` | `/mcp` | MCP JSON-RPC ハンドラ |
| `GET`  | `/mcp/sse` | SSE エンドポイント |

---

## MCP ツール一覧

| ツール名 | 引数 | 説明 |
|---------|------|------|
| `illuminate` | `brightness` (1-100), `color` (warm/cool) | 照明をつける |
| `turn_off_lights` | なし | 照明を消す |
| `set_light_color` | `color` (red/yellow/warm/green/blue/purple/pink) | 色を変える |
| `set_light_color_hex` | `hex` (#RRGGBB) | HEXカラーコードで色を指定する |
| `start_color_cycle` | `interval` (1-60秒), `brightness` (1-100) | 色を一定間隔で自動変化させる |
| `start_breathing` | `color` (red/yellow/.../pink), `speed` (slow/normal/fast) | 明るさが上下する呼吸モードを開始する |
| `stop_color_cycle` | なし | サイクル・呼吸モードをすべて停止する |
