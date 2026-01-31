# Redmine Banner Plugin

This is a maintained fork of Akiko Takano's Redmine Banner plugin.

Original repository: https://github.com/akiko-pusu/redmine_banner
Original author: Akiko Takano (@akiko_pusu)

---

Plugin to show site-wide message from site administrator, such as maintenance
information or notifications.

[![Plugin info at redmine.org](https://img.shields.io/badge/Redmine-plugin-green.svg?)](http://www.redmine.org/plugins/redmine_banner)
[![CircleCI](https://circleci.com/gh/akiko-pusu/redmine_banner/tree/master.svg?style=shield)](https://circleci.com/gh/akiko-pusu/redmine_banner/tree/master)
[![Sider](https://img.shields.io/badge/Special%20Thanks!-Sider-blue.svg?)](https://sider.review/features)

<img src='assets/images/banner-screenshot.png' width='500px'>

## About this fork

This repository is a fork that keeps the original behaviour while adding some
features and Redmine 6 support.

- Based on original **0.3.4**
- Plugin version: **0.4.1**
- Main additions in this fork:
  - Redmine **4 / 5 / 6** support
  - **Role-based project banners** (`project_id` + `role_id`)
  - **Force display** option for the default project banner
  - **Colored role labels** (“badges”) based on role priority
  - **Banner macros** for countdowns, date/time, environment and user info
  - Locales from the original plugin are kept; new strings are provided in
    English and Japanese (other languages fall back to English)
- Behaviour when you **do not** configure any role-specific banner:
  - Stays the same as original: “one project – one banner”

Tested with:

- Redmine 4.2.x
- Redmine 5.1.x
- Redmine 6.0.x / 6.1.x

Fork maintainer:

- Seraph (@seraph3000)

---

## Plugin installation

1. Copy the plugin directory into the $REDMINE_ROOT/plugins directory. Please
   note that plugin's folder name should be **"redmine_banner"**. If
   changed, some migration task will be failed.
2. Do migration task.

   ```bash
   rake redmine:plugins:migrate NAME=redmine_banner RAILS_ENV=production
   ```
3. (Re)Start Redmine.

## Upgrade from original `redmine_banner`

If you are already using Akiko's original plugin:

1. Stop Redmine.
2. Replace the old plugin directory with this fork (keeping the directory name `redmine_banner`):

```bash
cd $REDMINE_ROOT/plugins
rm -rf redmine_banner
git clone https://github.com/seraph3000/redmine_banner.git
```

3. Run migrations (this fork adds a new column `role_id` to `banners` table):

```bash
cd $REDMINE_ROOT
rake redmine:plugins:migrate NAME=redmine_banner RAILS_ENV=production
```

4. Restart Redmine.

Existing data:

* Existing project banners are kept as **default project banners**

  (`role_id` will be `NULL`).
* Until you configure role-specific banners, behaviour will be identical to

  the original plugin.

## Uninstall

Try this:

```bash
rake redmine:plugins:migrate NAME=redmine_banner VERSION=0 RAILS_ENV=production
```

## Usage for site wide banner

1. Go to plugin's page and click "Settings" link of Redmine Banner Plugin.
   You can edit banner message and select style for message. Also you can access setting page from administration menu, click "banner" icon.

### Banner macros (fork feature)

This fork adds simple macros that you can use inside the banner message.
They are expanded on display for both the global banner and project banners.

#### Countdown macros

All countdown macros take a target date/time in the current user's time zone:

* `%{cdate:YYYY-MM-DD HH:MM}` – remaining days until the target.
* `%{chours:YYYY-MM-DD HH:MM}` – remaining hours (0–23 after subtracting full days).
* `%{cmin:YYYY-MM-DD HH:MM}` – remaining minutes (0–59 after subtracting full hours).
* `%{ctime:YYYY-MM-DD HH:MM}` – remaining total time as `HH:MM`
  (for example `120:15`).

Example:

```text
Maintenance will start in %{cdate:2026-02-02 08:00} days \
%{chours:2026-02-02 08:00} hours \
%{cmin:2026-02-02 08:00} minutes.
```

If the target time is in the past, countdown macros return `0`
(or `00:00` for `ctime`).

#### Date / time and environment macros

* `%{today}` – current date formatted according to the user's language
  preferences (`format_date`).
* `%{now}` – current date and time formatted according to the user's language
  preferences (`format_time`).
* `%{env}` – environment label derived from `Rails.env`
  (for example `PROD`, `DEV`, `STG`).

Example:

```text
[%{env}] Information for %{today}.
This banner was last updated at %{now}.
```

#### User-related macros

These macros are expanded only for logged-in users. For anonymous users they
return an empty string.

* `%{user_name}` – current user's display name.
* `%{user_last_login}` – user's last login date/time
  (not shown on the login page for privacy reasons).
* `%{user_login_rank_today}` – “you are the N-th logged-in user today”,
  calculated from `users.last_login_on`.

Example:

```text
You are %{user_login_rank_today}-th user logged in today.
Your last login: %{user_last_login}
This notice is for %{user_name}.
```

> **Note:** `user_login_rank_today` performs a count query on the `users`
> table for the current day. On very large instances this may have some
> performance impact; if in doubt, do not use this macro.


### Usage for project scope banner

1. Banner can be used as a project module. If you want to manage the banner in your project, "Manage Banner" permission is required for your role.
2. Go to project settings tab and check "Banner" as project module.
3. Then you can see "Banner" tab on project settings page.

### Role-based project banners (fork feature)

This fork extends project banners so you can define different messages per role.

* Each banner record has:
  * `project_id`
  * `role_id` (may be `NULL`)
  * other fields (style, description, etc.)
* For a given project and current user:
  1. Plugin collects the user's roles in that project.
  2. If a banner exists whose `role_id` matches one of those roles:
     * The banner for the highest priority role (based on Redmine role

       `position`) is shown.
  3. If no role-specific banner exists:
     * The default project banner (`role_id = NULL`) is shown.

Example use cases:

* Project managers see:
  > “Reminder: please review open issues before the sprint starts.”
  >
* Reporters see:
  > “When creating issues, please fill in the ‘Steps to reproduce’ section.”
  >

If you do not configure any roles, the behaviour is exactly the same as

original: one banner per project.

### Current limitations

1. Banner for each project does not support timer.
2. Banner for each project is located at the top of the project only. (Not support footer)

### Note

Please use ver **0.1.x** or ``v0.1.x-support-Redmine3`` branch in case using Redmine3.x.

## Changelog

### 0.4.1

* Add banner macros for countdown, date/time, environment and user information.
* Apply macro expansion to both global and project banners.

### 0.4.0

* Add `role_id` column to `banners` table.
* Add `Banner.for(project, user)` to select a project banner based on user roles.
* Implement role-based selection in project banner hook.
* Keep PNG icons and behaviour for Redmine 4 / 5.
* Do not change default behaviour when `role_id` is not used.

For older changes, please see the original project’s changelog:

* [https://github.com/akiko-pusu/redmine_banner](https://github.com/akiko-pusu/redmine_banner?utm_source=chatgpt.com)

### 0.3.4

Maintenance release.

* Update German translation. (GitHub: #142 by @teatower)

### 0.3.3

This is bugfix release against 0.3.2.
Updating to 0.3.3 is highly recommended!

* Bugfix: HTML problems on redmine_banner.
* Bugfix: Fix wrong url to project banner setting.
  *Refactor: Remove unused file.

### 0.3.2

This is bugfix release against 0.3.1.
Updating to 0.3.2 is highly recommended!

* Bugfix: HTML problems on redmine_banner 0.3.1. (#134)
* Bugfix: Global banner off does not work correctly. (Degrade from v0.2x)
* Update Chinese translation. (GutHub: #131 by iWangJiaxiang)

### 0.3.1

* Feature: Enabled to switch who can see the global banner. (#126)
* Refactor: Change to use project menu to prevent the project setting tab's conflict. (#127)

### 0.3.1

* Feature: Enabled to switch who can see the global banner. (#126)
* Refactor: Change to use project menu to prevent the project setting tab's conflict. (#127)

### 0.3.0

* Add feature: Give the ability to specific users to manage the site-wide banner. (GitHub: #86 / #113)
  * Administrator can assign a group to manage global banner via UI.
* Code refactoring for maintainability.
* Change not to use SettingsController's patch to the update global banner.

### 0.2.2

This is bugfix release against 0.2.1.
Updating to 0.2.2 is highly recommended!

* Fix: Prevent conflict with other plugins. (GitHub: #121)
* French translation update by sparunakian (GitHub: #117)

### 0.2.1

* Fix: Prevent conflict with CKEditor. (GitHub: #111)
* Code refactoring.
* Add feature to update Global Banner via API. (Alpha / Related: #86 #113)
  * Not only Redmine admin but also user who assigned group named **GlobalBanner_Admin** can also update Global banner via API.
  * Even prptotype version.
  * Please see [swagger.yml](script/swagger.yml) to try update global banner via API.
* Update CI Setting
  * Add step to build and push image to AWS ECR.
  * Add steps to build and deploy to Heroku Container registry as release container service.
* Add how to try banner via Docker in README.

### 0.2.0

* Support Redmine 4.x.
  * Now master branch **unsupports** Redmine 3.x.
  * Please use ver **0.1.x** or ``v0.1.x-support-Redmine3`` branch in case using Redmine3.x.
  * [https://github.com/akiko-pusu/redmine_banner/tree/v0.1.x-support-Redmine3](https://github.com/akiko-pusu/redmine_banner/tree/v0.1.x-support-Redmine3)
* Follow Redmine's preview option to the wiki toolbar.

NOTE: Mainly, maintenance, bugfix and refactoring only. There is no additional feature, translation in this release.

### 0.1.2

* Fix style and css selector. (Github: #45)
* Change global banner style for responsive mode. (Github: #68)
* Code refactoring.
* Fix: Prevent deprecation warning. (Github PR: #60) Thanks, Wojciech.
* Refactor: Rename file to prevent conflict (Github #63 / r-labs: 54).
* i18n: Update Italian translation file. (Github: #61 / r-labs: 57) Thanks, R-i-c-k-y.
* i18n: Add Spanish translation file. (Github: #61 / r-labs: 52) Thanks Picazamora!
* i18n: Update Turkish translation file. (Github: #64) Thank you so much, Adnan.
* i18n: Update Portuguese translation file. (Github: #50) Thanks, Guilherme.

### 0.1.1

* Support Redmine 3.x.
* Update some translation files. Bulgarian, German. Thank you so much, Ivan Cenov, Daniel Felix.
* Change column type of banner_description from string to text.Thank you so much Namezero. (#44)

### 0.1.0

* Fixed bug: Global banner timer does not work. (r-labs: #1337)
* Feature: Add related link field for more information to Global Banner. (r-labs: #1339)
* i18n: Update Korean translation file. (r-labs: #1329) Thank you so much, Ki Won Kim.

### 0.0.9

* Authenticated users can turn off global banner in their session.
* Add option to show global banner only for authenticated users.
* Add option to show only at the login page.
* Code refactoring.
* Italian translation was contributed by @R-i-c-k-y.
* French translation was contributed by Laurent HADJADJ.

### 0.0.8

* Support Redmine 2.1. (Redmine 2.0.x is no longer supported. Please use version 0.0.7 for Redmine 2.0.x)

### 0.0.7

* Compatible with Redmine 2.0.0

### 0.0.6

* Fixed bug: Project banner should be off when module turned disabled.
* Fixed bug: In some situation, "ActionView::TemplateError undefined method is_action_to_display" is happened.
* Update Russian Translation. Thank you so much, Александр Ананьев.

### 0.0.5

* Support banner for each project. Thank you so much, Denny Schäfer, Haru Iida.

### 0.0.4

* Support timer function.
* Add links to turn off or modify banner message quickly. (Links are shown to Administrator only)

### 0.0.3

* Code refactoring. Stop to override base.rhtml and use javascript. Great thanks, Haru Iida-san. Also, remove some "To-Do" section of README.
* Add translations. Russian, German, Brazilian Portugues. Thank you so much, Александр Ананьев, Denny Schäfer, Maiko de Andrade!

### 0.0.2

* Support i18n.

### 0.0.1

* First release

### Quick try with using Docker

You can try quickly this plugin with Docker environment.
Please try:

```bash
# Admin password is 'redmine_banner_commit_sha'
% git clone https://github.com/akiko-pusu/redmine_banner
% cd redmine_banner
% docker-compose up web -d

# or
#
# Admin password is 'redmine_banner_{COMMIT}'
% docker build --build-arg=COMMIT=$(git rev-parse --short HEAD) \
  --build-arg=BRANCH=$(git name-rev --name-only HEAD) -t akiko/redmine_banner:latest .

% docker run -p 3000:3000 akiko/redmine_banner:latest
```

### Run test

Please see wercker.yml for more details.

```bash
% cd REDMINE_ROOT_DIR
% cp plugins/redmine_banner/Gemfile.local plugins/redmine_banner/Gemfile
% bundle install --with test
% export RAILS_ENV=test
% bundle exec ruby -I"lib:test" -I plugins/redmine_banner/test \
  plugins/redmine_banner/test/functional/banner_controller_test.rb
```

or

```bash
% bundle exec rails redmine_banner:test
```

### Repository

* Original: [https://github.com/akiko-pusu/redmine_banner](https://github.com/akiko-pusu/redmine_banner?utm_source=chatgpt.com)
* Fork (this repository): [https://github.com/seraph3000/redmine_banner](https://github.com/seraph3000/redmine_banner)

### WebPage

* [http://www.r-labs.org/projects/banner](http://www.r-labs.org/projects/banner) (Project Page)

### License

This software is licensed under the GNU GPL v2.

See `COPYRIGHT` and `COPYING` for details.

Original copyright remains with Akiko Takano.

Additional changes in this fork are provided under the same license.
