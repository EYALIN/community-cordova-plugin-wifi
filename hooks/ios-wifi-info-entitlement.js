#!/usr/bin/env node
'use strict';

/*
 * Opt-in "Access WiFi Information" entitlement (com.apple.developer.networking.wifi-info).
 *
 * The entitlement is only needed by apps that read SSID/BSSID on iOS, and it requires the
 * capability to be enabled on the App ID. Writing it unconditionally would add an unused
 * capability to every consuming app, so it is gated behind the WIFI_INFO_ENTITLEMENT plugin
 * variable (default false):
 *
 *   cordova plugin add community-cordova-plugin-wifi --variable WIFI_INFO_ENTITLEMENT=true
 *
 * or, in config.xml: <preference name="WIFI_INFO_ENTITLEMENT" value="true" />
 *
 * When on, the key is written into the project's Entitlements-Debug/Release.plist. When off,
 * the key is removed if present, so turning the variable off takes effect on the next prepare.
 */

const fs = require('fs');
const path = require('path');

const PLUGIN_ID = 'community-cordova-plugin-wifi';
const VARIABLE = 'WIFI_INFO_ENTITLEMENT';
const KEY = 'com.apple.developer.networking.wifi-info';

function isTrue(value) {
    return String(value).trim().toLowerCase() === 'true';
}

function readVariable(projectRoot) {
    // 1. Plugin variable recorded by `cordova plugin add --variable` in package.json.
    try {
        const pkg = JSON.parse(fs.readFileSync(path.join(projectRoot, 'package.json'), 'utf8'));
        const vars = pkg.cordova && pkg.cordova.plugins && pkg.cordova.plugins[PLUGIN_ID];
        if (vars && vars[VARIABLE] !== undefined) {
            return isTrue(vars[VARIABLE]);
        }
    } catch (e) { /* no package.json */ }

    // 2. <preference name="WIFI_INFO_ENTITLEMENT" value="true" /> in config.xml.
    try {
        const xml = fs.readFileSync(path.join(projectRoot, 'config.xml'), 'utf8');
        const m = xml.match(new RegExp('<preference\\s+name="' + VARIABLE + '"\\s+value="([^"]*)"', 'i'));
        if (m) {
            return isTrue(m[1]);
        }
    } catch (e) { /* no config.xml */ }

    return false;
}

function findEntitlementPlists(iosRoot) {
    const found = [];
    let entries = [];
    try {
        entries = fs.readdirSync(iosRoot, { withFileTypes: true });
    } catch (e) {
        return found;
    }
    entries.filter((d) => d.isDirectory()).forEach((dir) => {
        ['Entitlements-Debug.plist', 'Entitlements-Release.plist'].forEach((name) => {
            const p = path.join(iosRoot, dir.name, name);
            if (fs.existsSync(p)) found.push(p);
        });
    });
    return found;
}

const KEY_RE = new RegExp('\\s*<key>' + KEY.replace(/\./g, '\\.') + '</key>\\s*<(true|false)\\s*/>', 'g');

function apply(plistPath, enabled) {
    const original = fs.readFileSync(plistPath, 'utf8');
    let next = original.replace(KEY_RE, '');
    if (enabled) {
        const close = next.lastIndexOf('</dict>');
        if (close === -1) {
            console.warn('[' + PLUGIN_ID + '] ' + plistPath + ' has no <dict>; entitlement not written');
            return;
        }
        next = next.slice(0, close) + '\t<key>' + KEY + '</key>\n\t<true/>\n' + next.slice(close);
    }
    if (next !== original) {
        fs.writeFileSync(plistPath, next, 'utf8');
    }
}

module.exports = function (context) {
    const platforms = (context.opts && context.opts.platforms) || [];
    if (platforms.length && platforms.indexOf('ios') === -1) return;

    const projectRoot = context.opts.projectRoot;
    const iosRoot = path.join(projectRoot, 'platforms', 'ios');
    if (!fs.existsSync(iosRoot)) return;

    const enabled = readVariable(projectRoot);
    const plists = findEntitlementPlists(iosRoot);
    plists.forEach((p) => apply(p, enabled));
    if (enabled) {
        console.log('[' + PLUGIN_ID + '] ' + KEY + ' written to ' + plists.length + ' Entitlements plist(s)');
    }
};
