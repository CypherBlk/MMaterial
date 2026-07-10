pragma Singleton

import QtQuick

import MMaterial.UI as UI

UI.ThemeBase{
    id: root

    property UI.ThemeBase currentTheme: UI.DarkTheme
	property list<color> chartColors: [root.primary, root.secondary, root.info, root.success, root.warning, root.error]
    property ThemeSettings settings: ThemeSettings {}

    readonly property bool isDarkTheme: root.currentTheme == UI.DarkTheme || (root.currentTheme == UI.AutoTheme && root.currentTheme.activeTheme == UI.DarkTheme)

	function setTheme(theme: UI.ThemeBase) : void {
        console.log("Theme switched to " + theme.objectName)
        currentTheme = theme;
    }

	function getChartColorPattern(index: int) : UI.PaletteBasic {
        return chartColors[index % chartColors.length];
    }

	function getChartPatternColor(index: int, pattern: UI.PaletteBasic) : color {
        let switchArg = index % 5;
        switch(switchArg) {
            case 1:
                return pattern.light;
            case 2:
                return pattern.dark;
            case 3:
                return pattern.lighter;
            case 4:
                return pattern.darker;
            default:
                return pattern.main;
        }
    }

    function createAccent(color : string) : UI.PaletteBasic {
        if (color === "")
            return null;

        var isDark = root.currentTheme == UI.DarkTheme;
        var light  = isDark ? Qt.lighter(color, 1.2) : Qt.darker(color, 1.2);
        var dark   = isDark ? Qt.darker(color, 1.2)  : Qt.lighter(color, 1.2);
        var lighter = isDark ? Qt.lighter(color, 1.4) : Qt.darker(color, 1.4);
        var darker  = isDark ? Qt.darker(color, 1.4)  : Qt.lighter(color, 1.4);
        var contrastText = isDark ? "#FFFFFF" : "#000000";

        var qml =
            'import MMaterial.UI 1.0 as UI\n' +
            'UI.PaletteBasic {\n' +
            '    main: "' + color + '"\n' +
            '    contrastText: "' + contrastText + '"\n' +
            '    light: "' + light + '"\n' +
            '    dark: "' + dark + '"\n' +
            '    lighter: "' + lighter + '"\n' +
            '    darker: "' + darker + '"\n' +
            '}\n';

        return Qt.createQmlObject(qml, root);
    }


    // --- Runtime branding ---------------------------------------------------
    // The app may assign Theme.secondary directly at startup (breaking the
    // currentTheme delegation binding below), so a branded secondary has to be
    // applied/restored here as well as on the underlying themes.
    property UI.PaletteBasic _brandingSecondaryBackup: null
    property bool _brandingSecondaryOverridden: false

    // Keep the branded secondary pointing at the active variant's palette when
    // the theme flips (dark and light store their shade ramps swapped).
    onIsDarkThemeChanged: {
        if (!_brandingSecondaryOverridden)
            return;

        const active = root.isDarkTheme ? UI.DarkTheme : UI.LightTheme;
        if (active.hasBrandedChannel("secondary"))
            root.secondary = active.secondary;
    }

    // Applies a (possibly partial) branding palette to both theme variants.
    // `palette`: { primary: { main, light, lighter, dark, darker, contrastText }, secondary: {...}, info: {...}, success: {...}, warning: {...}, error: {...} }
    // Every channel and field is optional; invalid/empty values are skipped and
    // unspecified fields keep the compiled-in defaults. Passing a palette that
    // omits a previously branded channel restores that channel.
    function applyBrandingPalette(palette : var) : void {
        if (!palette) {
            resetBranding();
            return;
        }

        UI.LightTheme.applyBrandingToTheme(palette, false);
        // Dark theme stores its shade ramps inverted — swap light/dark.
        UI.DarkTheme.applyBrandingToTheme(palette, true);

        const active = root.isDarkTheme ? UI.DarkTheme : UI.LightTheme;
        if (active.hasBrandedChannel("secondary")) {
            if (!_brandingSecondaryOverridden) {
                _brandingSecondaryBackup = root.secondary;
                _brandingSecondaryOverridden = true;
            }
            root.secondary = active.secondary;
        } else if (_brandingSecondaryOverridden) {
            root.secondary = _brandingSecondaryBackup;
            _brandingSecondaryOverridden = false;
        }
    }

    // Restores both theme variants (and the local secondary override) to the
    // compiled-in defaults.
    function resetBranding() : void {
        UI.LightTheme.resetThemeBranding();
        UI.DarkTheme.resetThemeBranding();

        if (_brandingSecondaryOverridden) {
            root.secondary = _brandingSecondaryBackup;
            _brandingSecondaryOverridden = false;
        }
    }

    primary: currentTheme?.primary ?? null
    secondary: currentTheme?.secondary ?? null
    info: currentTheme?.info ?? null
    success: currentTheme?.success ?? null
    warning: currentTheme?.warning ?? null
    error: currentTheme?.error ?? null
    main: currentTheme?.main ?? null
    social: currentTheme?.social ?? null
    background: currentTheme?.background ?? null
    other: currentTheme?.other ?? null
    text: currentTheme?.text ?? null
    action: currentTheme?.action ?? null
    common: currentTheme?.common ?? null
    defaultNeutral: currentTheme?.defaultNeutral ?? null
    passive: currentTheme?.passive ?? null
}
