// Battle Chasers Reference Image Downloader - Final Version
// Curated high-quality images for LoRA training

const https = require('https');
const fs = require('fs');
const path = require('path');

const OUTPUT_DIR = './battle_chasers_refs';
const DELAY_MS = 2500;

// Curated image URLs collected from ArtStation
const IMAGE_URLS = [
    // Joe Madureira - NPC Vendors (colorful character art)
    'https://cdnb.artstation.com/p/assets/images/images/022/476/935/large/joe-mx-vendor-arenamaster.jpg',
    'https://cdna.artstation.com/p/assets/images/images/022/476/934/large/joe-mx-vendor-fishmonger.jpg',
    'https://cdnb.artstation.com/p/assets/images/images/022/476/937/large/joe-mx-vendor-miner.jpg',
    'https://cdnb.artstation.com/p/assets/images/images/022/476/939/large/joe-mx-vendor-beastmaster.jpg',
    'https://cdnb.artstation.com/p/assets/images/images/022/476/941/large/joe-mx-vendor-curio.jpg',
    'https://cdna.artstation.com/p/assets/images/images/022/476/944/large/joe-mx-vendor-enchantress.jpg',
    'https://cdna.artstation.com/p/assets/images/images/022/476/936/large/joe-mx-vendor-bartender.jpg',

    // Grace Liu - Character Concepts (heroes and enemies)
    'https://cdnb.artstation.com/p/assets/images/images/010/803/551/large/grace-liu-hero-alumon.jpg',
    'https://cdnb.artstation.com/p/assets/images/images/010/803/571/large/grace-liu-enemy-destra.jpg',
    'https://cdnb.artstation.com/p/assets/images/images/010/803/559/large/grace-liu-enemy-bandits.jpg',
    'https://cdna.artstation.com/p/assets/images/images/010/803/558/large/grace-liu-enemy-headsman.jpg',
    'https://cdnb.artstation.com/p/assets/images/images/010/803/563/large/grace-liu-enemy-skeleton-champion.jpg',
    'https://cdnb.artstation.com/p/assets/images/images/010/803/565/large/grace-liu-enemy-skeleton-mage.jpg',
    'https://cdnb.artstation.com/p/assets/images/images/010/803/561/large/grace-liu-enemy-bat.jpg',
    'https://cdna.artstation.com/p/assets/images/images/010/803/554/large/grace-liu-robotic-enemy-paintovers.jpg',
    'https://cdna.artstation.com/p/assets/images/images/010/803/570/large/grace-liu-enemy-bloodstained-vampire-a.jpg',
    'https://cdna.artstation.com/p/assets/images/images/010/803/556/large/grace-liu-enemy-giantskull.jpg',
    'https://cdna.artstation.com/p/assets/images/images/010/803/572/large/grace-liu-enemy-flamethrower-colored.jpg',
    'https://cdnb.artstation.com/p/assets/images/images/010/803/569/large/grace-liu-enemy-slime-painted.jpg',

    // Grace Liu - Key Art (main characters)
    'https://cdnb.artstation.com/p/assets/images/images/003/114/545/large/grace-liu-bcnw-key-art-2-variant-1.jpg',

    // Grace Liu - Burst Banners (character portraits)
    'https://cdna.artstation.com/p/assets/images/images/010/819/762/large/grace-liu-bc-banners.jpg',
    'https://cdna.artstation.com/p/assets/images/images/010/819/768/large/grace-liu-bc-banners-02.jpg',

    // Billy Garretsen - Battle Chasers Covers
    'https://cdnb.artstation.com/p/assets/images/images/075/025/961/large/billy-garretsen-bc-10-cover-jm-colored-screenres1600.jpg',
    'https://cdna.artstation.com/p/assets/images/images/075/025/944/large/billy-garretsen-bc-10-cover-jm-linecolorcomp-2024.jpg',

    // Additional curated URLs for variety
    'https://cdna.artstation.com/p/assets/images/images/003/114/552/large/grace-liu-bcnw-combat-bkg-forest-1.jpg',
    'https://cdnb.artstation.com/p/assets/images/images/003/114/547/large/grace-liu-bcnw-combat-bkg-cave-1.jpg',
    'https://cdna.artstation.com/p/assets/images/images/010/819/754/large/grace-liu-bc-vendor-arenamaster-colored.jpg',
    'https://cdnb.artstation.com/p/assets/images/images/010/819/759/large/grace-liu-bc-vendor-fishmonger-colored.jpg',
    'https://cdna.artstation.com/p/assets/images/images/003/114/550/large/grace-liu-bcnw-combat-bkg-junktown-1.jpg',
];

if (!fs.existsSync(OUTPUT_DIR)) {
    fs.mkdirSync(OUTPUT_DIR, { recursive: true });
}

function delay(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}

function downloadImage(url, filepath) {
    return new Promise((resolve, reject) => {
        const request = https.get(url, {
            headers: {
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
                'Accept': 'image/webp,image/apng,image/*,*/*;q=0.8',
                'Accept-Language': 'en-US,en;q=0.9',
                'Referer': 'https://www.artstation.com/',
                'Origin': 'https://www.artstation.com'
            }
        }, (response) => {
            if (response.statusCode === 301 || response.statusCode === 302) {
                downloadImage(response.headers.location, filepath)
                    .then(resolve)
                    .catch(reject);
                return;
            }

            if (response.statusCode !== 200) {
                reject(new Error(`HTTP ${response.statusCode}`));
                return;
            }

            const fileStream = fs.createWriteStream(filepath);
            response.pipe(fileStream);

            fileStream.on('finish', () => {
                fileStream.close();
                resolve(true);
            });

            fileStream.on('error', reject);
        });

        request.on('error', reject);
        request.setTimeout(30000, () => {
            request.destroy();
            reject(new Error('Timeout'));
        });
    });
}

async function main() {
    console.log('='.repeat(60));
    console.log('Battle Chasers Reference Image Downloader');
    console.log('='.repeat(60));
    console.log(`Target: ${IMAGE_URLS.length} curated images`);
    console.log(`Output: ${path.resolve(OUTPUT_DIR)}`);
    console.log('='.repeat(60));
    console.log('');

    const downloaded = [];
    const failed = [];
    let counter = 0;

    for (const url of IMAGE_URLS) {
        counter++;
        const ext = url.match(/\.(jpg|jpeg|png|webp)/i)?.[1] || 'jpg';
        const filename = `bc_${String(counter).padStart(3, '0')}.${ext}`;
        const filepath = path.join(OUTPUT_DIR, filename);

        // Extract descriptive name from URL
        const urlParts = url.split('/');
        const originalName = urlParts[urlParts.length - 1].split('?')[0];

        console.log(`[${counter}/${IMAGE_URLS.length}] ${filename}`);
        console.log(`    Source: ${originalName}`);

        try {
            await downloadImage(url, filepath);

            const stats = fs.statSync(filepath);
            if (stats.size < 5000) {
                fs.unlinkSync(filepath);
                console.log(`    SKIP (too small: ${stats.size} bytes)`);
                failed.push({ url, error: 'Too small' });
                counter--;
                continue;
            }

            downloaded.push({
                filename,
                size: stats.size,
                source: originalName
            });
            console.log(`    OK (${(stats.size / 1024).toFixed(1)} KB)`);

            await delay(DELAY_MS);
        } catch (e) {
            failed.push({ url, error: e.message });
            console.log(`    FAILED: ${e.message}`);
            counter--;
        }
    }

    // Summary
    console.log('\n' + '='.repeat(60));
    console.log('DOWNLOAD SUMMARY');
    console.log('='.repeat(60));
    console.log(`Successfully downloaded: ${downloaded.length} images`);
    console.log(`Failed: ${failed.length}`);
    console.log(`Output directory: ${path.resolve(OUTPUT_DIR)}`);
    console.log('');

    console.log('Downloaded files:');
    console.log('-'.repeat(50));

    let totalSize = 0;
    for (const file of downloaded) {
        const sizeKB = (file.size / 1024).toFixed(1);
        console.log(`  ${file.filename.padEnd(15)} ${sizeKB.padStart(8)} KB  ${file.source}`);
        totalSize += file.size;
    }

    console.log('-'.repeat(50));
    console.log(`Total size: ${(totalSize / 1024 / 1024).toFixed(2)} MB`);

    if (failed.length > 0) {
        console.log('\nFailed downloads:');
        for (const f of failed) {
            console.log(`  ${f.error}: ${f.url.substring(0, 60)}...`);
        }
    }

    console.log('\n' + '='.repeat(60));
    console.log('Done! Images ready for LoRA training.');
    console.log('='.repeat(60));
}

main().catch(console.error);
