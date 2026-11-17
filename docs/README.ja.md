<h1 align="center">
  <br>
  <a href="https://tryglance.app"><img src="../glance/Assets.xcassets/appicon.imageset/appicon.png" alt="Glance" width="150"></a>
  <br>
  Glance
  <br>
</h1>

<h3 align="center">Mac を顔でロック解除</h3>

<p align="center">
  <a href="../README.md" lang="en">English</a> ·
  <a href="README.zh-CN.md" lang="zh-CN">简体中文</a> ·
  <a href="README.ja.md" lang="ja">日本語</a> ·
  <a href="README.es.md" lang="es">Español</a> ·
  <a href="README.fr.md" lang="fr">Français</a> ·
  <a href="README.de.md" lang="de">Deutsch</a> ·
  <a href="README.pt-BR.md" lang="pt-BR">Português (Brasil)</a> ·
  <a href="README.tr.md" lang="tr">Türkçe</a>
</p>

<p align="center">
  <a href="../LICENSE"><img src="https://img.shields.io/badge/license-MIT-black.svg" alt="MIT ライセンス"></a>
  <img src="https://img.shields.io/badge/macOS-15%2B-black.svg" alt="macOS 15+">
  <img src="https://img.shields.io/badge/Swift-SwiftUI-black.svg" alt="Swift">
</p>

Glance は、iPhone の Face ID のような体験を Mac に届けます。Mac に視線を向けるだけでロック解除でき、パスワード入力や Touch ID キーに手を伸ばす必要はありません。Apple の Vision と Core ML フレームワークを使い、すべての処理をデバイス上で行います。顔データや Mac のパスワードがインターネットに送信されることはありません。UI は MacBook のノッチに組み込まれ、Dynamic Island のような滑らかなアニメーションを表示します。

https://github.com/user-attachments/assets/77438826-80a9-4ab2-9fc3-42407a2d0adb

---

> [!WARNING]
> ## ダウンロード前にお読みください
> ## Glance の安全性は Apple の Face ID や Touch ID には及びません
>
> MacBook には、iPhone の Face ID の信頼性と安全性を支える深度センサーがありません。iPhone は顔の 3D マップを作成しますが、MacBook のカメラが捉えるのは平面の 2D 画像です。そのため、次の制約があります。
>
> - Glance は、印刷した写真やスマートフォンの画面に表示した写真によるなりすましを、ある程度の確度で防げます（高強度の生体検知を有効にする必要があります）。
> - 本人の動画を使ったなりすましは、確実には防げません。
> - macOS にはサードパーティ製アプリがログインを承認するための API がないため、Glance は保存したパスワードをロック画面に入力してロックを解除します。
>
> Glance は利便性を高める機能であり、セキュリティを強化するものではありません。このトレードオフを受け入れたうえでご利用ください。

## インストール

**動作要件**

- macOS 15 Sequoia 以降
- Apple シリコンまたは Intel 搭載の Mac

<a href="https://github.com/perryles/glance/releases/latest/download/Glance-1.2.1.dmg" target="_self"><img width="200" src="https://github.com/user-attachments/assets/cdb8af97-1ee2-4669-b7cb-dcfb56c9dd61" alt="Mac 版をダウンロード" /></a>

`.dmg` ファイルを開き、Glance を `/Applications` にドラッグしてから起動してください。

## アクセス権限

| 権限 | 用途 |
|---|---|
| **カメラ** | 顔を検出します。フレームはメモリ内で処理され、ディスクには保存されません。 |
| **アクセシビリティ** | ロック画面にパスワードを入力します。 |
| **Touch ID** | 顔データとパスワードの暗号化に使う鍵へのアクセスを保護します。 |

## 仕組み

1. アプリを起動し、初期設定に従って顔を登録します。Glance の案内に沿って頭を 9 方向に動かすと、各フレームが 512 個の数値からなる*埋め込みベクトル*（数学的な特徴表現）に変換され、元の画像は破棄されます。
2. Mac のパスワードを一度入力します。パスワードは暗号化され、Touch ID で保護されます。
3. Mac がロックされたときやスリープから復帰したとき、ノッチにアニメーションが表示され、顔の検出を開始します。
4. 顔が一致し、生体検知で実際の人物と判定されると、Glance がパスワードを入力してロックを解除します。

## 機能

| 機能 | 説明 |
|---|---|
| **顔認証によるロック解除** | スリープ復帰時、ロック時、ロック画面でスペースキーを押したときに起動できます。自由に組み合わせられます。 |
| **複数の登録情報** | 複数人の顔や、眼鏡、ひげ、照明などの条件が異なる自分の顔を登録できます。削除せず個別に無効化できます。 |
| **生体検知** | 動きや反射を使って実際の顔と写真を区別します。低強度、高強度、オフから選べます。 |
| **ノッチ UI** | カプセル型の表示がスキャンアニメーションへと広がり、成功や失敗を表示します。ポインタを重ねると再試行できます。アニメーションを完全にオフにして非表示で動作させることもできます。 |
| **カメラとディスプレイ** | 使用するカメラを選択でき、内蔵ディスプレイと外部モニターに別々のカメラを設定できます。 |
| **セッションの自動ロック** | 設定した無操作時間が経過すると Touch ID の認証セッションが再ロックされ、放置した Mac がいつまでも認証済みの状態になるのを防ぎます。 |
| **トラックパッドの触覚フィードバック** | ノッチにポインタを重ねると触覚フィードバックが発生します。 |
| **ノッチのない Mac に対応** | ノッチがない Mac では、Dynamic Island 風のカプセル型 UI を表示します。 |
| **データの管理** | 登録情報や保存したパスワードをいつでも編集・削除できます。暗号化されたファイルは直ちに削除されます。 |

---

# プライバシーとセキュリティ

Glance は、生体認証データと認証情報をデバイス内に保持するよう設計されています。

### 顔データ

Glance はカメラ画像を保存しません。登録時には、ArcFace ベースの Core ML モデルで、撮影した顔を **512 次元の埋め込みベクトル**に変換します。その後、元のフレームを破棄します。

埋め込みベクトルは **AES-GCM** で暗号化し、ローカルに保存します。

### 認証情報

Mac のパスワードは暗号化して保存され、平文でディスクに書き込まれることはありません。暗号鍵は **macOS キーチェーンに保存された 256 ビットの AES 鍵**で、`userPresence` によって保護され、Touch ID またはデバイスのパスワードによる認証が必要です。

鍵がメモリに保持されるのは、認証済みの Glance セッションが有効な間だけです。

### ロック解除の流れ

Glance がパスワードを入力するには、次のすべての条件を満たす必要があります。

1. 有効な Glance セッションが認証されている。
2. Mac が実際にロック画面を表示している。
3. 有効な登録情報との類似度が、設定されたしきい値を超えている。
4. 検出した顔が生体検知を通過している。
5. パスワード入力に必要なアクセシビリティ権限がある。

顔認識と生体検知は独立して動作し、両方に成功してからパスワードを入力します。

### ローカルでの処理

顔認識、顔登録、生体検知は、Vision と Core ML を使ってすべてデバイス上で実行されます。Glance は顔データ、カメラのフレーム、認証情報をサーバーへ送信しません。

### 顔と写真を見分ける方法

約 2 秒のローリングウィンドウで、役割の異なる 5 つの独立した手掛かりを調べます。

- **拒否の手掛かり**は、画面の反射や顔を囲むデバイス形状の長方形など、なりすましの証拠です。どちらかが検出されると、ほかの結果にかかわらずスキャンは失敗します。
- **確認の手掛かり**は、顔の特徴点が平面か立体かという幾何学的特徴、首を振ったときの鼻の視差、まばたきなど、実際の顔の証拠です。どれか 1 つで十分です。実際の人でも静止したまままばたきをしないことがあるため、検出されないこと自体は失敗の理由になりません。

低強度の検知では拒否の手掛かりだけを使います。高強度では拒否と確認の両方を使います。

### Face Lab

Face Lab は、実際の数値を確認しながら顔認識と生体検知をテストできる隠しデバッグコンソールです。

設定 → このアプリについて を開き、アプリアイコンを 5 回クリックすると、サイドバーにデバッグ項目が表示されます。

---

## ソースからのビルド

### 必要な環境

- macOS 15+
- Xcode 26+

### 手順

1. リポジトリをクローンします。

   ```bash
   git clone https://github.com/jonnyoo/glance.git
   cd glance
   ```

2. Xcode で開きます。

   ```bash
   open glance.xcodeproj
   ```

3. 実行ボタンをクリックするか、`Cmd + R` を押します。

## コントリビューション

現在、PR は受け付けていません。このプロジェクトのフォークは歓迎します。

アプリへのフィードバックは [tryglance.app/feedback](https://tryglance.app/feedback) にお寄せください。

## 謝辞

- **[The Boring Notch](https://github.com/TheBoredTeam/boring.notch)** — ノッチウィンドウの物理的な動き。
- **[InsightFace](https://github.com/deepinsight/insightface)** — 顔認識に使用する ArcFace モデル。
- **[Alcove](https://tryalcove.com)** — デザインに大きなインスピレーションを与えてくれました。

## ライセンス

[MIT](../LICENSE) © Jonathan Zhou
