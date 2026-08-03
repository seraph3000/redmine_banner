/* Code for Banner UI */
function checkDateRange(event, confirm_msg, date_range_error_msg) {
    let s = $('#setting_start_ymd').val() + " " + $('#setting_start_hour').val() + ":" + $('#setting_start_min').val();
    let e = $('#setting_end_ymd').val() + " " + $('#setting_end_hour').val() + ":" + $('#setting_end_min').val();
    if (e.replace(/\-\s:/gi, "") < s.replace(/\-\s:/gi, "")) {
        window.alert(date_range_error_msg + " (From " + s + " to " + e + ")");
        return false;
    } else {
        let response = confirm(confirm_msg);
        if (response) {
            return true;
        }
    }
    return false;
}

function displayTopBanner() {
    if (window.matchMedia( '(max-width: 899px)' ).matches) {
        $('#content').prepend($('div.banner_area.global_banner').first());
    } else {
        $('div.banner_area.global_banner').first().insertAfter($('#top-menu'));
    }
}

function displayTopAndBottomBanner() {
    if (window.matchMedia( '(max-width: 899px)' ).matches) {
        $('#content').prepend($('div.banner_area.global_banner').clone());
    } else {
        $('div.banner_area.global_banner').clone().insertAfter($('#top-menu'));
    }
}

/* ------------------------------------------------------------------
 * Banner popup window
 * ------------------------------------------------------------------ */

var BannerPopup = (function () {
    var WIN_ID    = 'banner-popup-window';
    var WIDTH     = 420;
    var MIN_H     = 200;
    var MOBILE_MQ = '(max-width: 899px)';

    function isMobile() {
        return window.matchMedia(MOBILE_MQ).matches;
    }

    /* 隠しブロックから source に対応する中身を取り出す */
    function findSource(source) {
        return document.querySelector('.banner-popup-source[data-source="' + source + '"]');
    }

    /* 小窓本体を取得（無ければ生成して body 直下に置く） */
    function ensureWindow() {
        var win = document.getElementById(WIN_ID);
        if (win) { return win; }

        win = document.createElement('div');
        win.id = WIN_ID;
        win.className = 'banner-popup-window';
        win.style.width = WIDTH + 'px';

        var header = document.createElement('div');
        header.className = 'banner-popup-header';

        var title = document.createElement('span');
        title.className = 'banner-popup-title';
        header.appendChild(title);

        var closeBtn = document.createElement('a');
        closeBtn.href = '#';
        closeBtn.className = 'banner-popup-close';
        closeBtn.setAttribute('role', 'button');
        closeBtn.textContent = '\u00d7';
        closeBtn.addEventListener('click', function (e) {
        e.preventDefault();
        BannerPopup.close();
        });
        header.appendChild(closeBtn);

        var body = document.createElement('div');
        body.className = 'banner-popup-content';

        win.appendChild(header);
        win.appendChild(body);
        document.body.appendChild(win);

        return win;
    }

    /* 初期位置（右上寄せ）と初期高さを決める */
    function applyDefaultGeometry(win) {
        if (win.dataset.positioned === '1') { return; }

        var h = Math.max(MIN_H, Math.floor(window.innerHeight * 0.5));
        win.style.height = h + 'px';
        win.style.top    = '80px';
        win.style.left   = Math.max(10, window.innerWidth - WIDTH - 40) + 'px';
        win.dataset.positioned = '1';
    }

    /* 開く */
    function open(source, linkText, geometry) {
        var src = findSource(source);
        if (!src) { return; }

        var srcBody = src.querySelector('.banner-popup-body');
        if (!srcBody) { return; }

        var win = ensureWindow();

        if (geometry && typeof BannerPopup.applyGeometry === 'function') {
            BannerPopup.applyGeometry(win, geometry);
            win.dataset.positioned = '1';
        } else {
            applyDefaultGeometry(win);
        }

        var title = win.querySelector('.banner-popup-title');
        title.textContent = linkText || '';

        var content = win.querySelector('.banner-popup-content');
        content.innerHTML = '';
        content.appendChild(srcBody.cloneNode(true));

        win.dataset.source = source;
        win.classList.add('banner-popup-open');

        if (!geometry && typeof BannerPopup.saveState === 'function') {
            BannerPopup.saveState();
        }
    }

    function close() {
        var win = document.getElementById(WIN_ID);
        if (!win) { return; }
        win.classList.remove('banner-popup-open');

        if (typeof BannerPopup.clearState === 'function') {
        BannerPopup.clearState();
        }
    }

    /* トリガーリンクの委譲ハンドラ */
    function bindTriggers() {
        document.addEventListener('click', function (e) {
        var a = e.target.closest ? e.target.closest('a[href^="#banner-popup-"]') : null;
        if (!a) { return; }

        e.preventDefault();

        var source = a.getAttribute('href').replace('#banner-popup-', '');

        if (isMobile()) {
            if (typeof BannerPopup.toggleInline === 'function') {
                BannerPopup.toggleInline(source, a);
            }
        return;
        }

        open(source, a.textContent.trim());
        });
    }

    function init() {
        bindTriggers();
        if (typeof BannerPopup.restore === 'function') {
            BannerPopup.restore();
        }
    }

    return {
        WIN_ID:               WIN_ID,
        WIDTH:                WIDTH,
        MIN_H:                MIN_H,
        isMobile:             isMobile,
        findSource:           findSource,
        ensureWindow:         ensureWindow,
        applyDefaultGeometry: applyDefaultGeometry,
        open:                 open,
        close:                close,
        init:                 init
    };
})();

document.addEventListener('DOMContentLoaded', function () {
    BannerPopup.init();
});

/* ------------------------------------------------------------------
 * Banner popup window : drag / resize / sessionStorage
 * ------------------------------------------------------------------ */

(function (BP) {
  var EDGE        = 40;   /* 画面外に出しても最低これだけは残す */
  var storageKey  = null; /* key() が初回に組み立ててメモ化する */

    /* ---------- sessionStorage ---------- */
    function key() {
        if (storageKey === null) {
        var m = document.querySelector('meta[name="banner-popup-scope"]');
        storageKey = 'redmine_banner_popup:' + (m ? (m.getAttribute('content') || '') : '');
        }
        return storageKey;
    }

    function load() {
        try {
        var raw = window.sessionStorage.getItem(key());
        return raw ? JSON.parse(raw) : null;
        } catch (e) {
        return null;
        }
    }

    function store(st) {
        try {
            window.sessionStorage.setItem(key(), JSON.stringify(st));
        } catch (e) {
        /* プライベートモード等で書けない場合は諦める */
        }
    }

    function drop() {
        try {
            window.sessionStorage.removeItem(key());
        } catch (e) {
        /* noop */
        }
    }

    /* 開いている小窓の現在値を保存 */
    BP.saveState = function () {
        var win = document.getElementById(BP.WIN_ID);
        if (!win || !win.classList.contains('banner-popup-open')) { return; }

        var title = win.querySelector('.banner-popup-title');

        store({
            open:   true,
            source: win.dataset.source || '',
            title:  title ? title.textContent : '',
            top:    parseInt(win.style.top, 10)  || 0,
            left:   parseInt(win.style.left, 10) || 0,
            height: win.offsetHeight
        });
    };

    /* 閉じたことを記録（位置とサイズは残す） */
    BP.clearState = function () {
        var st = load();
        if (!st) { return; }
        st.open = false;
        store(st);
    };

    /* 状態を完全に破棄（バナー表示オフ用・次回で使う） */
    BP.dropState = function () {
        drop();
    };

    /* ---------- 位置の適用 ---------- */

    function clamp(win) {
        var maxLeft = Math.max(0, window.innerWidth  - EDGE);
        var maxTop  = Math.max(0, window.innerHeight - EDGE);

        var left = parseInt(win.style.left, 10) || 0;
        var top  = parseInt(win.style.top, 10)  || 0;

        if (left > maxLeft) { left = maxLeft; }
        if (top  > maxTop)  { top  = maxTop; }
        if (left < 0) { left = 0; }
        if (top  < 0) { top  = 0; }

        win.style.left = left + 'px';
        win.style.top  = top + 'px';
    }

    function applyGeometry(win, st) {
        /* 高さが未保存／小さすぎる場合は既定値（viewport の 50%）にフォールバック */
        var h = (typeof st.height === 'number' && st.height >= BP.MIN_H)
              ? st.height
              : Math.max(BP.MIN_H, Math.floor(window.innerHeight * 0.5));
        win.style.height = h + 'px';

        if (typeof st.top  === 'number') { win.style.top  = st.top + 'px'; }
        if (typeof st.left === 'number') { win.style.left = st.left + 'px'; }
        clamp(win);
    }

    /* open() から復元時に呼べるよう公開する */
    BP.applyGeometry = applyGeometry;

    /* ---------- 復元 ---------- */

    BP.restore = function () {
        var st = load();
        if (!st || !st.open) { return; }

        /* モバイルは小窓を使わない */
        if (BP.isMobile()) { return; }

        /* このページに popup リンクが1つも無ければ復元しない */
        if (!document.querySelector('a[href^="#banner-popup-"]')) { return; }

        /* 元ネタの隠しブロックが無いページでは何もしない（状態は残す） */
        if (!BP.findSource(st.source)) { return; }

        /* 第3引数を渡すことで、既定位置を経由せず保存値で直接開く */
        BP.open(st.source, st.title, st);
    };

    /* ---------- ドラッグ ---------- */

    var drag = null;

    document.addEventListener('mousedown', function (e) {
        if (!e.target.closest) { return; }

        var header = e.target.closest('.banner-popup-header');
        if (!header) { return; }
        if (e.target.closest('.banner-popup-close')) { return; }

        var win = document.getElementById(BP.WIN_ID);
        if (!win) { return; }

        drag = {
            win:      win,
            offsetX:  e.clientX - (parseInt(win.style.left, 10) || 0),
            offsetY:  e.clientY - (parseInt(win.style.top, 10)  || 0)
        };

        win.classList.add('banner-popup-dragging');
        e.preventDefault();   /* テキスト選択を抑止 */
    });

    document.addEventListener('mousemove', function (e) {
        if (!drag) { return; }

        drag.win.style.left = (e.clientX - drag.offsetX) + 'px';
        drag.win.style.top  = (e.clientY - drag.offsetY) + 'px';
    });

    /* ドラッグ終了と、CSS リサイズ終了の両方をここで拾う */
    document.addEventListener('mouseup', function () {
        if (drag) {
            clamp(drag.win);
            drag.win.classList.remove('banner-popup-dragging');
            drag = null;
        }
        BP.saveState();
    });

    /* ---------- 位置リセット（ヘッダーのダブルクリック） ---------- */

    document.addEventListener('dblclick', function (e) {
        if (!e.target.closest) { return; }

        var header = e.target.closest('.banner-popup-header');
        if (!header) { return; }
        if (e.target.closest('.banner-popup-close')) { return; }

        var win = document.getElementById(BP.WIN_ID);
        if (!win || !win.classList.contains('banner-popup-open')) { return; }

        win.dataset.positioned = '';
        BP.applyDefaultGeometry(win);
        BP.saveState();
    });

/* ---------- ESC で閉じる ---------- */

    document.addEventListener('keydown', function (e) {
        if (e.key !== 'Escape' && e.key !== 'Esc') { return; }
        if (e.defaultPrevented) { return; }

        var win = document.getElementById(BP.WIN_ID);
        if (!win || !win.classList.contains('banner-popup-open')) { return; }

        var a = document.activeElement;
        if (a) {
            var tag = a.tagName;
            if (tag === 'INPUT' || tag === 'TEXTAREA' || tag === 'SELECT' || a.isContentEditable) {
            return;
            }
        }

        /* Redmine のコンテキストメニュー等が開いていれば、そちらを優先する */
        /* if (document.querySelector('#context-menu:not([style*="display: none"])')) { return; } */

        BP.close();
    });

    /* ---------- ブラウザ幅変更への追従 ---------- */

    window.addEventListener('resize', function () {
        var win = document.getElementById(BP.WIN_ID);
        if (!win || !win.classList.contains('banner-popup-open')) { return; }

        if (BP.isMobile()) {
            win.classList.remove('banner-popup-open');
            BP.clearState();
            return;
        }

        clamp(win);
        BP.saveState();
    });
})(BannerPopup);

/* ------------------------------------------------------------------
 * Banner popup : mobile accordion / banner-off linkage
 * ------------------------------------------------------------------ */

(function (BP) {

    /* ---------- モバイル: バナー内アコーディオン ---------- */

    function localSource(link, source) {
        var sel  = '.banner-popup-source[data-source="' + source + '"]';
        var area = link.closest('.banner_area');
        var box  = area ? area.querySelector(sel) : null;
        return box || document.querySelector(sel);
    }

    function collapseInline(box) {
        if (!box) { return; }
        box.classList.remove('banner-popup-inline-open');
        box.style.display = 'none';

        /* 対応するトリガーリンクの開状態も戻す */
        if (box.bannerPopupLink) {
            box.bannerPopupLink.classList.remove('banner-popup-trigger-open');
        }
    }

    /* 展開パネル内に閉じるボタンを1度だけ差し込む */
    function ensureInlineClose(box) {
        if (box.querySelector('.banner-popup-inline-close')) { return; }

        var btn = document.createElement('a');
        btn.href = '#';
        btn.className = 'banner-popup-inline-close';
        btn.setAttribute('role', 'button');
        btn.textContent = '\u00d7';
        btn.addEventListener('click', function (e) {
            e.preventDefault();
            e.stopPropagation();
        collapseInline(box);
        });

        box.insertBefore(btn, box.firstChild);
    }

    BP.toggleInline = function (source, link) {
        var box = localSource(link, source);
        if (!box) { return; }

        if (box.classList.contains('banner-popup-inline-open')) {
            collapseInline(box);
        } else {
            box.bannerPopupLink = link;
            ensureInlineClose(box);
            box.classList.add('banner-popup-inline-open');
            box.style.display = 'block';
            link.classList.add('banner-popup-trigger-open');
        }
    };

    /* デスクトップ幅に戻ったらインライン展開は畳む */
    window.addEventListener('resize', function () {
        if (BP.isMobile()) { return; }

        var boxes = document.querySelectorAll('.banner-popup-source.banner-popup-inline-open');
        Array.prototype.forEach.call(boxes, collapseInline);
    });

    /* ---------- バナー表示オフとの連動 ---------- */

    function scopeOfOffLink(link) {
        if (link.closest('#project_banner_area')) { return 'project'; }
        if (link.closest('.global_banner'))       { return 'global'; }
        return null;
    }

    document.addEventListener('click', function (e) {
        if (!e.target.closest) { return; }

        var off = e.target.closest('a.banner-icon-off-link');
        if (!off) { return; }

        var scope = scopeOfOffLink(off);
        if (!scope) { return; }

        /* インライン展開（モバイル）を畳む */
        collapseInline(document.querySelector(
        '.banner-popup-source[data-source="' + scope + '"]'
        ));

        /* 小窓が同じ由来を表示中なら閉じて、状態も破棄 */
        var win = document.getElementById(BP.WIN_ID);
        if (win && win.classList.contains('banner-popup-open') && win.dataset.source === scope) {
            win.classList.remove('banner-popup-open');
            BP.dropState();
        }
    });
})(BannerPopup);
