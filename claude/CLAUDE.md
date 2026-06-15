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
