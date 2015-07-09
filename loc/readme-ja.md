# Outlook メール API と Ruby on Rails の使用を開始する #

[日本 (日本語)](https://github.com/jasonjoh/o365-tutorial/blob/master/loc/readme-ja.md) (日本語)

このガイドの目的は、Office 365 でユーザーのデータにアクセスする単純な Ruby on Rails アプリを作成するプロセスを手順を追って説明することです。このリポジトリ内のソースコードは、ここで概説する手順に従った場合の最終結果を示しています。

## 始める前に ##

このガイドは、以下を前提としています。

- Ruby on Rails がインストール済みで、開発用コンピューターで動作すること。 
- Office 365 テナントがあり、そのテナントに管理者アカウントのアクセス権があること。

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

アプリケーションは非常に簡単になります。ユーザーがサイトにアクセスすると、ログインして、自分の電子メールを表示するためのリンクが表示されます。そのリンクをクリックすると、ユーザーは Azure のログイン ページに移動します。このページでは、ユーザーは自分の Office 365 アカウントを使用してログインし、アプリへのアクセス権を付与できます。最後に、ユーザーはアプリにリダイレクトされます。アプリは、ユーザーの受信トレイに最新の電子メールの一覧を表示します。

最初に、既定のウェルカム ページを自分のページに置き換えましょう。そのためには、`.\o365-tutorial\app\controllers\application_controller.rb` ファイルに配置されたアプリケーション コントローラーを変更します。お好みのテキスト エディターでこのファイルを開きます。次の一覧に示すとおり、非常に単純な小さい HTML を表示する `home` アクションを定義しましょう。

### `.\o365-tutorial\app\controllers\application_controller.rb` ファイルのコンテンツ ###

    class ApplicationController < ActionController::Base
      # Prevent CSRF attacks by raising an exception.
      # For APIs, you may want to use :null_session instead.
      protect_from_forgery with: :exception
      
      def home
		# Display the login link.
    	render html: '<a href="#">Log in and view my email</a>'.html_safe
      end
    end

お分かりのように、非常に単純なホーム ページになります。現在のところ、リンクは機能しませんが、すぐに修復します。まず、Rails にこのアクションを呼び出すよう伝える必要があります。そのためには、ルートを定義する必要があります。`.\o365-tutorial\config\routes.rb` ファイルを開き、既定のルート (「root」) を、定義した `home` アクションに設定します。

### `.\o365-tutorial\config\routes.rb` ファイルのコンテンツ ###

    Rails.application.routes.draw do
      root 'application#home'
    end

変更内容を保存します。[http://localhost:3000](http://localhost:3000) をブラウズすると次のようになります。

![アプリのホーム ページ。](https://raw.githubusercontent.com/jasonjoh/o365-tutorial/master/readme-images/home-page.PNG)

## OAuth2 を実装する ##

このセクションの目標は、ホーム ページ上のリンクから [Azure AD による OAuth2 承認コードの付与フロー](https://msdn.microsoft.com/ja-jp/library/azure/dn645542.aspx)を開始させることです。処理を簡単にするには、[oauth2 gem](https://github.com/intridea/oauth2) を使用して、OAuth 要求を処理します。`./o365-tutorial/GemFile` を開き、次の行をそのファイルの任意の場所に追加します。

    gem 'oauth2'

ファイルを保存し、次のコマンドを実行します (後で Rails サーバーを再起動します)。

    bundle install

OAuth2 フローの性質上、Azure からのリダイレクトを処理するコントローラーを作成することは意味を成します。`Auth` という名前のコントローラーを生成するには、次のコマンドを実行します。

    rails generate controller Auth

`.\o365-tutorial\app\helpers\auth_helper.rb` ファイルを開きます。最初に、ログイン URL を生成する関数を定義します。

### `.\o365-tutorial\app\helpers\auth_helper.rb` ファイルのコンテンツ ###

    module AuthHelper
    
      # App's client ID. Register the app in Azure AD to get this value.
      CLIENT_ID = '<YOUR CLIENT ID>'
      # App's client secret. Register the app in Azure AD to get this value.
      CLIENT_SECRET = '<YOUR CLIENT SECRET>'
      
      REDIRECT_URI = 'http://localhost:3000/authorize' # Temporary!
    
      # Generates the login URL for the app.
      def get_login_url
    	client = OAuth2::Client.new(CLIENT_ID,
	                                CLIENT_SECRET,
	                                :site => "https://login.microsoftonline.com",
	                                :authorize_url => "/common/oauth2/authorize",
	                                :token_url => "/common/oauth2/token")
                                
    	login_url = client.auth_code.authorize_url(:redirect_uri => REDIRECT_URI)
      end
    end

最初にすることは、クライアント ID とシークレットを定義することです。また、ハードコーディング値としてリダイレクト URI を定義します。この点は少し改善される予定ですが、現時点でこのガイドの目的に対応しています。ここで、クライアント ID とシークレットの値を生成する必要があります。

### クライアント ID とシークレットを生成する ###

クライアント ID とシークレットを取得するには、[アプリを登録](https://github.com/jasonjoh/office365-azure-guides/blob/master/RegisterAnAppInAzure.md)する必要があります。登録するには、以下の内容を使用します。

#### パラメーターを作成する ####

- 名前: o365-tutorial
- 種類:Web アプリケーションまたは Web API

![](https://raw.githubusercontent.com/jasonjoh/o365-tutorial/master/readme-images/azure-wizard-1.PNG)
- サインオン URL: http://localhost:3000
- アプリ ID の URL: https://your_Office365_domain/o365-tutorial ('your_Office365_domain' を実際の Office 365 ドメインに置き換えてください。)

![](https://raw.githubusercontent.com/jasonjoh/o365-tutorial/master/readme-images/azure-wizard-2.PNG)

#### アプリの構成 ####

- キー:1 年間。
- 他のアプリケーションへのアクセス許可:Office 365 Exchange Online、代理アクセス許可、「ユーザー メールの読み取り」

![](https://raw.githubusercontent.com/jasonjoh/o365-tutorial/master/readme-images/azure-portal-3.PNG)

これが完了すると、クライアント ID とシークレットが得られます。`<YOUR CLIENT ID>` および `<YOUR CLIENT SECRET>` プレースホルダーをこれらの値に置き換え、変更内容を保存します。

### コーディングに戻る ###

`get_login_url` 関数に実際の値が得られたので、関数が機能するようにしましょう。このメソッドを使用してリンクに記入するには、`ApplicationController` の `home` アクションを変更します。この関数にアクセスできるようにするには、`AuthHelper` モジュールを含める必要があります。

#### `.\o365-tutorial\app\controllers\application_controller.rb` ファイルの更新されたコンテンツ ####

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

変更内容を保存し、[http://localhost:3000](http://localhost:3000) を参照します。マウス カーソルをリンクの上に重ねると、次のように表示されます。

    https://login.microsoftonline.com/common/oauth2/authorize?client_id=<SOME GUID>&redirect_uri=http%3A%2F%2Flocalhost%3A3000%2Fauthorize&response_type=code

`<SOME GUID>` の部分は、クライアント ID と一致する必要があります。リンクをクリックします。(ブラウザーでまだ Office 365 にサインインしていないと仮定すると)、次のサインイン ページが表示されます。

![Azure サインイン ページ](https://raw.githubusercontent.com/jasonjoh/o365-tutorial/master/readme-images/azure-sign-in.PNG)

Office 365 アカウントでサインインします。ブラウザーがアプリにリダイレクトするとともに、次のエラーが表示されます。

    No route matches [GET] "/authorize"

Rails のエラー ページをスクロールすると、承認コードを含む、要求のパラメーターが表示されます。

    Parameters:
	{"code"=>"AAABAAAAvPM1KaPlrEqdFSBzjqfTGPpcGZKd6RU5DuxG25u809qmosT...",
	 "session_state"=>"2be8576c-534b-4bc2-8ac2-0839270b9e07"}

エラーが表示される理由は、リダイレクト URI としてハードコーディングした `/authorize` パスを処理するルートを実装していないためです。しかし、Rails は、要求において承認コードを取得していることを示していました。方向としては正しいわけです。では、このエラーを修復しましょう。

### トークン用にコードを交換する ###

最初に、`routes.rb` への `/authorize` のパスのルートを追加しましょう。

#### `.\o365-tutorial\config\routes.rb` ファイルの更新されたコンテンツ ####

    Rails.application.routes.draw do
      root 'application#home'
      get 'authorize' => 'auth#gettoken'
    end

追加された行は、`/authorize` で GET 要求を受信すると、`auth` コントローラーで `gettoken` アクションを呼び出すことを Rails に伝えます。したがって、これを機能させるには、対象のアクションを実装する必要があります。`.\o365-tutorial\app\controllers\auth_controller.rb` ファイルを開き、`gettoken` アクションを定義します。

#### `.\o365-tutorial\app\controllers\auth_controller.rb` ファイルのコンテンツ ####

    class AuthController < ApplicationController
    
      def gettoken
    	render text: params[:code]
      end
    end

この新しいコードを試行する前に、最後にもう 1 つ改良しましょう。リダイレクト URI へのルートができたので、`auth_helper.rb` のハードコーディングされた定数を削除できます。代わりに、ルートの Rails 名 `authorize_url` を使用します。

#### `.\o365-tutorial\app\helpers\auth_helper.rb` ファイルの更新されたコンテンツ ####

    module AuthHelper
    
      # App's client ID. Register the app in Azure AD to get this value.
      CLIENT_ID = '<YOUR CLIENT ID>'
      # App's client secret. Register the app in Azure AD to get this value.
      CLIENT_SECRET = '<YOUR CLIENT SECRET>'
    
      # Generates the login URL for the app.
      def get_login_url
    	client = OAuth2::Client.new(CLIENT_ID,
	                                CLIENT_SECRET,
	                                :site => "https://login.microsoftonline.com",
	                                :authorize_url => "/common/oauth2/authorize",
	                                :token_url => "/common/oauth2/token")
                                
    	login_url = client.auth_code.authorize_url(:redirect_uri => authorize_url)
      end
    end

ご使用のブラウザーを更新します (または、サインイン処理を繰り返します)。ここで、Rails のエラー ページの代わりに、画面上に出力された承認コードの値が表示されます。完成に近づいてきましたが、まだ非常に便利な状態ではありません。実際にコードで何かしてみましょう。

`get_token_from_code` と呼ばれる、`auth_helper.rb` に対するもう 1 つのヘルパー関数を追加してみましょう。

#### 
            .\o365-tutorial\app\helpers\auth_helper.rb ファイルの `get_token_from_code` ####

    # Exchanges an authorization code for a token
    def get_token_from_code(auth_code)
      client = OAuth2::Client.new(CLIENT_ID,
                                  CLIENT_SECRET,
                                  :site => "https://login.microsoftonline.com",
                                  :authorize_url => "/common/oauth2/authorize",
                                  :token_url => "/common/oauth2/token")
    
      token = client.auth_code.get_token(auth_code,
                                         :redirect_uri => authorize_url,
                                         :resource => 'https://outlook.office365.com')
     
      access_token = token.token
    end

動作することを確認してみましょう。`auth_controller.rb` ファイルで `gettoken` アクションを変更すると、このヘルパー関数を使用して戻り値を表示できます。

#### `.\o365-tutorial\app\controllers\auth_controller.rb` ファイルの更新されたコンテンツ ####

    class AuthController < ApplicationController
    
      def gettoken
    	token = get_token_from_code params[:code]
    	render text: token
      end
    end

変更内容を保存して、サインイン処理をもう一度実行すると、一見意味不明な文字の長い文字列が表示されます。計画に従ってすべてがなくなれば、これがアクセス トークンになります。値全体をコピーして、http://jwt.calebb.net/ に移動します。値を貼り付けると、アクセス トークンの JSON 表現が表示されます。詳細および代替のパーサーについては、「[Office 365 のアクセス トークンを検証する](https://github.com/jasonjoh/office365-azure-guides/blob/master/ValidatingYourToken.md)」を参照してください。

トークンがあるべき状態であると確信したら、トークンを表示するのではなく、セッション Cookie に格納するようコードを変更しましょう。

#### 新しいバージョンの `gettoken` アクション ####
    def gettoken
      token = get_token_from_code params[:code]
      session[:azure_access_token] = token
      render text: "Access token saved in session cookie."
    end

## メール API を使用する ##

アクセス トークンを取得できたので、メール API を使って何かを実行する良いタイミングになりました。メール操作のコントローラーを作成することから始めましょう。

    rails generate controller Mail index

これは、`Auth` コントローラーの生成方法とは若干異なります。今回は、アクションの名前 `index` を渡しました。Rails は自動的にこのアクションのルートを追加し、ビュー テンプレートを生成します。

ここで、最後に、メール コントローラーのインデックス アクションをリダイレクトするために `gettoken` アクションを変更します。

### 新しいバージョンの `gettoken` アクション ###

    def gettoken
      token = get_token_from_code params[:code]
      session[:azure_access_token] = token
      redirect_to mail_index_url
    end

アプリのサインイン処理は、http://localhost:3000/mail/index にたどり着きました。もちろん、このページでは何もできないので、修復しましょう。

### REST を呼び出す ###

REST を呼び出すには、[Faraday gem](https://github.com/lostisland/faraday) をインストールします。この Gem は、要求の送受信を非常に簡単にします。`Gemfile` ファイルを開き、ファイルの任意の場所に次の行を追加します。

    gem 'faraday'

ファイルを保存し、`bundle install` を実行してから、サーバーを再起動します。これで、`Mail` コントローラーに `index` アクションを実装する準備ができました。`.\o365-tutorial\app\controllers\mail_controller.rb` ファイルを開き、次のように `index` アクションを定義します。

#### `.\o365-tutorial\app\controllers\mail_controller.rb` ファイルのコンテンツ ####

    class MailController < ApplicationController

      def index
    	token = session[:azure_access_token]
    	if token
	      # If a token is present in the session, get messages from the inbox
	      conn = Faraday.new(:url => 'https://outlook.office365.com') do |faraday|
		    # Outputs to the console
		    faraday.response :logger
		    # Uses the default Net::HTTP adapter
		    faraday.adapter  Faraday.default_adapter  
	      end
	      
	      response = conn.get do |request|
		    # Get messages from the inbox
		    # Sort by DateTimeReceived in descending orderby
		    # Get the first 20 results
		    request.url '/api/v1.0/Me/Messages?$orderby=DateTimeReceived desc&$select=DateTimeReceived,Subject,From&$top=20'
		    request.headers['Authorization'] = "Bearer #{token}"
		    request.headers['Accept'] = "application/json"
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

`index` アクションのコードの実行内容をまとめると、次のようになります。

- メール API のエンドポイント (https://outlook.office365.com) への接続を作成します。
- 次の特性を持つ受信トレイのメッセージの URL に、GET 要求を発行します。
	- [クエリ文字列](https://msdn.microsoft.com/office/office365/APi/complex-types-for-mail-contacts-calendar#UseODataqueryparameters) `?$orderby=DateTimeReceived desc&$select=DateTimeReceived,Subject,From&$top=20` を使用して、結果を `DateTimeReceived` で並べ替えます。また、[`DateTimeReceived`]、[`Subject`]、および [`From`] の各フィールドのみを要求し、結果を最初の 20 個に制限します。
	- `Authorization` ヘッダーを、Azure からアクセス トークンを使用するように設定します。
	- `Accept` ヘッダーを、JSON が必要とされていることを通知するように設定します。
- JSON として応答本体を解析し、`value` のハッシュを `@messages` 変数に割り当てます。この変数は、ビュー テンプレートで使用可能になります。

### 結果を表示する ###

ここで、`@messages` 変数を使用するように、`index` アクションに関連するビュー テンプレートを変更する必要があります。`.\o365-tutorial\app\views\mail\index.html.erb` ファイルを開き、内容を次のように置き換えます。

#### `.\o365-tutorial\app\views\mail\index.html.erb` ファイルのコンテンツ ####

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
	      <td><%= message['DateTimeReceived'] %></td>
	    </tr>
      <% end %>
    </table>

テンプレートは、非常に単純な HTML テーブルです。埋め込まれた Ruby を使用して、`index` アクションで設定した `@messages` 変数の結果を反復処理し、メッセージごとにテーブル行を作成します。各メッセージの値にアクセスする構文は簡単です。メッセージの送信者の表示名を抽出する方法に注意してください。

    <%= message['From']['EmailAddress']['Name'] %>

これにより、次の `From` 値の JSON 構造のミラー操作が実行されます。

    "From": {
      "@odata.type": "#Microsoft.OutlookServices.Recipient",
      "EmailAddress": {
	    "@odata.type": "#Microsoft.OutlookServices.EmailAddress",
	    "Address": "jason@contoso.com",
	    "Name": "Jason Johnston"
      }
    }

変更を保存し、アプリにサインインします。受信トレイに、簡単なメッセージのテーブルが表示されます。

![受信トレイの内容を表示する HTML テーブル。](https://raw.githubusercontent.com/jasonjoh/o365-tutorial/master/readme-images/simple-inbox-listing.PNG)

## 次の手順 ##

作業用サンプルを作成したら、[メール API の機能](https://msdn.microsoft.com/office/office365/APi/mail-rest-operations)の詳細について学習することができます。サンプルが動作していないため比較する場合は、[GitHub](https://github.com/jasonjoh/o365-tutorial) からこのチュートリアルの最終結果をダウンロードしてください。

## 著作権 ##

Copyright (c) Microsoft. All rights reserved.

----------
Twitter ([@JasonJohMSFT](https://twitter.com/JasonJohMSFT)) をぜひフォローしてください。

[Exchange 開発ブログ](http://blogs.msdn.com/b/exchangedev/)をフォローする

