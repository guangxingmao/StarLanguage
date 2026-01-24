const sharp = require('sharp');
const path = require('path');

// Create gradient backgrounds for slides
async function createGradients() {
    const assetsDir = path.join(__dirname, 'assets');

    // Dark gradient for cover and other slides
    const darkGradient = `<svg xmlns="http://www.w3.org/2000/svg" width="960" height="540">
    <defs>
      <linearGradient id="g1" x1="0%" y1="0%" x2="100%" y2="100%">
        <stop offset="0%" style="stop-color:#1a1a2e"/>
        <stop offset="50%" style="stop-color:#16213e"/>
        <stop offset="100%" style="stop-color:#0f3460"/>
      </linearGradient>
    </defs>
    <rect width="100%" height="100%" fill="url(#g1)"/>
    <circle cx="880" cy="80" r="200" fill="rgba(255, 159, 28, 0.12)"/>
    <circle cx="80" cy="480" r="150" fill="rgba(102, 126, 234, 0.15)"/>
    <circle cx="700" cy="420" r="80" fill="rgba(184, 241, 224, 0.1)"/>
  </svg>`;

    await sharp(Buffer.from(darkGradient))
        .png()
        .toFile(path.join(assetsDir, 'bg-dark.png'));

    // Warm gradient for content slides
    const warmGradient = `<svg xmlns="http://www.w3.org/2000/svg" width="960" height="540">
    <defs>
      <linearGradient id="g2" x1="0%" y1="0%" x2="100%" y2="100%">
        <stop offset="0%" style="stop-color:#fff8e7"/>
        <stop offset="100%" style="stop-color:#ffe4c4"/>
      </linearGradient>
    </defs>
    <rect width="100%" height="100%" fill="url(#g2)"/>
  </svg>`;

    await sharp(Buffer.from(warmGradient))
        .png()
        .toFile(path.join(assetsDir, 'bg-warm.png'));

    // Orange accent sidebar
    const orangeSidebar = `<svg xmlns="http://www.w3.org/2000/svg" width="960" height="540">
    <rect width="100%" height="100%" fill="#fff8f0"/>
    <rect x="0" y="0" width="8" height="540" fill="#FF9F1C"/>
  </svg>`;

    await sharp(Buffer.from(orangeSidebar))
        .png()
        .toFile(path.join(assetsDir, 'bg-accent.png'));

    // Screenshots background (for displaying phone mockups)
    const screenshotsBg = `<svg xmlns="http://www.w3.org/2000/svg" width="960" height="540">
    <defs>
      <linearGradient id="g3" x1="0%" y1="0%" x2="100%" y2="100%">
        <stop offset="0%" style="stop-color:#1a1a2e"/>
        <stop offset="100%" style="stop-color:#2d3561"/>
      </linearGradient>
    </defs>
    <rect width="100%" height="100%" fill="url(#g3)"/>
  </svg>`;

    await sharp(Buffer.from(screenshotsBg))
        .png()
        .toFile(path.join(assetsDir, 'bg-screenshots.png'));

    console.log('Gradient backgrounds created successfully!');
}

createGradients().catch(console.error);
