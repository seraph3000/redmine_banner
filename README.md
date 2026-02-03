
# Redmine Banner Plugin (Seraph3000 fork)

This is a maintained and extended fork of **Akiko Takano’s Redmine Banner** plugin, with added support and enhancements for **Redmine 4 / 5 / 6**.

* Upstream repository: [https://github.com/akiko-pusu/redmine_banner](https://github.com/akiko-pusu/redmine_banner)
* This fork: [https://github.com/seraph3000/redmine_banner](https://github.com/seraph3000/redmine_banner)
* Supported Redmine: 4.x / 5.x / 6.x

## Key features added in this fork

* Verified compatibility with **Redmine 4 / 5 / 6**
* **Role-based project banners per project**
  (configure different messages per role)
* **Forced display option**
  (always show the banner under certain conditions)
* **Role label colorization**
  (show role labels with colors per role)
* **Banner macro feature**

  * Countdown (deadlines, maintenance windows, etc.)
  * Date / time
  * Environment info (PROD / STG / DEV, etc.)
  * User info (last login, login rank, etc.)
* Localization fixes and small UI improvements

`README.md` is the English documentation. `README_ja.md` is the Japanese documentation.

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

## ⚠ If `Zeitwerk::NameError` occurs when upgrading from 0.3.4

When upgrading **from 0.3.4**, you may see an error like the following at boot time:

* `Zeitwerk::NameError (expected file ... to define ...)`

This is due to stricter **Zeitwerk autoloading (naming convention checks)** in newer Redmine/Rails versions.

### Recommended fix

* Do **not** overwrite the plugin directory in-place.
  Remove `plugins/redmine_banner` first, then deploy the latest version (clean deploy recommended).
* Restart Redmine.

### Note

If old files remain, mismatches between file paths and Ruby class/module names can trigger `Zeitwerk::NameError`.

---

## Uninstall

Run the following command:

```bash
bundle exec rake redmine:plugins:migrate NAME=redmine_banner VERSION=0 RAILS_ENV=production
```

---

## Site-wide banner (global banner)

1. Log in as an administrator.
2. Go to **Administration → Plugins → Redmine Banner → Configure**.
3. Turn **Enable banner** ON, then configure the message, type, position, etc.
4. Click **Apply** to display the banner site-wide.

You can use the **banner macros** (described below) in the global banner message.

---

## Banner macros (added in this fork)

This fork supports expanding special patterns in banner messages as **macros**, for both global and project banners.

* All macros are written in the format `%{...}`.
* Many macros are calculated automatically based on the current time and the logged-in user.
* For anonymous users (not logged in), some macros return an empty string.

### Countdown macros

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
Until maintenance starts:
%{cdate:2026-02-02 08:00} days
%{chours:2026-02-02 08:00} hours
%{cmin:2026-02-02 08:00} minutes
```

Behavior after the specified time has passed:

* `cdate` / `chours` / `cmin` return `0`
* `ctime` returns `00:00`

---

### Date / time / environment macros

#### Date and time

* `%{today}`
  Displays the current date based on the user’s language and date format
  (internally uses `format_date`)

* `%{now}`
  Displays the current date and time based on the user’s language and time format
  (internally uses `format_time`)

Example:

```text
This notice is as of %{today}.
This banner was updated at %{now}.
```

#### Environment (Rails.env)

* `%{env}`
  Returns a label based on the Redmine Rails environment, such as `PROD`, `STG`, `DEV`, etc.
  (exact mapping depends on this fork’s implementation)

Example:

```text
[%{env}] Environment notice.
```

This is useful if you operate multiple instances (production / staging / development) and want to make the environment obvious.

---

### User-related macros

These macros return values **only for logged-in users**.
For anonymous users, they return an empty string.

#### Logged-in user name

* `%{user_name}`
  Returns the display name of the current user
  (equivalent to `User.current.name`)

Example:

```text
Notice for %{user_name}.
```

#### Last login time

* `%{user_last_login}`
  Displays `User.current.last_login_on` using the user’s language/time format.
  **Not shown on the login page (`/login`)** (returns empty).

Example:

```text
Your last login: %{user_last_login}
```

#### Login rank for today

* `%{user_login_rank_today}`
  Returns “what number login you are today” among users who logged in on the same date.
  **Not shown on the login page (`/login`)** (returns empty).
  Example: `5` → “You are the 5th login today.”

Example:

```text
You are the %{user_login_rank_today}th login today.
```

> **Note:**
> This macro counts users based on `users.last_login_on`.
> On very large instances, this may add some DB load. Avoid using it if performance is a concern.

---

## Project-level banner

This plugin can also be used as a project module.

1. In the target project, go to **Settings → Modules** and enable **Banner**.
2. A **Banner** tab will appear in the project settings.
3. Configure the project-specific banner in the **Banner** tab.

Project banners can also use the same **banner macros** as global banners.

---

## Role-based project banners (fork extension)

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

### Example use cases

* For project managers:

  > “Before starting the sprint, please review unassigned issues.”

* For reporters:

  > “When creating issues, please fill in the ‘Steps to reproduce’ field.”

If you don’t configure any role-specific banners, the plugin behaves like the original: **one banner per project**.

---

## Current limitations

1. Project banners do not support timer settings (start/end datetime).
2. Project banners can only be displayed at the **top of the project page**.
   Footer display is not supported.
3. For Redmine 3.x, use the upstream plugin’s older versions (0.1.x series) instead of this fork.

---

## Changelog (this fork)

### 0.4.1

* Added **banner macros** for both global and project banners

  * Countdown: `cdate`, `chours`, `cmin`, `ctime`
  * Date/time: `today`, `now`
  * Environment: `env`
  * User info: `user_name`, `user_last_login`, `user_login_rank_today`
* Applied macro expansion to both global and project banners

### 0.4.0

* Added `role_id` column to the `banners` table
* Added logic to select project banners based on the user’s role
* Implemented role-based project banners
* Backward compatibility: if `role_id` is not used, behavior remains the same

For older changes, refer to the upstream plugin’s changelog:

* [https://github.com/akiko-pusu/redmine_banner](https://github.com/akiko-pusu/redmine_banner)

---

## Repositories

* Upstream (original): [https://github.com/akiko-pusu/redmine_banner](https://github.com/akiko-pusu/redmine_banner)
* This fork: [https://github.com/seraph3000/redmine_banner](https://github.com/seraph3000/redmine_banner)

---

## License

This plugin is distributed under **GNU GPL v2**, same as the original plugin.

* See `COPYRIGHT` and `COPYING` included in this repository for details.
* Copyright belongs to the original author, **Akiko Takano**.
* Modifications added in this fork are also distributed under the same license.

