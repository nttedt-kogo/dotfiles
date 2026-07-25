# 共通の作業ルール（全プロジェクト共通）

## tmux ペイン共有ワークフロー

ユーザーが「pane %X を見て」「pane %X のエラーを直して」のように tmux のペインIDを指す指示をしたら、
そのペインの内容を**自分で取得して**使うこと。ユーザーのコピペを待たない。

- 表示中の内容: `tmux capture-pane -p -t %X`
- スクロールバック込み: `tmux capture-pane -p -S -3000 -t %X`（直近3000行）
- ペインの一覧と中身の把握: `tmux list-panes -a -F "#{pane_id} #{pane_current_command} #{pane_current_path}"`

用途の例: 別ペインで実行したコマンドのエラーログ・テスト結果・ビルド出力を、長くてコピペしづらい時に
直接読み取って解析・修正する。

ペインIDは各ペイン上部のボーダーに `%12` 形式で表示されている（`.tmux.conf` の pane-border-format）。

## agmsg: team member の spawn (全プロジェクト共通・operator 方針 2026-07-25)

**team member は必ず bypass permissions モードで spawn する** (`claude --dangerously-skip-permissions`)。

理由: 通常モードで spawn すると、新セッションが最初の `/agmsg actas <name>` を実行した時点で
「Contains shell syntax that cannot be statically analyzed」の許可プロンプトに掛かって**起動直後に固まる**。
operator が各ペインを手で承認して回るまで team が動かない (2026-07-25 に実際に発生し、
spawn.sh の readiness handshake が `status=timeout` で終わった)。

**注意: agmsg の `spawn.sh` には bypass のオプションが無い**。manifest (`drivers/types/claude-code/type.conf`)
の `cli=claude` を `command -v` で解決して直接起動する作りで、追加フラグの pass-through が無い
(`--model` だけが例外)。manifest は read-only データなので書き換えない。

したがって **tmux から直接起動する** (spawn.sh の direct-CLI 起動と同じ形にフラグを足しただけ):

```bash
# 事前に role を join しておく (spawn.sh がやっていた前処理)
~/.agents/skills/agmsg/scripts/join.sh <team> <name> claude-code <project>

tmux new-window -d -n "<name>" -c <project> \
  "claude --dangerously-skip-permissions --model <opus|sonnet> '/agmsg actas <name>'"
```

- `--model` はプロセス単位なので**保存済みデフォルトを汚さない** (下記のモデル注意と同じ理由で `/model` より優先)
- 死んだペインの後始末は `reset.sh` ではなく pane kill + 必要なら `join.sh` で再登録する。
  **`reset.sh <project> claude-code <name>` は registration ごと消す** ので、
  actas lock を外すだけのつもりで使うと team から抜ける (メッセージ履歴は残る)

## uav-dev-env マルチエージェント体制 (agmsg team: airgrow)

対象プロジェクト: `~/dev/uav-dev-env` のみ。他プロジェクトには適用しない。

- **役割定義の SSOT は `~/dotfiles/claude/team-roles.md`**。編成・各役割の mission / boundaries / 検証ゲートフロー・merge 規律はすべてそこに書いてある。このファイルと重複記載しない
- どの役割のセッションも、**起動直後 (と clean handoff 再開直後) に team-roles.md を読み、motoko に読了 ack を送ってから作業に入る**
- 編成: motoko=統括 (Fable 5/high) / tachikoma=実装 lead (Opus 4.8/high) / togusa=SITL・harness (Sonnet 5/medium) / bato=検証専任 (Sonnet 5/high)。1 役割 = 1 セッション (agmsg actas lock が強制)。旧名: 2b→motoko / 9s→togusa / a2→bato / emil→tachikoma (2026-07-16 rename、Linear 過去コメントは旧名)
- merge / main への push は operator の動詞明示指示があるときのみ (詳細・経緯は team-roles.md 共通ルール 1)

### セッション開始フレーズ (operator 用)

**通常はこれだけ** — `~/dev/uav-dev-env` で Claude Code を開き、1 行:

```
/agmsg actas motoko した後、~/dotfiles/claude/team-roles.md と docs/plans/ の handoff ファイルを読んで、統括として業務を再開して
```

motoko が盤面を把握し、必要に応じて togusa / bato / tachikoma を spawn (agmsg の spawn.sh、要 operator GO) するか、手動起動を依頼してくる。

**他の役割を自分で直接立ち上げる場合** (名前だけ差し替え、モデルは編成表に合わせて `/model` で設定):

```
/agmsg actas togusa した後、~/dotfiles/claude/team-roles.md を読んで自分の役割・boundaries を確認し、motoko に読了 ack を送って指示を待って
```

**モデル/effort の注意**: 開始フレーズではモデルは切り替わらない (エージェントは自分のモデルを変えられない)。新セッションは保存済みデフォルトで立ち上がり、`/model` は打つたびにデフォルトも上書きするので、worker で打つと次の motoko まで変わってしまう。**worker は motoko からの spawn (`spawn.sh claude-code <name> --model sonnet ...`) が推奨** — プロセス単位の指定でデフォルトを汚さない。手動起動時のみ `/model` で都度設定 (次回 motoko 起動時にデフォルトを Fable 5 に戻すのを忘れない)。

### 運用メモ

- agmsg 本体: `~/.agents/skills/agmsg/` (b821759 以降、spawn/despawn あり)。更新時は clone した repo で `./install.sh --update` (DB・team 設定は保持される)
- 更新後は実行中 watcher の再起動が必要。旧形式 actas lock が残って「cannot claim (held by other sessions)」になったら、該当の `~/.agents/skills/agmsg/run/actas.<team>__<name>.session` を削除して actas-claim.sh で取り直す (2026-07-15 に 2b で実績あり)
