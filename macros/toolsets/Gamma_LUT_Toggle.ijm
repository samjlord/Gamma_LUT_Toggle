// Sam Lord 2026
// https://github.com/samjlord/Gamma_LUT_Toggle
// Version 2.0
//
//   left-click  the tool icon : toggle the gamma LUT on / off
//   right-click the tool icon : enter an arbitrary gamma and apply it (relative to linear)


var gammaValue   = 0.45;      // current gamma exponent
var gammaApplied = false;
var gammaImageID = 0;         // the image the saved LUT belongs to
var origReds, origGreens, origBlues;


macro "Gamma LUT Toggle Action Tool - C000T4b12y" {

    if (!imageOK()) exit();

    // The saved LUT belongs to a different image, so treat this one as untouched.
    if (gammaApplied && getImageID() != gammaImageID)
        gammaApplied = false;

    if (!gammaApplied) {
        getLut(origReds, origGreens, origBlues);
        gammaImageID = getImageID();
        applyGamma(gammaValue);
        gammaApplied = true;
        showStatus("Gamma " + d2s(gammaValue, 3) + " ON");

    } else {
        setLut(origReds, origGreens, origBlues);
        gammaApplied = false;
        showStatus("Gamma 1.0 (original LUT)");
    }
}


macro "Gamma LUT Toggle Action Tool Options" {

    Dialog.create("Gamma LUT Toggle");
    Dialog.addNumber("Gamma:", gammaValue, 3, 8, "");
    Dialog.addMessage("Applied to the original LUT, never compounded:\n"
                    + "the LUT is returned to linear first.\n \n"
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
        showStatus("Gamma set to " + d2s(gammaValue, 3) + " (no image open)");
        exit();
    }
    if (bitDepth() == 24) {
        showStatus("Gamma set to " + d2s(gammaValue, 3) + " (RGB - convert to 8-bit)");
        exit();
    }

    // Back to the linear LUT, then apply the new gamma to it.
    if (gammaApplied && getImageID() == gammaImageID) {
        setLut(origReds, origGreens, origBlues);
    } else {
        getLut(origReds, origGreens, origBlues);
        gammaImageID = getImageID();
    }
    applyGamma(gammaValue);
    gammaApplied = true;
    showStatus("Gamma " + d2s(gammaValue, 3) + " ON");
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
    setLut(reds, greens, blues);
}


function imageOK() {
    if (nImages == 0) {
        showMessage("Error", "No image open.");
        return false;
    }
    if (bitDepth() == 24) {
        showMessage("Error", "This tool does not work with RGB images.\n"
                           + "Please convert to grayscale first (Image > Type > 8-bit).");
        return false;
    }
    return true;
}

        
    } else {
        // Restore original LUT
        setLut(origReds, origGreens, origBlues);
        gammaApplied = false;
        showStatus("Gamma 1.0 (original)");
    }
}
