const path = require('path');
const pptxgen = require('pptxgenjs');
const html2pptx = require('./html2pptx.js');

const slides = [
  'slide01-cover.html',
  'slide02-vision.html',
  'slide03-ia.html',
  'slide04-learning.html',
  'slide05-assistant.html',
  'slide06-arena.html',
  'slide07-community.html',
  'slide08-growth.html',
  'slide09-tech.html',
  'slide10-roadmap.html',
  'slide11-screens.html'
];

async function build() {
  const pptx = new pptxgen();
  pptx.layout = 'LAYOUT_16x9';
  pptx.author = 'StarKnow';
  pptx.title = '星知 StarKnow 项目介绍';

  for (const file of slides) {
    const htmlPath = path.join(__dirname, 'slides', file);
    await html2pptx(htmlPath, pptx);
  }

  const outPath = path.join(__dirname, 'starknow-intro.pptx');
  await pptx.writeFile({ fileName: outPath });
  console.log(`Saved: ${outPath}`);
}

build().catch((err) => {
  console.error(err);
  process.exit(1);
});
