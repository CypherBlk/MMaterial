pragma ComponentBehavior: Bound

import QtQuick

import MMaterial.UI as UI

Item {
    id: root

	required property UI.PaletteBasic primary
	required property UI.PaletteBasic secondary
	required property UI.PaletteBasic info
	required property UI.PaletteBasic success
	required property UI.PaletteBasic warning
	required property UI.PaletteBasic error
	required property UI.PaletteText text
	required property UI.PaletteBackground background
	required property UI.PaletteAction action
	required property UI.PaletteOther other

	required property UI.PaletteGrey main
	required property UI.PaletteSocial social

	property UI.PaletteCommon common: UI.PaletteCommon{}

	property UI.PaletteBasic defaultNeutral: UI.PaletteBasic{
        main: root.text.primary
        contrastText: root.background.main
    }

	property UI.PaletteBasic passive: UI.PaletteBasic{
		darker: root.main.transparent.p32
		dark: root.main.transparent.p16
		main: root.main.p400
		light: root.main.transparent.p16
		lighter: root.main.transparent.p32
		contrastText: root.text.primary
    }

	// --- Runtime branding overrides ----------------------------------------
	// Original palette objects, captured the first time a channel is branded,
	// so resetThemeBranding() / a partial re-apply can always restore the
	// compiled-in defaults. Keyed by channel name.
	property var _brandingDefaults: ({})
	// Palette objects created by branding, keyed by channel name. Replaced
	// objects are intentionally NOT destroy()ed — non-binding references held
	// elsewhere (e.g. a captured Theme.primary) would dangle. They stay
	// parented to the theme; re-brandings are rare so the leak is bounded.
	property var _brandingCreated: ({})

	function hasBrandedChannel(channelName : string) : bool {
		return !!_brandingCreated[channelName];
	}

	function _isValidBrandingColor(value) : bool {
		return typeof value === "string"
			&& /^#([0-9a-fA-F]{3}|[0-9a-fA-F]{6}|[0-9a-fA-F]{8})$/.test(value);
	}

	function _createBrandingPalette(vals) : UI.PaletteBasic {
		const qml =
			'import MMaterial.UI 1.0 as UI\n' +
			'UI.PaletteBasic {\n' +
			'    main: "' + vals.main + '"\n' +
			'    contrastText: "' + vals.contrastText + '"\n' +
			'    light: "' + vals.light + '"\n' +
			'    lighter: "' + vals.lighter + '"\n' +
			'    dark: "' + vals.dark + '"\n' +
			'    darker: "' + vals.darker + '"\n' +
			'}\n';
		return Qt.createQmlObject(qml, root, "brandingPalette");
	}

	function _restoreBrandingChannel(channelName : string) : void {
		if (_brandingDefaults[channelName] !== undefined && root[channelName] !== _brandingDefaults[channelName])
			root[channelName] = _brandingDefaults[channelName];

		delete _brandingCreated[channelName];
	}

	// Applies a branding palette to this theme. `palette` is an object with
	// optional channels (primary/secondary/info/success/warning/error), each
	// holding optional fields (main/light/lighter/dark/darker/contrastText).
	// Fields that are missing or not valid hex colors keep the compiled-in
	// default; channels absent from `palette` are restored to defaults, so a
	// re-apply for a different tenant never leaks the previous brand.
	// `swapShades` maps light<->dark and lighter<->darker: the dark theme
	// stores its PaletteBasic ramps inverted (its "darker" holds the visually
	// lightest color), while branding manifests use light-theme semantics.
	function applyBrandingToTheme(palette, swapShades : bool) : void {
		const channels = ["primary", "secondary", "info", "success", "warning", "error"];
		const fields = ["main", "contrastText", "light", "lighter", "dark", "darker"];
		const fieldMap = swapShades
			? { main: "main", contrastText: "contrastText", light: "dark", lighter: "darker", dark: "light", darker: "lighter" }
			: { main: "main", contrastText: "contrastText", light: "light", lighter: "lighter", dark: "dark", darker: "darker" };

		for (let i = 0; i < channels.length; ++i) {
			const name = channels[i];
			const src = palette ? palette[name] : undefined;

			if (!src || typeof src !== "object") {
				_restoreBrandingChannel(name);
				continue;
			}

			// Capture the default object once so unspecified fields always
			// come from the compiled-in palette, never a previous branding.
			if (_brandingDefaults[name] === undefined)
				_brandingDefaults[name] = root[name];

			const base = _brandingDefaults[name];
			let vals = {
				main: base.main,
				contrastText: base.contrastText,
				light: base.light,
				lighter: base.lighter,
				dark: base.dark,
				darker: base.darker
			};

			let anyOverride = false;
			for (let f = 0; f < fields.length; ++f) {
				const value = src[fields[f]];
				if (_isValidBrandingColor(value)) {
					vals[fieldMap[fields[f]]] = value;
					anyOverride = true;
				}
			}

			if (!anyOverride) {
				_restoreBrandingChannel(name);
				continue;
			}

			const created = _createBrandingPalette(vals);
			if (!created)
				continue;

			_brandingCreated[name] = created;
			root[name] = created;
		}
	}

	// Restores every branded channel to its compiled-in default.
	function resetThemeBranding() : void {
		const channels = ["primary", "secondary", "info", "success", "warning", "error"];
		for (let i = 0; i < channels.length; ++i)
			_restoreBrandingChannel(channels[i]);
	}
}
