# Redmine Banner Plugin (Seraph3000 Fork)

This is a maintained and extended fork of Akiko Takano's Redmine Banner plugin,
with support and enhancements for Redmine 5 / 6 / 7.

- Original repository: https://github.com/akiko-pusu/redmine_banner
- This fork: https://github.com/seraph3000/redmine_banner
- Supported Redmine: 5.x / 6.x / 7.x

## Key Features Added in This Fork

- Redmine **5 / 6 / 7** support
- **Role-based project banners**
  (configure different messages per role)
- **Forced display option**
  (always show the banner under certain conditions)
- **Role label colorization**
  (show role labels with colors per role)
- **Banner macro feature**
  - Countdown (deadlines, maintenance windows, etc.)
  - Date / time
  - Environment info (PROD / STG / DEV, etc.)
  - User info (last login, login rank, etc.)
  - Popup window (show content that does not fit in the banner itself)
- Localization fixes and small UI improvements

`README.md` is the English documentation. `README_ja.md` is the Japanese version.

### Visual Examples

**Role-based Project Banners**

Display different messages to different roles within the same project.

![Role-based banners with color coding](https://assets.st-note.com/img/1774708569-IGREpPwB01KvmDayL7CjlXHt.png)

**Banner Macros**

Add dynamic content to your banners using macros.

![Banner configuration screen](https://assets.st-note.com/img/1774708660-sQ860BSPEwLetAoZ94mK3dfc.png)

![Macro expansion example](https://assets.st-note.com/img/1774708680-Vbuoi0ev9rTpwPmOg1D4xqYa.png)

**Popup window**

A movable, resizable window opens from a link in the banner.

![Popup window](https://assets.st-note.com/img/1785745393-dALpV7COuxol8vQ5cjs9yGm2.png)

Detailed articles (Japanese, auto-translated into English):

* [Role-based banners and macros](https://note.com/taba_muichi/n/ncf2c00d2c54b?hl=en)
* [Adding a popup window to Redmine Banner](https://note.com/taba_muichi/n/n9ddeb0663758?hl=en)

---

## Installation

1. Copy this plugin into your Redmine `plugins` directory.

   Example:
   `REDMINE_ROOT/plugins/redmine_banner`

2. Run the plugin migration.

   ```bash
   bundle exec rake redmine:plugins:migrate NAME=redmine_banner RAILS_ENV=production
   ```

3. Restart Redmine.

   Follow the restart procedure for your application server (Passenger / Puma / Thin / Unicorn, etc.).

---

## ⚠ If `Zeitwerk::NameError` Occurs When Upgrading from 0.3.4

When upgrading **from 0.3.4**, you may see an error like the following at boot time:

* `Zeitwerk::NameError (expected file ... to define ...)`

This is due to stricter **Zeitwerk autoloading (naming convention checks)** in newer Redmine/Rails versions.

**Recommended Fix**

* Do **not** overwrite the plugin directory in-place. Remove `plugins/redmine_banner` first, then deploy the latest version (clean deploy recommended).
* Restart Redmine.

**Note**

If old files remain, mismatches between file paths and Ruby class/module names can trigger `Zeitwerk::NameError`.

---

## Upgrading

The directory layout of this fork differs from upstream (`lang/` removed, CI
and test files dropped). **Do not copy the new files over an existing
installation** — files that should have been removed will remain and cause
`Zeitwerk::NameError` or locale conflicts.

Move the old directory **outside** `plugins/`. Renaming it in place does not
help: Redmine loads every directory under `plugins/`, so the old `init.rb`
would be registered as well.

    cd $REDMINE_ROOT
    mkdir -p ../plugin_backup
    mv plugins/redmine_banner ../plugin_backup/redmine_banner.$(date +%Y%m%d)
    # Place the new directory in plugins/
    bundle exec rake redmine:plugins:migrate RAILS_ENV=production
    # Restart Redmine

Delete the backup once you have confirmed the plugin works.

## Uninstall

Run the following command:

```bash
bundle exec rake redmine:plugins:migrate NAME=redmine_banner VERSION=0 RAILS_ENV=production
```

---

## Site-wide Banner (Global Banner)

1. Log in as an administrator.
2. Go to **Administration → Plugins → Redmine Banner → Configure**.
3. Turn **Enable banner** ON, then configure the message, type, position, etc.
4. Click **Apply** to display the banner site-wide.

You can use the **banner macros** (described below) in the global banner message.

---

## Banner Macros (Fork Feature)

This fork supports expanding special patterns in banner messages as **macros**, for both global and project banners.

* All macros are written in the format `%{...}`.
* Many macros are calculated automatically based on the current time and the logged-in user.
* For anonymous users (not logged in), some macros return an empty string.

### Countdown Macros

These macros display the remaining time until a specified date/time.
The date/time is interpreted according to Redmine/user timezone settings.

Available macros:

* `%{cdate:YYYY-MM-DD HH:MM}`
  Remaining **days** until the specified time (integer)

* `%{chours:YYYY-MM-DD HH:MM}`
  Remaining **hours (0–23)** excluding full days

* `%{cmin:YYYY-MM-DD HH:MM}`
  Remaining **minutes (0–59)** excluding full days and hours

* `%{ctime:YYYY-MM-DD HH:MM}`
  Total remaining time in `HH:MM` format
  Example: `120:15` (= 120 hours 15 minutes)

#### Example

```text
Maintenance will start in
%{cdate:2026-02-02 08:00} days
%{chours:2026-02-02 08:00} hours
%{cmin:2026-02-02 08:00} minutes.
```

Behavior after the specified time has passed:

* `cdate` / `chours` / `cmin` return `0`
* `ctime` returns `00:00`

---

### Date / Time / Environment Macros

#### Date and Time

* `%{today}`
  Displays the current date based on the user's language and date format
  (internally uses `format_date`)

* `%{now}`
  Displays the current date and time based on the user's language and time format
  (internally uses `format_time`)

Example:

```text
This notice is as of %{today}.
This banner was updated at %{now}.
```

#### Environment (Rails.env)

* `%{env}`
  Returns a label based on the Redmine Rails environment, such as `PROD`, `STG`, `DEV`, etc.
  (exact mapping depends on this fork's implementation)

Example:

```text
[%{env}] Environment notice.
```

This is useful if you operate multiple instances (production / staging / development) and want to make the environment obvious.

---

### User-related Macros

These macros return values **only for logged-in users**.
For anonymous users, they return an empty string.

#### Logged-in User Name

* `%{user_name}`
  Returns the display name of the current user
  (equivalent to `User.current.name`)

Example:

```text
Notice for %{user_name}.
```

#### Last Login Time

* `%{user_last_login}`
  Displays `User.current.last_login_on` using the user's language/time format.
  **Not shown on the login page (`/login`)** (returns empty).

Example:

```text
Your last login: %{user_last_login}
```

#### Login Rank for Today

* `%{user_login_rank_today}`
  Returns "what number login you are today" among users who logged in on the same date.
  **Not shown on the login page (`/login`)** (returns empty).
  Example: `5` → "You are the 5th login today."

Example:

```text
You are the %{user_login_rank_today}th user to log in today.
```

> **Note:**
> This macro counts users based on `users.last_login_on`.
> On very large instances, this may add some DB load. Avoid using it if performance is a concern.

---

### Popup Window Macro

* `%{popup:TEXT}`
  Expands to a link that opens a floating window. `TEXT` is used as the link label and as the window title.

The window content is **not** written inside the macro. Turn on **Enable popup window** in the banner settings and write the content in the **Popup content** field that appears.

#### Setup

1. Open the banner settings (global or project).
2. Check **Enable popup window**.
3. Write the content in the **Popup content** textarea that appears. Textile / Markdown and banner macros are both available, following your Redmine wiki format setting.
4. Put `%{popup:TEXT}` anywhere in the banner message.

#### Example

Banner message:

```text
A new feature has been added. %{popup:Read more}
```

Popup content:

```text
h3. What's new

* Role-based project banners
* Banner macros

Please contact the administrator if you have any questions.
```

#### Behavior

* The window stays open while you keep using Redmine. No modal overlay is shown.
* Drag the header to move it. Drag the bottom edge to change the height. The width is fixed at 420px.
* **Double-click the header** to reset the position and height.
* Only one window exists per tab. Clicking another popup link replaces the content and keeps the position.
* The state is kept across page transitions (per browser tab). Closing the tab or the browser discards it.
* On narrow screens (899px or less), the content is expanded inline in the banner instead of a floating window.
* Project banners can have a different popup per role, since the setting belongs to each role-specific banner record.

#### Notes

* If **Enable popup window** is off, or **Popup content** is empty, the macro is removed from the banner message and nothing is shown.
* The macro is also removed on the login page, so the window never appears for anonymous visitors.
* `%{popup:...}` written inside **Popup content** is not expanded. Popups cannot be nested.

---

## Project-level Banner

This plugin can also be used as a project module.

1. In the target project, go to **Settings → Modules** and enable **Banner**.
2. A **Banner** tab will appear in the project settings.
3. Configure the project-specific banner in the **Banner** tab.

Project banners can also use the same **banner macros** as global banners.

---

## Role-based Project Banners (Fork Extension)

This fork allows you to define **role-specific banners per project**.

* Each banner record has `project_id` and `role_id`.
  * When `role_id` is `NULL`, the banner is treated as the default (common to all roles).
* When showing a banner in a project, selection works as follows:

1. Get the list of roles the current user has in that project.
2. If there are banners for those roles:
   * Select **one** banner based on the highest-priority role, using the Redmine role `position`.
3. If no role-specific banner matches:
   * Show the default banner (`role_id = NULL`) if present.
4. If nothing matches:
   * No banner is shown for that project.

### Example Use Cases

* For project managers:
  > "Before starting the sprint, please review unassigned issues."

* For reporters:
  > "When creating issues, please fill in the 'Steps to reproduce' field."

If you don't configure any role-specific banners, the plugin behaves like the original: **one banner per project**.

---

## Current Limitations

1. Project banners do not support timer settings (start/end datetime).
2. Project banners can only be displayed at the **top of the project page**.
   Footer display is not supported.
3. For Redmine 4.x, use version **0.4.2** of this fork.
4. For Redmine 3.x, use the upstream plugin's older versions (0.1.x series) instead of this fork.

---

## Changelog

### 0.5.4

#### Fixes

* Updated banner edit and hide links to use main_app route helpers for compatibility with views rendered inside Rails engines.
* Thanks to @alecghica for contributing this fix.

### 0.5.3

#### Fixes

* Fixed an issue where popup links were not displayed correctly when using Textile formatting.
* Increased the text limit for banner and popup content to 30,000 characters.

### 0.5.2

#### Added
* **Popup window macro** (`%{popup:TEXT}`) for both global and project banners
  * Clicking the expanded link opens a floating window that can be moved and
    resized while continuing to use Redmine
  * Popup content supports Textile / Markdown and banner macros
    (except `%{popup:...}` itself — popups cannot be nested)
  * Window position, height and open state are kept across page transitions
    (per browser tab)
  * On narrow screens (899px or less), the content is expanded inline in the
    banner instead
  * Project banners can have a different popup per role

#### Fixed (inherited from upstream)
* The global banner "Off" link passed `remote: true` in the URL options hash
  instead of the HTML options hash, so it was sent as a query parameter
  (`?moderate=yes&remote=true`) rather than becoming an Ajax request. Clicking
  it navigated to the raw JavaScript response. Replaced with an explicit
  `$.ajax` call. (Present in upstream 0.3.4 and in agileware-jp/redmine_banner.)

#### Fixed (inherited from upstream / security)

* The "more info" link on the global banner did not validate the URL scheme,
  so values such as `javascript:` were emitted directly into `href`. A user
  with global banner management rights could place a script-executing link on
  every page. Only `http` and `https` are accepted now.

#### Removed

* CI / Docker / test files inherited from upstream
  * `.circleci` (contained deployment settings for external services),
    `Dockerfile`, `docker-compose.yml`, `Gemfile.local`, `script/`, `test/`
  * All were built for Redmine 4.x and no longer work

### 0.5.1

* Security fixes [#1](https://github.com/seraph3000/redmine_banner/issues/1) [#2](https://github.com/seraph3000/redmine_banner/issues/2) [#3](https://github.com/seraph3000/redmine_banner/pull/3) (thanks to [@mael-chouteau](https://github.com/mael-chouteau))

### 0.5.0

* **Macro preview**: macros can now be previewed (expanded) in the "Preview" tab of the banner settings screen before applying.
* **Redmine 7.0 support**, following the SVG icon change on Redmine 6.x and later (admin / project menu, edit / off actions).
  * Verified on **Redmine 7.0 / 6.1 / 6.0**.
  * Also works on Redmine 5.x, but icons are simplified (text only).
* **Supported versions changed**: dropped Redmine 4.x; now targets **Redmine 5.0 or higher**.
  * For Redmine 4.x or earlier, use **0.4.2**.
* **Fix**: project banner "Off" now hides the banner per session instead of permanently disabling it (previously one click disabled the banner).
* Other minor bug fixes.

### 0.4.2

* Fix: global banner could not be saved when edited from a project page as an admin (routing error to `/global_banner/<project>`). The global banner now always posts correctly to `global_banner#update`.

### 0.4.1

* Add **banner macro feature** for both global and project banners
  * Countdown macros: `cdate`, `chours`, `cmin`, `ctime`
  * Date/time: `today`, `now`
  * Environment: `env`
  * User info: `user_name`, `user_last_login`, `user_login_rank_today`
* Apply macro expansion to both global and project banners

### 0.4.0

* Add `role_id` column to `banners` table
* Add logic to select project banners based on user roles
* Implement role-based banner feature for project banners
* Maintain compatibility with existing installations (works as before when `role_id` is not used)

For earlier changes, please see the original plugin's changelog:

* [https://github.com/akiko-pusu/redmine_banner](https://github.com/akiko-pusu/redmine_banner)

---

## Repository

* Original: [akiko-pusu/redmine_banner](https://github.com/akiko-pusu/redmine_banner)
  (Archived in January 2021 / final version 0.3.4)
* Transferred to: [agileware-jp/redmine_banner](https://github.com/agileware-jp/redmine_banner)
  (Latest tag 0.3.5 / CI configuration changes only)
* This fork: [seraph3000/redmine_banner](https://github.com/seraph3000/redmine_banner)
  (Based on 0.3.4, updated for Redmine 5 / 6 / 7)
---

## License

This software is licensed under the **GNU GPL v2**, same as the original plugin.

* See `COPYRIGHT` and `COPYING` for details.
* Original copyright remains with Akiko Takano.
* Additional changes in this fork are provided under the same license.
