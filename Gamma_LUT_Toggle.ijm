var gammaApplied = false;
var origReds, origGreens, origBlues;
macro "Gamma LUT Toggle Action Tool - C000T4b12γ" {
    // Check if image is RGB
    if (bitDepth() == 24) {
        showMessage("Error", "This tool does not work with RGB images.\nPlease convert to grayscale first (Image > Type > 8-bit).");
        exit();
    }
    
    if (!gammaApplied) {
        // Store original LUT
        getLut(origReds, origGreens, origBlues);
        
        // Apply gamma = 0.45
        getLut(reds, greens, blues);
        gamma = 0.45;
        
        for (i = 0; i < 256; i++) {
            reds[i] = round(255 * pow(reds[i]/255.0, gamma));
            greens[i] = round(255 * pow(greens[i]/255.0, gamma));
            blues[i] = round(255 * pow(blues[i]/255.0, gamma));
        }
        
        setLut(reds, greens, blues);
        gammaApplied = true;
        showStatus("Gamma 0.45 ON");
        
    } else {
        // Restore original LUT
        setLut(origReds, origGreens, origBlues);
        gammaApplied = false;
        showStatus("Gamma 1.0 (original)");
    }
}
