// Battle Chasers PREMIUM 5-STAR Content
// Maximum quality for scenario.gg LoRA

const https = require('https');
const fs = require('fs');
const path = require('path');

const OUTPUT_DIR = './battle_chasers_refs/style';
const DELAY_MS = 2000;

const PREMIUM_URLS = [
    // === WINTERVEIN COMBAT BACKGROUNDS (Ice/Snow - Colorful) ===
    { url: 'https://cdnb.artstation.com/p/assets/images/images/007/522/395/large/grace-liu-bc-combatbg-wv-01.jpg', name: 'premium_wintervein_01.jpg' },
    { url: 'https://cdnb.artstation.com/p/assets/images/images/007/522/447/large/grace-liu-bc-combatbg-wv-02.jpg', name: 'premium_wintervein_02.jpg' },
    { url: 'https://cdnb.artstation.com/p/assets/images/images/007/522/449/large/grace-liu-bc-combatbg-wv-03.jpg', name: 'premium_wintervein_03.jpg' },

    // === CAVE COMBAT BACKGROUNDS (Dungeon - Atmospheric) ===
    { url: 'https://cdna.artstation.com/p/assets/images/images/007/545/070/large/grace-liu-bc-bg-cave-a2.jpg', name: 'premium_cave_01.jpg' },
    { url: 'https://cdnb.artstation.com/p/assets/images/images/007/545/081/large/grace-liu-bc-bg-cave-a.jpg', name: 'premium_cave_02.jpg' },
    { url: 'https://cdna.artstation.com/p/assets/images/images/007/545/072/large/grace-liu-bc-bg-cave-aboss.jpg', name: 'premium_cave_boss.jpg' },

    // === ARENA COMBAT BACKGROUNDS (Epic Battle Scenes) ===
    { url: 'https://cdnb.artstation.com/p/assets/images/images/007/554/573/large/grace-liu-bc-bg-arena-lyce.jpg', name: 'premium_arena_boss.jpg' },
    { url: 'https://cdnb.artstation.com/p/assets/images/images/007/554/577/large/grace-liu-bc-bg-arena.jpg', name: 'premium_arena_main.jpg' },

    // === WORLD MAP LOCATIONS (Vibrant Overworld Art) ===
    { url: 'https://cdna.artstation.com/p/assets/images/images/008/030/262/large/grace-liu-6-worldmap-screenshot.jpg', name: 'premium_worldmap_ironoutpost.jpg' },
    { url: 'https://cdna.artstation.com/p/assets/images/images/008/030/266/large/grace-liu-7-worldmap-screenshot2.jpg', name: 'premium_worldmap_arena.jpg' },
    { url: 'https://cdna.artstation.com/p/assets/images/images/008/030/272/large/grace-liu-wm-rushland.jpg', name: 'premium_worldmap_rushland.jpg' },
    { url: 'https://cdnb.artstation.com/p/assets/images/images/008/030/265/large/grace-liu-wm-junktown.jpg', name: 'premium_worldmap_junktown.jpg' },
    { url: 'https://cdna.artstation.com/p/assets/images/images/008/030/270/large/grace-liu-7-worldmap-screenshot3.jpg', name: 'premium_worldmap_thedig.jpg' },
    { url: 'https://cdnb.artstation.com/p/assets/images/images/008/030/271/large/grace-liu-wm-deadwatch.jpg', name: 'premium_worldmap_deadwatch.jpg' },
    { url: 'https://cdnb.artstation.com/p/assets/images/images/008/030/275/large/grace-liu-wm-strongmont.jpg', name: 'premium_worldmap_strongmont.jpg' },
    { url: 'https://cdnb.artstation.com/p/assets/images/images/008/030/261/large/grace-liu-wm-iris.jpg', name: 'premium_worldmap_iris.jpg' },
    { url: 'https://cdna.artstation.com/p/assets/images/images/008/030/274/large/grace-liu-wm-garden.jpg', name: 'premium_worldmap_garden.jpg' },
    { url: 'https://cdnb.artstation.com/p/assets/images/images/008/030/269/large/grace-liu-wm-manarift.jpg', name: 'premium_worldmap_manarift.jpg' },
    { url: 'https://cdna.artstation.com/p/assets/images/images/008/030/268/large/grace-liu-wm-castle.jpg', name: 'premium_worldmap_castle.jpg' },
];

function delay(ms) { return new Promise(resolve => setTimeout(resolve, ms)); }

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
            if (response.statusCode !== 200) { reject(new Error(`HTTP ${response.statusCode}`)); return; }
            const stream = fs.createWriteStream(filepath);
            response.pipe(stream);
            stream.on('finish', () => { stream.close(); resolve(true); });
            stream.on('error', reject);
        }).on('error', reject);
    });
}

async function main() {
    console.log('');
    console.log('╔════════════════════════════════════════════════════════════════╗');
    console.log('║  ⭐⭐⭐⭐⭐ PREMIUM 5-STAR CONTENT ⭐⭐⭐⭐⭐                    ║');
    console.log('║  Battle Chasers - Environment & World Art                      ║');
    console.log('╚════════════════════════════════════════════════════════════════╝');
    console.log('');

    let downloaded = 0, failed = 0;

    for (let i = 0; i < PREMIUM_URLS.length; i++) {
        const item = PREMIUM_URLS[i];
        const filepath = path.join(OUTPUT_DIR, item.name);
        console.log(`[${i + 1}/${PREMIUM_URLS.length}] ${item.name}`);

        try {
            await downloadImage(item.url, filepath);
            const size = fs.statSync(filepath).size;
            console.log(`    ⭐ OK (${(size / 1024).toFixed(0)} KB)`);
            downloaded++;
            await delay(DELAY_MS);
        } catch (e) {
            console.log(`    ✗ FAILED: ${e.message}`);
            failed++;
        }
    }

    console.log('');
    console.log('═'.repeat(66));
    console.log(`⭐ PREMIUM DOWNLOAD COMPLETE: ${downloaded}/${PREMIUM_URLS.length}`);
    console.log('═'.repeat(66));
}

main().catch(console.error);
