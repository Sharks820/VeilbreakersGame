// Battle Chasers UI & Icon Reference Downloader
// Billy Garretsen's UI art and weapon icons

const https = require('https');
const fs = require('fs');
const path = require('path');

const OUTPUT_DIR = './battle_chasers_refs';
const DELAY_MS = 2500;

const UI_URLS = [
    // UI Art & Design
    { url: 'https://cdnb.artstation.com/p/assets/images/images/007/400/889/large/billy-garretsen-bc-ui-menugameselect.jpg', name: 'bc_027.jpg', desc: 'Main Menu UI' },
    { url: 'https://cdna.artstation.com/p/assets/images/images/007/400/806/large/billy-garretsen-bc-ui-combatbattle02.jpg', name: 'bc_028.jpg', desc: 'Combat HUD UI' },
    { url: 'https://cdnb.artstation.com/p/assets/images/images/007/400/795/large/billy-garretsen-bc-ui-partyselection.jpg', name: 'bc_029.jpg', desc: 'Party Select UI' },
    { url: 'https://cdnb.artstation.com/p/assets/images/images/007/400/807/large/billy-garretsen-bc-ui-dungeoninfo.jpg', name: 'bc_030.jpg', desc: 'Dungeon Info UI' },
    { url: 'https://cdna.artstation.com/p/assets/images/images/007/400/798/large/billy-garretsen-bc-ui-dungeonhud01.jpg', name: 'bc_031.jpg', desc: 'Dungeon HUD UI' },
    { url: 'https://cdna.artstation.com/p/assets/images/images/007/400/790/large/billy-garretsen-bc-ui-forgecrafting.jpg', name: 'bc_032.jpg', desc: 'Crafting Station UI' },
    { url: 'https://cdnb.artstation.com/p/assets/images/images/007/400/801/large/billy-garretsen-bc-ui-bookequip01.jpg', name: 'bc_033.jpg', desc: 'Equipment UI 1' },
    { url: 'https://cdna.artstation.com/p/assets/images/images/007/400/804/large/billy-garretsen-bc-ui-bookequip02.jpg', name: 'bc_034.jpg', desc: 'Equipment UI 2' },
    { url: 'https://cdna.artstation.com/p/assets/images/images/007/400/796/large/billy-garretsen-bc-ui-bookinventory.jpg', name: 'bc_035.jpg', desc: 'Inventory UI' },
    { url: 'https://cdnb.artstation.com/p/assets/images/images/007/400/797/large/billy-garretsen-bc-ui-bookcraftingindex.jpg', name: 'bc_036.jpg', desc: 'Crafting Codex UI' },
    { url: 'https://cdnb.artstation.com/p/assets/images/images/007/400/793/large/billy-garretsen-bc-ui-bookbestiary.jpg', name: 'bc_037.jpg', desc: 'Bestiary UI' },
    { url: 'https://cdnb.artstation.com/p/assets/images/images/007/400/791/large/billy-garretsen-bc-ui-arenarewards.jpg', name: 'bc_038.jpg', desc: 'Arena Rewards UI' },
    { url: 'https://cdna.artstation.com/p/assets/images/images/007/400/800/large/billy-garretsen-bc-ui-combatarena01.jpg', name: 'bc_039.jpg', desc: 'Arena Combat HUD' },

    // Weapon Icons
    { url: 'https://cdna.artstation.com/p/assets/images/images/007/449/452/large/billy-garretsen-bc-icons-gullygloves.jpg', name: 'bc_040.jpg', desc: 'Gully Glove Icons' },
    { url: 'https://cdna.artstation.com/p/assets/images/images/007/449/542/large/billy-garretsen-bc-icons-calibrettocannons.jpg', name: 'bc_041.jpg', desc: 'Calibretto Cannon Icons' },
    { url: 'https://cdnb.artstation.com/p/assets/images/images/007/449/505/large/billy-garretsen-bc-icons-garrisonsword.jpg', name: 'bc_042.jpg', desc: 'Garrison Sword Icons' },
    { url: 'https://cdna.artstation.com/p/assets/images/images/007/449/454/large/billy-garretsen-bc-icons-knolanstx.jpg', name: 'bc_043.jpg', desc: 'Knolan Staff Icons' },
    { url: 'https://cdnb.artstation.com/p/assets/images/images/007/449/455/large/billy-garretsen-bc-icons-monikapistols.jpg', name: 'bc_044.jpg', desc: 'Monika Pistol Icons' },
    { url: 'https://cdnb.artstation.com/p/assets/images/images/007/449/507/large/billy-garretsen-bc-icons-alumonshield.jpg', name: 'bc_045.jpg', desc: 'Alumon Shield Icons' },
];

function delay(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}

function downloadImage(url, filepath) {
    return new Promise((resolve, reject) => {
        https.get(url, {
            headers: {
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
                'Referer': 'https://www.artstation.com/',
                'Accept': 'image/*'
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
    console.log('='.repeat(60));
    console.log('Battle Chasers UI & Icon Downloader');
    console.log('='.repeat(60));
    console.log(`Downloading ${UI_URLS.length} UI/Icon images...`);
    console.log('');

    const downloaded = [];
    const failed = [];

    for (const item of UI_URLS) {
        const filepath = path.join(OUTPUT_DIR, item.name);
        console.log(`[${item.name}] ${item.desc}`);

        try {
            await downloadImage(item.url, filepath);
            const stats = fs.statSync(filepath);
            downloaded.push({ ...item, size: stats.size });
            console.log(`  OK (${(stats.size / 1024).toFixed(1)} KB)`);
            await delay(DELAY_MS);
        } catch (e) {
            failed.push({ ...item, error: e.message });
            console.log(`  FAILED: ${e.message}`);
        }
    }

    console.log('\n' + '='.repeat(60));
    console.log('UI DOWNLOAD SUMMARY');
    console.log('='.repeat(60));
    console.log(`Downloaded: ${downloaded.length}`);
    console.log(`Failed: ${failed.length}`);

    let totalSize = downloaded.reduce((sum, f) => sum + f.size, 0);
    console.log(`Total size: ${(totalSize / 1024 / 1024).toFixed(2)} MB`);
    console.log('='.repeat(60));
}

main().catch(console.error);
