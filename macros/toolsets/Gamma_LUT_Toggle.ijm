// Sam Lord 2026
// https://github.com/samjlord/Gamma_LUT_Toggle
// Version 2.5
//
//   click       the tool icon : toggle the gamma LUT on / off
//   shift-click the tool icon : enter an arbitrary gamma and apply it
//
// The on/off state is stored on each image (and each channel) as image
// properties, so switching between images never double-applies gamma.
// All channels of a multichannel image are toggled together. The properties
// (GammaLUTToggle.*) are saved in TIFF files, so the state survives a reopen.
//
// Macro-language quirks worth knowing before editing: string comparisons
// can't be combined with && in a return, and Property.get/set need plain
// variables as arguments (not nested function calls).


var gammaValue = 0.45;        // gamma exponent used for the next apply


macro "Gamma LUT Toggle Action Tool - C000T4b12y" {

    if (isKeyDown("shift")) {
        setKeyDown("none");
        setGamma();
        exit();
    }

    if (!imageOK()) exit();

    // If any channel is on, turn everything off, so a mixed image never
    // ends up with gamma applied twice.
    if (anyChannelOn()) {
        setAllChannels(false, gammaValue);
        showStatus("Gamma OFF (original LUT)");
    } else {
        setAllChannels(true, gammaValue);
        showStatus("Gamma " + d2s(gammaValue, 2) + " ON");
    }
}


// Asks for a gamma and applies it to the original LUT. Never compounds: each
// channel is restored to its original LUT first, then the new gamma is applied.
function setGamma() {

    Dialog.create("Gamma LUT Toggle");
    Dialog.addNumber("Gamma:", gammaValue, 2, 8, "");
    Dialog.addMessage("Applied to the original LUT, never compounded.\n \n"
                    + "0.45 = sRGB-like encoding.    1.0 = linear, uncorrected.");
    Dialog.show();                                  // Cancel aborts the macro

    g = Dialog.getNumber();
    if (isNaN(g) || g <= 0) {
        showMessage("Gamma LUT Toggle", "Gamma must be a number greater than 0.");
        exit();
    }
    gammaValue = g;

    // Nothing to act on yet -- keep the value for the next click.
    if (nImages == 0) {
        showStatus("Gamma set to " + d2s(gammaValue, 2) + " (no image open)");
        exit();
    }
    if (bitDepth() == 24) {
        showStatus("Gamma set to " + d2s(gammaValue, 2) + " (RGB - convert to 8-bit)");
        exit();
    }

    setAllChannels(true, gammaValue);
    showStatus("Gamma " + d2s(gammaValue, 2) + " ON");
}


// True if gamma is on for any channel of the current image.
function anyChannelOn() {
    getDimensions(w, h, channels, slices, frames);
    if (channels == 1) return gammaIsOn();
    Stack.getPosition(c0, s0, f0);
    on = false;
    for (c = 1; c <= channels; c++) {
        Stack.setChannel(c);
        if (gammaIsOn()) on = true;
    }
    Stack.setChannel(c0);
    return on;
}


// Turns gamma off on every channel, then (if turnOn) applies it to every
// channel. Each channel is restored to its original LUT first, so a new
// gamma never compounds on an old one.
function setAllChannels(turnOn, gam) {
    getDimensions(w, h, channels, slices, frames);
    c0 = 1;
    if (channels > 1) Stack.getPosition(c0, s0, f0);
    for (c = 1; c <= channels; c++) {
        if (channels > 1) Stack.setChannel(c);
        if (gammaIsOn()) restoreLut();
        if (turnOn) saveAndApply(gam);
    }
    if (channels > 1) Stack.setChannel(c0);
}


// True only if this image/channel was gamma'd by this tool AND its LUT is
// still the one we set. If the LUT was changed since (e.g. Image > Lookup
// Tables), the saved state is stale and the current LUT is treated as original.
function gammaIsOn() {
    key = propKey("applied");
    applied = Property.get(key);
    if (applied == "") return false;
    current = lutToString();
    if (applied == current) return true;
    return false;
}


// Saves the current LUT as the original, applies gamma, and saves the result
// so gammaIsOn() can recognize it later.
function saveAndApply(gam) {
    origKey = propKey("orig");
    appliedKey = propKey("applied");
    orig = lutToString();
    Property.set(origKey, orig);
    applyGamma(gam);
    applied = lutToString();
    Property.set(appliedKey, applied);
}


// Puts back the saved original LUT and clears this channel's saved state.
function restoreLut() {
    origKey = propKey("orig");
    appliedKey = propKey("applied");
    orig = Property.get(origKey);
    stringToLut(orig);
    Property.set(origKey, "");
    Property.set(appliedKey, "");
}


// Property name for the current channel. Each channel keeps its own saved
// LUTs, since each has its own color.
function propKey(name) {
    getDimensions(w, h, channels, slices, frames);
    c = 1;
    if (channels > 1) Stack.getPosition(c, s, f);
    return "GammaLUTToggle." + name + ".c" + c;
}


// LUTs are stored as one "r,g,b,r,g,b,..." string of 768 values.
function lutToString() {
    getLut(reds, greens, blues);
    s = "";
    for (i = 0; i < 256; i++)
        s = s + reds[i] + "," + greens[i] + "," + blues[i] + ",";
    return s;
}


function stringToLut(s) {
    v = split(s, ",");
    reds = newArray(256);
    greens = newArray(256);
    blues = newArray(256);
    for (i = 0; i < 256; i++) {
        reds[i]   = parseInt(v[3*i]);
        greens[i] = parseInt(v[3*i + 1]);
        blues[i]  = parseInt(v[3*i + 2]);
    }
    setLutKeepRange(reds, greens, blues);
}


// Composes gamma onto whatever LUT is currently displayed, so non-grayscale
// LUTs (Fire, Green, etc.) keep their hues.
function applyGamma(gam) {
    getLut(reds, greens, blues);
    for (i = 0; i < 256; i++) {
        reds[i]   = round(255 * pow(reds[i]   / 255.0, gam));
        greens[i] = round(255 * pow(greens[i] / 255.0, gam));
        blues[i]  = round(255 * pow(blues[i]  / 255.0, gam));
    }
    setLutKeepRange(reds, greens, blues);
}


// setLut on an 8-bit image drops the B&C display range from the screen (the
// range is still reported, but not drawn until B&C "Set"), so re-apply it.
function setLutKeepRange(reds, greens, blues) {
    getMinAndMax(lo, hi);
    setLut(reds, greens, blues);
    setMinAndMax(lo, hi);
}


function imageOK() {
    if (nImages == 0) {
        showMessage("Gamma LUT Toggle", "No image open.");
        return false;
    }
    if (bitDepth() == 24) {
        showMessage("Gamma LUT Toggle", "This tool does not work with RGB images.\n"
                           + "Please convert to grayscale first (Image > Type > 8-bit).");
        return false;
    }
    return true;
}
