// Battle Chasers COMPLETE Style Training Dataset
// Optimized for scenario.gg LoRA training - BEST QUALITY

const https = require('https');
const fs = require('fs');
const path = require('path');

const OUTPUT_DIR = './battle_chasers_refs/style';
const DELAY_MS = 2000;

// CURATED HIGH-QUALITY STYLE IMAGES
// Focus: Colorful, vibrant, consistent Battle Chasers aesthetic
const STYLE_URLS = [
    // === VENDOR BACKGROUNDS (Character + Environment - EXCELLENT for style) ===
    { url: 'https://cdna.artstation.com/p/assets/images/images/007/571/528/large/grace-liu-bc-vendorbg-inn.jpg', name: 'style_vendor_inn.jpg', desc: 'Inn Vendor + Background' },
    { url: 'https://cdnb.artstation.com/p/assets/images/images/007/571/407/large/grace-liu-bc-vendorbg-curio.jpg', name: 'style_vendor_curio.jpg', desc: 'Curio Vendor + Background' },
    { url: 'https://cdna.artstation.com/p/assets/images/images/007/571/408/large/grace-liu-bc-vendorbg-enchantress.jpg', name: 'style_vendor_enchantress.jpg', desc: 'Enchantress Vendor + Background' },
    { url: 'https://cdna.artstation.com/p/assets/images/images/007/571/406/large/grace-liu-bc-vendorbg-beast.jpg', name: 'style_vendor_beast.jpg', desc: 'Beastmaster Vendor + Background' },
    { url: 'https://cdna.artstation.com/p/assets/images/images/007/571/410/large/grace-liu-bc-vendorbg-fishmonger.jpg', name: 'style_vendor_fishmonger.jpg', desc: 'Fishmonger Vendor + Background' },
    { url: 'https://cdna.artstation.com/p/assets/images/images/007/571/400/large/grace-liu-bc-vendorbg-minert.jpg', name: 'style_vendor_miner.jpg', desc: 'Miner Vendor + Background' },
    { url: 'https://cdna.artstation.com/p/assets/images/images/007/571/404/large/grace-liu-bc-vendorbg-arena.jpg', name: 'style_vendor_arena.jpg', desc: 'Arena Master Vendor + Background' },
    { url: 'https://cdnb.artstation.com/p/assets/images/images/007/571/455/large/grace-liu-bc-vendorbg-smith.jpg', name: 'style_vendor_smith.jpg', desc: 'Blacksmith Vendor + Background' },
    { url: 'https://cdna.artstation.com/p/assets/images/images/007/571/424/large/grace-liu-bc-vendorbg-collector.jpg', name: 'style_vendor_collector.jpg', desc: 'Collector Vendor + Background' },
    { url: 'https://cdnb.artstation.com/p/assets/images/images/007/571/425/large/grace-liu-bc-vendorbg-resting.jpg', name: 'style_vendor_resting.jpg', desc: 'Resting Area + Background' },

    // === COMBAT BACKGROUNDS (Environment Art - Colorful) ===
    { url: 'https://cdna.artstation.com/p/assets/images/images/007/531/558/large/grace-liu-bc-bg-forest-a-01.jpg', name: 'style_bg_forest_01.jpg', desc: 'Forest Combat BG 1' },
    { url: 'https://cdna.artstation.com/p/assets/images/images/007/531/560/large/grace-liu-bc-bg-forest-a-02.jpg', name: 'style_bg_forest_02.jpg', desc: 'Forest Combat BG 2' },
    { url: 'https://cdnb.artstation.com/p/assets/images/images/007/531/563/large/grace-liu-bc-bg-forest-a-03.jpg', name: 'style_bg_forest_03.jpg', desc: 'Forest Combat BG 3' },
    { url: 'https://cdna.artstation.com/p/assets/images/images/007/531/566/large/grace-liu-bc-bg-forest-a-04.jpg', name: 'style_bg_bandit_camp.jpg', desc: 'Bandit Camp BG' },

    // === COMIC COVERS (Premium Character Art - Joe Mad + Billy Garretsen) ===
    { url: 'https://cdnb.artstation.com/p/assets/images/images/065/388/169/large/billy-garretsen-vectorflats-06-review10.jpg', name: 'style_cover_bc12.jpg', desc: 'BC #12 Cover - Full Color' },
    { url: 'https://cdnb.artstation.com/p/assets/images/images/065/504/949/large/billy-garretsen-bc11-joemx-color-updatenosignage-1600-b.jpg', name: 'style_cover_bc11.jpg', desc: 'BC #11 Cover - Full Color' },

    // === COLORED VIGNETTES (Multiple Characters - Excellent Style Reference) ===
    { url: 'https://cdnb.artstation.com/p/assets/images/images/007/604/579/large/billy-garretsen-gracecollab-fin1.jpg', name: 'style_vignettes_colored.jpg', desc: 'Colored Vignettes Compilation' },
];

if (!fs.existsSync(OUTPUT_DIR)) {
    fs.mkdirSync(OUTPUT_DIR, { recursive: true });
}

function delay(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}

function downloadImage(url, filepath) {
    return new Promise((resolve, reject) => {
        https.get(url, {
            headers: {
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
                'Referer': 'https://www.artstation.com/',
                'Accept': 'image/webp,image/apng,image/*,*/*;q=0.8',
                'Accept-Language': 'en-US,en;q=0.9'
            }
        }, (response) => {
            if (response.statusCode === 301 || response.statusCode === 302) {
                downloadImage(response.headers.location, filepath).then(resolve).catch(reject);
                return;
            }
            if (response.statusCode !== 200) {
                reject(new Error(`HTTP ${response.statusCode}`));
                return;
            }
            const stream = fs.createWriteStream(filepath);
            response.pipe(stream);
            stream.on('finish', () => { stream.close(); resolve(true); });
            stream.on('error', reject);
        }).on('error', reject);
    });
}

async function main() {
    console.log('');
    console.log('╔══════════════════════════════════════════════════════════════╗');
    console.log('║  BATTLE CHASERS - COMPLETE STYLE TRAINING DATASET            ║');
    console.log('║  Optimized for scenario.gg LoRA Training                     ║');
    console.log('╚══════════════════════════════════════════════════════════════╝');
    console.log('');
    console.log(`Downloading ${STYLE_URLS.length} additional style images...`);
    console.log('');

    const downloaded = [];
    const failed = [];

    for (let i = 0; i < STYLE_URLS.length; i++) {
        const item = STYLE_URLS[i];
        const filepath = path.join(OUTPUT_DIR, item.name);

        console.log(`[${i + 1}/${STYLE_URLS.length}] ${item.desc}`);
        console.log(`    → ${item.name}`);

        try {
            await downloadImage(item.url, filepath);
            const stats = fs.statSync(filepath);

            if (stats.size < 10000) {
                fs.unlinkSync(filepath);
                console.log(`    ✗ SKIPPED (too small)`);
                failed.push({ ...item, error: 'Too small' });
                continue;
            }

            downloaded.push({ ...item, size: stats.size });
            console.log(`    ✓ OK (${(stats.size / 1024).toFixed(0)} KB)`);
            await delay(DELAY_MS);
        } catch (e) {
            failed.push({ ...item, error: e.message });
            console.log(`    ✗ FAILED: ${e.message}`);
        }
    }

    console.log('');
    console.log('═'.repeat(65));
    console.log('DOWNLOAD COMPLETE');
    console.log('═'.repeat(65));
    console.log(`✓ Downloaded: ${downloaded.length} images`);
    console.log(`✗ Failed: ${failed.length}`);

    const totalSize = downloaded.reduce((sum, f) => sum + f.size, 0);
    console.log(`📦 Total size: ${(totalSize / 1024 / 1024).toFixed(2)} MB`);
    console.log('═'.repeat(65));
}

main().catch(console.error);
