# Outlook メール API と Ruby on Rails の使用を開始する #

[日本 (日本語)](https://github.com/jasonjoh/o365-tutorial/blob/master/loc/readme-ja.md) (日本語)

このガイドの目的は、Office 365 または Outlook.com でユーザーのデータにアクセスする単純な Ruby on Rails アプリを作成するプロセスを手順を追って説明することです。このリポジトリ内のソース コードは、ここで概説する手順に従った場合の最終結果を示しています。

## 始める前に ##

このガイドは、以下を前提としています。

- Ruby on Rails がインストール済みで、開発用コンピューターで動作すること。 
- Office 365 のテナントを持ち、そのテナントのアカウントにアクセス権があること、**または** Outlook.com の開発者プレビューのアカウントを持っていること。

## アプリを作成する ##

では始めましょう!コマンド ラインから、ご使用のディレクトリを、新しい Ruby on Rails アプリを作成する目的のディレクトリに変更します。次のコマンドを実行して、`o365-tutorial` というアプリを作成します (**注:** 名前は希望する名前に自由に変更できます。このガイドの目的から、アプリの名前を `o365-tutorial` と仮定します)。

    rails new o365-tutorial

Ruby on Rails を熟知している場合は、新しい情報は何もありません。それを初めて使う場合は、コマンドによって、多数のファイルとディレクトリが含まれた `o365-tutorial` サブディレクトリが作成されていることが分かります。これらのほとんどは、このガイドの目的にとって重要ではないため、あまり心配することはありません。

コマンド ラインで、ディレクトリを `o365-tutorial` サブディレクトリに変更します。それでは少し回り道をして、アプリが正常に作成されたことを確認しましょう。次のコマンドを実行します。

    rails server

ブラウザーを開き、[http://localhost:3000](http://localhost:3000) に移動します。既定の Ruby on Rails のウェルカム ページが表示されます。

![既定の Ruby on Rails のウェルカム ページ。](https://raw.githubusercontent.com/jasonjoh/o365-tutorial/master/readme-images/default-ruby-page.PNG)

Ruby on Rails が動作していることを確認したので、実際の作業をする準備が整いました。

## アプリを設計する ##

アプリは非常にシンプルになります。ユーザーがサイトにアクセスすると、ログインして、自分の電子メールを表示するためのリンクが表示されます。そのリンクをクリックすると、ユーザーは Azure のログイン ページに移動します。このページで、ユーザーは自分の Office 365 または Outlook.com のアカウントを使用してログインし、アプリへのアクセス権を付与できます。最後に、ユーザーはアプリにリダイレクトされます。アプリは、ユーザーの受信トレイに最新の電子メールの一覧を表示します。

最初に、既定のウェルカム ページを自分のページに置き換えましょう。そのためには、`.\o365-tutorial\app\controllers\application_controller.rb` ファイルに配置されたアプリケーション コントローラーを変更します。お好みのテキスト エディターでこのファイルを開きます。次の一覧に示すとおり、非常に単純な小さい HTML を表示する `home` アクションを定義しましょう。

### `.\o365-tutorial\app\controllers\application_controller.rb` ファイルのコンテンツ ###

```ruby
class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  
  def home
    # Display the login link.
    render html: '<a href="#">Log in and view my email</a>'.html_safe
  end
end
```

お分かりのように、非常に単純なホーム ページになります。現在のところ、リンクは機能しませんが、すぐに修復します。まず、Rails にこのアクションを呼び出すよう伝える必要があります。そのためには、ルートを定義する必要があります。`.\o365-tutorial\config\routes.rb` ファイルを開き、既定のルート (「root」) を、定義した `home` アクションに設定します。

### `.\o365-tutorial\config\routes.rb` ファイルのコンテンツ ###

```ruby
Rails.application.routes.draw do
  root 'application#home'
end
```

変更内容を保存します。[http://localhost:3000](http://localhost:3000) をブラウズすると次のようになります。

![アプリのホーム ページ。](https://raw.githubusercontent.com/jasonjoh/o365-tutorial/master/readme-images/home-page.PNG)

## OAuth2 を実装する ##

このセクションの目標は、ホーム ページ上のリンクから [Azure AD による OAuth2 承認コードの付与フロー](https://msdn.microsoft.com/en-us/library/azure/dn645542.aspx)を開始することです。より簡単にするには、[oauth2 gem](https://github.com/intridea/oauth2) を使用して、OAuth 要求を処理します。セッションをデータベースに格納するために [activerecord session_store gem](https://github.com/rails/activerecord-session_store) も使用します。`./o365-tutorial/GemFile` を開き、次の行をそのファイルの任意の場所に追加します。

    gem 'oauth2'
    gem 'activerecord-session_store'

ファイルを保存し、次のコマンドを実行します (後で Rails サーバーを再起動します)。

    bundle install

次に、セッション ストレージで `activerecord-session_store` gemを使えるようにアプリを構成しましょう。これを行う理由は、既定の Cookie ストアのデータ量が 4 KB に制限されており、 Azure から返されるトークンを格納するのに十分でないためです。

`.\o365-tutorial\config\initializers\session_store.rb` ファイルを開きます。テキスト `:cookie_store` を `:active_record_store` に置換します。

コマンド ラインに次のコマンドを入力して、セッション データベースを生成します。

    rails generate active_record:session_migration
    rails db:migrate

OAuth2 フローの性質上、Azure からのリダイレクトを処理するコントローラーを作成することは意味を成します。`Auth` という名前のコントローラーを生成するには、次のコマンドを実行します。

    rails generate controller Auth

`.\o365-tutorial\app\helpers\auth_helper.rb` ファイルを開きます。最初に、ログイン URL を生成する関数を定義します。

### `.\o365-tutorial\app\helpers\auth_helper.rb` ファイルのコンテンツ ###

```ruby
module AuthHelper

  # App's client ID. Register the app in Application Registration Portal to get this value.
  CLIENT_ID = '<YOUR APP ID HERE>'
  # App's client secret. Register the app in Application Registration Portal to get this value.
  CLIENT_SECRET = '<YOUR APP PASSWORD HERE>'

  # Scopes required by the app
  SCOPES = [ 'openid',
             'https://outlook.office.com/mail.read' ]
  
  REDIRECT_URI = 'http://localhost:3000/authorize' # Temporary!

  # Generates the login URL for the app.
  def get_login_url
    client = OAuth2::Client.new(CLIENT_ID,
                                CLIENT_SECRET,
                                :site => 'https://login.microsoftonline.com',
                                :authorize_url => '/common/oauth2/v2.0/authorize',
                                :token_url => '/common/oauth2/v2.0/token')
                              
    login_url = client.auth_code.authorize_url(:redirect_uri => REDIRECT_URI, :scope => SCOPES.join(' '))
  end
end
```

最初にすることは、クライアント ID とシークレット、およびアプリに必要なアクセス許可スコープを定義することです。また、ハードコーディング値としてリダイレクト URI を定義します。この点は少し改善される予定ですが、現時点でこのガイドの目的に対応しています。ここで、クライアント ID とシークレットの値を生成する必要があります。

### クライアント ID とシークレットを生成する ###

クライアント ID とシークレットを素早く取得するには、https://apps.dev.microsoft.com にアクセスします。サインインのボタンを使用し、Microsoft アカウント (Outlook.com) か職場または学校アカウント (Office 365) のいずれかを使用してサインインします。

![アプリケーション登録ポータル サインイン ページ](https://raw.githubusercontent.com/jasonjoh/o365-tutorial/master/readme-images/sign-in.PNG)

サインインしたら、**[アプリの追加]** をクリックします。名前に「`o365-tutorial`」を入力し、**[アプリケーションの作成]** をクリックします。アプリを作成したら、**[アプリケーション シークレット]** セクションを検索し、**[新しいパスワードを生成する]** をクリックします。ここでパスワードをコピーし、安全な場所に保存します。パスワードをコピーしたら、**[OK]** をクリックします。

![新しいパスワードのダイアログ。](https://raw.githubusercontent.com/jasonjoh/o365-tutorial/master/readme-images/new-password.PNG)

**[プラットフォーム]** セクションを検索し、**[プラットフォームの追加]** をクリックします。**[Web]** を選択し、**[リダイレクト URI]** に「`http://localhost:3000/authorize`」を入力します。**[保存]** をクリックし、登録を完了します。**[アプリケーション ID]** をコピーし、先ほどコピーしたパスワードとともに保存します。後ほど、これらの値が必要になります。

完了後のアプリケーション登録の詳細は、次のように表示されます。

![完了後の登録のプロパティ。](https://raw.githubusercontent.com/jasonjoh/o365-tutorial/master/readme-images/ruby-tutorial.PNG)

これが完了すると、クライアント ID とシークレットが得られます。`<YOUR APP ID HERE>` と `<YOUR APP PASSWORD HERE>` のプレースホルダーをこれらの値に置き換え、変更内容を保存します。

### コーディングに戻る ###

`get_login_url` 関数に実際の値が得られたので、関数が機能するようにしましょう。このメソッドを使用してリンクに記入するには、`home` の `ApplicationController` アクションを変更します。この関数にアクセスできるようにするには、`AuthHelper` モジュールを含める必要があります。

#### `.\o365-tutorial\app\controllers\application_controller.rb` ファイルの更新されたコンテンツ ####

```ruby
class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  include AuthHelper
  
  def home
    # Display the login link.
    login_url = get_login_url
    render html: "<a href='#{login_url}'>Log in and view my email</a>".html_safe
  end
end
```

変更内容を保存し、[http://localhost:3000](http://localhost:3000) を参照します。マウス カーソルをリンクの上に重ねると、次のように表示されます。

    https://login.microsoftonline.com/common/oauth2/v2.0/authorize?client_id=<SOME GUID>&redirect_uri=http%3A%2F%2Flocalhost%3A3000%2Fauthorize&response_type=code&scope=openid+https%3A%2F%2Foutlook.office.com%2Fmail.read

`<SOME GUID>` の部分は、クライアント ID と一致する必要があります。リンクをクリックすると、次のサインイン ページが表示されます。

![Azure サインイン ページ](https://raw.githubusercontent.com/jasonjoh/o365-tutorial/master/readme-images/azure-sign-in.PNG)

Office 365 アカウントでサインインします。ブラウザーがアプリにリダイレクトするとともに、次のエラーが表示されます。

    No route matches [GET] "/authorize"

Rails のエラー ページをスクロールすると、承認コードを含む、要求のパラメーターが表示されます。

    Parameters:
        {"code"=>"M2ff0cb19-ec9d-db94-c5ab-4c634e319315"}

エラーが表示される理由は、リダイレクト URI としてハードコーディングした `/authorize` パスを処理するルートを実装していないためです。しかし、Rails は、要求において承認コードを取得していることを示していました。方向としては正しいわけです。では、このエラーを修復しましょう。

### トークン用にコードを交換する ###

最初に、`/authorize` への `routes.rb` のパスのルートを追加しましょう。

#### `.\o365-tutorial\config\routes.rb` ファイルの更新されたコンテンツ ####

```ruby
Rails.application.routes.draw do
  root 'application#home'
  get 'authorize' => 'auth#gettoken'
end
```

追加された行は、`/authorize` で GET 要求を受信すると、`gettoken` コントローラーで `auth` アクションを呼び出すことを Rails に伝えます。したがって、これを機能させるには、対象のアクションを実装する必要があります。`.\o365-tutorial\app\controllers\auth_controller.rb` ファイルを開き、`gettoken` アクションを定義します。

#### `.\o365-tutorial\app\controllers\auth_controller.rb` ファイルのコンテンツ ####

```ruby
class AuthController < ApplicationController

  def gettoken
    render text: params[:code]
  end
end
```

この新しいコードを試行する前に、最後にもう 1 つ改良しましょう。リダイレクト URI へのルートができたので、`auth_helper.rb` のハードコーディングされた定数を削除できます。代わりに、ルートの Rails 名 `authorize_url` を使用します。

#### `.\o365-tutorial\app\helpers\auth_helper.rb` ファイルの更新されたコンテンツ ####

```ruby
module AuthHelper

  # App's client ID. Register the app in Application Registration Portal to get this value.
  CLIENT_ID = '<YOUR APP ID HERE>'
  # App's client secret. Register the app in Application Registration Portal to get this value.
  CLIENT_SECRET = '<YOUR APP PASSWORD HERE>'

  # Scopes required by the app
  SCOPES = [ 'openid',
             'https://outlook.office.com/mail.read' ]

  # Generates the login URL for the app.
  def get_login_url
    client = OAuth2::Client.new(CLIENT_ID,
                                CLIENT_SECRET,
                                :site => "https://login.microsoftonline.com",
                                :authorize_url => "/common/oauth2/v2.0/authorize",
                                :token_url => "/common/oauth2/v2.0/token")
                              
    login_url = client.auth_code.authorize_url(:redirect_uri => authorize_url, :scope => SCOPES.join(' '))
  end
end
```

ご使用のブラウザーを更新します (または、サインイン処理を繰り返します)。ここで、Rails のエラー ページの代わりに、画面上に出力された承認コードの値が表示されます。完成に近づいてきましたが、まだ非常に便利な状態ではありません。実際にコードで何かしてみましょう。

`auth_helper.rb` と呼ばれる、`get_token_from_code` に対するもう 1 つのヘルパー関数を追加してみましょう。

#### `get_token_from_code` ファイル内の `.\o365-tutorial\app\helpers\auth_helper.rb` ####

```ruby
# Exchanges an authorization code for a token
def get_token_from_code(auth_code)
  client = OAuth2::Client.new(CLIENT_ID,
                              CLIENT_SECRET,
                              :site => 'https://login.microsoftonline.com',
                              :authorize_url => '/common/oauth2/v2.0/authorize',
                              :token_url => '/common/oauth2/v2.0/token')

  token = client.auth_code.get_token(auth_code,
                                     :redirect_uri => authorize_url,
                                     :scope => SCOPES.join(' '))
end
```

### ユーザーの電子メール アドレスの取得 ###

Outlook の API からユーザーの電子メール アドレスを取得するときに、はじめてアクセス トークンを使用します。これが必要な理由は、後で分かります。

`auth_helper.rb` に新しい関数 `get_user_email` を追加する

#### `get_user_email` ファイル内の `.\o365-tutorial\app\helpers\auth_helper.rb` ####

```ruby
# Gets the user's email from the /Me endpoint
def get_user_email(access_token)
  conn = Faraday.new(:url => 'https://outlook.office.com') do |faraday|
    # Outputs to the console
    faraday.response :logger
    # Uses the default Net::HTTP adapter
    faraday.adapter  Faraday.default_adapter  
  end

  response = conn.get do |request|
    # Get user's info from /Me
    request.url 'api/v2.0/Me'
    request.headers['Authorization'] = "Bearer #{access_token}"
    request.headers['Accept'] = 'application/json'
  end

  email = JSON.parse(response.body)['EmailAddress']
end
```

動作することを確認してみましょう。`gettoken` ファイルで `auth_controller.rb` アクションを変更すると、これらのヘルパー関数を使用して戻り値を表示できます。

#### `.\o365-tutorial\app\controllers\auth_controller.rb` ファイルの更新されたコンテンツ ####

```ruby
class AuthController < ApplicationController

  def gettoken
    token = get_token_from_code params[:code]
    email = get_user_email token.token
    render text: "Email: #{email}, TOKEN: #{token.token}"
  end
end
```

変更内容を保存して、サインイン処理をもう一度実行すると、ユーザーの電子メールとともに、一見意味不明な文字の長い文字列が表示されます。計画に従ってすべてが完了すれば、これがアクセス トークンになります。

ここで、トークンを表示するのではなく、セッション Cookie に格納するようコードを変更しましょう。

#### 新しいバージョンの `gettoken` アクション ####

```ruby
def gettoken
  token = get_token_from_code params[:code]
  session[:azure_token] = token.to_hash
  session[:user_email] = get_user_email token.token
  render text: "Access token saved in session cookie."
end
```

### アクセス トークンを更新する

Azure から返されるアクセス トークンの有効期限は 1 時間です。期限切れになった後にトークンを使用すると、API 呼び出しから 401 エラーが返されます。ユーザーにもう一度サインインするよう求めることもできますが、それより良い方法として、トークンを更新することができます。

これを行うために、アプリで `offline_access` スコープを要求する必要があります。このスコープを `auth_helper.rb` にある `SCOPES` 配列に追加します。

```ruby
# Scopes required by the app
SCOPES = [ 'openid',
           'offline_access',
           'https://outlook.office.com/mail.read' ]
```

これにより、Azure から更新トークンを含めるためのトークン応答が発せられます。次にヘルパー メソッドを `auth_helper.rb` に追加してキャッシュされたトークンを取得し、有効期限が切れていないか確認し、期限切れの場合は更新します。

#### `.\o365-tutorial\app\helpers\auth_helper.rb` ファイル内の `get_access_token` ####

```ruby
# Gets the current access token
def get_access_token
  # Get the current token hash from session
  token_hash = session[:azure_token]

  client = OAuth2::Client.new(CLIENT_ID,
                              CLIENT_SECRET,
                              :site => 'https://login.microsoftonline.com',
                              :authorize_url => '/common/oauth2/v2.0/authorize',
                              :token_url => '/common/oauth2/v2.0/token')

  token = OAuth2::AccessToken.from_hash(client, token_hash)

  # Check if token is expired, refresh if so
  if token.expired?
    new_token = token.refresh!
    # Save new token
    session[:azure_token] = new_token.to_hash
    access_token = new_token.token
  else
    access_token = token.token
  end
end
```

## メール API を使用する ##

アクセス トークンを取得できたので、メール API を使って何かを実行する良いタイミングになりました。メール操作のコントローラーを作成することから始めましょう。

    rails generate controller Mail index

これは、`Auth` コントローラーの生成方法とは若干異なります。今回は、アクションの名前 `index` を渡しました。Rails は自動的にこのアクションのルートを追加し、ビュー テンプレートを生成します。

ここで、最後に、メール コントローラーのインデックス アクションをリダイレクトするために `gettoken` アクションを変更します。

### 新しいバージョンの `gettoken` アクション ###

```ruby
def gettoken
  token = get_token_from_code params[:code]
  session[:azure_token] = token.to_hash
  session[:user_email] = get_user_email token.token
  redirect_to mail_index_url
end
```

アプリのサインイン処理を進めて、http://localhost:3000/mail/index にたどり着きました。もちろん、このページでは何もできないので、修復しましょう。

### REST を呼び出す ###

REST を呼び出すには、[Faraday gem](https://github.com/lostisland/faraday) をインストールします。この Gem は、要求の送受信を非常に簡単にします。`Gemfile` ファイルを開き、ファイルの任意の場所に次の行を追加します。

    gem 'faraday'

ファイルを保存し、`bundle install` を実行してから、サーバーを再起動します。これで、`index` コントローラーに `Mail` アクションを実装する準備ができました。`.\o365-tutorial\app\controllers\mail_controller.rb` ファイルを開き、次のように `index` アクションを定義します。

#### `.\o365-tutorial\app\controllers\mail_controller.rb` ファイルのコンテンツ ####

```ruby
class MailController < ApplicationController

  include AuthHelper

  def index
    token = get_access_token
    email = session[:user_email]
    if token
      # If a token is present in the session, get messages from the inbox
      conn = Faraday.new(:url => 'https://outlook.office.com') do |faraday|
        # Outputs to the console
        faraday.response :logger
        # Uses the default Net::HTTP adapter
        faraday.adapter  Faraday.default_adapter  
      end
      
      response = conn.get do |request|
        # Get messages from the inbox
        # Sort by ReceivedDateTime in descending orderby
        # Get the first 20 results
        request.url '/api/v2.0/Me/Messages?$orderby=ReceivedDateTime desc&$select=ReceivedDateTime,Subject,From&$top=20'
        request.headers['Authorization'] = "Bearer #{token}"
        request.headers['Accept'] = 'application/json'
        request.headers['X-AnchorMailbox'] = email
      end
      
      # Assign the resulting value to the @messages
      # variable to make it available to the view template.
      @messages = JSON.parse(response.body)['value']
    else
      # If no token, redirect to the root url so user
      # can sign in.
      redirect_to root_url
    end
  end
end
```

`index` アクションのコードの実行内容をまとめると、次のようになります。

- メール API のエンドポイント (https://outlook.office.com) への接続を作成します。
- 受信トレイのメッセージの URL に、次の特性を持つ GET 要求を発行します。
    - [クエリ文字列](https://msdn.microsoft.com/office/office365/APi/complex-types-for-mail-contacts-calendar#UseODataqueryparameters) `?$orderby=ReceivedDateTime desc&$select=ReceivedDateTime,Subject,From&$top=20` を使用して、結果を `ReceivedDateTime` で並べ替えます。また、[`ReceivedDateTime`]、[`Subject`]、[`From`] の各フィールドのみを要求し、結果を最初の 20 個に制限します。
    - `Authorization` ヘッダーを、Azure からのアクセス トークンを使用するように設定します。
    - `Accept` ヘッダーを、JSON が必要とされていることを通知するように設定します。
    - `X-AnchorMailbox`ヘッダーを、ユーザーの電子メール アドレスに設定します。このヘッダーの設定により、API エンドポイントが、API 呼び出しを適切なバックエンド メールボックス サーバーへ、より効率的にルーティングされます。
- JSON として応答本体を解析し、`value` のハッシュを `@messages` 変数に割り当てます。この変数は、ビュー テンプレートで使用可能になります。

### 結果を表示する ###

ここで、`index` 変数を使用するように、`@messages` アクションに関連するビュー テンプレートを変更する必要があります。`.\o365-tutorial\app\views\mail\index.html.erb` ファイルを開き、内容を次のように置き換えます。

#### `.\o365-tutorial\app\views\mail\index.html.erb` ファイルのコンテンツ ####

```erb
<h1>My messages</h1>
<table>
  <tr>
  <th>From</th>
  <th>Subject</th>
  <th>Received</th>
  </tr>
  <% @messages.each do |message| %>
  <tr>
    <td><%= message['From']['EmailAddress']['Name'] %></td>
    <td><%= message['Subject'] %></td>
    <td><%= message['ReceivedDateTime'] %></td>
  </tr>
  <% end %>
</table>
```

テンプレートは、非常に単純な HTML テーブルです。埋め込まれた Ruby を使用して、`@messages` アクションで設定した `index` 変数の結果を反復処理し、メッセージごとにテーブル行を作成します。各メッセージの値にアクセスする構文は簡単です。メッセージの送信者の表示名を抽出する方法に注意してください。

```erb
<%= message['From']['EmailAddress']['Name'] %>
```

これにより、次の `From` 値の JSON 構造のミラー操作が実行されます。

```json
"From": {
  "@odata.type": "#Microsoft.OutlookServices.Recipient",
  "EmailAddress": {
  "@odata.type": "#Microsoft.OutlookServices.EmailAddress",
  "Address": "jason@contoso.com",
  "Name": "Jason Johnston"
  }
}
```

変更を保存し、アプリにサインインします。受信トレイに、簡単なメッセージのテーブルが表示されます。

![受信トレイの内容を表示する HTML テーブル。](https://raw.githubusercontent.com/jasonjoh/o365-tutorial/master/readme-images/simple-inbox-listing.PNG)

## 次の手順 ##

作業用サンプルを作成したら、[メール API の機能](https://msdn.microsoft.com/office/office365/APi/mail-rest-operations)の詳細について学習することができます。サンプルが動作していないため比較する場合は、[GitHub](https://github.com/jasonjoh/o365-tutorial) からこのチュートリアルの最終結果をダウンロードしてください。

## 著作権 ##

Copyright (c) Microsoft. All rights reserved.

----------
Twitter ([@JasonJohMSFT](https://twitter.com/JasonJohMSFT)) をぜひフォローしてください。

[Outlook/Exchange 開発ブログ](http://blogs.msdn.com/b/exchangedev/)をフォローする