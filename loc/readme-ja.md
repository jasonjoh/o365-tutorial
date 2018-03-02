# <a name="getting-started-with-the-outlook-mail-api-and-ruby-on-rails"></a>Outlook メール API と Ruby on Rails の使用を開始する #

このサンプル アプリは [https://docs.microsoft.com/ja-jp/outlook/rest/ruby-tutorial](https://docs.microsoft.com/en-us/outlook/rest/ruby-tutorial) のチュートリアルの結果を示します。 このチュートリアルを実行すると、このリポジトリ内のコードに非常に近い結果が得られるはずです。

> **注:** Microsoft Graph ではなく、Outlook API を直接使用するチュートリアル バージョンをお探しの場合は、 `outlook-api` ブランチをご覧ください。 Microsoft は、メール、予定表、連絡先へのアクセスに Microsoft Graph を使用することをお勧めしています。 Graph エンドポイントで利用できない機能が必要な場合にのみ、Outlook API を直接 (https://outlook.office.com/api から) 使用してください。

## <a name="running-the-sample"></a>サンプルの実行

このチュートリアルを実行せず、このリポジトリをダウンロードして試すだけの場合は、最初にいくつかの操作を実行する必要があります。

### <a name="setup-your-dev-environment"></a>開発環境のセットアップ

このガイドは、以下を前提としています。

- Ruby on Rails がインストール済みで、開発用コンピューターで動作すること。 
- Office 365 のテナントを持ち、そのテナントのアカウントにアクセス権があること、**または** Outlook.com のアカウントを持っていること。

### <a name="register-the-app"></a>アプリを登録する

クライアント ID とシークレットを素早く取得するには、https://apps.dev.microsoft.com にアクセスします。サインインのボタンを使用し、Microsoft アカウント (Outlook.com) か職場または学校アカウント (Office 365) のいずれかを使用してサインインします。

![アプリケーション登録ポータル サインイン ページ](readme-images/sign-in.PNG)

サインインしたら、**[アプリの追加]** をクリックします。名前に「`o365-tutorial`」を入力し、**[アプリケーションの作成]** をクリックします。アプリを作成したら、**[アプリケーション シークレット]** セクションを検索し、**[新しいパスワードを生成する]** をクリックします。ここでパスワードをコピーし、安全な場所に保存します。パスワードをコピーしたら、**[OK]** をクリックします。

![新しいパスワードのダイアログ。](readme-images/new-password.PNG)

**[プラットフォーム]** セクションを検索し、**[プラットフォームの追加]** をクリックします。**[Web]** を選択し、**[リダイレクト URI]** に「`http://localhost:3000/authorize`」を入力します。**[保存]** をクリックし、登録を完了します。**[アプリケーション ID]** をコピーし、先ほどコピーしたパスワードとともに保存します。後ほど、これらの値が必要になります。

完了後のアプリケーション登録の詳細は、次のように表示されます。

![完了後の登録のプロパティ。](readme-images/ruby-tutorial.PNG)

これが完了すると、クライアント ID とシークレットが得られます。[auth_helper.rb](app/helpers/auth_helper.rb) で `<YOUR APP ID HERE>` と `<YOUR APP PASSWORD HERE>` のプレースホルダーをこれらの値に置き換え、変更内容を保存します。

### <a name="install-dependencies-and-initialize-project"></a>依存関係をインストールしてプロジェクトを初期化する

このプロジェクトのルートでコマンド プロンプト/シェルから次のコマンドを実行します。

```Shell
bundle install
rails db:migrate
```

### <a name="start-the-rails-server"></a>Rails サーバーを起動する

このプロジェクトのルートでコマンド プロンプト/シェルから次のコマンドを実行します。

```Shell
rails server
```

[http://localhost:3000](http://localhost:3000) を参照します。

## <a name="copyright"></a>Copyright ##

Copyright (c) Microsoft.All rights reserved.

----------
Twitter ([@JasonJohMSFT](https://twitter.com/JasonJohMSFT)) をぜひフォローしてください。

[Outlook/Exchange 開発ブログ](http://blogs.msdn.com/b/exchangedev/)をフォローする