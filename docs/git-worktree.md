# git worktree で Claude 並列作業

1つのリポジトリから複数の作業ディレクトリ(worktree)を切り出し、別ブランチで複数のClaudeを
同時に走らせる。各worktreeは独立ディレクトリなので互いに衝突しない。

`.zshrc` にヘルパーを定義済み。worktree置き場は `<repo親>/<repo名>.wt/<branch>`。

| コマンド | 動作 |
|---|---|
| `wt <branch>` | worktree作成(無ければブランチも新規作成)。tmux内なら新ウィンドウ `<repo>-<branch>` で開く |
| `wtl` | worktree一覧（`git worktree list`） |
| `wtrm <branch>` | worktree削除（`git worktree remove`） |

## 並列ワークフロー

```
1. プロジェクトで  wt feature-a   → 新ウィンドウが開く（worktree = feature-aブランチ）
2. そのウィンドウで claude / dev  → feature-a 専用のClaude
3. 元ウィンドウのClaudeは別ブランチで継続（衝突なし）
4. Alt+h/l でウィンドウを行き来して並行監視
5. 完了したら wtrm feature-a（ブランチ削除は git branch -D <branch> で別途）
```

## 補足

- worktree間でブランチは共有しない（同じブランチを2つのworktreeにcheckoutはできない）。
- 複数Claudeの協調が必要なら、リポジトリ直下に `TASKS.md` を置き各Claudeが読み書きするパターンが有効。
- プロジェクト固有の環境変数(PORT等)をworktreeごとに変えたい場合は direnv + `.envrc` の導入を検討。
