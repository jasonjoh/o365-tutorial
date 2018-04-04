# Getting Started with the Outlook Mail API and Ruby on Rails #

This sample app is the result of following the tutorial at [https://docs.microsoft.com/en-us/outlook/rest/ruby-tutorial](https://docs.microsoft.com/en-us/outlook/rest/ruby-tutorial). If you follow that tutorial, you should come up with something fairly close to the code in this repository.

> **NOTE:** Looking for the version of this tutorial that used the Outlook API directly instead of Microsoft Graph? Check out the `outlook-api` branch. Note that Microsoft recommends using the Microsoft Graph to access mail, calendar, and contacts. You should use the Outlook APIs directly (via https://outlook.office.com/api) only if you require a feature that is not available on the Graph endpoints.

## Running the sample

If you didn't follow the tutorial and just want to download this repository and try it out, you need to do a few things first.

### Setup your dev environment

This guide assumes:

- That you already have Ruby on Rails installed and working on your development machine. 
- That you have an Office 365 tenant, with access to an account in that tenant **OR** an Outlook.com account.

### Register the app

Head over to https://apps.dev.microsoft.com to quickly get a client ID and secret. Using the sign in buttons, sign in with either your Microsoft account (Outlook.com), or your work or school account (Office 365).

![The Application Registration Portal Sign In Page](readme-images/sign-in.PNG)

Once you're signed in, click the **Add an app** button. Enter `o365-tutorial` for the name and click **Create application**. After the app is created, locate the **Application Secrets** section, and click the **Generate New Password** button. Copy the password now and save it to a safe place. Once you've copied the password, click **Ok**.

![The new password dialog.](readme-images/new-password.PNG)

Locate the **Platforms** section, and click **Add Platform**. Choose **Web**, then enter `http://localhost:3000/authorize` under **Redirect URIs**. Click **Save** to complete the registration. Copy the **Application Id** and save it along with the password you copied earlier. We'll need those values soon.

Here's what the details of your app registration should look like when you are done.

![The completed registration properties.](readme-images/ruby-tutorial.PNG)

Once this is complete you should have a client ID and a secret. Replace the `<YOUR APP ID HERE>` and `<YOUR APP PASSWORD HERE>` placeholders in [auth_helper.rb](app/helpers/auth_helper.rb) with these values and save your changes.

### Install dependencies and initialize project

From a command prompt/shell in the root of this project, run the following commands.

```Shell
bundle install
rails db:migrate
```

### Start the Rails server

From a command prompt/shell in the root of this project, run the following command.

```Shell
rails server
```

Browse to [http://localhost:3000](http://localhost:3000).

## Copyright ##

Copyright (c) Microsoft. All rights reserved.

----------
Connect with me on Twitter [@JasonJohMSFT](https://twitter.com/JasonJohMSFT)

Follow the [Outlook/Exchange Dev Blog](http://blogs.msdn.com/b/exchangedev/)